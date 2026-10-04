function opts=demo_options(cfg,seed)
% Use identical stopping, monitoring, and row-action budgets for every method.
opts=struct('Seed',seed,'alpha',cfg.alpha,'TOL',cfg.tol, ...
    'Max_iter',cfg.maxIter,'Max_attempts',cfg.maxAttempts, ...
    'Max_row_actions',cfg.maxRows,'Max_time',cfg.maxTime, ...
    'RecordEvery',cfg.recordEvery,'CheckEvery',cfg.checkEvery);
if isfield(cfg,'maxVolumeProposals'), opts.Max_volume_proposals=cfg.maxVolumeProposals; end
if isfield(cfg,'volumeSampler'), opts.VolumeSampler=cfg.volumeSampler; end
if isfield(cfg,'strictRSE'), opts.StrictRSE=cfg.strictRSE; end
end
