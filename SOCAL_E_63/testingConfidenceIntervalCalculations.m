% testing localization CI
global LOC
loadParams('localize.params')

load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')
hydLoc{1} = hLatLonZ(1,:);
hydLoc{2} = hLatLonZ(2,:);
hydLoc{3} = hLatLonZ(3,:);
hydLoc{4} = hLatLonZ(4,:);

h0 = mean([hydLoc{1}; hydLoc{2}]);

% convert hydrophone locations to meters:
[h1(1), h1(2)] = latlon2xy_wgs84(hydLoc{1}(1), hydLoc{1}(2), h0(1), h0(2));
h1(3) = abs(h0(3))-abs(hydLoc{1}(3));

[h2(1), h2(2)] = latlon2xy_wgs84(hydLoc{2}(1), hydLoc{2}(2), h0(1), h0(2));
h2(3) = abs(h0(3))-abs(hydLoc{2}(3));

[h3(1), h3(2)] = latlon2xy_wgs84(hydLoc{3}(1), hydLoc{3}(2), h0(1), h0(2));
h3(3) = abs(h0(3))-abs(hydLoc{3}(3));

[h4(1), h4(2)] = latlon2xy_wgs84(hydLoc{4}(1), hydLoc{4}(2), h0(1), h0(2));
h4(3) = abs(h0(3))-abs(hydLoc{4}(3));

hloc = [h1;h2;h3;h4];

hyd1 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EE_Hmatrix_fromHydLocInversion_210702.mat');
hyd2 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EW_Hmatrix_fromHydLocInversion_210702.mat');

% HEW = H;

% Reorder hydrophones to fit new TDOA order
H1 = [hyd1.hydPos(2,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(3,:)];

H2 = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];


c = 1488.4;

sig2 = ones(1,18);
sig2(1:12) = ((.1e-3)^2 + (.05e-3).^2);
sig2(13:18) = ((5e-3)^2 + (.3e-3)^2);
Asml = (2*pi*sig2(1)).^(-12/2);
Alrg = (2*pi*sig2(18)).^(-6/2);

for n = 1:10
w(1) = randi(8000, 1) - 4000;
w(2) = randi(8000, 1) - 4000;
w(3) = randi(1000, 1) - 100;

[TDOAperfect, wout] = makeModel(w(1), w(2), w(3), hloc, H1, H2, c);

TDOA = TDOAperfect + randn(size(TDOAperfect)).*sig2.*100;

xv = -4000:100:4000;
yv = -4000:100:4000;
zv = -100:50:1100;

[mTDOA, mwloc] = makeModel(xv, yv, zv, hloc, H1, H1, c);


L = Alrg.*Asml.*exp(-1.*sum((mTDOA-TDOA).^2./(2.*sig2), 2));

[~, Ibest] = max(L);

[CIx, CIy, CIz] = calcCI(TDOA, mwloc(Ibest, :), hloc, H1, H2, sig2, Asml, Alrg, LOC);

figure(1)
subplot(3,1,1)
plot(n, w(1), 'x')
hold on
errorbar(n, w(1), CIx(1)-w(1), CIx(2)-w(1))

subplot(3,1,2)
plot(n, w(2), 'x')
hold on
errorbar(n, w(2), CIy(1)-w(2), CIy(2)-w(2))

subplot(3,1,3)
plot(n, w(3), 'x')
hold on
errorbar(n, w(3), CIz(1)-w(3), CIz(2)-w(3))
end

%%
function [TDOA, wloc] = makeModel(xv, yv, zv, h, H1, H2, c)

% make wloc (matrix of whale positions)
[cx, cy, cz] = ndgrid(xv, yv, zv);
wloc = [cx(:), cy(:), cz(:)];

s1 = wloc-h(1, :);
r1 = sqrt(sum(s1.^2, 2)); % range to instrument 1
s1 = s1./r1; % direction vector to instrument 1

s2 = wloc-h(2, :);
r2 = sqrt(sum(s2.^2, 2)); % range to instrument 2
s2 = s2./r2; % direction vector to instrument 2

s3 = wloc-h(3, :);
r3 = sqrt(sum(s3.^2, 2)); % range to instrument 3

s4 = wloc-h(4, :);
r4 = sqrt(sum(s4.^2, 2)); % range to instrument 4

% small aperture TDOAs
TDOA(:, 1:6) = (s1*H1.')./c;
TDOA(:, 7:12) = (s2*H2.')./c;

% large aperture TDOAs
TDOA(:, 13) = (r1-r2)./c;
TDOA(:, 14) = (r1-r3)./c;
TDOA(:, 15) = (r1-r4)./c;
TDOA(:, 16) = (r2-r3)./c;
TDOA(:, 17) = (r2-r4)./c;
TDOA(:, 18) = (r3-r4)./c;

end

%%
function [CIx, CIy, CIz] = calcCI(TDOA, wloc, h, H1, H2, sig2, Asml, Alrg, LOC)
CIx = nan(1, 2);
CIy = nan(1, 2);
CIz = nan(1, 2);
% vectors used for CI calculations:
xv = LOC.wxlim(1):LOC.wxlim(2);
yv = LOC.wylim(1):LOC.wylim(2);
zv = LOC.wzlim(1):LOC.wzlim(2);

% calculate CIx:
[mTDOA, mwloc] = makeModel(xv, wloc(2), wloc(3), h, H1, H2, LOC.c);
Lx = Asml*Alrg*exp(-1.*sum((mTDOA-TDOA).^2./(2.*sig2), 2, 'omitnan'));
Cx = cumsum(Lx)./sum(Lx);
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
[mTDOA, mwloc] = makeModel(wloc(1), yv, wloc(3), h, H1, H2, LOC.c);
Ly = Asml*Alrg*exp(-1.*sum((mTDOA-TDOA).^2./(2.*sig2), 2, 'omitnan'));
Cy = cumsum(Ly)./sum(Ly);
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
[mTDOA, mwloc] = makeModel(wloc(1), wloc(2), zv, h, H1, H2, LOC.c);
Lz = Asml*Alrg*exp(-1.*sum((mTDOA-TDOA).^2./(2.*sig2), 2, 'omitnan'));
Cz = cumsum(Lz)./sum(Lz);
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

ok = 1;

end