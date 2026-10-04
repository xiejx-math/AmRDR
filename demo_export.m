function demo_export(results,cfg)
% Export paired intervals, timing repetitions, diagnostics, and RHS-prefix costs.
rdr_export_results(results,cfg);
writeHistories=true;
if isfield(cfg,'exportHistories') && ~cfg.exportHistories
    writeHistories=false;
end
% Preallocate the potentially large history table when CSV export is enabled.
% The full histories remain available in the saved MAT results either way.
if writeHistories
    historyCount=0;
    for ci=1:numel(results)
        for k=1:numel(results(ci).runs)
            historyCount=historyCount+numel(results(ci).runs(k).out.error);
        end
    end
    histories=cell(historyCount,10);
else
    histories=cell(0,10);
end
historyRow=0;
timings=cell(0,9); diagnostics=cell(0,18); paired=cell(0,10); prefixes=cell(0,10);
prefixSummary=cell(0,9);
for ci=1:numel(results)
    R=results(ci); N=numel(cfg.methods);
    for k=1:numel(R.runs)
        r=R.runs(k); o=r.out;
        if writeHistories
            work=rdr_row_history(o);
            for point=1:numel(work)
                historyRow=historyRow+1;
                histories(historyRow,:)={R.caseName,r.trial,r.rhs,r.method, ...
                    o.iterations(point),work(point),o.updateRowActionsHistory(point), ...
                    o.proposalRowActionsHistory(point),o.error(point),o.times(point)};
            end
        end
        for rep=1:numel(r.timingSeconds)
            timings(end+1,:)={R.caseName,r.trial,r.rhs,r.method,rep,r.timingSeconds(rep), ...
                r.timingStatuses{rep},rep==r.selectedRepetition,r.repeatConsistent};
        end
        diagnostics(end+1,:)={R.caseName,r.trial,r.rhs,r.method,o.status,o.FinalResidual, ...
            o.attempts,o.RepeatRate,o.FallbackCount/max(o.iter,1),o.MinNormalizedGram, ...
            o.GramFallbacks,o.HistoryFallbacks,r.repeatConsistent, ...
            o.VolumeProposals,o.VolumeRejected,o.VolumeRejectionRate,o.ProposalRowActions,o.UpdateRowActions};
    end
    qValues=1;
    if strcmp(cfg.experiment,'reuse'), qValues=cfg.qValues; end
    for q=qValues
        groupTimes=NaN(cfg.trials,N); withTune=groupTimes;
        for a=1:N
            for trial=1:cfg.trials
                s=R.runs(strcmp({R.runs.method},cfg.methods{a}) & [R.runs.trial]==trial & [R.runs.rhs]<=q);
                if isempty(s), continue; end
                complete=numel(s)==q && all(arrayfun(@(r)r.out.converged,s));
                prep=s(1).rowPrepTime+s(1).volumePrepTime;
                batch=prep+sum(arrayfun(@(r)r.out.solveTime,s));
                tune=0; if strcmp(cfg.methods{a},'mRDR'), tune=R.tuneTime/cfg.trials; end
                successes=sum(arrayfun(@(r)r.out.converged,s));
                prefixes(end+1,:)={R.caseName,trial,q,cfg.methods{a},successes,complete,prep,batch,batch/q,(batch+tune)/q};
                if complete, groupTimes(trial,a)=batch/q; withTune(trial,a)=(batch+tune)/q; end
            end
            good=isfinite(groupTimes(:,a));
            prefixSummary(end+1,:)={R.caseName,q,cfg.methods{a},sum(good),cfg.trials, ...
                avg(groupTimes(good,a)),spread(groupTimes(good,a)),avg(withTune(good,a)),spread(withTune(good,a))};
        end
        % Compare every selected method with the first baseline. Add the
        % established matched contrasts only when both methods are selected.
        comparisons=[ones(N-1,1),(2:N)'];
        matchedPairs={'IRDR-I','AmRDR-I';'IRDR-II','AmRDR-II'; ...
            'IRDR-I','IRDR-II';'AmRDR-I','AmRDR-II'};
        for pairIndex=1:size(matchedPairs,1)
            first=find(strcmp(cfg.methods,matchedPairs{pairIndex,1}),1);
            second=find(strcmp(cfg.methods,matchedPairs{pairIndex,2}),1);
            if ~isempty(first) && ~isempty(second)
                comparisons(end+1,:)=[first,second];
            end
        end
        comparisons=unique(comparisons,'rows','stable');
        for k=1:size(comparisons,1)
            a=comparisons(k,1); b=comparisons(k,2);
            for cost=1:2
                times=groupTimes; label='preprocessing_included';
                if cost==2, times=withTune; label='tuning_amortized'; end
                [gm,lo,hi,count]=demo_bootstrap(times(:,a),times(:,b),cfg,cfg.bootstrapSeed+ci*100+k);
                paired(end+1,:)={R.caseName,q,cfg.methods{a},cfg.methods{b},label,count,cfg.trials,gm,lo,hi};
            end
        end
    end
end
if writeHistories
    write(histories,{'Case','Trial','RHS','Method','AcceptedIterations','RowActions', ...
        'UpdateRowActions','ProposalRowActions','RSE','SolveSeconds'},'histories.csv');
end
write(timings,{'Case','Trial','RHS','Method','Repetition','Seconds','Status','Selected','RepeatConsistent'},'timing_repetitions.csv');
write(diagnostics,{'Case','Trial','RHS','Method','Status','FinalRelativeResidual','Attempts','RejectionRate', ...
    'FallbackRate','MinNormalizedGram','GramFallbacks','HistoryFallbacks','RepeatConsistent', ...
    'VolumeProposals','VolumeRejected','VolumeRejectionRate','ProposalRowActions','UpdateRowActions'},'diagnostics.csv');
write(paired,{'Case','RHSCount','Baseline','Method','CostConvention','CommonSuccessUnits','TotalUnits', ...
    'GeometricMeanTimeRatio','CILower95','CIUpper95'},'paired_comparisons.csv');
write(prefixes,{'Case','Trial','RHSCount','Method','SuccessfulRHS','Complete','PrepSeconds', ...
    'ObservedBatchSeconds','ObservedAverageSeconds','ObservedAverageIncludingTune'},'prefix_costs.csv');
write(prefixSummary,{'Case','RHSCount','Method','SuccessfulGroups','Groups', ...
    'MeanSuccessAverageSeconds','StdSuccessAverageSeconds','MeanSuccessIncludingTune','StdSuccessIncludingTune'},'prefix_summary.csv');
    function write(rows,names,file)
        writetable(cell2table(rows,'VariableNames',names),fullfile(cfg.outputDir,file));
    end
    function x=avg(v)
        if isempty(v), x=NaN; else, x=mean(v); end
    end
    function x=spread(v)
        if numel(v)<2, x=NaN; else, x=std(v); end
    end
end
