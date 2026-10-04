function [tune,beta,tuneTime]=demo_tune_case(c,cfg,ci,folder)
% Tune on independent systems with common random numbers across beta values.
file=fullfile(folder,'tuning.mat');
tune=struct('trial',{},'beta',{},'iter',{},'time',{},'status',{},'wallSeconds',{});
buildTimes=zeros(cfg.tuneTrials,1);
% Interactive demos may use a disclosed fixed beta to skip training entirely.
if isfield(cfg,'autoTune') && ~cfg.autoTune
    beta=cfg.fixedBeta; tuneTime=0; score=[];
    save(file,'tune','buildTimes','beta','tuneTime','score'); return
end
if exist(file,'file'), saved=load(file); tune=saved.tune; buildTimes=saved.buildTimes; end
for ti=1:cfg.tuneTrials
    if sum([tune.trial]==ti)==numel(cfg.betaGrid), continue; end
    timer=tic;
    [A,b,xstar]=demo_matrix(c,cfg.seed+ci*100000+ti);
    prep=rdr_prepare(A,false);
    if buildTimes(ti)==0, buildTimes(ti)=toc(timer); end
    for bi=1:numel(cfg.betaGrid)
        if any([tune.trial]==ti & [tune.beta]==cfg.betaGrid(bi)), continue; end
        timer=tic;
        o=demo_options(cfg,cfg.seed+ci*100000+1000+ti);
        o.Prepared=prep; o.xstar=xstar; o.beta=cfg.betaGrid(bi);
        [~,out]=rdr_solve(A,b,'mRDR',o);
        tune(end+1)=struct('trial',ti,'beta',o.beta,'iter',out.iter, ...
            'time',out.solveTime,'status',out.status,'wallSeconds',toc(timer));
        save(file,'tune','buildTimes');
        fprintf('TUNE %s %d/%d beta=%.2f %s %.2fs\n',c.name,ti,cfg.tuneTrials,o.beta,out.status,out.solveTime);
    end
end
score=Inf(size(cfg.betaGrid));
for bi=1:numel(cfg.betaGrid)
    rows=tune([tune.beta]==cfg.betaGrid(bi));
    if numel(rows)==cfg.tuneTrials && all(strcmp({rows.status},'converged'))
        score(bi)=mean([rows.iter]);
    end
end
beta=NaN;
if any(isfinite(score)), [~,idx]=min(score); beta=cfg.betaGrid(idx); end
tuneTime=sum(buildTimes)+sum([tune.wallSeconds]);
save(file,'tune','buildTimes','beta','tuneTime','score');
end
