function [x,out] = my_RK(A,b,opts,varargin)
% RK with shared stopping, diagnostics, and timing.
% Sample row i with probability ||A(i,:)||^2 / ||A||_F^2, then update
% x <- x + (b(i)-A(i,:)*x) * A(i,:)' / ||A(i,:)||^2.
% opts.xstar selects solution-error monitoring; otherwise use the residual.
% Sampling, the projection update, and monitoring are timed by rdr_solve.
if nargin<3, opts=struct; end
if ~isempty(varargin)
    if numel(varargin)~=2, error('rdr:Options','Expected legacy mm and edges.'); end
    opts.Prepared=rdr_legacy_prepare(A,varargin{1},varargin{2});
end
[x,out]=rdr_solve(A,b,'RK',opts);
end
