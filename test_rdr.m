function test_rdr()
% Exercise numerical safeguards, sampling laws, and shared output contracts.
methods={'RK','RDR','mRDR','IRDR-I','IRDR-II','AmRDR-I','AmRDR-II'};
A=[1,0;0,1;1,1;2,-1]; target=[1;2]; b=A*target;
for k=1:numel(methods)
    opts=struct('xstar',target,'TOL',1e-12,'Max_iter',10000,'Seed',42);
    [x,o]=rdr_solve(A,b,methods{k},opts);
    assert(o.converged && norm(x-target)/norm(target)<=1e-6);
    assert(o.iterations(1)==0 && o.iterations(end)==o.iter);
    assert(numel(o.error)==numel(o.times) && all(diff(o.times)>=0));
    assert(abs(o.error(1)-1)<eps && o.finalError==o.error(end));
    opts.initial=target;
    [~,o]=rdr_solve(A,b,methods{k},opts); assert(o.iter==0 && o.converged);
    opts.initial=zeros(2,1); opts.xstar=zeros(2,1);
    [~,o]=rdr_solve(A,zeros(4,1),methods{k},opts); assert(o.iter==0 && o.converged);
end
for name={'AmRDR-I','AmRDR-II'}
    % The first pair leaves x unchanged; the next pair must still be reached.
    opts=struct('xstar',[0;0;1],'PairSequence',[1,2;1,3],'Max_iter',4);
    [x,o]=rdr_solve(eye(3),[0;0;1],name{1},opts);
    assert(o.converged && o.RepeatCount==1 && all(isfinite(x)));
    opts.PairSequence=[1,2]; opts.Max_attempts=3;
    [~,o]=rdr_solve(eye(3),[0;0;1],name{1},opts);
    assert(strcmp(o.status,'max_attempts') && o.iter==0 && o.attempts==3);
    % Scaling the right-hand side must not trigger an absolute-step rejection.
    opts=struct('xstar',target*1e-20,'Max_iter',10000,'Seed',42);
    [~,o]=rdr_solve(A,b*1e-20,name{1},opts); assert(o.converged);
    opts=struct('xstar',target,'PairSequence',[1,3;3,4;1,2], ...
        'AngleTol',0.99,'Max_iter',1000);
    [~,o]=rdr_solve(A,b,name{1},opts);
    assert(o.FallbackCount>0 && isfinite(o.finalError));
end
[~,o]=rdr_solve(A,b,'RK',struct('initial',[0;0],'Max_iter',1,'TOL',0));
assert(o.iter==1 && strcmp(o.metric,'squared_relative_residual'));
[~,o]=rdr_solve(A,b,'RK',struct('Max_iter',0)); assert(o.iter==0);
% Initial error is normalized by the reference norm, not the initial error.
[~,o]=rdr_solve(A,b,'RK',struct('initial',3*target,'xstar',target,'Max_iter',0));
assert(abs(o.error(1)-4)<10*eps);
[~,o]=rdr_solve(A,b,'RK',struct('Max_iter',1,'Max_attempts',1,'TOL',0));
assert(strcmp(o.status,'max_iter'));
% Check the stabilized update against the original algebra on safe directions.
sequence=[1,3;2,4]; reference=zeros(2,1); previous=reference;
for k=1:size(sequence,1)
    i=sequence(k,1); j=sequence(k,2); ai=A(i,:)'; aj=A(j,:)';
    u=(ai'*reference-b(i))/(ai'*ai);
    y=reference-2*u*ai; v=(aj'*y-b(j))/(aj'*aj);
    z=y-2*v*aj; t=(reference-z)/2; d=reference-previous;
    if k==1
        next=reference-t;
    else
        den=(d'*d)*(t'*t)-(d'*t)^2;
        assert(den>1e-10);
        numerator=t'*reference-u*b(i)-v*b(j);
        next=reference-(d'*d)*numerator/den*t+(d'*t)*numerator/den*d;
    end
    previous=reference; reference=next;
end
[actual,~]=rdr_solve(A,b,'AmRDR-I',struct('PairSequence',sequence,'Max_iter',2,'TOL',0));
assert(norm(actual-reference)<1e-12);
% Rank-deficient systems use the minimum-norm reference from a zero start.
B=[A,A(:,1)+A(:,2)]; bb=B*[1;2;3]; xx=lsqminnorm(B,bb);
for k=1:numel(methods)
    [~,o]=rdr_solve(B,bb,methods{k},struct('xstar',xx,'Max_iter',20000));
    assert(o.converged);
end
% Empirical checks detect triangular decoding and conditional-CDF errors.
C=[1,0;0,2;1,1;0,0]; p=rdr_prepare(C,true); N=100000;
s=RandStream('mt19937ar','Seed',91);
pair=rdr_sample(p,'rk',N,s);
freq=accumarray(pair(:,1),1,[4,1])/N;
assert(max(abs(freq-p.rowProbability))<0.01);
pair=rdr_sample(p,'distinct',N,s); assert(all(pair(:,1)~=pair(:,2)));
freq=accumarray(pair,1,[4,4])/N;
expected=zeros(4);
for i=1:3
    for j=1:3
        if i~=j, expected(i,j)=p.rowProbability(i)*p.rowProbability(j)/(1-p.rowProbability(i)); end
    end
end
assert(max(abs(freq(:)-expected(:)))<0.01);
pair=rdr_sample(p,'volume',N,s); freq=accumarray(pair,1,[4,4])/N;
w=sum(C.^2,2); expected=w*w'-(C*C').^2; expected=expected/sum(expected(:));
assert(max(abs(freq(:)-expected(:)))<0.01);
% Pair storage is gone; the obsolete CDF memory limit has no effect.
p=rdr_prepare(C,true,1); assert(isempty(p.volumeCDF) && p.volumeReady);
try
    rdr_prepare([1,2;2,4;0,0],true);
    error('test:MissingError','Rank-one guard did not run.');
catch exception
    assert(strcmp(exception.identifier,'rdr:Rank'));
end
% Extremely concentrated proposals must terminate, never hang in a sampler.
D=[1,0;0,1e-8]; xx=ones(2,1);
[~,o]=rdr_solve(D,D*xx,'IRDR-II',struct('xstar',xx, ...
    'Max_volume_proposals',7,'Seed',1));
assert(strcmp(o.status,'max_volume_proposals') && o.VolumeProposals==7);
assert(o.VolumeRejected==7 && o.rowActions==14 && o.attempts==0);
% Accounting separates sampler rejection from zero-update rejection.
[~,o]=rdr_solve(A,b,'AmRDR-II',struct('xstar',target,'Seed',42));
assert(o.rowActions==2*o.attempts+2*o.VolumeProposals);
assert(o.VolumeProposals-o.VolumeRejected==o.attempts);
fprintf('ALL_RDR_TESTS_PASSED\n');
end
