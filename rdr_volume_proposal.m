function [pair,accepted]=rdr_volume_proposal(prep,stream)
%RDR_VOLUME_PROPOSAL Make exactly one diagonal-proposal rejection attempt.
% Proposal probability is p(i)*p(j); acceptance is sin(angle(ai,aj))^2.
% Their product is proportional to the two-row Gram determinant. Keeping
% proposal order gives both reflection orders equal conditional probability.
pair=rdr_cdf_draw(prep.rowCDF,rand(stream,2,1))';
i=pair(1); j=pair(2); accepted=false;
if i==j, return; end
u=prep.volumeMatrix(i,:)/prep.volumeRowNorm(i);
v=prep.volumeMatrix(j,:)/prep.volumeRowNorm(j);
c=full(u*v'); q=max(0,min(1,1-c*c));
% Near parallel rows suffer cancellation in 1-c^2. The projection residual
% is algebraically equivalent and resolves small positive angles better.
if q<1e-8
    d=v-(c/full(u*u'))*u;
    q=max(0,min(1,full(d*d')/full(v*v')));
end
accepted=rand(stream)<q;
end
