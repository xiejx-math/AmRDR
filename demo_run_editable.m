function [results,cfg]=demo_run_editable(settings)
%DEMO_RUN_EDITABLE Translate the visible script settings into one frozen run.
% Every fresh execution creates a unique folder. To resume, paste the exact
% prior folder into resumeFolder and keep settings AND source files unchanged.
root=fileparts(mfilename('fullpath')); addpath(root);
s=settings; experiment=s.experiment;
base=experiment; if strcmp(base,'robustness'), base='synthetic'; end
cfg=demo_config(base,'formal'); cfg.experiment=experiment; cfg.mode='editable';
cfg.protocol=['editable-v4-row-actions-',s.volumeSampler]; cfg.volumeSampler=s.volumeSampler;
if isfield(s,'methods'), cfg.methods=s.methods; end
cfg.seed=s.seed; cfg.trials=s.trials; cfg.tuneTrials=s.tuneTrials;
cfg.autoTune=s.autoTune; cfg.fixedBeta=s.fixedBeta; cfg.betaGrid=s.betaGrid;
cfg.alpha=s.alpha; cfg.tol=s.tolerance; cfg.maxIter=s.maxIterations;
if isfield(s,'makePlots'), cfg.makePlots=s.makePlots; end
if isfield(s,'strictRSE'), cfg.strictRSE=s.strictRSE; end
if isfield(s,'exportHistories'), cfg.exportHistories=s.exportHistories; end
cfg.maxAttempts=s.maxAttempts; cfg.maxRows=s.maxRowActions;
cfg.maxVolumeProposals=s.maxVolumeProposals; cfg.maxTime=s.maxSeconds;
cfg.recordEvery=s.recordEvery; cfg.maxPairBytes=s.maxPairGB*1e9;
cfg.warmupRepeats=1; cfg.warmupSteps=50; cfg.timingRepeats=1;
cfg.bootstrapSamples=1000;
validateattributes(s.trials,{'numeric'},{'scalar','integer','positive'});
validateattributes(s.tuneTrials,{'numeric'},{'scalar','integer','positive'});
validateattributes(s.betaGrid,{'numeric'},{'vector','nonempty','finite','nonnegative'});
validateattributes(s.fixedBeta,{'numeric'},{'scalar','finite','nonnegative'});
if ~ismember(s.volumeSampler,{'pair_cdf','diagonal_rejection'})
    error('demo:Settings','Choose pair_cdf or diagonal_rejection.');
end
if ismember(experiment,{'synthetic','reuse'})
    validateattributes(s.n,{'numeric'},{'scalar','integer','>=',2});
    validateattributes(s.mValues,{'numeric'},{'vector','nonempty','integer','>=',2});
    if strcmp(s.matrixKind,'spectral')
        validateattributes(s.rankA,{'numeric'},{'scalar','integer','>=',2,'<=',min([s.n,s.mValues(:)'])});
        if isempty(s.singularValues)
            validateattributes(s.delta,{'numeric'},{'scalar','positive','finite'});
            validateattributes(s.sigmaValues,{'numeric'},{'vector','nonempty','finite','>=',s.delta});
        else
            validateattributes(s.singularValues,{'double'},{'vector','numel',s.rankA,'positive','finite'});
        end
    elseif strcmp(s.matrixKind,'uniform')
        validateattributes(s.tValues,{'numeric'},{'vector','nonempty','finite','>=',0,'<',1});
    end
    c=cfg.cases(1); c.delta=s.delta; c.singularValues=s.singularValues;
    cfg.cases=repmat(c,0,1);
    if strcmp(experiment,'reuse')
        validateattributes(s.qValues,{'numeric'},{'vector','nonempty','integer','positive'});
        cfg.qValues=unique(s.qValues); cfg.qDecision='User-defined RHS prefixes.';
        c.rhsCount=max(cfg.qValues);
    else, c.rhsCount=1; end
    if strcmp(s.matrixKind,'uniform'), parameters=s.tValues;
    elseif ~isempty(s.singularValues), parameters=max(s.singularValues);
    else, parameters=s.sigmaValues; end
    for m=unique(s.mValues(:)')
        for value=unique(parameters(:)')
            c.m=m; c.n=s.n; c.rank=s.rankA; c.kind=s.matrixKind;
            if strcmp(c.kind,'uniform')
                if value<0 || value>=1, error('demo:Settings','Uniform t must be in [0,1).'); end
                c.t=value; tag=sprintf('uniform_m%d_n%d_t%g',m,s.n,value);
            elseif strcmp(c.kind,'spectral')
                c.sigma=value; tag=sprintf('spectral_m%d_n%d_r%d_sigma%g',m,s.n,s.rankA,value);
            else, error('demo:Settings','Choose spectral or uniform.'); end
            c.name=tag; cfg.cases(end+1)=c;
        end
    end
elseif strcmp(experiment,'real')
    cfg.realNames=cellfun(@strtrim,s.realNames,'UniformOutput',false);
    c=cfg.cases(1); cfg.cases=repmat(c,0,1);
    for k=1:numel(cfg.realNames)
        c.name=cfg.realNames{k}; c.kind='real';
        c.file=fullfile(root,'data_AmRDR',[c.name,'.mat']); cfg.cases(end+1)=c;
    end
elseif strcmp(experiment,'robustness')
    for field={'copies','etas','angleMultipliers','rhsScales','systemScales'}
        cfg.(field{1})=s.(field{1});
    end
else, error('demo:Settings','Unknown experiment.'); end
if isempty(s.resumeFolder)
    folder=fullfile(root,'results','editable',s.outputName,s.volumeSampler);
    if ~exist(folder,'dir'), mkdir(folder); end
    % tempname gives uniqueness even for executions in the same second.
    cfg.outputDir=tempname(folder);
else, cfg.outputDir=char(s.resumeFolder); end
fprintf('OUTPUT: %s\n',cfg.outputDir);
if strcmp(experiment,'robustness')
    results=demo_robustness(cfg);
else
    results=demo_execute(cfg);
    demo_print_zero_rejections(results);
    % Final comparison figures are controlled independently from per-case
    % diagnostic plots. This allows a run to skip expensive duplicate plots
    % while still generating one compact comparison set after all cases finish.
    if s.showFigures && ~isempty(results)
        plotTimer=tic;
        demo_plot_comparison(results,'all', ...
            fullfile(cfg.outputDir,'standalone_figures'),cfg);
        fprintf('PLOT_COMPLETE seconds=%.3f\n',toc(plotTimer));
    end
end
end
