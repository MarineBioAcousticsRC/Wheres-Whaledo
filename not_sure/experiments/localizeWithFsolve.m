load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track600_180611_110414\track600_180611_110414_localized_cleaned.mat')
% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track666_180601_153000\track666_180601_153000_localized_cleaned.mat')
% W4ch = load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks_both4chOnly\track666_180601_153000_localized_cleaned.mat');
W4ch = load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks_both4chOnly\track600_180611_110414_localized_cleaned.mat');
wn = 2;


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

% load drift:
load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift.mat');
dp{1} = coeffvalues(Dpoly{1}); % drift coefficients between inst 1 and 2
dp{2} = coeffvalues(Dpoly{2}); % drift coefficients between inst 1 and 3
dp{3} = coeffvalues(Dpoly{3}); % drift coefficients between inst 1 and 4
dp{4} = coeffvalues(Dpoly{4}); % drift coefficients between inst 2 and 3
dp{5} = coeffvalues(Dpoly{5}); % drift coefficients between inst 2 and 4
dp{6} = coeffvalues(Dpoly{6}); % drift coefficients between inst 3 and 4


tic
global LOC
loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\localize.params')
wloc = nan(size(whale{wn}.wloc));
for i = 1:length(whale{wn}.TDet)
    NTDOA = find(~isnan(whale{wn}.TDOA(i, :)));
    if length(NTDOA)<LOC.minNumTDOA
        continue
    end
    TDOA = whale{wn}.TDOA(i, :);
    drift = zeros(1, 6);
    for ntdoa = 1:6
        drift(ntdoa) = polyval(dp{ntdoa}, whale{wn}.TDet(i));
    end
    TDOA(13:end) = TDOA(13:end) + LOC.driftSign.*drift;
    
    fun = @(w)tdoaSolve(w, TDOA, LOC, H{1}, H{2}, hloc);
    options = optimoptions('fsolve', 'Display', 'none');
    [w, ~, exitflag, output]  = fsolve(fun, 500.*round(whale{wn}.wloc(i, :)./500), options);
    
    
%     [w,resnorm,residual,exitflag,~,~,jacobian] = lsqnonlin(fun, [0,0,0], [-5000, -5000, -200], [5000, 5000, 1350], options);
% [w,resnorm,residual,exitflag,~,~,jacobian] = lsqnonlin(fun, [0,0,0], [], [], options);
%      [estParams,~,residual,~,~,~,jacobian] = lsqnonlin();
%  CI = nlparci(w,residual,'jacobian',jacobian);
%     residual = tdoaSolve(w, TDOA, LOC, H{1}, H{2}, hloc);
%     CI = nlparci(w, residual,'jacobian',jacobian);
    
    wloc(i, :) = w;

%     if abs((wloc(i, 3) - whale{wn}.wloc(i, 3)))>500
%         ok = 1;
%     end

end
toc

% tic
% whale = localize(whale, hloc, H{1}, H{2}, dp);
% toc
%%
figure(1)
posText{1} = 'x [m]';
posText{2} = 'y [m]';
posText{3} = 'z [m]';

for sp = 1:3
    subplot(3,2,2*sp-1)
   plot(whale{wn}.TDet, whale{wn}.wloc(:,sp), 'x')
   hold on
   plot(whale{wn}.TDet, wloc(:, sp), 'o')
   plot(W4ch.whale{wn}.TDet, W4ch.whale{wn}.wloc(:,sp), '^')
   hold off
   datetick
   grid on
   legend('ML', 'fsolve', 'DOAintersect')
   ylabel(posText{sp})
end

angText{1} = 'Azimuth [deg]';
angText{2} = 'Elevation [deg]';
for sp = 1:2
    subplot(2,2,2*sp)
    plot(W4ch.whale{wn}.TDet, W4ch.whale{wn}.Ang1(:,sp), 'x')
    hold on
    plot(whale{wn}.TDet, whale{wn}.Ang1(:,sp), '.')
    plot(W4ch.whale{wn}.TDet, W4ch.whale{wn}.Ang2(:,sp), 'x')
    plot(whale{wn}.TDet, whale{wn}.Ang2(:,sp), '.')
    hold off
    legend('Array 1', 'Array 2')
    datetick
    grid on
    ylabel(angText{sp})
end
%%

function L = tdoaSolve(wloc, TDOA, LOC, H1, H2, hloc)

sig2sml = LOC.sig_sml^2;
sig2lrg = LOC.sig_lrg^2;

Isml = find(~isnan(TDOA(1:12))); % indices of small ap used
Ilrg = find(~isnan(TDOA(13:end)))+12; % indices of large ap used

Asml = (2*pi*sig2sml)^(-length(Isml)/2); % coefficient of small ap
Alrg = (2*pi*sig2lrg)^(-length(Ilrg)/2); % coefficient of large ap

s1 = wloc - hloc(1,:);
r1 = sqrt(sum(s1.^2));
s1 = s1./r1;

s2 = wloc - hloc(2,:);
r2 = sqrt(sum(s2.^2));
s2 = s2./r2;

s3 = wloc - hloc(3,:);
r3 = sqrt(sum(s3.^2));

s4 = wloc - hloc(4,:);
r4 = sqrt(sum(s4.^2));

mTDOA(1:6) = s1*H1.'./LOC.c;
mTDOA(7:12) = s2*H2.'./LOC.c;

mTDOA(13) = (r1-r2)./LOC.c;
mTDOA(14) = (r1-r3)./LOC.c;
mTDOA(15) = (r1-r4)./LOC.c;
mTDOA(16) = (r2-r3)./LOC.c;
mTDOA(17) = (r2-r4)./LOC.c;
mTDOA(18) = (r3-r4)./LOC.c;

Lsml = 1./(2.*sig2sml).*sum((mTDOA(:,1:12)-TDOA(1:12)).^2, 2, 'omitnan');
Llrg = 1./(2.*sig2lrg).*sum((mTDOA(:,13:end)-TDOA(13:end)).^2, 2, 'omitnan');

L = Lsml.*Llrg;
end
