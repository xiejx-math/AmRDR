function prep = rdr_prepare(A, volume, maxPairBytes, sampler)
%RDR_PREPARE Select pair-CDF or diagonal-rejection volume sampling.
% Rejection mode forms no Gram matrix or pair CDF. A is retained by MATLAB's
% copy-on-write mechanism, so callers must keep the prepared A immutable.
% maxPairBytes bounds retained pair-CDF storage in pair_cdf mode.
if nargin<4, sampler='diagonal_rejection'; end
sampler=char(sampler);
if ~ismember(sampler,{'pair_cdf','diagonal_rejection'}), error('rdr:Sampler','Unknown volume sampler.'); end
if nargin<2, volume=false; end
if nargin<3, maxPairBytes=Inf; end %#ok<NASGU>
validateattributes(A,{'double'},{'2d','real','nonempty'});
if any(~isfinite(nonzeros(A))), error('rdr:Input','A must be finite.'); end
timer=tic;
scale=max(abs(nonzeros(A)));
if isempty(scale) || scale==0, error('rdr:Input','A must have a nonzero row.'); end
As=A/scale; w=full(sum(As.^2,2));
if any(~isfinite(w)) || sum(w)<=0, error('rdr:Scale','Invalid row weights.'); end
% Reject unrepresentable positive weights instead of silently dropping rows.
if any(w==0 & any(A~=0,2)), error('rdr:Scale','Row probabilities underflow.'); end
prep.size=size(A); prep.rowNorm2=full(sum(A.^2,2));
prep.rowProbability=w/sum(w); prep.rowCDF=cumsum(prep.rowProbability);
prep.rowCDF(end)=1; prep.volumeCDF=[]; prep.volumePairs=0;
prep.volumeReady=false; prep.volumeSampler=sampler;
prep.rowPrepTime=toc(timer); prep.volumePrepTime=0;
if ~volume, return; end
timer=tic;
if any(~isfinite(prep.rowNorm2)) || any(prep.rowNorm2==0 & w>0)
    error('rdr:Scale','Scale A and b together to keep row norms representable.');
end
if strcmp(sampler,'pair_cdf')
    % Original implementation: store one weight per unordered pair. Each
    % draw is followed by a fair coin to select the reflection ordering.
    m=size(A,1); count=m*(m-1)/2;
    if count*8>maxPairBytes
        error('rdr:Memory','Pair CDF exceeds MaxPairBytes (%.3g GB required).',count*8/1e9);
    end
    weights=zeros(count,1);
    for first=2:64:m
        cols=first:min(first+63,m); gram=full(As*As(cols,:)');
        for q=1:numel(cols)
            j=cols(q); offset=(j-1)*(j-2)/2;
            weights(offset+(1:j-1))=max(0,w(1:j-1)*w(j)-gram(1:j-1,q).^2);
        end
    end
    total=sum(weights);
    if ~isfinite(total) || total<=0, error('rdr:Rank','No positive volume weight.'); end
    prep.volumeCDF=cumsum(weights/total); prep.volumeCDF(end)=1;
    prep.volumePairs=count; prep.volumeReady=true;
    prep.volumePrepTime=toc(timer); return
end
% A linear-size collinearity check detects rank-one inputs without an SVD.
% This is a finite-precision guard, not a rank-revealing decomposition.
positive=find(w>0); [~,pivot]=max(w); u=As(pivot,:)/sqrt(w(pivot));
independent=false;
for k=positive'
    v=As(k,:)/sqrt(w(k)); d=v-(v*u')*u;
    if norm(d)>100*eps, independent=true; break; end
end
if ~independent, error('rdr:Rank','No numerically independent row pair.'); end
prep.volumeMatrix=A; prep.volumeRowNorm=sqrt(prep.rowNorm2);
prep.volumeReady=true; prep.volumePrepTime=toc(timer);
end
