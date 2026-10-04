function label=rdr_case_label(R)
%RDR_CASE_LABEL Show actual saved parameters, including reduced smoke sizes.
% A case identifier may retain its formal name during a smoke run, so it
% must not be used alone as the scientific description of a plotted system.
c=R.caseConfig;
if strcmp(c.kind,'spectral')
    sigma=c.sigma;
    if isfield(c,'singularValues') && ~isempty(c.singularValues)
        sigma=max(c.singularValues);
    end
    label=sprintf('$m=%d,\\quad n=%d,\\quad r=%d,\\quad \\sigma_1=%g$',c.m,c.n,c.rank,sigma);
elseif strcmp(c.kind,'uniform')
    label=sprintf('$m=%d,\\quad n=%d,\\quad t=%g$',c.m,c.n,c.t);
    if isfield(R,'matrixMetadata') && ~isempty(R.matrixMetadata)
        ranks=cellfun(@(v)v.rank,R.matrixMetadata);
        if all(isfinite(ranks)) && all(ranks==ranks(1))
            label=sprintf('$m=%d,\\quad n=%d,\\quad r=%d,\\quad t=%g$',c.m,c.n,ranks(1),c.t);
        end
    end
else
    % Use real-matrix metadata, never the placeholder synthetic dimensions.
    if isfield(R,'matrixMetadata') && ~isempty(R.matrixMetadata)
        meta=R.matrixMetadata{1}; m=meta.m; n=meta.n; rankA=meta.rank;
    else
        data=load(c.file,'Problem'); m=size(data.Problem.A,1); n=size(data.Problem.A,2);
        rankA=NaN;
        if isfield(R,'numericRank') && ~isempty(R.numericRank), rankA=R.numericRank(1); end
    end
    label=sprintf('$m=%d,\\quad n=%d$',m,n);
    if isfinite(rankA), label=sprintf('$m=%d,\\quad n=%d,\\quad r=%d$',m,n,rankA); end
end
end
