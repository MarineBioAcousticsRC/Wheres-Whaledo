hyd1a = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EE_Hmatrix_fromHydLocInversion_210702.mat');
hyd1b = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EE_Hmatrix_new.mat');
% hyd1.hydPos = hyd1.recPos;
hyd2a = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EW_Hmatrix_fromHydLocInversion_210702.mat');
hyd2b = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EW_Hmatrix_new.mat');

% Reorder hydrophones to fit new TDOA order
H1 = [hyd1a.hydPos(2,:)-hyd1a.hydPos(1,:);
    hyd1a.hydPos(3,:)-hyd1a.hydPos(1,:);
    hyd1a.hydPos(4,:)-hyd1a.hydPos(1,:);
    hyd1a.hydPos(3,:)-hyd1a.hydPos(2,:);
    hyd1a.hydPos(4,:)-hyd1a.hydPos(2,:);
    hyd1a.hydPos(4,:)-hyd1a.hydPos(3,:)];

H2 = [hyd2a.hydPos(2,:)-hyd2a.hydPos(1,:);
    hyd2a.hydPos(3,:)-hyd2a.hydPos(1,:);
    hyd2a.hydPos(4,:)-hyd2a.hydPos(1,:);
    hyd2a.hydPos(3,:)-hyd2a.hydPos(2,:);
    hyd2a.hydPos(4,:)-hyd2a.hydPos(2,:);
    hyd2a.hydPos(4,:)-hyd2a.hydPos(3,:)];

% load drift:
load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift.mat');
dp{1} = coeffvalues(Dpoly{1}); % drift coefficients between inst 1 and 2
dp{2} = coeffvalues(Dpoly{2}); % drift coefficients between inst 1 and 3
dp{3} = coeffvalues(Dpoly{3}); % drift coefficients between inst 1 and 4
dp{4} = coeffvalues(Dpoly{4}); % drift coefficients between inst 2 and 3
dp{5} = coeffvalues(Dpoly{5}); % drift coefficients between inst 2 and 4
dp{6} = coeffvalues(Dpoly{6}); % drift coefficients between inst 3 and 4

c = 1488.4;

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
hloc(:,3) = hloc(:,3) + [6, 6, 10, 10].';

%%
xv = linspace(-400, 200, 61);
yv = linspace(-1500, 150, 83);
zv = linspace(0, 300, 61);
[MOD{1}.TDOA, MOD{1}.wloc] = makeModel(xv, yv, zv, hloc, H1, H2, c);
[MOD{2}.TDOA, MOD{2}.wloc] = makeModel(xv, yv, zv, hloc, H1, H2, 1470);
[MOD{3}.TDOA, MOD{3}.wloc] = makeModel(xv, yv, zv, hloc, H1, H2, 1480);
[MOD{4}.TDOA, MOD{4}.wloc] = makeModel(xv, yv, zv, hloc, H1, H2, 1500);

%%
% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track600_180611_110414\SOCAL_E_63_track600_180611_110414_ericMod_localized.mat')
% synthetic track:
Ndet = 500;
whale{1}.wloc(:,1) = linspace(-300, 100, Ndet)+ 10.*sin(2*pi*.01.*(1:Ndet));
whale{1}.wloc(:,2) = linspace(-1000, -800, Ndet) + 10.*sin(2*pi*.01.*(1:Ndet));
whale{1}.wloc(:,3) = linspace(10, 100, Ndet)+ 10.*sin(2*pi*.01.*(1:Ndet));
wn = 1;

global LOC
loadParams('localize.params')

sig2sml = LOC.sig_sml^2; % variance of small ap
sig2lrg = LOC.sig_lrg^2; % variance of large ap
Asml = (2*pi*sig2sml)^(-12/2); % coefficient of small ap
Alrg = (2*pi*sig2lrg)^(-6/2); % coefficient of small ap

for i = 1:length(whale{1}.wloc)
%     TDOA = whale{wn}.TDOA(Iuse(i), :);
    [TDOA, ~] = makeModel(whale{wn}.wloc(i, 1), whale{wn}.wloc(i, 2), whale{wn}.wloc(i, 3), hloc, H1, H2, c);
    for mi = 1:numel(MOD)
%         Lsml = Asml*exp(-1./(2.*sig2sml).*sum((MOD{mi}.TDOA(:,1:12)-TDOA(1:12)).^2, 2));
        Llrg = Alrg.*exp(-1./(2.*sig2lrg).*sum((MOD{mi}.TDOA(:,13:18)-TDOA(13:18)).^2, 2));
        [Lmax, Imax] = max(Llrg);

        WLOC{mi}(i, :) = MOD{mi}.wloc(Imax, :);
        LBest{mi}(i) = Lmax;
    end

end

%%
tstr{1} = 'x (m)';
tstr{2} = 'y (m)';
tstr{3} = 'z (m)';
figure(1)
for sp = 1:3
    subplot(3,1,sp)
    for mi = 1:numel(WLOC)
        scatter(1:Ndet, WLOC{mi}(:,sp), LBest{mi}.'/1000000)
        hold on
        
    end
%     datetick
    hold off
    grid on
    ylabel(tstr{sp})
end
% legend('T1-T2', 'T1-E2', 'E1-T2', 'E1-E2')
legend('1488.4', '1470', '1490', '1500')
sgtitle(['Erroneous sound speed'])