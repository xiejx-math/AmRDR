function [comparison,parameters]=demo_real_report(results,cfg)
%DEMO_REAL_REPORT Print measured work/time and grid-selected mRDR parameters.
% Means cover all evaluation RHS only if every run attained the target.
% Failed groups show NaN rather than a misleading successful-subset speed.
% TotalSeconds includes preprocessing but excludes parameter search. Search
% cost is disclosed separately; it belongs to one entire matrix configuration.
rows=cell(0,10); params=cell(0,6);
for ci=1:numel(results)
    R=results(ci);
    for a=1:numel(cfg.methods)
        runs=R.runs(strcmp({R.runs.method},cfg.methods{a}));
        ok=arrayfun(@(r)r.out.converged && r.out.finalError<cfg.tol,runs);
        work=NaN; solve=NaN; rowPrep=NaN; volumePrep=NaN; total=NaN; final=NaN;
        if ~isempty(runs)
            final=max(arrayfun(@(r)r.out.finalError,runs));
            rowPrep=mean([runs.rowPrepTime]);
            volumePrep=mean([runs.volumePrepTime]);
            if all(ok)
                work=mean(arrayfun(@(r)r.out.rowActions,runs));
                solve=mean(arrayfun(@(r)r.out.solveTime,runs));
                total=mean(arrayfun(@(r)r.out.solveTime+r.rowPrepTime+ ...
                    r.volumePrepTime,runs));
            end
        end
        rows(end+1,:)={R.caseName,cfg.methods{a},sum(ok),numel(runs), ...
            work,solve,rowPrep,volumePrep,total,final};
    end
    rule='independent training grid'; trainingCount=cfg.tuneTrials;
    if isfield(cfg,'autoTune') && ~cfg.autoTune
        rule='manual; not optimized'; trainingCount=0;
    end
    params(end+1,:)={R.caseName,cfg.alpha,R.beta,R.tuneTime,trainingCount,rule};
end
comparison=cell2table(rows,'VariableNames',{'Matrix','Method','Successes','Trials', ...
    'NumberOfRowActions','SolveSeconds','RowPrepSeconds','VolumePrepSeconds', ...
    'TotalSeconds','MaxFinalRSE'});
parameters=cell2table(params,'VariableNames',{'Matrix','Alpha','SelectedBeta', ...
    'TuningSeconds','TrainingRHS','SelectionRule'});
fprintf('\nREAL MATRIX COMPARISON: RSE < %.1e\n',cfg.tol);
fprintf('Row actions and seconds are means over evaluation RHS.\n');
fprintf(['RowPrepSeconds and VolumePrepSeconds are printed separately. ', ...
    'VolumePrepSeconds is nonzero for Strategy-II methods.\n']);
fprintf('TotalSeconds = solve + row preprocessing + volume preprocessing; excludes tuning.\n');
fprintf('NaN means not all evaluations converged; inspect runs.csv for statuses.\n');
disp(comparison);
fprintf('mRDR: alpha is fixed; beta is best within the disclosed training grid.\n');
disp(parameters);
if isempty(results), warning('demo:NoResults','No completed matrix groups; inspect setup_failures.csv.'); end
writetable(comparison,fullfile(cfg.outputDir,'real_comparison.csv'));
writetable(parameters,fullfile(cfg.outputDir,'mrdr_parameters.csv'));
end
