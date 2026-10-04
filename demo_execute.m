function results=demo_execute(cfg)
% Execute a frozen suite, checkpoint cases, and preserve explicit setup failures.
environment=demo_freeze(cfg);
demo_warmup(cfg);
results=struct([]); failures=struct('caseName',{},'identifier',{},'message',{});
if strcmp(cfg.experiment,'real')
    auditFile=fullfile(cfg.outputDir,'matrix_inventory.mat');
    if exist(auditFile,'file'), loaded=load(auditFile); audit=loaded.inventory;
    else, audit=demo_real_inventory(cfg); end
end
for ci=1:numel(cfg.cases)
    c=cfg.cases(ci);
    fprintf('BEGIN %s %s (%d/%d)\n',cfg.experiment,c.name,ci,numel(cfg.cases));
    try
        if strcmp(cfg.experiment,'real')
            item=audit(strcmp({audit.localName},c.name));
            if ~strcmp(item.status,'verified_local_matrix') || ~strcmp(item.sha256,demo_hash(c.file))
                error('demo:Identity','Matrix identity unavailable or file changed for %s.',c.name);
            end
        end
        R=demo_run_case(c,cfg,ci);
        if isempty(results), results=R; else, results(end+1)=R; end
    catch err
        failures(end+1)=struct('caseName',c.name,'identifier',err.identifier,'message',err.message);
        warning('demo:CaseFailure','%s: %s',c.name,err.message);
        save(fullfile(cfg.outputDir,'setup_failures.mat'),'failures');
        writetable(struct2table(failures),fullfile(cfg.outputDir,'setup_failures.csv'));
        continue
    end
    exportTimer=tic;
    demo_export(results,cfg);
    fprintf('EXPORT_COMPLETE %s seconds=%.3f\n',c.name,toc(exportTimer));
    if ~isfield(cfg,'makePlots') || cfg.makePlots, demo_plot(R,cfg); end
    saveTimer=tic;
    save(fullfile(cfg.outputDir,'all_results.mat'),'results','cfg','environment','failures','-v7');
    fprintf('RESULT_SAVE_COMPLETE %s seconds=%.3f\n',c.name,toc(saveTimer));
end
fprintf('SUITE_COMPLETE %s %s cases=%d failedSetups=%d\n',cfg.experiment,cfg.mode,numel(results),numel(failures));
end
