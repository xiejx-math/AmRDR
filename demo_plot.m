function demo_plot(R,cfg)
% Add explicit training sensitivity and tuning-cost plots to convergence curves.
rdr_plot_case(R,cfg);
fig=figure('Visible','off','Color','w','Position',[100,100,1100,450]);
cleanup=onCleanup(@()close(fig));
tiledlayout(fig,1,2);
nexttile; hold on;
for trial=1:cfg.tuneTrials
    s=R.tuning([R.tuning.trial]==trial);
    [betas,idx]=sort([s.beta]); values=[s(idx).iter];
    ok=strcmp({s(idx).status},'converged'); values(~ok)=NaN;
    plot(betas,values,'-o','DisplayName',sprintf('Training system %d',trial));
    if any(~ok), plot(betas(~ok),[s(idx(~ok)).iter],'rx','HandleVisibility','off'); end
end
xlabel('Fixed momentum beta'); ylabel('Training iterations'); grid on; legend('Location','best');
title(rdr_case_label(R),'Interpreter','latex');
nexttile; costs=NaN(numel(cfg.methods),3);
for a=1:numel(cfg.methods)
    s=R.runs(strcmp({R.runs.method},cfg.methods{a}));
    ok=arrayfun(@(r)r.out.converged,s);
    if all(ok)
        total=arrayfun(@(r)r.out.solveTime+r.rowPrepTime+r.volumePrepTime,s);
        tune=0; if strcmp(cfg.methods{a},'mRDR'), tune=R.tuneTime; end
        costs(a,:)=[mean(total),mean(total)+tune/numel(s),mean(total)+tune];
    end
end
bar(costs); set(gca,'XTickLabel',cfg.methods,'XTickLabelRotation',30,'YScale','log');
ylabel('Seconds'); title(rdr_case_label(R),'Interpreter','latex');
legend('No tuning','Tuning amortized','Full configuration tuning','Location','best'); grid on;
rdr_style_figure(fig);
exportgraphics(fig,fullfile(cfg.outputDir,[R.caseName,'_tuning.png']),'Resolution',150);
exportgraphics(fig,fullfile(cfg.outputDir,[R.caseName,'_tuning.pdf']),'ContentType','vector');
if strcmp(cfg.experiment,'reuse')
    fig2=figure('Visible','off','Color','w'); clean2=onCleanup(@()close(fig2));
    T=readtable(fullfile(cfg.outputDir,'prefix_summary.csv'));
    for a=1:numel(cfg.methods)
        mask=strcmp(T.Case,R.caseName) & strcmp(T.Method,cfg.methods{a});
        semilogx(T.RHSCount(mask),T.MeanSuccessAverageSeconds(mask),'-o','DisplayName',cfg.methods{a}); hold on;
    end
    xlabel('Number of reused right-hand sides'); ylabel('Mean seconds per RHS including preprocessing');
    title(rdr_case_label(R),'Interpreter','latex'); legend('Location','best'); grid on;
    rdr_style_figure(fig2);
    exportgraphics(fig2,fullfile(cfg.outputDir,[R.caseName,'_reuse.png']),'Resolution',150);
end
end
