function environment=demo_freeze(cfg)
% Save source snapshots and reject accidental resumes with a changed protocol.
root=fileparts(mfilename('fullpath'));
if ~exist(cfg.outputDir,'dir'), mkdir(cfg.outputDir); end
files=dir(fullfile(root,'*.m'));
snapshotFiles=files;
% Editable scripts are UI settings, captured by cfg rather than source hashes.
% This permits pasting resumeFolder into a script without invalidating a run.
% Changes to solver/helper files or effective settings still reject resume.
if isfield(cfg,'mode') && strcmp(cfg.mode,'editable')
    files=files(~startsWith({files.name},'demo_editable_'));
end
sources=struct('name',{},'sha256',{});
for k=1:numel(files)
    sources(k)=struct('name',files(k).name,'sha256',demo_hash(fullfile(root,files(k).name)));
end
file=fullfile(cfg.outputDir,'configuration.mat');
if exist(file,'file')
    old=load(file,'cfg','sources','environment');
    if ~isequaln(old.cfg,cfg) || ~isequal(old.sources,sources)
        error('demo:Resume','Settings or source changed. Use a new output directory; do not mix runs.');
    end
    environment=old.environment; return
end
environment=struct('matlab',version,'release',version('-release'),'computer',computer, ...
    'started',datestr(now,30),'processor',getenv('PROCESSOR_IDENTIFIER'), ...
    'logicalProcessors',getenv('NUMBER_OF_PROCESSORS'),'maxThreads',maxNumCompThreads, ...
    'timing','Serial wall-clock; median actual repetition for short groups');
save(file,'cfg','environment','sources');
f=fopen(fullfile(cfg.outputDir,'configuration.json'),'w','n','UTF-8');
fprintf(f,'%s',jsonencode(struct('configuration',cfg,'environment',environment,'sources',sources))); fclose(f);
zip(fullfile(cfg.outputDir,'source_snapshot.zip'),{snapshotFiles.name},root);
end
