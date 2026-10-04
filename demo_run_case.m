function R=demo_run_case(c,cfg,ci)
% Checkpoint every RHS; safely reuse completed records under a frozen protocol.
folder=fullfile(cfg.outputDir,c.name);
if ~exist(folder,'dir'), mkdir(folder); end
complete=fullfile(folder,'complete.mat');
if exist(complete,'file'), saved=load(complete,'R'); R=saved.R; return; end
[tune,beta,tuneTime]=demo_tune_case(c,cfg,ci,folder);
runs=struct('trial',{},'rhs',{},'method',{},'dataSeed',{},'algorithmSeed',{}, ...
    'rowPrepTime',{},'volumePrepTime',{},'rhsCount',{},'out',{}, ...
    'timingSeconds',{},'timingStatuses',{},'selectedRepetition',{},'repeatConsistent',{});
matrixMetadata=cell(cfg.trials,1);
fixedA=[];
if strcmp(c.kind,'real'), data=load(c.file,'Problem'); fixedA=double(data.Problem.A); end
for trial=1:cfg.trials
    trialFolder=fullfile(folder,sprintf('trial_%02d',trial));
    if ~exist(trialFolder,'dir'), mkdir(trialFolder); end
    dataSeed=cfg.seed+ci*100000+10000+trial*100;
    pending=false;
    for rhs=1:c.rhsCount
        if ~exist(fullfile(trialFolder,sprintf('rhs_%03d.mat',rhs)),'file'), pending=true; break; end
    end
    if pending
        [A,~,~]=demo_matrix(c,dataSeed,fixedA);
        [prep,issue]=demo_prepare(A,cfg);
        metaFile=fullfile(trialFolder,'matrix_metadata.mat');
        if exist(metaFile,'file')
            saved=load(metaFile,'meta'); meta=saved.meta;
            % Resume rebuilds sampling data, but deployment cost is charged once.
            prep.rowPrepTime=meta.rowPrepTime; prep.volumePrepTime=meta.volumePrepTime;
        else
            meta=demo_describe(A,cfg,dataSeed+61);
            if strcmp(c.kind,'spectral') && isfinite(meta.rank) && meta.rank~=c.rank
                error('demo:Rank','Rank mismatch for %s.',c.name);
            end
            meta.rowPrepTime=prep.rowPrepTime; meta.volumePrepTime=prep.volumePrepTime;
            meta.volumeCDFBytes=8*numel(prep.volumeCDF); meta.volumeSampler=prep.volumeSampler; meta.volumeIssue=issue;
            save(metaFile,'meta');
        end
    else
        saved=load(fullfile(trialFolder,'matrix_metadata.mat'),'meta'); meta=saved.meta;
    end
    matrixMetadata{trial}=meta;
    for rhs=1:c.rhsCount
        file=fullfile(trialFolder,sprintf('rhs_%03d.mat',rhs));
        if exist(file,'file')
            saved=load(file,'group'); group=saved.group;
        else
            % All RHS use an independent, recorded seed even for the first solve.
            [~,b,xstar,reference]=demo_matrix(c,dataSeed+rhs,A);
            order=circshift(1:numel(cfg.methods),[0,mod(trial+rhs-2,numel(cfg.methods))]);
            seed=cfg.seed+ci*100000+50000+trial*1000+rhs*10;
            measured=demo_measure(A,b,xstar,prep,cfg,seed,beta,order);
            group=runs([]);
            for a=1:numel(measured)
                v=measured(a); vp=0;
                if endsWith(v.method,'-II'), vp=prep.volumePrepTime; end
                group(end+1)=struct('trial',trial,'rhs',rhs,'method',v.method, ...
                    'dataSeed',dataSeed+rhs,'algorithmSeed',v.algorithmSeed, ...
                    'rowPrepTime',prep.rowPrepTime,'volumePrepTime',vp,'rhsCount',c.rhsCount, ...
                    'out',v.out,'timingSeconds',v.timingSeconds,'timingStatuses',{v.timingStatuses}, ...
                    'selectedRepetition',v.selectedRepetition,'repeatConsistent',v.repeatConsistent);
            end
            partial=[file,'.partial.mat']; save(partial,'group','reference'); movefile(partial,file);
            fprintf('SAVED %s trial=%d/%d rhs=%d/%d successes=%d/%d\n',c.name,trial,cfg.trials,rhs,c.rhsCount, ...
                sum(arrayfun(@(r)r.out.converged,group)),numel(group));
        end
        runs=[runs,group]; %#ok<AGROW>
    end
end
R=struct('caseName',c.name,'caseConfig',c,'beta',beta,'tuneTime',tuneTime, ...
    'tuning',tune,'runs',runs,'numericRank',cellfun(@(m)m.rank,matrixMetadata), ...
    'matrixMetadata',{matrixMetadata});
save(complete,'R','cfg','-v7');
end
