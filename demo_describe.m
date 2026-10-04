function meta=demo_describe(A,cfg,seed)
% Bound dense diagnostics and label sampled correlations as sampled quantities.
meta=struct('m',size(A,1),'n',size(A,2),'nnz',nnz(A), ...
    'density',nnz(A)/numel(A),'zeroRows',sum(~any(A~=0,2)), ...
    'rank',NaN,'rankTolerance',NaN,'nonzeroCondition',NaN,'rankMethod','not computed');
if numel(A)<=cfg.maxDenseEntries
    s=svd(full(A),'econ'); threshold=max(size(A))*eps(max(s));
    r=sum(s>threshold); meta.rank=r; meta.rankTolerance=threshold;
    meta.rankMethod='SVD with max(size(A))*eps(sigma_max)';
    if r>0, meta.nonzeroCondition=s(1)/s(r); end
end
positive=find(any(A~=0,2));
stream=RandStream('mt19937ar','Seed',seed);
if numel(positive)>=2
    i=randi(stream,numel(positive),2000,1);
    j=randi(stream,numel(positive)-1,2000,1); j=j+(j>=i);
    X=A(positive(i),:); Y=A(positive(j),:);
    correlation=full(abs(sum(X.*Y,2))./sqrt(sum(X.^2,2).*sum(Y.^2,2)));
    meta.sampledCorrelationMedian=median(correlation);
    meta.sampledCorrelationP90=quantile(correlation,0.9);
else
    meta.sampledCorrelationMedian=NaN; meta.sampledCorrelationP90=NaN;
end
meta.correlationPairs=2000;
end
