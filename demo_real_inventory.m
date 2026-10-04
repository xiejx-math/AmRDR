function inventory=demo_real_inventory(cfg)
% Audit local matrix identities without silently substituting a different file.
if nargin<1, cfg=demo_config('real'); end
if ~exist(cfg.outputDir,'dir'), mkdir(cfg.outputDir); end
names=cellfun(@strtrim,cfg.realNames,'UniformOutput',false);
names=unique(names,'stable');
inventory=struct('localName',{},'path',{},'sha256',{},'problemName',{},'problemId',{}, ...
    'status',{},'m',{},'n',{},'nnz',{},'numericRank',{},'rankTolerance',{}, ...
    'nonzeroCondition',{},'zeroRows',{},'rankMethod',{});
for k=1:numel(names)
    file=fullfile(fileparts(mfilename('fullpath')),'data_AmRDR',[names{k},'.mat']);
    item=struct('localName',names{k},'path',file,'sha256','','problemName','', ...
        'problemId',NaN,'status','missing','m',NaN,'n',NaN,'nnz',NaN, ...
        'numericRank',NaN,'rankTolerance',NaN,'nonzeroCondition',NaN, ...
        'zeroRows',NaN,'rankMethod','not computed');
    if exist(file,'file')
        data=load(file,'Problem'); item.sha256=demo_hash(file);
        if isfield(data,'Problem') && isfield(data.Problem,'A')
            P=data.Problem; A=double(P.A); meta=demo_describe(A,cfg,61917+k);
            if isfield(P,'name'), item.problemName=char(P.name); end
            if isfield(P,'id'), item.problemId=double(P.id); end
            item.status='verified_local_matrix';
            if isempty(item.problemName), item.status='identity_metadata_missing'; end
            item.m=meta.m; item.n=meta.n; item.nnz=meta.nnz;
            item.numericRank=meta.rank; item.rankTolerance=meta.rankTolerance;
            item.nonzeroCondition=meta.nonzeroCondition; item.zeroRows=meta.zeroRows;
            item.rankMethod=meta.rankMethod;
        else
            item.status='invalid_Problem_A';
        end
    end
    inventory(end+1)=item;
    fprintf('AUDIT %s: %s [%s]\n',item.localName,item.status,item.problemName);
end
save(fullfile(cfg.outputDir,'matrix_inventory.mat'),'inventory');
writetable(struct2table(inventory),fullfile(cfg.outputDir,'matrix_inventory.csv'));
end
