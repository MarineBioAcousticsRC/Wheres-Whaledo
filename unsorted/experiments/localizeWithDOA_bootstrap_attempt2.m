% TO DO HERE:
% I want to set the conditions for bootstrapping better. Have separate
% functions for different combinations of instruments. All of them will
% call one of two 

% STEPS:
% 1) group detections according to which instruments received detection.
% 2) Have separate functions which solve for each condition:
%       a) both 4ch and at least one 1ch (bootstrap for both DOAs and randomly
%           replacing large ap TDOAs)
%       b) 
load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track600_180611_110414\track600_180611_110414_localized_cleaned.mat')
% W4ch = load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks_both4chOnly\track600_180611_110414_localized_cleaned.mat');
% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track666_180601_153000\track666_180601_153000_localized_cleaned.mat')
% W4ch = load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks_both4chOnly\track666_180601_153000_localized_cleaned.mat');
% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track216_180429_201958\track216_180429_201958_localized_cleaned.mat')
% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track30_180324_205700\track30_180324_205700_localized_cleaned.mat')
wn = 1;


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
LOC.R = (0:4000).';

loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\localize.params')

LOC.Nboot = 20;
LOC.largePairs = [1, 2; 1, 3; 1, 4; 2, 3; 2, 4; 3, 4];
ci_int = tinv([.025, .975], LOC.Nboot-1);


wloc = nan(length(whale{wn}.TDet), 3);
CIx = nan(length(whale{wn}.TDet), 2);
CIy = CIx;
CIz = CIx;

%% Case 1: DOA1 and at least one large ap TDOA:

Iuse = find(~isnan(whale{wn}.TDOA(:, 1)) & isnan(whale{wn}.TDOA(:,7)) ...
    & sum(~isnan(whale{wn}.TDOA(:, 13:end)), 2)>=1);

for i = 1:length(Iuse)
    tdoa = whale{wn}.TDOA(Iuse(i), :);
    drift = zeros(1,6);
    for ntdoa = 1:6
        drift(ntdoa) = polyval(dp{ntdoa}, whale{wn}.TDet(i));
    end
    tdoa(13:end) = tdoa(13:end) + LOC.driftSign.*drift;

    Ilrg = find(~isnan(tdoa(13:end))); % non-nan large ap TDOAs

    wlocs = nan(LOC.Nboot*length(Ilrg), 3);
    wts = nan(LOC.Nboot*length(Ilrg), 1);
    
    
    for ilrg = 1:length(Ilrg)
        hind = LOC.largePairs(Ilrg(ilrg), :); % which hydrophones are being used
        [wlocs_temp, wts_temp] = bs_OneSmlOneLrg(tdoa([1:6, Ilrg(ilrg)+12]), H{1}, hloc(1, :), hloc([hind(1), hind(2)], :), LOC);
        wlocs((LOC.Nboot*(ilrg-1) + 1):(LOC.Nboot*ilrg), :) = wlocs_temp;
        wts((LOC.Nboot*(ilrg-1) + 1):(LOC.Nboot*ilrg)) = wts_temp;
    end

    bootstat = bootstrp(LOC.Nboot, @(wlocs)(weightedAverage(wlocs, wts)), wlocs);
    wloc(Iuse(i), :) = mean(bootstat);
    SEM = std(bootstat)./sqrt(LOC.Nboot);

%     wloc(Iuse(i), :) = weightedAverage(wlocs, wts);
%     std_weighted = std(wlocs).*sqrt(sum(wts.^2)./(sum(wts)).^2);
%     SEM = std_weighted./sqrt(LOC.Nboot);
    
    CIx(Iuse(i), :) = wloc(Iuse(i), 1) + SEM(1).*ci_int;
    CIy(Iuse(i), :) = wloc(Iuse(i), 2) + SEM(2).*ci_int;
    CIz(Iuse(i), :) = wloc(Iuse(i), 3) + SEM(3).*ci_int;

