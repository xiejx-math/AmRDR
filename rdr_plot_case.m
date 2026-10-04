function rdr_plot_case(R,cfg)
% Plot all seven methods on aligned grids using actual recorded elapsed times.
% Successful runs retain their final error. Failed runs are visibly truncated.
suffixes={'row_actions','time'};
colors=lines(numel(cfg.methods));
for panel=1:2
    fig=figure('Visible','off','Color','w','Position',[100,100,820,650]);
    cleanup=onCleanup(@()close(fig));
    ax=axes('Parent',fig); hold(ax,'on'); handles=gobjects(numel(cfg.methods),1); labels=cell(size(handles));
    for a=1:numel(cfg.methods)
        method=cfg.methods{a}; runs=R.runs(strcmp({R.runs.method},method));
        ending=zeros(numel(runs),1);
        for k=1:numel(runs)
            if panel==1, ending(k)=runs(k).out.rowActions;
            else, ending(k)=runs(k).out.solveTime+(runs(k).rowPrepTime+runs(k).volumePrepTime)/runs(k).rhsCount; end
        end
        endpoint=max(ending);
        plotGrid=unique([0,logspace(log10(max(endpoint/1e5,realmin)),log10(max(endpoint,realmin)),250)]);
        values=NaN(numel(runs),numel(plotGrid));
        for k=1:numel(runs)
            o=runs(k).out;
            if panel==1, x=rdr_row_history(o);
            else, x=o.times(:)+(runs(k).rowPrepTime+runs(k).volumePrepTime)/runs(k).rhsCount; end
            y=o.error(:);
            [x,idx]=unique(x,'last'); y=y(idx);
            if numel(x)==1, values(k,plotGrid==x)=y;
            else, values(k,:)=interp1(x,y,plotGrid,'previous',NaN); end
            values(k,plotGrid<x(1))=y(1);
            if o.converged, values(k,plotGrid>x(end))=y(end); end
        end
        % A missing failed run makes the aggregate undefined, never selectively averaged.
        curve=mean(values,1);
        handles(a)=semilogy(ax,plotGrid,max(curve,realmin),'Color',colors(a,:),'LineWidth',1.4);
        labels{a}=method;
    end
    set(ax,'YScale','log','XGrid','off','YGrid','off', ...
        'XMinorGrid','off','YMinorGrid','off'); ylim(ax,[cfg.tol/10,10]);
    ylabel(ax,'Mean RSE');
    if panel==1, xlabel(ax,'Number of row actions');
    else, xlabel(ax,'Elapsed seconds including amortized preprocessing'); end
    legend(ax,handles,labels,'Location','best','FontSize',8);
    title(ax,rdr_case_label(R),'Interpreter','latex');
    stem=fullfile(cfg.outputDir,[R.caseName,'_mean_',suffixes{panel}]);
    rdr_style_figure(fig);
    exportgraphics(fig,[stem,'.png'],'Resolution',200);
    exportgraphics(fig,[stem,'.pdf'],'ContentType','vector');
    savefig(fig,[stem,'.fig']);
    clear cleanup
end
% Preserve the original mean-RSE figure and add descriptive quantile bands.
% The two representations answer different questions; filenames distinguish
% mean error at a fixed cost from median cost at a fixed recorded error.
for panel=1:2
    qfig=figure('Visible','off','Color','w','Position',[100,100,820,650]);
    qcleanup=onCleanup(@()close(qfig));
    ax=axes('Parent',qfig); h=rdr_plot_quantiles(ax,R,cfg,panel);
    legend(ax,h,'Location','best','FontSize',8);
title(ax,rdr_case_label(R),'Interpreter','latex');
stem=fullfile(cfg.outputDir,[R.caseName,'_quantiles_',suffixes{panel}]);
rdr_style_figure(qfig);
exportgraphics(qfig,[stem,'.png'],'Resolution',200);
exportgraphics(qfig,[stem,'.pdf'],'ContentType','vector');
savefig(qfig,[stem,'.fig']);
clear qcleanup
end
end

