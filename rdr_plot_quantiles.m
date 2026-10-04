function handles=rdr_plot_quantiles(ax,R,cfg,panel)
%RDR_PLOT_QUANTILES Compare first recorded attainment of common RSE levels.
% Light shading: minimum to maximum over every trial.
% Dark shading: 25th to 75th percentiles. Solid line: median cost.
% These are descriptive trial ranges, NOT confidence intervals of a mean.
% Unlike mean-RSE histories, horizontal bands compare the work needed to
% first reach a fixed error level. Sparse histories give recorded attainment
% times (upper estimates), not interpolated or exact first-passage times.
% A level is omitted unless ALL trials have attained it: failures are never
% silently removed. Success counts remain in the saved data and tables.
colors=[.20,.20,.20; .30,.50,.82; .70,.30,.65; ...
    .30,.68,.46; .08,.40,.23; .96,.58,.24; .72,.20,.09];
styles={'-','--',':','--','-', '--','-'};
levels=logspace(0,log10(cfg.tol),160);
hold(ax,'on'); stats=cell(numel(cfg.methods),1); labels=stats;
for a=1:numel(cfg.methods)
    runs=R.runs(strcmp({R.runs.method},cfg.methods{a}));
    costs=NaN(numel(runs),numel(levels));
    for k=1:numel(runs)
        o=runs(k).out;
        if panel==1
            x=rdr_row_history(o);
        else
            % Preprocessing is charged once per matrix and amortized only
            % when the saved experiment actually specifies multiple RHS.
            prep=(runs(k).rowPrepTime+runs(k).volumePrepTime)/runs(k).rhsCount;
            x=o.times(:)+prep;
        end
        % Find the first attainment of every threshold in one pass. The
        % previous implementation rescanned the full history once per
        % threshold, which was expensive for reuse experiments with many RHS.
        hits=firstAttainmentIndices(o.error,levels);
        attained=isfinite(hits);
        costs(k,attained)=x(hits(attained));
    end
    valid=all(isfinite(costs),1) & ~isempty(runs);
    if any(valid)
        v=costs(:,valid);
        stats{a}=struct('y',levels(valid),'lo',min(v,[],1),'hi',max(v,[],1), ...
            'q25',quantile(v,.25,1),'q75',quantile(v,.75,1),'mid',median(v,1));
    end
    labels{a}=cfg.methods{a};
end
% Draw all bands before all lines, so later bands never obscure an earlier
% method's median. Related I/II variants use light/dark shades of one hue.
for layer=1:2
    for a=1:numel(stats)
        s=stats{a}; if isempty(s), continue; end
        if layer==1, lo=s.lo; hi=s.hi; alpha=.12;
        else, lo=s.q25; hi=s.q75; alpha=.27; end
        fill(ax,[lo,fliplr(hi)],[s.y,fliplr(s.y)],colors(a,:), ...
            'FaceAlpha',alpha,'EdgeColor','none','HandleVisibility','off');
    end
end
handles=gobjects(numel(stats),1);
for a=1:numel(stats)
    s=stats{a}; x=NaN; y=NaN;
    if ~isempty(s), x=s.mid; y=s.y; end
    handles(a)=plot(ax,x,y,'Color',colors(a,:),'LineStyle',styles{a}, ...
        'LineWidth',1.7,'DisplayName',labels{a});
end
set(ax,'YScale','log','FontSize',5,'Box','on', ...
    'XGrid','off','YGrid','off','XMinorGrid','off','YMinorGrid','off');
ylim(ax,[cfg.tol,1]); ylabel(ax,'RSE');
if panel==1, xlabel(ax,'Number of row actions');
else, xlabel(ax,'Elapsed time (s)'); end
end

function hits=firstAttainmentIndices(errorHistory,levels)
% Return each threshold's first recorded hit using a single history scan.
% Thresholds are processed from largest to smallest as the running error
% trajectory first crosses them. This reduces work from O(history*levels)
% to O(history+levels).
errorHistory=errorHistory(:);
[ascendingLevels,order]=sort(levels(:),'ascend');
sortedHits=NaN(size(ascendingLevels));
next=numel(ascendingLevels);
for k=1:numel(errorHistory)
    currentError=errorHistory(k);
    if ~isfinite(currentError), continue; end
    while next>=1 && ascendingLevels(next)*(1+8*eps)>=currentError
        sortedHits(next)=k;
        next=next-1;
    end
    if next==0, break; end
end
hits=NaN(size(levels));
hits(order)=sortedHits;
end
