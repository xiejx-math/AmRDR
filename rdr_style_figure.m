function rdr_style_figure(fig)
%RDR_STYLE_FIGURE Shared readable font sizes for every exported figure.
% Edit these four values to adjust all benchmark and saved-data plots.
tickSize=9; labelSize=14; titleSize=14; legendSize=9;
for ax=reshape(findall(fig,'Type','axes'),1,[])
    set(ax,'FontUnits','points','FontSize',tickSize);
    set(ax.XLabel,'FontUnits','points','FontSize',labelSize);
    set(ax.YLabel,'FontUnits','points','FontSize',labelSize);
    set(ax.Title,'FontUnits','points','FontSize',titleSize);
end
set(findall(fig,'Type','legend'),'FontUnits','points','FontSize',legendSize);
drawnow;
end
