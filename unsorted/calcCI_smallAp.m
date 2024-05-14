function [CIx, CIy, CIz] = calcCI_smallAp(w1, w2, hloc, LOC)

CIx = nan(1, 2);
CIy = nan(1, 2);
CIz = nan(1, 2);
% vectors used for CI calculations:
xv = LOC.wxlim(1):LOC.wxlim(2);
yv = LOC.wylim(1):LOC.wylim(2);
zv = LOC.wzlim(1):LOC.wzlim(2);

% calculate CIx:
[mTDOA, mwloc] = makeModel(xv, wloc(2), wloc(3), h, H1, H2, LOC.c, 'DOA');
Lx = Asml*exp(-1./(2.*LOC.sig_sml^2).*sum((mTDOA(:,1:12)-TDOA(1:12)).^2, 2, 'omitnan'));
Cx = cumsum(Lx)./sum(Lx);
% Cx = cumsum(Lx);
% Cx = Cx-min(Cx);
% Cx = Cx./max(Cx);
I = find(Cx<=.025, 1, 'last');
if ~isempty(I)
    CIx(1) = xv(I);
else
    CIx(1) = LOC.wxlim(1);
end
I = find(Cx>=.975, 1, 'first');
if ~isempty(I)
    CIx(2) = xv(I);
else
    CIx(2) = LOC.wxlim(2);
end

% calculate CIy:
[mTDOA, mwloc] = makeModel(wloc(1), yv, wloc(3), h, H1, H2, LOC.c, 'DOA');
Ly = Asml*exp(-1./(2.*LOC.sig_sml^2).*sum((mTDOA(:,1:12)-TDOA(1:12)).^2, 2, 'omitnan'));
Cy = cumsum(Ly)./sum(Ly);
% Cy = cumsum(Ly);
% Cy = Cy - min(Cy);
% Cy = Cy./max(Cy);
I = find(Cy<=.025, 1, 'last');
if ~isempty(I)
    CIy(1) = yv(I);
else
    CIy(1) = LOC.wylim(1);
end
I = find(Cy>=.975, 1, 'first');
if ~isempty(I)
    CIy(2) = yv(I);
else
    CIy(2) = LOC.wylim(2);
end

% calculate CIz:
[mTDOA, mwloc] = makeModel(wloc(1), wloc(2), zv, h, H1, H2, LOC.c, 'DOA');
Lz = Asml*exp(-1./(2.*LOC.sig_sml^2).*sum((mTDOA(:,1:12)-TDOA(1:12)).^2, 2, 'omitnan'));
Cz = cumsum(Lz)./sum(Lz);
% Cz = cumsum(Lz);
% Cz = Cz-min(Cz);
% Cz = Cz./max(Cz);
I = find(Cz<=.025, 1, 'last');
if ~isempty(I)
    CIz(1) = zv(I);
else
    CIz(1) = LOC.wzlim(1);
end
I = find(Cz>=.975, 1, 'first');
if ~isempty(I)
    CIz(2) = zv(I);
else
    CIz(2) = LOC.wzlim(2);
end

