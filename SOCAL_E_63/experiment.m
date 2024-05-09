% load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')
load('D:\SOCAL_E_63\xwavTables\instrumentLocs_new.mat')
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

% xwav tables:
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EE_C4_xwavLookupTable');
XH{1} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EW_C4_xwavLookupTable');
XH{2} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EN_xwavLookupTable');
XH{3} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_ES_xwavLookupTable');
XH{4} = xwavTable;

hyd1 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EE_Hmatrix_new.mat');
hyd2 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EW_Hmatrix_new.mat');

% HEW = H;

% Reorder hydrophones to fit new TDOA order (needed at SOCAL_E because sometimes I make things confusing even for myself)
H{1} = [hyd1.hydPos(2,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(3,:)];

H{2} = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];

%%
c = 1488.4;
wloc(1) = randi(4000, 1) - 2000;
wloc(2) = randi(4000, 1) - 2000;
wloc(3) = randi(1300, 1)-100;

r1 = sqrt(sum((wloc - hloc(1, :)).^2));
s1 = (wloc - hloc(1, :))./r1;

r2 = sqrt(sum((wloc - hloc(2, :)).^2));
s2 = (wloc - hloc(2, :))./r2;

r3 = sqrt(sum((wloc - hloc(3, :)).^2));
s3 = (wloc - hloc(3, :))./r3;

r4 = sqrt(sum((wloc - hloc(4, :)).^2));
s4 = (wloc - hloc(4, :))./r4;

