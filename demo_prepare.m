function [prep,issue]=demo_prepare(A,cfg)
% Prepare diagonal proposals once per matrix for reuse across right-hand sides.
% A failed numerical rank check must not prevent RK/Strategy I from running.
issue='';
try
    sampler='diagonal_rejection';
    if isfield(cfg,'volumeSampler'), sampler=cfg.volumeSampler; end
    prep=rdr_prepare(A,true,cfg.maxPairBytes,sampler);
catch err
    if ~ismember(err.identifier,{'rdr:Memory','rdr:Rank','MATLAB:nomem'})
        rethrow(err);
    end
    prep=rdr_prepare(A,false); issue=[err.identifier,': ',err.message];
    warning('demo:Preprocess','Volume preprocessing unavailable: %s',issue);
end
end
