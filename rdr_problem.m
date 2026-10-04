function [A,b,xstar,meta]=rdr_problem(c,seed,A)
% Build a consistent system using an isolated data-generation random stream.
stream=RandStream('mt19937ar','Seed',seed);
if nargin<3 || isempty(A)
    switch c.kind
        case 'spectral'
            [U,~]=qr(randn(stream,c.m,c.rank),0);
            [V,~]=qr(randn(stream,c.n,c.rank),0);
            s=ones(c.rank,1); s(1)=c.sigma;
            A=(U.*s')*V';
        case 'uniform'
            A=c.t+(1-c.t)*rand(stream,c.m,c.n);
        case 'real'
            root=fileparts(mfilename('fullpath'));
            found=dir(fullfile(root,'**',c.file));
            if isempty(found), error('rdr:Data','Missing matrix %s.',c.file); end
            data=load(fullfile(found(1).folder,found(1).name));
            if ~isfield(data,'Problem') || ~isfield(data.Problem,'A')
                error('rdr:Data','Expected Problem.A in %s.',c.file);
            end
            A=double(data.Problem.A);
        otherwise
            error('rdr:Data','Unknown matrix construction.');
    end
end
truth=randn(stream,size(A,2),1);
b=A*truth;
xstar=lsqminnorm(A,b);
meta=struct('seed',seed,'m',size(A,1),'n',size(A,2));
end
