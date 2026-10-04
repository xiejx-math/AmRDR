function summary=demo_print_zero_rejections(results)
%DEMO_PRINT_ZERO_REJECTIONS Print AmRDR zero-movement rejections per solve.
% RepeatCount counts zero-movement UPDATE attempts, not VolumeRejected.
% Include every evaluation run, even if it did not converge. Training and
% warm-up runs are absent from results.runs and are therefore not included.
% Average over RHS within each trial first, then weight trials equally.
% In reuse experiments each trial is an independent matrix group; in real
% experiments trials are independent RHS for the same fixed matrix.
% This helper also accepts results loaded from an existing all_results.mat.
rows=cell(0,7);
for ci=1:numel(results)
    R=results(ci);
    for method={'AmRDR-I','AmRDR-II'}
        runs=R.runs(strcmp({R.runs.method},method{1}));
        if isempty(runs), continue; end
        counts=arrayfun(@(r)r.out.RepeatCount,runs);
        trials=unique([runs.trial]); groupMeans=zeros(numel(trials),1);
        for k=1:numel(trials)
            groupMeans(k)=mean(counts([runs.trial]==trials(k)));
        end
        successes=sum(arrayfun(@(r)r.out.converged,runs));
        rows(end+1,:)={R.caseName,method{1},numel(runs),successes, ...
            numel(trials),mean(groupMeans),sum(counts)};
    end
end
summary=cell2table(rows,'VariableNames',{'Case','Method','Runs','Successes', ...
    'TrialGroups','MeanZeroRejections','TotalZeroRejections'});
fprintf('\nAmRDR zero-movement rejections (evaluation runs only)\n');
fprintf('Mean per solve: average RHS within each trial, then average trials.\n');
fprintf('Includes unsuccessful runs; excludes internal volume-sampling rejections.\n');
if isempty(rows)
    fprintf('No AmRDR evaluation records were found.\n');
else
    disp(summary);
end
end
