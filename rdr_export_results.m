function rdr_export_results(results,cfg)
% Export per-run records and transparent summaries without treating failures as successes.
rows=cell(0,20); summary=cell(0,17); tuning=cell(0,6);
for ci=1:numel(results)
    R=results(ci);
    for k=1:numel(R.tuning)
        t=R.tuning(k);
        tuning(end+1,:)={R.caseName,t.trial,t.beta,t.iter,t.time,t.status};
    end
    for k=1:numel(R.runs)
        r=R.runs(k); o=r.out;
        prep=r.rowPrepTime+r.volumePrepTime;
        amortized=o.solveTime+prep/r.rhsCount;
        tuningCharge=0;
        if strcmp(r.method,'mRDR'), tuningCharge=R.tuneTime; end
        rows(end+1,:)={R.caseName,r.trial,r.rhs,r.method,o.status,o.iter,o.rowActions, ...
            o.solveTime,r.rowPrepTime,r.volumePrepTime,amortized, ...
            tuningCharge,tuningCharge+o.solveTime+prep, ...
            amortized+tuningCharge/(cfg.trials*r.rhsCount), ...
            o.finalError,o.RepeatCount,o.FallbackCount,r.dataSeed,r.algorithmSeed,R.beta};
    end
    for ai=1:numel(cfg.methods)
        method=cfg.methods{ai}; subset=R.runs(strcmp({R.runs.method},method));
        ok=arrayfun(@(r)r.out.converged,subset);
        it=arrayfun(@(r)r.out.iter,subset);
        work=arrayfun(@(r)r.out.rowActions,subset);
        st=arrayfun(@(r)r.out.solveTime,subset);
        total=arrayfun(@(r)r.out.solveTime+(r.rowPrepTime+r.volumePrepTime)/r.rhsCount,subset);
        % For repeated RHS, average within each matrix before estimating spread.
        groupTime=NaN(cfg.trials,1); groupIter=groupTime;
        for trial=1:cfg.trials
            mask=[subset.trial]==trial;
            if all(ok(mask)), groupTime(trial)=mean(total(mask)); groupIter(trial)=mean(it(mask)); end
        end
        valid=~isnan(groupTime);
        tuneCharge=0; if strcmp(method,'mRDR'), tuneCharge=R.tuneTime; end
        summary(end+1,:)={R.caseName,method,numel(subset),sum(ok),sum(valid), ...
            avg(it(ok)),spread(it(ok)),avg(st(ok)),avg(groupTime(valid)), ...
            spread(groupTime(valid)),avg(groupIter(valid)), ...
            tuneCharge,tuneCharge/numel(subset),R.beta,mean(st),avg(work(ok)),spread(work(ok))};
    end
end
T=cell2table(rows,'VariableNames',{'Case','Trial','RHS','Method','Status','Iterations','RowActions', ...
    'SolveSeconds','RowPrepSeconds','VolumePrepSeconds','AmortizedTotalSeconds', ...
    'ConfigurationTuneSeconds','StandaloneIncludingTuneSeconds','BatchAmortizedIncludingTuneSeconds', ...
    'FinalError','RejectedPairs','Fallbacks','DataSeed','AlgorithmSeed','SelectedBeta'});
writetable(T,fullfile(cfg.outputDir,'runs.csv'));
S=cell2table(summary,'VariableNames',{'Case','Method','Runs','Successes','SuccessfulMatrixGroups', ...
    'MeanSuccessIterations','StdSuccessIterations','MeanSuccessSolveSeconds', ...
    'MeanSuccessGroupTotalSeconds','StdSuccessGroupTotalSeconds','MeanSuccessGroupIterations', ...
    'ConfigurationTuneSeconds','TuneSecondsPerEvaluation','SelectedBeta','MeanObservedSolveSeconds','MeanSuccessRowActions','StdSuccessRowActions'});
writetable(S,fullfile(cfg.outputDir,'summary.csv'));
writetable(cell2table(tuning,'VariableNames',{'Case','TuningTrial','Beta','Iterations','SolveSeconds','Status'}), ...
    fullfile(cfg.outputDir,'tuning.csv'));
    function x=avg(v)
        if isempty(v), x=NaN; else, x=mean(v); end
    end
    function x=spread(v)
        if numel(v)<2, x=NaN; else, x=std(v); end
    end
end