end 
%% Case 2: DOA2 and at least one large ap TDOA:

Iuse = find(isnan(whale{wn}.TDOA(:, 1)) & ~isnan(whale{wn}.TDOA(:,7)) ...
    & sum(~isnan(whale{wn}.TDOA(:, 13:end)), 2)>=1);

for i = 1:length(Iuse)
    tdoa = whale{wn}.TDOA(Iuse(i), :);
    drift = zeros(1,6);
    for ntdoa = 1:6
        drift(ntdoa) = polyval(dp{ntdoa}, whale{wn}.TDet(i));
    end
    tdoa(13:end) = tdoa(13:end) + LOC.driftSign.*drift;

    Ilrg = find(~isnan(tdoa(13:end))); % non-nan large ap TDOAs

    wlocs = nan(LOC.Nboot*length(Ilrg), 3);
    wts = nan(LOC.Nboot*length(Ilrg), 1);
    
    
    for ilrg = 1:length(Ilrg)
        hind = LOC.largePairs(Ilrg(ilrg), :); % which hydrophones are being used
        [wlocs_temp, wts_temp] = bs_OneSmlOneLrg(tdoa([7:12, Ilrg(ilrg)+12]), H{2}, hloc(2, :), hloc([hind(1), hind(2)], :), LOC);
        wlocs((LOC.Nboot*(ilrg-1) + 1):(LOC.Nboot*ilrg), :) = wlocs_temp;
        wts((LOC.Nboot*(ilrg-1) + 1):(LOC.Nboot*ilrg)) = wts_temp;
    end

    bootstat = bootstrp(LOC.Nboot, @(wlocs)(weightedAverage(wlocs, wts)), wlocs);
    wloc(Iuse(i), :) = mean(bootstat);
    SEM = std(bootstat)./sqrt(LOC.Nboot);

%     wloc(Iuse(i), :) = weightedAverage(wlocs, wts);
%     std_weighted = std(wlocs).*sqrt(sum(wts.^2)./(sum(wts)).^2);
%     SEM = std_weighted./sqrt(LOC.Nboot);
%     
    CIx(Iuse(i), :) = wloc(Iuse(i), 1) + SEM(1).*ci_int;
    CIy(Iuse(i), :) = wloc(Iuse(i), 2) + SEM(2).*ci_int;
    CIz(Iuse(i), :) = wloc(Iuse(i), 3) + SEM(3).*ci_int;

end 

%% Case 3: both small ap. TDOAs, at least one large ap TDOA:

Iuse = find(~isnan(whale{wn}.TDOA(:, 1)) & ~isnan(whale{wn}.TDOA(:,7)) ...
    & sum(~isnan(whale{wn}.TDOA(:, 13:end)), 2)>=1);

for i = 1:length(Iuse)
    tdoa = whale{wn}.TDOA(Iuse(i), :);
    drift = zeros(1,6);
    for ntdoa = 1:6
        drift(ntdoa) = polyval(dp{ntdoa}, whale{wn}.TDet(i));
    end
    tdoa(13:end) = tdoa(13:end) + LOC.driftSign.*drift;

    Ilrg = find(~isnan(tdoa(13:end))); % non-nan large ap TDOAs

    wlocs = [];
    wts = [];
    
    for ilrg = 1:length(Ilrg)
        hind = LOC.largePairs(Ilrg(ilrg), :); % which hydrophones are being used in large ap TDOA
        % Using DOA1:
        [wlocs_temp, wts_temp] = bs_OneSmlOneLrg(tdoa([1:6, Ilrg(ilrg)+12]), H{1}, hloc(1, :), hloc([hind(1), hind(2)], :), LOC);
        wlocs = [wlocs; wlocs_temp];
        wts = [wts; wts_temp];
        
        % using DOA2:
        [wlocs_temp, wts_temp] = bs_OneSmlOneLrg(tdoa([7:12, Ilrg(ilrg)+12]), H{2}, hloc(2, :), hloc([hind(1), hind(2)], :), LOC);
        wlocs = [wlocs; wlocs_temp];
        wts = [wts; wts_temp];
    end

    % using DOA intersect, DOA1 as primary:
    [wlocs_temp, wts_temp] = bs_TwoSml(tdoa(1:12), H, hloc([1,2], :), LOC);
    wlocs = [wlocs; wlocs_temp];
    wts = [wts; wts_temp];

    % using DOA intersect, DOA2 as primary:
    [wlocs_temp, wts_temp] = bs_TwoSml(tdoa([7:12, 1:6]), {H{2}, H{1}}, hloc([2,1], :), LOC);
    wlocs = [wlocs; wlocs_temp];
    wts = [wts; wts_temp];

    bootstat = bootstrp(LOC.Nboot, @(wlocs)(weightedAverage(wlocs, wts)), wlocs);
    wloc(Iuse(i), :) = mean(bootstat);

    SEM = std(bootstat)./sqrt(LOC.Nboot);
