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
fn = 'D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track600_180611_110414\track600_180611_110414_localized_cleaned.mat'
% fn = 'D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track666_180601_153000\track666_180601_153000_localized_cleaned.mat'
% W4ch = load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks_both4chOnly\track666_180601_153000_localized_cleaned.mat');
% fn = 'D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track216_180429_201958\track216_180429_201958_localized_cleaned.mat';
% fn = 'D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track30_180324_205700\track30_180324_205700_localized_cleaned.mat'
load(fn)

% 
% wn = 2;


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

% H{1} = [.5762, .0644, -0.2829;
%         -.1556, -.8496, -.3445;
%         .2621, .3964, -.3176;
%         .0830, .2010, -.0358;
%         .3206, .7112, -.0411;
%         .1582, .2459, -.0426];
% 
% H{2} = [0.3236,   -0.0683,   -0.1350;
%    -0.0240,    0.0079,   -0.0843;
%     0.2837,   -0.1509,   -0.1914;
%    -0.0736,   -0.1776,   -0.0137;
%    -0.2741,    0.0438,   -0.0128;
%    -0.1456,    0.7263,    0.0141];

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

ci_int = tinv([.025, .975], LOC.Nboot-1);

for wn = 1:numel(whale)
    if isempty(whale{wn})
        continue
    end

wloc = nan(length(whale{wn}.TDet), 3);
CIx = nan(length(whale{wn}.TDet), 2);
CIy = CIx;
CIz = CIx;

%% Interpolate
for ntdoa = 1:18
    Iuse = find(~isnan(whale{wn}.TDOA(:, ntdoa)));
    if isempty(Iuse)
        continue
    end
    tdoa = interp1(whale{wn}.TDet(Iuse), whale{wn}.TDOA(Iuse, ntdoa), whale{wn}.TDet);

    whale{wn}.TDOA(:, ntdoa) = tdoa;
end

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

    wlocs = [];
    wts = [];
    
    
    for ilrg = 1:length(Ilrg)
        hind = LOC.largePairs(Ilrg(ilrg), :); % which hydrophones are being used
        [wlocs_temp, wts_temp] = mc_OneSmlOneLrg(tdoa([1:6, Ilrg(ilrg)+12]), H{1}, hloc(1, :), hloc([hind(1), hind(2)], :), LOC);
        wlocs = [wlocs; wlocs_temp];
%         wts = [wts; wts_temp];
wts = [wts; ones(size(wts_temp))./sum(var(wlocs))];
    end

%     bootstat = bootstrp(LOC.Nboot, @(wlocs)(weightedAverage(wlocs, wts)), wlocs);
bootfun = @(wlocs)(weightedAverage(wlocs, wts));
[ci, bootstat] = bootci(LOC.Nboot,{bootfun, wlocs},'Type','norm');
    wloc(Iuse(i), :) = mean(ci);
    %     SEM = std(bootstat)./sqrt(LOC.Nboot);
    
%     std_weighted = std(wlocs).*sqrt(sum(wts.^2)./(sum(wts)).^2);
%     SEM = std_weighted./sqrt(length(wts));
%     CIx(Iuse(i), :) = wloc(Iuse(i), 1) + SEM(1).*ci_int;
%     CIy(Iuse(i), :) = wloc(Iuse(i), 2) + SEM(2).*ci_int;
%     CIz(Iuse(i), :) = wloc(Iuse(i), 3) + SEM(3).*ci_int;
    CIx(Iuse(i), :) = ci(:, 1);
    CIy(Iuse(i), :) = ci(:, 2);
    CIz(Iuse(i), :) = ci(:, 3);

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

    wlocs = [];
    wts = [];
    
    for ilrg = 1:length(Ilrg)
        hind = LOC.largePairs(Ilrg(ilrg), :); % which hydrophones are being used
        [wlocs_temp, wts_temp] = mc_OneSmlOneLrg(tdoa([7:12, Ilrg(ilrg)+12]), H{2}, hloc(2, :), hloc([hind(1), hind(2)], :), LOC);
        wlocs = [wlocs; wlocs_temp];
