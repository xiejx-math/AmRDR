% Edit parameters, then press Run. Matrix dimensions come from the data file.
% This entry compares fixed real matrices with independent right-hand sides.
settings=struct;
settings.experiment='real';
settings.outputName='real';
settings.realNames={'cari','cage','mk9-b1','n4c5-b2','ch5-5-b2','D_8','GL6_D_9'};
settings.methods={'RK','mRDR','AmRDR-I','AmRDR-II'};
% The default list matches the real-matrix suite configured by demo_config.
% Real matrices retain their original dimensions and singular spectrum.

%% Sampling and solver parameters
settings.volumeSampler = 'pair_cdf'; % 'pair_cdf' or 'diagonal_rejection'.
% Pair CDF: more setup/storage, cheap subsequent draws.
% Rejection: no pair table, but low acceptance can make iterations expensive.
settings.alpha = 0.5;
settings.autoTune = false;           % Select beta on independent training RHS.
settings.fixedBeta = 0.05;          % Used only when autoTune=false.
settings.betaGrid = 0:0.05:0.5;      % Eleven candidates when tuning is enabled.
settings.tuneTrials = 5;

%% Repetitions and limits (per solve, not for the entire experiment)
settings.trials = 20;                % Use 20 for the reviewer protocol.
settings.seed = 170926;
settings.tolerance = 1e-12;         % Same RSE threshold for all four methods.
settings.strictRSE = true;          % Require RSE < tolerance, not <= tolerance.
settings.maxIterations = 2000000;
settings.maxAttempts = 6000000;
settings.maxVolumeProposals = 6000000;
settings.maxRowActions = 6000000;   % Includes rejection-proposal row work.
settings.maxSeconds = 60;
settings.recordEvery = 10;          % Record after this many additional row actions.
settings.maxPairGB = 0.5;           % Retained CDF limit, not process memory.

%% Plotting and output
settings.showFigures = false;      % Command-window tables only.
settings.makePlots = false;        % Do not generate or export any figures.
settings.resumeFolder = '';        % Empty creates a NEW folder every run.
% To resume, paste the printed OUTPUT folder above and keep all settings fixed.
% Tables report means across evaluation RHS and the number of successful runs.
% TotalSeconds includes preprocessing; mRDR training time is shown separately.
% "Best beta" means best on the training grid with the specified fixed alpha.

%% Execute; do not edit the shared driver to change experiment parameters
[results,cfg] = demo_run_editable(settings);
[comparison,mRDRParameters] = demo_real_report(results,cfg);
fprintf('Results are saved in: %s\n',cfg.outputDir);
