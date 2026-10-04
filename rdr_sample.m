function pairs = rdr_sample(prep, strategy, count, stream)
% Sample RK rows, independent pairs, conditional distinct pairs, or volume pairs.
if strcmp(strategy,'volume')
    if ~isfield(prep,'volumeReady') || ~prep.volumeReady
        error('rdr:Sampler','Rejection-sampling preprocessing is missing.');
    end
    if strcmp(prep.volumeSampler,'pair_cdf')
        k=rdr_cdf_draw(prep.volumeCDF,rand(stream,count,1));
        j=ceil((1+sqrt(1+8*k))/2); i=k-(j-1).*(j-2)/2;
        bad=i<1; j(bad)=j(bad)-1;
        i(bad)=k(bad)-(j(bad)-1).*(j(bad)-2)/2;
        pairs=[i,j]; swap=rand(stream,count,1)<0.5;
        pairs(swap,:)=pairs(swap,[2,1]); return
    end
    % This public batch helper has a finite proposal budget. The solver uses
    % single proposals directly so wall time and row budgets are interruptible.
    pairs=zeros(count,2); accepted=0; proposals=0;
    limit=max(10000,1000*count);
    while accepted<count && proposals<limit
        [pair,ok]=rdr_volume_proposal(prep,stream); proposals=proposals+1;
        if ok, accepted=accepted+1; pairs(accepted,:)=pair; end
    end
    if accepted<count, error('rdr:SamplingBudget','Volume proposal budget exhausted.'); end
    return
end

i = rdr_cdf_draw(prep.rowCDF,rand(stream,count,1));
if strcmp(strategy,'rk'), pairs = [i,i]; return; end
if strcmp(strategy,'independent')
    j = rdr_cdf_draw(prep.rowCDF,rand(stream,count,1));
elseif strcmp(strategy,'distinct')
    pi = prep.rowProbability(i);
    if any(pi >= 1), error('rdr:Rank','Distinct sampling needs two positive row weights.'); end
    left = prep.rowCDF(i)-pi;
    u = rand(stream,count,1).*(1-pi);
    u = u + (u >= left).*pi;
    u = min(u,1-eps);
    j = rdr_cdf_draw(prep.rowCDF,u);
    if any(i == j), error('rdr:Precision','Row probabilities are too concentrated for reliable sampling.'); end
else
    error('rdr:Sampler','Unknown sampling strategy.');
end
pairs = [i,j];
end
