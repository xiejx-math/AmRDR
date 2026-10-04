function index = rdr_cdf_draw(cdf, u)
% Return the first cumulative probability strictly greater than each draw.
% Zero-weight intervals are skipped, including repeated CDF entries.
u = u(:);
lo = ones(size(u));
hi = repmat(numel(cdf),size(u));
while any(lo < hi)
    active = lo < hi;
    mid = floor((lo(active)+hi(active))/2);
    below = cdf(mid) <= u(active);
    a = find(active);
    lo(a(below)) = mid(below)+1;
    hi(a(~below)) = mid(~below);
end
index = lo;
end
