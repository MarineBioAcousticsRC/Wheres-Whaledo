% TO DO HERE:
% I still haven't implemented bootstrapping. The idea is to rewrite
% searchOneDOA and searchTwoDOA so the input is only the TDOAs, then:
% 1) convert TDOAsml to DOA
% 2) calculate expected TDOA along DOA
% 3) find range that minimizes this distance (2 and 3 can be done with
% fsolve instead)
% 4) resample TDOAs and do it again (bootstrap resampling)
% 5) use distribution of locs from resample to estimate variance & CI
%
load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track600_180611_110414\track600_180611_110414_localized_cleaned.mat')
% W4ch = load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks_both4chOnly\track600_180611_110414_localized_cleaned.mat');
% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track666_180601_153000\track666_180601_153000_localized_cleaned.mat')
% W4ch = load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks_both4chOnly\track666_180601_153000_localized_cleaned.mat');
% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track216_180429_201958\track216_180429_201958_localized_cleaned.mat')
% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track30_180324_205700\track30_180324_205700_localized_cleaned.mat')
wn = 2;


% load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')
load('D:\SOCAL_E_63\xwavTables\instrumentLocs_new.mat')
hydLoc{1} = hLatLonZ(1,:) + [0,0,6+10];
hydLoc{2} = hLatLonZ(2,:) + [0,0,6+10];
hydLoc{3} = hLatLonZ(3,:) + [0,0,10+10];
hydLoc{4} = hLatLonZ(4,:) + [0,0,10+10];

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

% load drift:
load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift.mat');
dp{1} = coeffvalues(Dpoly{1}); % drift coefficients between inst 1 and 2
dp{2} = coeffvalues(Dpoly{2}); % drift coefficients between inst 1 and 3
dp{3} = coeffvalues(Dpoly{3}); % drift coefficients between inst 1 and 4
dp{4} = coeffvalues(Dpoly{4}); % drift coefficients between inst 2 and 3
dp{5} = coeffvalues(Dpoly{5}); % drift coefficients between inst 2 and 4
dp{6} = coeffvalues(Dpoly{6}); % drift coefficients between inst 3 and 4

options = optimoptions('fsolve', 'Display', 'none');

tic
global LOC
loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\localize.params')
% LOC.c = 1480
wloc = nan(size(whale{wn}.wloc));

Iuse = find(isnan(whale{wn}.Ang1(:,1)) | ~isnan(whale{wn}.Ang2(:,1)));
for i = 1:length(Iuse)
    ind = Iuse(i);

    drift = zeros(1,6);
    for ntdoa = 1:6
        drift(ntdoa) = polyval(dp{ntdoa}, whale{wn}.TDet(i));
    end
    tdoa = whale{wn}.TDOA(ind, :);
    tdoa(13:end) = whale{wn}.TDOA(ind, 13:end) + LOC.driftSign.*drift;

    wloc(i, :) = loc(tdoa, H, hloc, LOC.c);

%     wlocs = bs_tdoasml(tdoa, H, hloc, LOC.c, 50);

%     residuals = (wlocs - wloc).^2;

    ok = 1;
end

toc

%%
figure(1)
posText{1} = 'x [m]';
posText{2} = 'y [m]';
posText{3} = 'z [m]';


G = load('D:\SOCAL_E_63\bathymetry\SOCAL_E_63_GMRT.mat');
[x,~] = latlon2xy_wgs84(h0(1).*ones(size(G.lon)), G.lon, h0(1), h0(2));
[~,y] = latlon2xy_wgs84(G.lat, h0(2).*ones(size(G.lat)), h0(1), h0(2));

zb_new = nan(length(wloc), 1);
for nd = 1:length(wloc)
    [~, Iwx] = min((x - wloc(nd, 1)).^2);
    [~, Iwy] = min((y - wloc(nd, 2)).^2);
    zb_new(nd) = G.z(Iwy, Iwx);
end


zb_ml = nan(length(wloc), 1);
for nd = 1:length(wloc)
    [~, Iwx] = min((x - whale{wn}.wloc(nd, 1)).^2);
    [~, Iwy] = min((y - whale{wn}.wloc(nd, 2)).^2);
    zb_ml(nd) = G.z(Iwy, Iwx);
end



