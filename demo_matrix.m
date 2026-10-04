function [A,b,xstar,meta]=demo_matrix(c,seed,A)
% Construct paired systems; keep rank-deficient references in the row space.
if nargin<3, A=[]; end
stream=RandStream('mt19937ar','Seed',seed);
if isempty(A)
    if strcmp(c.kind,'real')
        data=load(c.file,'Problem'); A=double(data.Problem.A);
    elseif strcmp(c.kind,'spectral')
        [U,~]=qr(randn(stream,c.m,c.rank),0);
        [V,~]=qr(randn(stream,c.n,c.rank),0);
        delta=1; if isfield(c,'delta'), delta=c.delta; end
        s=delta*ones(c.rank,1); s(1)=c.sigma;
        if isfield(c,'singularValues') && ~isempty(c.singularValues), s=c.singularValues(:); end
        validateattributes(s,{'double'},{'vector','numel',c.rank,'positive','finite'});
        A=(U.*s')*V';
    else
        A=c.t+(1-c.t)*rand(stream,c.m,c.n);
    end
end
g=randn(stream,size(A,2),1); b=A*g;
xstar=lsqminnorm(A,b);
scale=norm(b); residual=norm(A*xstar-b)/max(scale,realmin);
if any(~isfinite(xstar)) || residual>1e-10
    error('demo:Reference','Reference residual %.3g is not reliable for %s.',residual,c.name);
end
meta=struct('seed',seed,'referenceResidual',residual);
end
