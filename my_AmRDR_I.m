function [x,out] = my_AmRDR_I(A,b,opts,varargin)
% AmRDR-I with shared stopping, diagnostics, and timing.
% Legacy mm/edges arguments are supported for old volume-sampling callers.
if nargin<3, opts=struct; end
if ~isempty(varargin)
    if numel(varargin)~=2, error('rdr:Options','Expected legacy mm and edges.'); end
    opts.Prepared=rdr_legacy_prepare(A,varargin{1},varargin{2});
end
[x,out]=rdr_solve(A,b,'AmRDR-I',opts);
end
