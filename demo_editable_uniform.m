% Edit the parameter sections below, then press Run (F5).
% Small exploratory defaults; these are NOT the full reviewer protocol.
close all
clear
%% Problem parameters
settings = struct;
settings.experiment = 'synthetic';
settings.outputName = 'uniform';
settings.matrixKind = 'uniform';
settings.mValues = 500;             % Scalar or list, e.g. [200 500 1000].
settings.n = 100;
settings.rankA = 100;              % Spectral rank: 2 <= rankA <= min(m,n).
settings.sigmaValues = 5;           % Largest singular value; scalar or list.
settings.delta = 1;                 % Remaining nonzero singular values.
% A=U*diag([sigma,delta,...,delta])*V'; no row normalization is applied.
settings.singularValues = [];       % Optional explicit rankA positive values.
% Example: logspace(log10(10),0,settings.rankA). Overrides sigmaValues/delta.
settings.tValues = 0.9;             % Uniform mode only: entries in [t,1].
% In uniform mode rank/spectral parameters are not imposed on the matrix.
settings.qValues = [1 2];           % Reuse only: shared A, nested RHS prefixes.

%% Sampling and solver parameters
settings.volumeSampler = 'pair_cdf'; % 'pair_cdf' or 'diagonal_rejection'.
% Pair CDF: more setup/storage, cheap subsequent draws.
% Rejection: no pair table, but low acceptance can make iterations expensive.
settings.alpha = 0.5;
settings.autoTune = true;          % true: train mRDR on independent systems.
settings.fixedBeta = 0.15;          % Used only when autoTune=false.
settings.betaGrid = 0:0.05:0.5;      % Eleven candidates when tuning is enabled.
settings.tuneTrials = 5;            % Use 3 for the reviewer protocol.

%% Repetitions and limits (per solve, not for the entire experiment)
settings.trials = 20;                % Use 20 for the reviewer protocol.
settings.seed = 170926;
settings.tolerance = 1e-12;          % Squared relative solution error (RSE).
settings.maxIterations = 200000000;
settings.maxAttempts = 100000000;
settings.maxVolumeProposals = 100000000;
settings.maxRowActions = 400000000;    % Includes rejection-proposal row work.
settings.maxSeconds = 100;
settings.recordEvery = 1000;          % Record after this many additional row actions.
settings.maxPairGB = 0.5;           % Retained CDF limit, not process memory.

%% Plotting and output
settings.showFigures = true;       % Open separate iteration/time figures.
settings.resumeFolder = '';        % Empty creates a NEW folder every run.
% To resume, paste the printed OUTPUT folder above and keep all settings fixed.
% All comments and figure labels are English. Shading: min-max and IQR;
% line: median recorded attainment cost. Seconds include preprocessing.

%% Execute; do not edit the shared driver to change experiment parameters
[results,cfg] = demo_run_editable(settings);
fprintf('Results are saved in: %s\n',cfg.outputDir);
