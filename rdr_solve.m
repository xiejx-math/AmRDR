function [x,out] = rdr_solve(A,b,method,opts)
% Solve a real consistent system using RK or one of six RDR variants.
% Reference mode uses squared relative solution error; residual mode uses
% squared relative residual. All methods use the same monitoring policy.
%
% COSTS: solveTime is tic/toc elapsed time, including all proposal rejections,
% updates, stopping checks and recorded histories. prepTime is separate when
% this function prepares A; the benchmark charges shared preprocessing itself.
% ITERATIONS: iter counts accepted updates. attempts counts update attempts,
% including AmRDR zero-direction rejections but excluding volume proposals.
% ROW WORK: update row actions are one per RK attempt and two per RDR attempt.
% Each volume proposal additionally charges two row accesses, conservatively
% including diagonal proposals, so rowActions includes both kinds of work.
% DIAGNOSTICS: VolumeRejected and RepeatCount describe different rejection
% layers and must not be combined into one rejection probability.
if nargin < 4, opts = struct; end
if ~isstruct(opts), error('rdr:Options','opts must be a structure.'); end
validateattributes(A,{'double'},{'2d','real','nonempty'});
validateattributes(b,{'double'},{'column','real','finite','numel',size(A,1)});
if any(~isfinite(nonzeros(A))), error('rdr:Input','A must be finite.'); end
[m,n] = size(A);
x = option('initial',zeros(n,1));
validateattributes(x,{'double'},{'column','real','finite','numel',n});
maxIter = option('Max_iter',200000);
maxAttempts = option('Max_attempts',max(1000,10*maxIter));
maxTime = option('Max_time',Inf);
maxRows = option('Max_row_actions',Inf);
tol = option('TOL',1e-12);
strictRSE = option('StrictRSE',false);
absTol = option('AbsTol',0);
alphaFixed = option('alpha',0.5);
betaFixed = option('beta',0);
angleTol = option('AngleTol',100*eps);
recordEvery = option('RecordEvery',10);
checkEvery = option('CheckEvery',1);
batchSize = option('BatchSize',256);
validateattributes(maxIter,{'numeric'},{'scalar','integer','nonnegative','finite'});
validateattributes(maxAttempts,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(tol,{'numeric'},{'scalar','nonnegative','finite'});
validateattributes(absTol,{'numeric'},{'scalar','nonnegative','finite'});
validateattributes(recordEvery,{'numeric'},{'scalar','integer','positive'});
validateattributes(checkEvery,{'numeric'},{'scalar','integer','positive'});
validateattributes(batchSize,{'numeric'},{'scalar','integer','positive'});
validateattributes(angleTol,{'numeric'},{'scalar','positive','<',1});
validateattributes(maxTime,{'numeric'},{'scalar','positive'});
validateattributes(maxRows,{'numeric'},{'real','scalar','nonnegative'});
if isfinite(maxRows) && maxRows~=fix(maxRows)
    error('rdr:Options','Max_row_actions must be an integer or Inf.');
end
validateattributes(alphaFixed,{'numeric'},{'real','scalar','finite','>',0,'<',1});
validateattributes(betaFixed,{'numeric'},{'real','scalar','finite'});
names = {'RK','RDR','mRDR','IRDR-I','IRDR-II','AmRDR-I','AmRDR-II'};
if ~ismember(method,names), error('rdr:Method','Unknown method.'); end
isRK = strcmp(method,'RK');
adaptive = startsWith(method,'AmRDR');
volume = endsWith(method,'-II');
if isRK, strategy='rk';
elseif volume, strategy='volume';
elseif endsWith(method,'-I'), strategy='distinct';
else, strategy='independent'; end
if isfield(opts,'Stream'), stream=opts.Stream;
else, stream=RandStream('mt19937ar','Seed',option('Seed',1)); end
hasReference = isfield(opts,'xstar');
if hasReference
    target = opts.xstar;
    validateattributes(target,{'double'},{'column','real','finite','numel',n});
    normScale = norm(target);
    metricName = 'squared_relative_solution_error';
else
    normScale = norm(b);
    metricName = 'squared_relative_residual';
end
if normScale == 0, metricName = strrep(metricName,'relative','absolute'); end
[err,converged] = measure(x);
iter=0; attempts=0; rejected=0; fallback=0; rowsUsed=0;
volumeProposals=0; volumeRejected=0; proposalRows=0;
maxVolumeProposals=option('Max_volume_proposals',maxAttempts);
validateattributes(maxVolumeProposals,{'numeric'},{'scalar','integer','positive','finite'});
minGap=Inf; gramFallback=0; historyFallback=0;
status='max_iter';
histIter=zeros(1024,1); histErr=histIter; histTime=histIter;
% Work histories align one-to-one with errors/times, including rejected work.
histRows=histIter; histProposalRows=histIter; histUpdateRows=histIter;
used=1; histErr(1)=err;
prepTime=0;
if converged
    status='converged'; solveTime=0; finish(); return
end
if maxIter==0, solveTime=0; finish(); return; end
if isfield(opts,'Prepared')
    prep=opts.Prepared;
    if ~isequal(prep.size,size(A)), error('rdr:Sampler','Prepared matrix size mismatch.'); end
else
    prep=rdr_prepare(A,volume,option('MaxPairBytes',2e9),option('VolumeSampler','diagonal_rejection'));
    prepTime=prep.rowPrepTime+prep.volumePrepTime;
end
if volume && (~isfield(prep,'volumeReady') || ~prep.volumeReady)
    error('rdr:Sampler','Prepared data must use the current rejection sampler.');
end
% Prepared data must belong to exactly the same immutable matrix A.
rowNorm2=prep.rowNorm2;
if any(~isfinite(rowNorm2)) || any(rowNorm2<0) || ~any(rowNorm2>0) || ...
        any(rowNorm2==0 & any(A~=0,2))
    error('rdr:Scale','Scale A and b together to avoid overflowing or underflowing row norms.');
end
if ~isRK && nnz(rowNorm2)>0 && nnz(rowNorm2)<2
    error('rdr:Rank','RDR requires rank at least two; use RK for rank-one systems.');
end
timer=tic;
previous=x;
haveHistory=false;
pairBatch=zeros(0,2); cursor=1;
while iter < maxIter && attempts < maxAttempts
    if rowsUsed+2-isRK>maxRows, status='max_row_actions'; break; end
    if toc(timer)>=maxTime, status='max_time'; break; end
    if isfield(opts,'PairSequence')
        % Deterministic row pairs support regression tests and diagnostics.
        seq=opts.PairSequence;
        pair=seq(mod(attempts,size(seq,1))+1,:);
        if numel(pair)~=2 || any(pair<1 | pair>m | pair~=fix(pair))
            error('rdr:Pairs','Invalid diagnostic row pair.');
        end
    elseif volume && strcmp(prep.volumeSampler,'diagonal_rejection')
        % Count proposal row access separately from projection/reflection work.
        % No accepted-pair prefetch: all rejection time belongs to this solve.
        if volumeProposals>=maxVolumeProposals
            status='max_volume_proposals'; break
        end
        if rowsUsed+4>maxRows, status='max_row_actions'; break; end
        [pair,ok]=rdr_volume_proposal(prep,stream);
        volumeProposals=volumeProposals+1;
        proposalRows=proposalRows+2; rowsUsed=rowsUsed+2;
        if ~ok
            volumeRejected=volumeRejected+1;
            recordRejectedWork();
            continue
        end
    else
        if cursor>size(pairBatch,1)
            pairBatch=rdr_sample(prep,strategy,batchSize,stream); cursor=1;
        end
        pair=pairBatch(cursor,:); cursor=cursor+1;
    end
    attempts=attempts+1;
    i=pair(1); j=pair(2);
    if rowNorm2(i)==0 || (~isRK && rowNorm2(j)==0)
        error('rdr:Pairs','A sampled row must be nonzero.');
    end
    ai=A(i,:)';
    p1=((ai'*x-b(i))/rowNorm2(i))*ai;
    rowsUsed=rowsUsed+1;
    if isRK
        candidate=x-p1;
    else
        aj=A(j,:)';
        p2=((aj'*(x-2*p1)-b(j))/rowNorm2(j))*aj;
        t=p1+p2;
        rowsUsed=rowsUsed+1;
        nt=norm(t);
        if ~isfinite(nt), status='numerical_failure'; break; end
        if adaptive && nt==0
            rejected=rejected+1;
            recordRejectedWork();
            continue
        end
        d=x-previous;
        if adaptive && haveHistory
            nd=norm(d);
            if nd==0 || ~isfinite(nd)
                candidate=x-t; fallback=fallback+1;
                historyFallback=historyFallback+1;
            else
                % Orthogonalize the reflection direction against the history.
                % For consistent systems <x-x*,t>=||t||^2 and <x-x*,d>=0.
                v=d/nd; q=t/nt; q=q-v*(v'*q);
                gap=q'*q;
                if isfinite(gap), minGap=min(minGap,gap); end
                if ~isfinite(gap) || gap<=angleTol
                    candidate=x-t; fallback=fallback+1;
                    gramFallback=gramFallback+1;
                else
                    candidate=x-(nt/gap)*q;
                end
            end
        elseif adaptive
            candidate=x-t;
        else
            momentum=0;
            if strcmp(method,'mRDR') && haveHistory, momentum=betaFixed; end
            candidate=x-2*alphaFixed*t+momentum*d;
        end
    end
    if any(~isfinite(candidate)), status='numerical_failure'; break; end
    if adaptive && all(candidate==x)
        % No representable progress is different from a mathematically zero pair.
        status='stagnation'; break
    end
    previous=x; x=candidate; haveHistory=true; iter=iter+1;
    % RecordEvery now measures total online row actions, not accepted updates.
    needRecord=rowsUsed-histRows(used)>=recordEvery;
    if mod(iter,checkEvery)==0 || needRecord || iter==maxIter
        [err,converged]=measure(x);
        if ~isfinite(err), status='numerical_failure'; break; end
        if needRecord || converged || iter==maxIter, append(); end
        if converged, status='converged'; break; end
    end
end
if strcmp(status,'max_iter') && iter<maxIter && attempts>=maxAttempts
    status='max_attempts';
end
[err,converged]=measure(x);
if converged, status='converged'; end
% A rejected tail can consume work without changing the accepted iterate.
% Always retain that tail at budget/time exit, including zero accepted steps.
if histRows(used)~=rowsUsed || histIter(used)~=iter, append(); end
solveTime=toc(timer);
finish();

    function value=option(name,default)
        if isfield(opts,name), value=opts.(name); else, value=default; end
    end
    function [value,done]=measure(y)
        if hasReference, en=norm(y-target); else, en=norm(A*y-b); end
        done=en<=absTol+sqrt(tol)*normScale;
        if normScale>0, value=(en/normScale)^2; else, value=en^2; end
        if strictRSE && normScale>0, done=value<tol; end
    end
    function recordRejectedWork()
        % Rejection leaves x unchanged but advances the work/time axes. Store
        % periodic plateaus; count every proposal even between saved samples.
        if rowsUsed-histRows(used)>=recordEvery
            [err,~]=measure(x); append();
        end
    end
    function append()
        used=used+1;
        if used>numel(histIter)
            histIter(end+1024)=0; histErr(end+1024)=0; histTime(end+1024)=0;
            histRows(end+1024)=0; histProposalRows(end+1024)=0; histUpdateRows(end+1024)=0;
        end
        histRows(used)=rowsUsed; histProposalRows(used)=proposalRows;
        histUpdateRows(used)=rowsUsed-proposalRows;
        histIter(used)=iter; histErr(used)=err; histTime(used)=toc(timer);
    end
    function finish()
        residual=norm(A*x-b); bnorm=norm(b);
        if bnorm>0, residual=residual/bnorm; end
        recordedGap=minGap; if isinf(recordedGap), recordedGap=NaN; end
        out=struct('method',method,'status',status,'converged',strcmp(status,'converged'), ...
            'iter',iter,'attempts',attempts,'rowActions',rowsUsed, ...
            'RepeatCount',rejected,'RepeatRate',rejected/max(attempts,1), ...
            'FallbackCount',fallback,'finalError',err,'metric',metricName, ...
            'MinNormalizedGram',recordedGap,'GramFallbacks',gramFallback, ...
            'HistoryFallbacks',historyFallback,'FinalResidual',residual, ...
            'VolumeProposals',volumeProposals,'VolumeRejected',volumeRejected, ...
            'VolumeRejectionRate',volumeRejected/max(volumeProposals,1), ...
            'ProposalRowActions',proposalRows,'UpdateRowActions',rowsUsed-proposalRows, ...
            'maxRowActions',maxRows, ...
            'rowActionsHistory',histRows(1:used), ...
            'proposalRowActionsHistory',histProposalRows(1:used), ...
            'updateRowActionsHistory',histUpdateRows(1:used), ...
            'rowActionConvention','online_updates_plus_two_per_volume_proposal', ...
            'iterations',histIter(1:used),'error',histErr(1:used), ...
            'times',histTime(1:used),'solveTime',solveTime,'prepTime',prepTime, ...
            'totalTime',solveTime+prepTime,'maxiter',maxIter);
    end
end
