load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track322_180513_011652\SOCAL_E_63_track322_180513_011652_ericMod_CTC.mat')
load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track322_180513_011652\SOCAL_E_63_track322_180513_011652_ericMod_localized.mat')

%%
% clock sync with DOA intersect
c = 1488.4;

wn = 2;

% load drift:
load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift.mat');
dp{1} = coeffvalues(Dpoly{1}); % drift coefficients between inst 1 and 2
dp{2} = coeffvalues(Dpoly{2}); % drift coefficients between inst 1 and 3
dp{3} = coeffvalues(Dpoly{3}); % drift coefficients between inst 1 and 4
dp{4} = coeffvalues(Dpoly{4}); % drift coefficients between inst 2 and 3
dp{5} = coeffvalues(Dpoly{5}); % drift coefficients between inst 2 and 4
dp{6} = coeffvalues(Dpoly{6}); % drift coefficients between inst 3 and 4

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

%%
% whaleOut = localize(whale, hloc, H1, H2, dp)

Iboth = find(sum(isnan(whale{wn}.TDOA(:, 1:12)), 2)==0); % detections on both 4ch arrays
TDOAexp = nan(size(whale{wn}.TDOA(:,13:18)));
wloc = nan(length(whale{wn}.TDet), 3);
werr = nan(length(whale{wn}.TDet), 1);
Ang1 = nan(length(whale{wn}.TDet), 2);
Ang2 = Ang1;

for ndet = 1:length(Iboth)

    tdoa1 = whale{wn}.TDOA(Iboth(ndet), 1:6);
    tdoa2 = whale{wn}.TDOA(Iboth(ndet), 7:12);

    doa1 = (tdoa1.'\H1);
    doa1 = doa1./sqrt(sum(doa1.^2));
    ang1(1) = atan2d(doa1(2), doa1(1));
    ang1(2) = 180-acosd(doa1(3));

    doa2 = (tdoa2.'\H2);
    doa2 = doa2./sqrt(sum(doa2.^2));
    ang2(1) = atan2d(doa2(2), doa2(1));
    ang2(2) = 180-acosd(doa2(3));

    D = [doa1; -doa2];
    R = D.'\(hloc(2,:) - hloc(1,:)).';
    
    w1 = R(1).*doa1 + hloc(1,:);
    w2 = R(2).*doa2 + hloc(2,:);

    w = mean([w1; w2]);

    R = sqrt(sum((w - hloc).^2, 2));
    
    wloc(Iboth(ndet), :) = w;
    werr(Iboth(ndet)) = sqrt(sum((w1-w2).^2));

    TDOAexp(Iboth(ndet), 1) = (R(1)-R(2))/c;
    TDOAexp(Iboth(ndet), 2) = (R(1)-R(3))/c;
    TDOAexp(Iboth(ndet), 3) = (R(1)-R(4))/c;
    TDOAexp(Iboth(ndet), 4) = (R(2)-R(3))/c;
    TDOAexp(Iboth(ndet), 5) = (R(2)-R(4))/c;
    TDOAexp(Iboth(ndet), 6) = (R(3)-R(4))/c;

    Ang1(Iboth(ndet), :) = ang1;
    Ang2(Iboth(ndet), :) = ang2;
    
end

%%

figure(10)
for sp = 1:6
    subplot(6,1,sp)
%     plot(CTC{wn}.TDet, CTC{wn}.TDOA(:, 12+sp), '.')
%     hold on
drft = polyval(dp{sp}, mean(CTC{wn}.TDet));
    plot(whale{wn}.TDet, whaleOut{wn}.TDOA(:, 12+sp)-drft, '.')
    hold on
    plot(whale{wn}.TDet, TDOAexp(:, sp), 'x')
    
    hold off
end
%%
figure(2)
for sp = 1:6
    subplot(6,1,sp)
%     plot(CTC{wn}.TDet, CTC{wn}.TDOA(:, 12+sp), '.')
%     hold on
    plot(whale{wn}.TDet, whale{wn}.TDOA(:, 12+sp)-TDOAexp(:, sp), '.')
    hold on
    drft = polyval(dp{sp}, mean(whale{wn}.TDet));
    plot(whale{wn}.TDet([1, end]), [drft, drft])
    
    hold off
end


figure(3)
for sp = 1:6
    subplot(6,1,sp)
%     plot(CTC{wn}.TDet, CTC{wn}.TDOA(:, 12+sp), '.')
%     hold on
    plot(CTC{wn}.TDet, CTC{wn}.TDOA(:, 12+sp)-TDOAexp(:, sp), '.')
    hold on
    drft = polyval(dp{sp}, mean(CTC{wn}.TDet));
    plot(CTC{wn}.TDet([1, end]), [drft, drft])
    
    hold off
end

figure(4)
subplot(1,2,1)
plot3(wloc(:,1), wloc(:,2), wloc(:,3), '.-')
hold on
plot3(whale{wn}.wloc(:,1), whale{wn}.wloc(:,2), whale{wn}.wloc(:,3), 'x')
hold off
for sp = 1:3
    subplot(3,2,2*sp)
    plot(whale{wn}.TDet, wloc(:,sp), '.')
    hold on
    plot(whale{wn}.TDet, whale{wn}.wloc(:,sp), 'x')
    hold off
end

figure(5)
subplot(4,1,1)
plot(whale{wn}.TDet, Ang1(:,1), '.')

subplot(4,1,2)
plot(whale{wn}.TDet, Ang1(:,2), '.')

subplot(4,1,3)
plot(whale{wn}.TDet, Ang2(:,1), '.')

subplot(4,1,4)
plot(whale{wn}.TDet, Ang2(:,2), '.')


%%

figure(21)
plot3(whaleOut{wn}.wloc(:,1), whaleOut{wn}.wloc(:,2), whaleOut{wn}.wloc(:,3), '.')
hold on
plot3(whale{wn}.wloc(:,1), whale{wn}.wloc(:,2), whale{wn}.wloc(:,3), '.')
plot3(wloc(:,1), wloc(:,2), wloc(:,3), '.')
hold off

figure(22)
for sp = 1:3
    subplot(3,1,sp)
plot(whaleOut{wn}.TDet, whaleOut{wn}.wloc(:,sp), '.')
hold on
plot(whale{wn}.TDet, whale{wn}.wloc(:,sp), '.')
plot(whale{wn}.TDet, wloc(:,sp), '.')
hold off
end

%%