%         wts((LOC.NMonteCarlo*(ilrg-1) + 1):(LOC.NMonteCarlo*ilrg)) = wts_temp;
wts = [wts; ones(size(wts_temp))./sum(var(wlocs))];
    end


    %     bootstat = bootstrp(LOC.Nboot, @(wlocs)(weightedAverage(wlocs, wts)), wlocs);
    bootfun = @(wlocs)(weightedAverage(wlocs, wts));
    [ci, bootstat] = bootci(LOC.Nboot,{bootfun, wlocs},'Type','student');
    wloc(Iuse(i), :) = mean(ci);

    %     SEM = std(bootstat)./sqrt(LOC.Nboot);
%     std_weighted = std(wlocs).*sqrt(sum(wts.^2)./(sum(wts)).^2);
%     SEM = std_weighted./sqrt(length(wts));

%     CIx(Iuse(i), :) = wloc(Iuse(i), 1) + SEM(1).*ci_int;
%     CIy(Iuse(i), :) = wloc(Iuse(i), 2) + SEM(2).*ci_int;
%     CIz(Iuse(i), :) = wloc(Iuse(i), 3) + SEM(3).*ci_int;

    CIx(Iuse(i), :) = ci(:, 1);
    CIy(Iuse(i), :) = ci(:, 2);
    CIz(Iuse(i), :) = ci(:, 3);


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
        [wlocs_temp, wts_temp] = mc_OneSmlOneLrg(tdoa([1:6, Ilrg(ilrg)+12]), H{1}, hloc(1, :), hloc([hind(1), hind(2)], :), LOC);
        wlocs = [wlocs; wlocs_temp];
%         wts = [wts; wts_temp];
wts = [wts; ones(size(wts_temp))./sum(var(wlocs))];
        
        % using DOA2:
        [wlocs_temp, wts_temp] = mc_OneSmlOneLrg(tdoa([7:12, Ilrg(ilrg)+12]), H{2}, hloc(2, :), hloc([hind(1), hind(2)], :), LOC);
                wlocs = [wlocs; wlocs_temp];
%         wts = [wts; wts_temp];
wts = [wts; ones(size(wts_temp))./sum(var(wlocs))];
    end

    % using DOA intersect:
    [wlocs_temp, wts_temp] = mc_TwoSml(tdoa(1:12), H, hloc([1,2], :), LOC);
    wlocs = [wlocs; wlocs_temp];
%     wts = [wts; wts_temp];
wts = [wts; ones(size(wts_temp))./sum(var(wlocs))];

    [wlocs_temp, wts_temp] = mc_TwoSml(tdoa([7:12, 1:6]), {H{2}, H{1}}, hloc([2,1], :), LOC);
    wlocs = [wlocs; wlocs_temp];
%     wts = [wts; wts_temp];
wts = [wts; ones(size(wts_temp))./sum(var(wlocs))];

%     bootstat = bootstrp(LOC.Nboot, @(wlocs)(weightedAverage(wlocs, wts)), wlocs);

bootfun = @(wlocs)(weightedAverage(wlocs, wts));
[ci, bootstat] = bootci(LOC.Nboot,{bootfun, wlocs},'Type','student');

    wloc(Iuse(i), :) = mean(ci);


%     SEM = std(bootstat)./sqrt(LOC.Nboot);
%     std_weighted = std(wlocs).*sqrt(sum(wts.^2)./(sum(wts)).^2);
%     SEM = std_weighted./sqrt(length(wts));
%     CIx(Iuse(i), :) = wloc(Iuse(i), 1) + SEM(1).*ci_int;
%     CIy(Iuse(i), :) = wloc(Iuse(i), 2) + SEM(2).*ci_int;
%     CIz(Iuse(i), :) = wloc(Iuse(i), 3) + SEM(3).*ci_int;
    CIx(Iuse(i), :) = ci(:, 1);
    CIy(Iuse(i), :) = ci(:, 2);
    CIz(Iuse(i), :) = ci(:, 3);

end 
%% Case 4: both small ap. TDOAs, no large ap TDOAs:
Iuse = find(~isnan(whale{wn}.TDOA(:, 1)) & ~isnan(whale{wn}.TDOA(:,7)) ...
    & sum(~isnan(whale{wn}.TDOA(:, 13:end)), 2)==0);

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
  
    % using DOA intersect:
    [wlocs_temp, wts_temp] = mc_TwoSml(tdoa(1:12), H, hloc([1,2], :), LOC);
    wlocs = [wlocs; wlocs_temp];
