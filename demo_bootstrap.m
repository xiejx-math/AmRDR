function [estimate,low,high,n]=demo_bootstrap(a,b,cfg,seed)
% Paired geometric mean time ratios; resample independent experimental units.
valid=isfinite(a) & isfinite(b) & a>0 & b>0;
z=log(a(valid)./b(valid)); z=z(:); n=numel(z);
estimate=NaN; low=NaN; high=NaN;
if n==0, return; end
estimate=exp(mean(z));
if n<2, return; end
stream=RandStream('mt19937ar','Seed',seed);
idx=randi(stream,n,n,cfg.bootstrapSamples);
samples=exp(mean(z(idx),1)); interval=quantile(samples,[0.025,0.975]);
low=interval(1); high=interval(2);
end
