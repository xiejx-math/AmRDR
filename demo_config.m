function cfg=demo_config(experiment,mode)
% Freeze common reviewer-experiment settings before inspecting evaluation results.
if nargin<1, experiment='synthetic'; end
if nargin<2, mode='formal'; end
cfg=rdr_config('full');
cfg.experiment=experiment; cfg.mode=mode; cfg.protocol='demo-v4-row-actions';
cfg.maxIter=60000000; cfg.maxAttempts=60000000;
cfg.maxRows=60000000; cfg.maxTime=600;
cfg.recordEvery=500; cfg.checkEvery=1;
cfg.warmupRepeats=3; cfg.warmupSteps=1000;
cfg.shortSeconds=0.1; cfg.timingRepeats=3;
cfg.bootstrapSamples=10000; cfg.bootstrapSeed=260917;
cfg.qValues=[1,2,5,10,20];
cfg.qDecision='Freeze qmax=20 uniformly to bound engineering-estimated runtime; retain q=10.';
% Kept for old function signatures; rejection sampling has no pair CDF.
cfg.maxPairBytes=1e9; cfg.maxDenseEntries=2e6;
cfg.realNames={'cari','cage','mk9-b1','n4c5-b2','ch5-5-b2','D_8','GL6_D_9'};
switch experiment
    case 'synthetic'
        cfg.seed=170926;
    case 'reuse'
        cfg.seed=1170926;
        base=cfg.cases(3); cfg.cases=repmat(base,0,1);
        for m=[1000,5000,10000]
            c=base; c.m=m; c.rhsCount=max(cfg.qValues);
            c.name=sprintf('reuse_m%d',m); cfg.cases(end+1)=c;
        end
    case 'real'
        cfg.seed=2170926;
        base=cfg.cases(1); cfg.cases=repmat(base,0,1);
        root=fileparts(mfilename('fullpath'));
        for k=1:numel(cfg.realNames)
            c=base; c.kind='real'; c.name=cfg.realNames{k};
            c.file=fullfile(root,'data_AmRDR',[c.name,'.mat']);
            cfg.cases(end+1)=c;
        end
    otherwise
        error('demo:Config','Unknown experiment.');
end
if strcmp(mode,'pilot')
    if ~strcmp(experiment,'reuse'), error('demo:Config','Pilot mode is reserved for reuse.'); end
    cfg.trials=1; cfg.tuneTrials=1; cfg.qValues=[1,2];
    for k=1:numel(cfg.cases), cfg.cases(k).rhsCount=2; end
    cfg.qDecision='User requested engineering pre-run only; full reuse remains unexecuted.';
elseif strcmp(mode,'smoke')
    cfg.trials=2; cfg.tuneTrials=1;
    cfg.warmupRepeats=1; cfg.warmupSteps=50;
    cfg.bootstrapSamples=200; cfg.maxTime=10; cfg.maxRows=100000;
    cfg.recordEvery=10; cfg.qValues=[1,2];
    cfg.cases=cfg.cases(1);
    if ~strcmp(experiment,'real')
        cfg.cases.m=40; cfg.cases.n=10; cfg.cases.rank=10; cfg.cases.sigma=3;
        if strcmp(experiment,'reuse'), cfg.cases.rhsCount=2; end
    end
elseif ~strcmp(mode,'formal')
    error('demo:Config','Mode must be formal, pilot, or smoke.');
end
cfg.outputDir=fullfile(fileparts(mfilename('fullpath')),'results','demo_v4_row_actions',mode,experiment);
end