%     wloc(Iuse(i), :) = weightedAverage(wlocs, wts);
%     std_weighted = std(wlocs).*sqrt(sum(wts.^2)./(sum(wts)).^2);
%     SEM = std_weighted./sqrt(LOC.Nboot);
    
    CIx(Iuse(i), :) = wloc(Iuse(i), 1) + SEM(1).*ci_int;
    CIy(Iuse(i), :) = wloc(Iuse(i), 2) + SEM(2).*ci_int;
    CIz(Iuse(i), :) = wloc(Iuse(i), 3) + SEM(3).*ci_int;

end 
%% Case 4: both small ap. TDOAs, no large ap TDOAs:

%% PLOT

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

Iuse = find(~isnan(CIx(:, 1)));
subplot(3,2,1)
plot(whale{wn}.TDet, whale{wn}.wloc(:,1), '.')
hold on
plot(whale{wn}.TDet, wloc(:,1), '.')
fill([whale{wn}.TDet(Iuse); flipud(whale{wn}.TDet(Iuse))], [CIx(Iuse,1); flipud(CIx(Iuse,2))] , [.3, .3, .3], 'EdgeColor', 'none', 'FaceAlpha', .5)
title('x')
ylabel('m')
datetick
hold off

subplot(3,2,3)
plot(whale{wn}.TDet, whale{wn}.wloc(:,2), '.')
hold on
plot(whale{wn}.TDet, wloc(:,2), '.')
fill([whale{wn}.TDet(Iuse); flipud(whale{wn}.TDet(Iuse))], [CIy(Iuse,1); flipud(CIy(Iuse,2))], [.3, .3, .3], 'EdgeColor', 'none', 'FaceAlpha', .5)
title('y')
ylabel('m')
datetick
hold off

subplot(3,2,5)
plot(whale{wn}.TDet, whale{wn}.wloc(:,3) + h0(3) , '.')
hold on
plot(whale{wn}.TDet, wloc(:,3) + h0(3) , '.')
fill([whale{wn}.TDet(Iuse); flipud(whale{wn}.TDet(Iuse))], [CIz(Iuse,1); flipud(CIz(Iuse,2))] + h0(3) , [.3, .3, .3], 'EdgeColor', 'none', 'FaceAlpha', .5)
plot(whale{wn}.TDet, zb_new, 'k')
title('z')
ylabel('m')
datetick
hold off
legend('ML', 'new method', '95% CI', 'bathymetry')

subplot(2,2,2)
plot(whale{wn}.TDet, whale{wn}.Ang1(:,1), '.')
hold on
plot(whale{wn}.TDet, whale{wn}.Ang2(:,1), '.')
hold off
title('azimuth')
ylabel('Ang [deg]')
datetick

subplot(2,2,4)
plot(whale{wn}.TDet, whale{wn}.Ang1(:,2), '.')
hold on
plot(whale{wn}.TDet, whale{wn}.Ang2(:,2), '.')
hold off
title('elevation')
ylabel('Ang [deg]')
legend('Array 1', 'Array 2')
datetick
%% *************************** FUNCTIONS ********************************

