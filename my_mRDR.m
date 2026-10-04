function [x,out] = my_mRDR(A,b,beta,opts)
% Fixed-momentum RDR with the shared validated solver.
if nargin<4, opts=struct; end
opts.beta=beta;
[x,out]=rdr_solve(A,b,'mRDR',opts);
end