%     wts = [wts; wts_temp];
wts = [wts; ones(size(wts_temp))./sum(var(wlocs))];

    [wlocs_temp, wts_temp] = mc_TwoSml(tdoa([7:12, 1:6]), {H{2}, H{1}}, hloc([2,1], :), LOC);
    wlocs = [wlocs; wlocs_temp];
%     wts = [wts; wts_temp];
wts = [wts; ones(size(wts_temp))./sum(var(wlocs))];

%     bootstat = bootstrp(LOC.Nboot, @(wlocs)(weightedAverage(wlocs, wts)), wlocs);
bootfun = @(wlocs)(weightedAverage(wlocs, wts));
[ci, bootstat] = bootci(LOC.Nboot,{bootfun, wlocs},'Type','student');
    wloc(Iuse(i), :) = mean(ci);

%     SEM = std(bootstat)./sqrt(LOC.Nboot);
%     std_weighted = std(wlocs).*sqrt(sum(wts.^2)./(sum(wts)).^2);
%     SEM = std_weighted./sqrt(length(wts));
%     CIx(Iuse(i), :) = wloc(Iuse(i), 1) + SEM(1).*ci_int;
%     CIy(Iuse(i), :) = wloc(Iuse(i), 2) + SEM(2).*ci_int;
%     CIz(Iuse(i), :) = wloc(Iuse(i), 3) + SEM(3).*ci_int;
    CIx(Iuse(i), :) = ci(:, 1);
    CIy(Iuse(i), :) = ci(:, 2);
    CIz(Iuse(i), :) = ci(:, 3);

end 
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
fig = figure(wn)
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

subplot(1,2,2)
contour(x, y, G.z)
hold on
plot(whale{wn}.wloc(:, 1), whale{wn}.wloc(:, 2), '.')
plot(wloc(:,1), wloc(:,2), '.')
plot(hloc(:,1), hloc(:,2), 'ks')
hold off
title('azimuth')
ylabel('y [m]')
xlabel('x [m]')
axis([-4000, 4000, -4000, 4000])
pbaspect([1,1,1])

whale{wn}.wloc = wloc;
whale{wn}.CIx = CIx;
whale{wn}.CIy = CIy;
whale{wn}.CIz = CIz;


end
save([fn(1:end-4), '_mc'], 'whale')
%% *************************** FUNCTIONS ********************************

%% Weighted average function

function wloc = weightedAverage(wlocs, wts)
    wloc = sum(wlocs.*wts)./sum(wts);
end

%% Monte Carlo functions
function [wlocs, wts] = mc_OneSmlOneLrg(tdoa, H, hloc_sml, hloc_lrg, LOC)
wlocs = nan(LOC.NMonteCarlo, 3);
wts = nan(LOC.NMonteCarlo, 1);

parfor i = 1:LOC.NMonteCarlo

        tdoa_mc = tdoa;

        % add random perturbations to tdoas according:
        tdoa_mc(1:6) = tdoa_mc(1:6) + randn(1, 6).*LOC.sig_sml;
        tdoa_mc(7) = tdoa_mc(7) + randn(1).*LOC.sig_lrg;

        [wlocs(i, :), wts(i)] = OneSmlOneLrg(tdoa_mc, H, hloc_sml, hloc_lrg, LOC);

end
end

function [wlocs, wts] = mc_TwoSml(tdoa, H, hloc, LOC)
wlocs = nan(LOC.NMonteCarlo, 3);
wts = nan(LOC.NMonteCarlo, 1);
parfor i = 1:LOC.NMonteCarlo
    tdoa_mc = tdoa;
    
    tdoa_mc = tdoa_mc + randn(1, 12).*LOC.sig_sml;

    [wlocs(i, :), wts(i)] = TwoSml(tdoa_mc, H, hloc, LOC);
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

Idiff = max([1, I-2]):min([I+2, length(MSE)]); % indices to use in weight calculation
wt = mean(diff(diff(MSE(Idiff)))); % weight

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

Idiff = max([1, I-2]):min([I+2, length(MSE)]); % indices to use in weight calculation
wt = mean(diff(diff(MSE(Idiff)))); % weight

end