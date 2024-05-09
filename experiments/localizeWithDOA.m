% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track600_180611_110414\track600_180611_110414_localized_cleaned.mat')
load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track666_180601_153000\track666_180601_153000_localized_cleaned.mat')
W4ch = load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks_both4chOnly\track666_180601_153000_localized_cleaned.mat');
% W4ch = load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks_both4chOnly\track600_180611_110414_localized_cleaned.mat');

wn = 1;


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

options = optimoptions('fsolve', 'Display', 'none');

tic
global LOC
loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\localize.params')
wloc = nan(size(whale{wn}.wloc));
IuseCase = zeros(length(wloc), 1);

% Find cases with both 4chs:
Iuse = find(~isnan(whale{wn}.Ang1(:,1)) & ~isnan(whale{wn}.Ang2(:,1)));
IuseCase(Iuse) = 1;
for i = 1:length(Iuse)
    ind = Iuse(i);

    % loc with DOA1: 
    ang = whale{wn}.Ang1(ind, :);
    doa(1) = sind(180-ang(2))*cosd(ang(1));
    doa(2) = sind(180-ang(2))*sind(ang(1));
    doa(3) = cosd(180-ang(2));
    doa = doa./sqrt(sum((doa.^2)));

    drift = zeros(1,3);
    Itdoa = [14, 15, 18];
    for ntdoa = 1:3
        drift(ntdoa) = polyval(dp{Itdoa(ntdoa) - 12}, whale{wn}.TDet(ind));
    end

    tdoa = whale{wn}.TDOA(ind, [14, 15, 18]) + LOC.driftSign.*drift;

    fun = @(r1)searchOneDOA(r1, doa, tdoa, LOC.c, hloc([1,3,4], :));
    [r1, ~, exitflag, output]  = fsolve(fun, 0, options);

    wloc1 = r1.*doa + hloc(1, :);

    % loc with DOA2:
    % loc with DOA2:
    ang = whale{wn}.Ang2(ind, :);
    doa(1) = sind(180-ang(2))*cosd(ang(1));
    doa(2) = sind(180-ang(2))*sind(ang(1));
    doa(3) = cosd(180-ang(2));
    doa = doa./sqrt(sum((doa.^2)));

    drift = zeros(1,3);
    for ntdoa = 1:3
        drift(ntdoa) = polyval(dp{ntdoa+3}, whale{wn}.TDet(i));
    end

    tdoa = whale{wn}.TDOA(ind, 16:end) + LOC.driftSign.*drift;

    fun = @(r2)searchOneDOA(r2, doa, tdoa, LOC.c, hloc([2,3,4], :));
    [r2, ~, exitflag, output]  = fsolve(fun, 1000, options);

    wloc2 = r2.*doa + hloc(2, :);

    wloc(ind, :) = mean([wloc1; wloc2]);
end


% Find cases with all DOA1 only:
Iuse = find(~isnan(whale{wn}.Ang1(:,1)) & isnan(whale{wn}.Ang2(:,1)));
IuseCase(Iuse) = 2;
for i = 1:length(Iuse)
    ind = Iuse(i);

    ang = whale{wn}.Ang1(ind, :);
    doa(1) = sind(180-ang(2))*cosd(ang(1));
    doa(2) = sind(180-ang(2))*sind(ang(1));
    doa(3) = cosd(180-ang(2));
    doa = doa./sqrt(sum((doa.^2)));

    drift = zeros(1,3);
    Itdoa = [14, 15, 18];
    for ntdoa = 1:3
        drift(ntdoa) = polyval(dp{Itdoa(ntdoa) - 12}, whale{wn}.TDet(i));
    end

    tdoa = whale{wn}.TDOA(ind, [14, 15, 18]) + LOC.driftSign.*drift;

    fun = @(r1)searchOneDOA(r1, doa, tdoa, LOC.c, hloc([1,3,4], :));
    [r1, ~, exitflag, output]  = fsolve(fun, 1000, options);

    wloc(ind, :) = r1.*doa + hloc(1, :);

end



% Find cases with DOA2 only:
Iuse = find(isnan(whale{wn}.Ang1(:,1)) & ~isnan(whale{wn}.Ang2(:,1)));
IuseCase(Iuse) = 3;
for i = 1:length(Iuse)
    ind = Iuse(i);

    ang = whale{wn}.Ang2(ind, :);
    doa(1) = sind(180-ang(2))*cosd(ang(1));
    doa(2) = sind(180-ang(2))*sind(ang(1));
    doa(3) = cosd(180-ang(2));
    doa = doa./sqrt(sum((doa.^2)));

    drift = zeros(1,3);
    for ntdoa = 1:3
        drift(ntdoa) = polyval(dp{ntdoa+3}, whale{wn}.TDet(i));
    end

    tdoa = whale{wn}.TDOA(ind, 16:end) + LOC.driftSign.*drift;

    fun = @(r2)searchOneDOA(r2, doa, tdoa, LOC.c, hloc([2,3,4], :));
    [r2, ~, exitflag, output]  = fsolve(fun, 1000, options);

    wloc(ind, :) = r2.*doa + hloc(2, :);

end





toc

%%
figure(1)
posText{1} = 'x [m]';
posText{2} = 'y [m]';
posText{3} = 'z [m]';

for sp = 1:3
    subplot(3,2,2*sp-1)
   plot(whale{wn}.TDet, whale{wn}.wloc(:,sp), 'x')
   hold on
   for ic = 1:3
       Iuse = find(IuseCase==ic);
       plot(whale{wn}.TDet(Iuse), wloc(Iuse, sp), '.', 'markersize', 20-2*ic)
   end
   plot(W4ch.whale{wn}.TDet, W4ch.whale{wn}.wloc(:,sp), '^')
   hold off
   datetick
   grid on
   
   ylabel(posText{sp})
end
legend('ML', 'fsolve - both 4ch', 'fsolve - DOA1', 'fsolve - DOA2', 'DOAintersect')

angText{1} = 'Azimuth [deg]';
angText{2} = 'Elevation [deg]';
for sp = 1:2
    subplot(2,2,2*sp)
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
%%

function L = searchOneDOA(r1, doa, tdoa, c, hloc)
    w = r1*doa + hloc(1, :);
    
    r2 = sqrt(sum((w - hloc(2, :)).^2));
    r3 = sqrt(sum((w - hloc(3, :)).^2));
    
    err(1) = (tdoa(1) - (r1-r2)./c)^2;
    err(2) = (tdoa(2) - (r1-r3)./c)^2;
    err(3) = (tdoa(3) - (r2-r3)./c)^2;
    
    L = sum(err, 'omitnan');
end

function L = searchTwoDOA(R, doa, tdoa, c, hloc)
    w = r1*doa + hloc(1, :);
    
    r2 = sqrt(sum((w - hloc(2, :)).^2));
    r3 = sqrt(sum((w - hloc(3, :)).^2));
    
    err(1) = (tdoa(1) - (r1-r2)./c)^2;
    err(2) = (tdoa(2) - (r1-r3)./c)^2;
    err(3) = (tdoa(3) - (r2-r3)./c)^2;
    err(4)

    L = sum(err, 'omitnan');
end