tdoa(1:6) = (s1*H{1}.')./c;
tdoa(7:12) = (s2*H{2}.')./c;
tdoa(13) = (r1-r2)/c;
tdoa(14) = (r1-r3)/c;
tdoa(15) = (r1-r4)/c;
tdoa(16) = (r2-r3)/c;
tdoa(17) = (r2-r4)/c;
tdoa(18) = (r3-r4)/c;



% R = fsolve(fun, 200, options)

R1 = 0:4000;
L1 = nan(size(R1));
L2 = nan(size(R1));
L3 = nan(size(R1));

for i = 1:length(R1)
    L{1}(i) = loc1DOA(R1(i), tdoa(1:6), tdoa(13), H{1}, hloc([1,2], :), c);
    L{2}(i) = loc1DOA(R1(i), tdoa(1:6), tdoa(14), H{1}, hloc([1,3], :), c);
    L{3}(i) = loc1DOA(R1(i), tdoa(1:6), tdoa(15), H{1}, hloc([1,4], :), c);
    L{4}(i) = loc2DOA(R1(i), tdoa(1:12), H, hloc([1,2], :), c);
end

R2 = R1;
for i = 1:length(R1)
    L{5}(i) = loc1DOA(R2(i), tdoa(7:12), -tdoa(13), H{2}, hloc([2,1], :), c);
    L{6}(i) = loc1DOA(R2(i), tdoa(7:12), tdoa(16), H{2}, hloc([2,3], :), c);
    L{7}(i) = loc1DOA(R2(i), tdoa(7:12), tdoa(17), H{2}, hloc([2,4], :), c);
    L{8}(i) = loc2DOA(R2(i), tdoa([7:12, 1:6]), {H{2}, H{1}}, hloc([2,1], :), c);
end

for il = 1:numel(L)
    dl(il, :) = diff(L{il})./diff(R1);
end

%%
fig = figure(100);
for sp = 1:4
    subplot(4,2,2*sp-1)
    plot(R1, L{sp})
    hold on
    [~, Imin] = min(L{sp});
    plot([R1(Imin), R1(Imin)], [min(L{sp}), max(L{sp})])
    plot([r1, r1], [min(L{sp}), max(L{sp})])
    hold off
end

for sp = 1:4
    subplot(4,2,2*sp)
    plot(R2, L{sp+4})
    hold on
    [~, Imin] = min(L{sp+4});
    plot([R2(Imin), R2(Imin)], [min(L{sp+4}), max(L{sp+4})])
    plot([r2, r2], [min(L{sp+4}), max(L{sp+4})])
    hold off
end
sgtitle('E')

figure(101)
for sp = 1:8
    subplot(4,2,sp)
    plot(R1(2:end), dl(sp, :))
end
sgtitle('dE/dT')

Lsum1 = zeros(size(R1));
for sp = 1:4
    Lsum1 =Lsum1 + L{sp};
end

%%
tic
wlocEst = loc(tdoa, H, hloc, c);
tc = toc;
wloc
wlocEst

%% Function for calling Likelihood function calcuations, determining weights

function wloc = loc(tdoa, H, hloc, c)
R1 = (0:4000).';
R2 = (0:4000).';

wts = nan(1, 8);
wloc_est = nan(3, 8);
if ~isnan(tdoa(1)) % detection found on H1 (array)
    doa1 = (tdoa(1:6).'.*c)\H{1};
    if ~isnan(tdoa(13))
        L = loc1DOA(R1, tdoa(1:6), tdoa(13), H{1}, hloc([1,2], :), c);
        [~, Ibest] = min(L);
        wloc_est(:, 1) = doa1.*R1(Ibest);
        wts(1) = mean(diff(L(Ibest-1:Ibest+1))./diff(R1(Ibest-1:Ibest+1)));
    end

    if ~isnan(tdoa(14))
        L = loc1DOA(R1, tdoa(1:6), tdoa(14), H{1}, hloc([1,3], :), c);
        [~, Ibest] = min(L);
        wloc_est(:, 2) = doa1.*R1(Ibest);
        wts(2) = mean(diff(L(Ibest-1:Ibest+1))./diff(R1(Ibest-1:Ibest+1)));
    end

    if ~isnan(tdoa(15))
        L = loc1DOA(R1, tdoa(1:6), tdoa(15), H{1}, hloc([1,4], :), c);
        [~, Ibest] = min(L);
        wloc_est(:, 3) = doa1.*R1(Ibest);
        wts(3) = mean(diff(L(Ibest-1:Ibest+1))./diff(R1(Ibest-1:Ibest+1)));
    end

    if ~isnan(tdoa(18))
        loc1DOA_both1ch(R1, tdoa(1:6), tdoa(18), H{1}, hloc([1, 3, 4], :), c)
        [~, Ibest] = min(L);
        wloc_est(:, 5) = doa1.*R1(Ibest);
        wts(5) = mean(diff(L(Ibest-1:Ibest+1))./diff(R1(Ibest-1:Ibest+1)));
    end
end

if ~isnan(tdoa(7)) % detection found on H1 (array)
    doa2 = (tdoa(7:12).'.*c)\H{2};
    if ~isnan(tdoa(13))
        L = loc1DOA(R2, tdoa(7:12), -tdoa(13), H{2}, hloc([2,1], :), c);
        [~, Ibest] = min(L);
        wloc_est(:, 5) = doa2.*R2(Ibest);
        wts(5) = mean(diff(L(Ibest-1:Ibest+1))./diff(R1(Ibest-1:Ibest+1)));
    end

    if ~isnan(tdoa(16))
        L = loc1DOA(R2, tdoa(7:12), tdoa(16), H{2}, hloc([2,3], :), c);
        [~, Ibest] = min(L(2:end-1));
        
        wloc_est(:, 6) = doa2.*R2(Ibest);
        wts(6) = mean(diff(L(Ibest-1:Ibest+1))./diff(R1(Ibest-1:Ibest+1)));
    end

    if ~isnan(tdoa(17))
        L = loc1DOA(R2, tdoa(7:12), tdoa(17), H{2}, hloc([2,4], :), c);
        [~, Ibest] = min(L);
        wloc_est(:, 7) = doa2.*R2(Ibest);
        wts(7) = mean(diff(L(Ibest-1:Ibest+1))./diff(R1(Ibest-1:Ibest+1)));
    end

    if ~isnan(tdoa(18))
        loc1DOA_both1ch(R2, tdoa(7:12), tdoa(18), H{2}, hloc([2, 3, 4], :), c)
        [~, Ibest] = min(L);
        wloc_est(:, 8) = doa2.*R2(Ibest);
        wts(8) = mean(diff(L(Ibest-1:Ibest+1))./diff(R1(Ibest-1:Ibest+1)));
    end
end

wloc = (sum(wts.*wloc_est, 2, 'omitnan')./sum(wts, 'omitnan')).';

end
%% Functions for localizing with minimum data
function L = loc1DOA(R, tdoasml, tdoalrg, H, hloc, c)

doa = (tdoasml.'.*c)\H;
doa = doa./sqrt(sum(doa.^2));

wloc = R*doa + hloc(1, :);

r2 = sqrt(sum((wloc - hloc(2, :)).^2, 2));

tdoa_exp = (R - r2)./c;

L = (tdoalrg - tdoa_exp).^2;

end

function L = loc1DOA_both1ch(R, tdoasml, tdoalrg, H, hloc, c)
doa = (tdoasml.'.*c)\H;
doa = doa./sqrt(sum(doa.^2));

wloc = R*doa + hloc(1, :);

r2 = sqrt(sum((wloc - hloc(2, :)).^2, 2));
r3 = sqrt(sum((wloc - hloc(3, :)).^2, 2));

tdoa_exp = (r2 - r3)./c;

L = (tdoalrg - tdoa_exp).^2;
end

function L = loc2DOA(R, tdoa, H, hloc, c)

doa1 = (tdoa(1:6).'.*c)\H{1};
doa1 = doa1./sqrt(sum(doa1.^2));

doa2 = (tdoa(7:12).'.*c)\H{2};
doa2 = doa2./sqrt(sum(doa2.^2));

w1 = R*doa1 + hloc(1, :);

L = sum(((w1 - hloc(2, :)) - ((w1-hloc(2, :))*doa2.').*doa2).^2, 2)./c^2;
end