for sp = 1:3
    subplot(3,3,3*sp-2)
    plot(whale{wn}.TDet, whale{wn}.wloc(:,sp), 'o', 'Color', [.3, .2, .8]);
    %    legstr{1} = locTypes{1};
    hold on
%     plot(W4ch.whale{wn}.TDet, W4ch.whale{wn}.wloc(:,sp), 'x')
    plot(whale{wn}.TDet, wloc(:, sp), 'x', 'Color', [.9, .11, .2])
    hold off
    datetick
    grid on

    ylabel(posText{sp})
end
hold on
plot(whale{wn}.TDet, zb_ml-h0(3), '.', 'Color', [.3, .2, .8].*.6)
plot(whale{wn}.TDet, zb_new-h0(3), '.', 'Color', [.9, .11, .2].*.6)
hold off

legend('ML', 'new method', 'bathymetry')

angText{1} = 'Azimuth [deg]';
angText{2} = 'Elevation [deg]';
for sp = 1:2
    subplot(2,3,3*sp-1)
    %     plot(W4ch.whale{wn}.TDet, W4ch.whale{wn}.Ang1(:,sp), 'x')
    %     hold on
    plot(whale{wn}.TDet, whale{wn}.Ang1(:,sp), '.')
    hold on
    %     plot(W4ch.whale{wn}.TDet, W4ch.whale{wn}.Ang2(:,sp), 'x')
    plot(whale{wn}.TDet, whale{wn}.Ang2(:,sp), '.')
    hold off
    legend('Array 1', 'Array 2')
    datetick
    grid on
    ylabel(angText{sp})
end

pairstr = {'1-2', '1-3', '1-4', '2-3', '2-4', '3-4'};
for sp = 1:6
    subplot(6,3, 3*sp)
    plot(whale{wn}.TDet, whale{wn}.TDOA(:, 12+sp), '.');
    datetick
    grid on
    ylabel('TDOA [s]')
    title(['Pair ', pairstr{sp}])

end
%%

%% Function for calling Likelihood function calcuations, determining weights

function wloc = loc(tdoa, H, hloc, c)
R1 = (0:5000).';
R2 = (0:5000).';

