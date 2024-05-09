% using shipTDOA to solve for hydrophone positions and orientations (no
% assumption about instrument location)

load('D:\SOCAL_E_63\SOCAL_E_63_EW\ShipLocalization\fromGPS\E_63_combined.mat');
T = load('D:\SOCAL_E_63\SOCAL_E_63_EW\ShipLocalization\EWtoEallTDOA.mat')

y2k = datenum([2000, 0, 0, 0, 0, 0]);
stime = stime - y2k;

Irem = find(diff(stime)==0);

stime(Irem+1) = [];
slat(Irem+1) = [];
slon(Irem+1) = [];

[sx, sy]= latlon2xy_wgs84(slat, slon, slat0, slon0);
sz = 1330.*ones(size(sx));

tstart = max([min(T.TDet), min(stime)]);
tend = min([max(T.TDet), max(stime)]);
I = find(T.TDet>=tstart & T.TDet<=tend);
ti = T.TDet(I).';
tdoa = T.TDOA(I, :);

for i = 1:length(ti)
    [~, I] = min(abs(stime - ti(i)));
    s(i, 1) = sx(I);
    s(i, 2) = sy(I);
    s(i,3) = sz(I);
end

h0 = randn(1, 13);
h0(13) = 1490;

fun = @(x)hydSolve(x,s, tdoa);
hv = fsolve(fun, h0);

h(1, :) = hv(1:3);
h(2, :) = hv(4:6);
h(3, :) = hv(7:9);
h(4, :) = hv(10:12);
c = hv(13);

scatter3(h(:,1), h(:,2), h(:,3))
%%

% h (4x3), instrument locations

% equation relating TDOA to ship locations:
% TDOA = (R_1 - R_2)/c

function F = hydSolve(h, s, tdoa)

R1 = sqrt(sum((h(1:3)-s).^2, 2));
R2 = sqrt(sum((h(4:6)-s).^2, 2));
R3 = sqrt(sum((h(7:9)-s).^2, 2));
R4 = sqrt(sum((h(10:12)-s).^2, 2));

F(:, 1) = (R1 - R2)./h(13) - tdoa(:, 1);
F(:, 2) = (R1 - R3)./h(13) - tdoa(:, 2);
F(:, 3) = (R1 - R4)./h(13) - tdoa(:, 3);
F(:, 4) = (R2 - R3)./h(13) - tdoa(:, 4);
F(:, 5) = (R2 - R4)./h(13) - tdoa(:, 5);
F(:, 6) = (R3 - R4)./h(13) - tdoa(:, 6);


end
