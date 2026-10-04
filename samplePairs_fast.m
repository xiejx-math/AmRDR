function pairs=samplePairs_fast(m,numSamples,edges)
% Compatibility sampler for a legacy ordered-pair cumulative distribution.
if numel(edges)~=m*m+1 || any(~isfinite(edges)) || any(diff(edges)<0)
    error('rdr:Sampler','Invalid ordered-pair CDF.');
end
cdf=edges(2:end); cdf=cdf(:);
if cdf(end)<=0, error('rdr:Sampler','CDF has zero mass.'); end
cdf=cdf/cdf(end); cdf(end)=1;
idx=rdr_cdf_draw(cdf,rand(numSamples,1));
pairs=[rem(idx-1,m)+1,ceil(idx/m)];
end
