function records=demo_measure(A,b,xstar,prep,cfg,seed,beta,order)
% Repeat all methods in a paired group when any successful first run is short.
% Retain the actual median-time repetition and its unmodified measured history.
N=numel(cfg.methods); outputs=cell(N,cfg.timingRepeats); times=NaN(N,cfg.timingRepeats);
for a=order
    runOne(a,1);
end
successful=cellfun(@(o)o.converged,outputs(:,1));
repeat=any(times(successful,1)<cfg.shortSeconds);
reps=1;
if repeat
    reps=cfg.timingRepeats;
    for rep=2:reps
        for a=circshift(order,[0,rep-1]), runOne(a,rep); end
    end
end
records=struct('method',{},'out',{},'timingSeconds',{},'timingStatuses',{}, ...
    'selectedRepetition',{},'repeatConsistent',{},'algorithmSeed',{});
for a=1:N
    values=outputs(a,1:reps); first=values{1};
    same=all(cellfun(@(o)strcmp(o.status,first.status) && o.iter==first.iter && ...
        o.rowActions==first.rowActions && isequaln(o.finalError,first.finalError),values));
    chosen=1;
    if same
        [~,idx]=sort(times(a,1:reps)); chosen=idx(ceil(reps/2));
    else
        % A timeout can vary across repetitions. Report the original run explicitly.
        warning('demo:Timing','Inconsistent repetitions for %s; retain first run.',cfg.methods{a});
    end
    records(a)=struct('method',cfg.methods{a},'out',outputs{a,chosen}, ...
        'timingSeconds',times(a,1:reps),'timingStatuses',{cellfun(@(o)o.status,values,'UniformOutput',false)}, ...
        'selectedRepetition',chosen,'repeatConsistent',same,'algorithmSeed',seed+a);
end
    function runOne(a,rep)
        o=demo_options(cfg,seed+a); o.Prepared=prep; o.xstar=xstar; o.beta=beta;
        if isnan(beta), o.beta=0; end
        if endsWith(cfg.methods{a},'-II') && ~prep.volumeReady
            [~,out]=rdr_solve(A,b,cfg.methods{a},setfield(o,'Max_iter',0)); %#ok<SFLD>
            out.status='preprocessing_unavailable'; out.converged=false;
        elseif strcmp(cfg.methods{a},'mRDR') && isnan(beta)
            o.beta=0; o.Max_iter=0; [~,out]=rdr_solve(A,b,cfg.methods{a},o);
            out.status='tuning_failed'; out.converged=false;
        else
            [~,out]=rdr_solve(A,b,cfg.methods{a},o);
        end
        outputs{a,rep}=out; times(a,rep)=out.solveTime;
    end
end