wts = nan(1, 10);
wloc_est = nan(3, 10);
if ~isnan(tdoa(1)) % detection found on H1 (array)
    doa1 = (tdoa(1:6).'.*c)\H{1};
    doa1 = doa1./sqrt(sum(doa1.^2));
    if ~isnan(tdoa(13))
        L = loc1DOA(R1, tdoa(1:6), tdoa(13), H{1}, hloc([1,2], :), c);
        [~, Ibest] = min(L(1:end-1));
        wloc_est(:, 1) = doa1.*R1(Ibest) + hloc(1, :);
        Idiff = max([1, Ibest-2]):min([Ibest+2, length(L)]);
        wts(1) = mean(diff(diff(L(Idiff))));
    end

    if ~isnan(tdoa(14))
        L = loc1DOA(R1, tdoa(1:6), tdoa(14), H{1}, hloc([1,3], :), c);
        [~, Ibest] = min(L(1:end-1));
        wloc_est(:, 2) = doa1.*R1(Ibest) + hloc(1, :);
        Idiff = max([1, Ibest-2]):min([Ibest+2, length(L)]);
        wts(2) = mean(diff(diff(L(Idiff))));
    end

    if ~isnan(tdoa(15))
        L = loc1DOA(R1, tdoa(1:6), tdoa(15), H{1}, hloc([1,4], :), c);
        [~, Ibest] = min(L(1:end-1));
        wloc_est(:, 3) = doa1.*R1(Ibest) + hloc(1, :);
        Idiff = max([1, Ibest-2]):min([Ibest+2, length(L)]);
        wts(3) = mean(diff(diff(L(Idiff))));
    end

    if ~isnan(tdoa(18))
        L = loc1DOA_both1ch(R1, tdoa(1:6), tdoa(18), H{1}, hloc([1, 3, 4], :), c);
        [~, Ibest] = min(L(1:end-1));
        wloc_est(:, 4) = doa1.*R1(Ibest) + hloc(1, :);
        Idiff = max([1, Ibest-2]):min([Ibest+2, length(L)]);
        wts(4) = mean(diff(diff(L(Idiff))));
    end
end

if ~isnan(tdoa(7)) % detection found on H1 (array)
    doa2 = (tdoa(7:12).'.*c)\H{2};
    doa2 = doa2./sqrt(sum(doa2.^2));
    if ~isnan(tdoa(13))
        L = loc1DOA(R2, tdoa(7:12), -tdoa(13), H{2}, hloc([2,1], :), c);
        [~, Ibest] = min(L(1:end-1));
        wloc_est(:, 5) = doa2.*R2(Ibest) + hloc(2, :);
        Idiff = max([1, Ibest-2]):min([Ibest+2, length(L)]);
        wts(5) = mean(diff(diff(L(Idiff))));
    end

    if ~isnan(tdoa(16))
        L = loc1DOA(R2, tdoa(7:12), tdoa(16), H{2}, hloc([2,3], :), c);
        [~, Ibest] = min(L(1:end-1));

        wloc_est(:, 6) = doa2.*R2(Ibest) + hloc(2, :);
        Idiff = max([1, Ibest-2]):min([Ibest+2, length(L)]);
        wts(6) = mean(diff(diff(L(Idiff))));
    end

    if ~isnan(tdoa(17))
        L = loc1DOA(R2, tdoa(7:12), tdoa(17), H{2}, hloc([2,4], :), c);
        [~, Ibest] = min(L(1:end-1));
        wloc_est(:, 7) = doa2.*R2(Ibest) + hloc(2, :);
        Idiff = max([1, Ibest-2]):min([Ibest+2, length(L)]);
        wts(7) = mean(diff(diff(L(Idiff))));
    end

    if ~isnan(tdoa(18))
        L = loc1DOA_both1ch(R2, tdoa(7:12), tdoa(18), H{2}, hloc([2, 3, 4], :), c);
        [~, Ibest] = min(L(1:end-1));
        wloc_est(:, 8) = doa2.*R2(Ibest) + hloc(2, :);
        Idiff = max([1, Ibest-2]):min([Ibest+2, length(L)]);
        wts(8) = mean(diff(diff(L(Idiff))));
    end
end

if ~isnan(tdoa(1)) && ~isnan(tdoa(7))
    doa1 = (tdoa(1:6).'.*c)\H{1};
    doa1 = doa1./sqrt(sum(doa1.^2));

    doa2 = (tdoa(7:12).'.*c)\H{2};
    doa2 = doa2./sqrt(sum(doa2.^2));

    L = loc2DOA(R1, tdoa(1:12), H, hloc([1,2], :), c);
    [~, Ibest] = min(L(1:end-1));
    wloc_est(:, 9) = doa1.*R1(Ibest) + hloc(1, :);
    Idiff = max([1, Ibest-2]):min([Ibest+2, length(L)]);
    wts(9) = mean(diff(diff(L(Idiff))));

    L = loc2DOA(R2, [tdoa(7:12), tdoa(1:6)], {H{2}, H{1}}, hloc([2,1], :), c);
    [~, Ibest] = min(L(1:end));
    wloc_est(:, 10) = doa2.*R2(Ibest) + hloc(2, :);

    Idiff = max([1, Ibest-2]):min([Ibest+2, length(L)]);
    wts(10) = mean(diff(diff(L(Idiff))));

end
%
wloc = (sum(abs(wts).*wloc_est, 2, 'omitnan')./sum(abs(wts), 'omitnan')).';
% fun = @(wloc)(weightedMean)
% for ndim = 1:3
%     wloc_bs(:,ndim) = bootstrp(10, @(west)(weightedMean(west, wts)), wloc_est(ndim, :))
% end

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

%% Function for bootstrapping small ap TDOAs

function [wlocs] = bs_tdoasml(tdoa, H, hloc, c, Nbs)

wlocs = zeros(Nbs, 3);

for n = 1:Nbs
    tdoa_resampled = tdoa;
    % resample:
    for nh = 1:2
        Ireplace = randi(6, [2, 1]); % indices to replace
        replaceWith = randi(6, [2,1]); % replace those indices with data from these indices
        H_resampled{nh} = H{nh};
        H_resampled{nh}(Ireplace, :) = H_resampled{nh}(replaceWith, :); % resample H matrix
        tdoa_resampled(Ireplace + 6*(nh-1)) = tdoa_resampled(replaceWith + 6*(nh-1)); % resample TDOAs
    end

    wlocs(n, :) = loc(tdoa_resampled, H_resampled, hloc, c);

end
end