%% Weighted average function

function wloc = weightedAverage(wlocs, wts)
    wloc = sum(wlocs.*wts)./sum(wts);
end

%% Bootstrap functions
function [wlocs, wts] = bs_OneSmlOneLrg(tdoa, H, hloc_sml, hloc_lrg, LOC)
wlocs = nan(LOC.Nboot, 3);
wts = nan(LOC.Nboot, 1);

parfor ibs = 1:LOC.Nboot

    tdoa_bs = tdoa;
    H_bs = H;

    Ireplace = randi(6, [2, 1]); % randomly select one index to replace:
    replaceWith = randi(6, [2, 1]); % randomly select the index that will go in its place

    tdoa_bs(Ireplace) = tdoa_bs(replaceWith);
    H_bs(Ireplace, :) = H(replaceWith, :);

    [wlocs(ibs, :), wts(ibs)] = OneSmlOneLrg(tdoa_bs, H_bs, hloc_sml, hloc_lrg, LOC);

end
end

function [wlocs, wts] = bs_TwoSml(tdoa, H, hloc, LOC)
wlocs = nan(LOC.Nboot, 3);
wts = nan(LOC.Nboot, 1);
parfor nb = 1:LOC.Nboot
    tdoa_bs = tdoa;
    H_bs = H;
    
    for nh = 1:2
        Ireplace = randi(6, [2, 1]); % randomly select two indices to replace:
        replaceWith = randi(6, [2,1]) ; % randomly select the indices that will go in their place

        tdoa_bs(Ireplace+ (nh-1)*6) = tdoa_bs(replaceWith+ (nh-1)*6);
        H_bs{nh}(Ireplace, :) = H{nh}(replaceWith, :);

    end
    [wlocs(nb, :), wts(nb)] = TwoSml(tdoa_bs, H_bs, hloc, LOC);
end
end
%% Localization functions
function [wloc, wt] = OneSmlOneLrg(tdoa, H, hloc_sml, hloc_lrg, LOC)
doa = (tdoa(1:6).'.*LOC.c)\H;
doa = doa./sqrt(sum(doa.^2));

wloc_pot = LOC.R*doa + hloc_sml; % potential source locations along DOA

r1 = sqrt(sum((wloc_pot - hloc_lrg(1, :)).^2, 2)); % potential ranges to first inst
r2 = sqrt(sum((wloc_pot - hloc_lrg(2, :)).^2, 2)); % potential ranges to second inst

tdoa_exp = (r1 - r2)./LOC.c;

MSE = (tdoa(7) - tdoa_exp).^2; % mean squared error

[~, I] = min(MSE);

wloc = wloc_pot(I, :);

% Idiff = max([1, I-2]):min([I+2, length(MSE)]); % indices to use in weight calculation
% wt = mean(diff(diff(MSE(Idiff)))); % weight
wt = 1./sum(var(wloc));
end

function [wloc, wt] = TwoSml(tdoa, H, hloc, LOC)
doa1 = (tdoa(1:6).'.*LOC.c)\H{1};
doa1 = doa1./sqrt(sum(doa1.^2));

doa2 = (tdoa(7:12).'.*LOC.c)\H{2};
doa2 = doa2./sqrt(sum(doa2.^2));

wloc_pot = LOC.R*doa1 + hloc(1, :);

MSE = sum(((wloc_pot - hloc(2, :)) - ((wloc_pot-hloc(2, :))*doa2.').*doa2).^2, 2)./LOC.c^2;

[~, I] = min(MSE);

wloc = wloc_pot(I, :);

% Idiff = max([1, I-2]):min([I+2, length(MSE)]); % indices to use in weight calculation
% wt = mean(diff(diff(MSE(Idiff)))); % weight
wt = 1./sum(var(wloc));
end