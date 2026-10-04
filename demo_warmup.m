function demo_warmup(cfg)
% Warm every method using independent systems, excluding all warm-up time.
w=rdr_config('smoke'); [A,b,x]=rdr_problem(w.cases,61917); [p,~]=demo_prepare(A,cfg);
for rep=1:cfg.warmupRepeats
    for k=1:numel(cfg.methods)
        o=demo_options(cfg,119+rep); o.Prepared=p; o.xstar=x;
        o.Max_iter=cfg.warmupSteps; o.TOL=0; o.beta=0.15;
        rdr_solve(A,b,cfg.methods{k},o);
    end
end
end
