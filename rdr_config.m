function cfg=rdr_config(profile)
% Reproducible experiment settings. Tuning and evaluation seeds are disjoint.
if nargin<1, profile='review'; end
cfg.profile=profile;
cfg.seed=170926;
cfg.trials=20;
cfg.tuneTrials=3;
% Search eleven momentum values; alpha remains fixed at 0.5.
cfg.betaGrid=0:0.05:0.5;
cfg.alpha=0.5;
cfg.tol=1e-12;
cfg.maxIter=200000;
cfg.maxTime=60;
cfg.recordEvery=20;
cfg.checkEvery=1;
cfg.maxPairBytes=2e9;
cfg.methods={'RK','RDR','mRDR','IRDR-I','IRDR-II','AmRDR-I','AmRDR-II'};
cfg.outputDir=fullfile(fileparts(mfilename('fullpath')),'results','row_actions_v4',profile);
base=struct('name','','kind','spectral','m',500,'n',100,'rank',100, ...
    'sigma',10,'t',0.3,'rhsCount',1,'file','');
cfg.cases=repmat(base,0,1);
switch profile
    case 'smoke'
        cfg.trials=2; cfg.tuneTrials=1;
        cfg.maxIter=10000; cfg.maxTime=10; cfg.recordEvery=5;
        c=base; c.name='smoke'; c.m=40; c.n=10; c.rank=10; c.sigma=3;
        cfg.cases=c;
    case 'review'
        c=base; c.name='gaussian_full_sigma10'; cfg.cases(end+1)=c;
        c=base; c.name='gaussian_rank90_sigma10'; c.rank=90; cfg.cases(end+1)=c;
        c=base; c.name='uniform_t03'; c.kind='uniform'; cfg.cases(end+1)=c;
    case {'NE1','NE2','NE5','NE6','full'}
        ranks=100;
        if ismember(profile,{'NE2','NE6'}), ranks=90; end
        if strcmp(profile,'full'), ranks=[100,90]; end
        for r=ranks
            for sig=[10,50,100]
                c=base; c.rank=r; c.sigma=sig;
                c.name=sprintf('spectral_r%d_sigma%d',r,sig); cfg.cases(end+1)=c;
            end
        end
        if strcmp(profile,'full')
            for t=[0.3,0.6,0.9]
                c=base; c.kind='uniform'; c.t=t; c.name=sprintf('uniform_t%02d',round(10*t)); cfg.cases(end+1)=c;
            end
        end
        cfg.maxIter=30000000; cfg.maxTime=600;
    case {'NE3','NE7'}
        for t=[0.3,0.6,0.9]
            c=base; c.kind='uniform'; c.t=t; c.name=sprintf('uniform_t%02d',round(10*t)); cfg.cases(end+1)=c;
        end
        cfg.maxIter=5000000; cfg.maxTime=600;
    case {'NE4_m1000','NE4_m5000','NE4_m10000'}
        c=base; c.name=profile; c.m=str2double(extractAfter(profile,'NE4_m'));
        c.sigma=100; c.rhsCount=10; cfg.cases=c;
        cfg.maxIter=10000000; cfg.maxTime=600;
    case 'real'
        for name={'cari','cage','mk9-b1','n4c5-b2','ch5-5-b2','D_8','GL6_D_9'}
            c=base; c.name=name{1}; c.kind='real'; c.file=[name{1},'.mat']; cfg.cases(end+1)=c;
        end
        cfg.maxIter=2000000; cfg.maxTime=300;
    otherwise
        error('rdr:Config','Unknown profile.');
end
end
