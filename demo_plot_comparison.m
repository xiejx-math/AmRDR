function figures=demo_plot_comparison(dataFile,selection,outputDir,cfgOverride)
%DEMO_PLOT_COMPARISON Replot saved data with VRRK-style light/dark bands.
% No solver is called. Old CDF results may be plotted only by explicitly
% supplying their MAT path; their timing is never relabeled as rejection.
% Examples:
%   demo_plot_comparison([], 'all')        % Two separate figures per case.
%   demo_plot_comparison([], 'spectral_r100_sigma50')
% Figures stay open; PNG, vector PDF and editable FIG copies are exported.
root=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(dataFile)
    dataFile=fullfile(root,'results','demo_v4_row_actions','formal','synthetic','all_results.mat');
end
if nargin<2 || isempty(selection), selection='all'; end
if nargin<3 || isempty(outputDir)
    if isstruct(dataFile)
        outputDir=fullfile(pwd,['quantiles_',datestr(now,'yyyymmdd_HHMMSS')]);
    else
        outputDir=fullfile(fileparts(dataFile),['quantiles_',datestr(now,'yyyymmdd_HHMMSS')]);
    end
end
if isstruct(dataFile)
    % Accept in-memory results to avoid loading a second copy of a large MAT
    % file immediately before plotting at the end of an editable run.
    results=dataFile;
    if nargin<4 || isempty(cfgOverride)
        error('demo:SavedData','Pass cfg as the fourth input with in-memory results.');
    end
    cfg=cfgOverride;
else
    S=load(dataFile);
    if isfield(S,'results'), results=S.results;
    elseif isfield(S,'R'), results=S.R;
    else, error('demo:SavedData','Select a complete case or benchmark MAT file.'); end
    cfg=S.cfg;
end
if isempty(results), error('demo:SavedData','No complete cases.'); end
if ~exist(outputDir,'dir'), mkdir(outputDir); end
% Keep 'grid' as an alias for old commands, but always export standalone axes.
if ismember(selection,{'all','grid'}), indices=1:numel(results);
else, indices=find(strcmp({results.caseName},selection)); end
if isempty(indices), error('demo:Selection','Unknown complete case.'); end
figures=gobjects(numel(indices),2);
suffixes={'row_actions','time'};
for k=1:numel(indices)
    R=results(indices(k));
    for panel=1:2
        fig=figure('Color','w', ...
            'Name',[R.caseName,' - ',suffixes{panel}],'NumberTitle','off');
        figures(k,panel)=fig;
        ax=axes('Parent',fig); h=rdr_plot_quantiles(ax,R,cfg,panel); 
        title(ax, rdr_case_label(R),'Interpreter','latex','FontSize',9);
        legend(ax,h,'Location','best','FontSize',9);
        exportFigure(fig,[R.caseName,'_quantiles_',suffixes{panel}]);
    end
end
    function exportFigure(fig,name)
        stem=fullfile(outputDir,name);
        rdr_style_figure(fig);
        exportgraphics(fig,[stem,'.png'],'Resolution',200);
        exportgraphics(fig,[stem,'.pdf'],'ContentType','vector');
        savefig(fig,[stem,'.fig']); fprintf('Saved %s\n',stem);
    end
end
