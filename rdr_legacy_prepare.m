function prep=rdr_legacy_prepare(A,m,edges)
%RDR_LEGACY_PREPARE Migrate old call signatures to diagonal rejection.
% Old pair probabilities are deliberately not reused with the new sampler.
if m~=size(A,1), error('rdr:Sampler','Legacy matrix size mismatch.'); end
if isempty(edges), error('rdr:Sampler','Empty legacy probability input.'); end
warning('rdr:Legacy','Legacy pair CDF ignored; rebuilding diagonal proposals.');
prep=rdr_prepare(A,true);
end
