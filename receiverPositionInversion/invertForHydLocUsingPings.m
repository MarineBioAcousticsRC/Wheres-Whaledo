% inst 1:
filepathname{1} = 'D:\SOCAL_E_63\HARP_Deployment_Metadata\SOCAL_E_63_EE_C4\Loc\Deploy\SOCAL_E_63_EE_ttgps.txt';
% filepathname{1} = 'D:\SOCAL_E_63\HARP_Deployment_Metadata\SOCAL_E_63_EE_C4\Loc\Recover\SOCAL_E_63_EE_Rec_ttgps.txt';
ymd{1} = [2018, 03, 16];

% inst 2:
filepathname{2} = 'D:\SOCAL_E_63\HARP_Deployment_Metadata\SOCAL_E_63_EW_C4\Loc\Deploy\SOCAL_E_63_EW_ttgps_combined.txt';
% filepathname{2} = 'D:\SOCAL_E_63\HARP_Deployment_Metadata\SOCAL_E_63_EW_C4\Loc\Recover\SOCAL_E_63_EW_C4_Rec_ttgps.txt';
ymd{2} = [2018, 03, 15];

% inst 3:
filepathname{3} = 'D:\SOCAL_E_63\HARP_Deployment_Metadata\SOCAL_E_63_EN\Loc\Deploy\SOCAL_E_63_EN_ttgps.txt';
% filepathname{3} = 'D:\SOCAL_E_63\HARP_Deployment_Metadata\SOCAL_E_63_EN\Loc\Recover\SOCAL_E_63_EN_Rec_ttgps_combined.txt';
ymd{3} = [2018, 03, 16];

% inst 4:
filepathname{4} = 'D:\SOCAL_E_63\HARP_Deployment_Metadata\SOCAL_E_63_ES\Loc\Deploy\SOCAL_E_63_ES_ttgps.txt';
% filepathname{4} = 'D:\SOCAL_E_63\HARP_Deployment_Metadata\SOCAL_E_63_ES\Loc\Recover\SOCAL_E_63_ES_Rec_ttgps.txt';
ymd{4} = [2018, 03, 16];

load('D:\Writing\wheresWhaledo\figures\tracks\hydLoc.mat') % file with original hydrophone location estimates

% turnAroundTime = 12.5e-3; % time between received and transmitted ping, from edgetech specs
turnAroundTime = 0;
cest = 1490;
%%

for nh = 1:numel(filepathname)
    hlocEst = hLatLonZ(nh, :); % original hydrophone location estimate
    [Lat, Lon, T, ping] = readttgpsAndPings(filepathname{nh}, ymd{nh}); % extract ping data and lat/lon data
    
    if T(end)<T(1) % time period crosses midnight
        Ifix = find(diff(T)<0)
    end

    tt = zeros(size(ping.travelTime));
    xs = tt;
    ys = tt;
    for n = 1:length(ping.startTime)
        tt(n) = (ping.travelTime(n) - turnAroundTime)/2;

        [~, I] = min(abs(T - ping.startTime(n)));

        [xs(n), ys(n)] = latlon2xy_wgs84(Lat(I), Lon(I), hlocEst(1), hlocEst(2));

    end
    
    figure(nh)
    plot(ping.startTime, tt, 'x');
    hold on

    zs = hlocEst(3).*ones(size(xs));


    % Remove erroneous pings

    R = sqrt(xs.^2 + ys.^2 + zs.^2);
        
    travelTimeEst = R./cest.*2 + turnAroundTime;

    Irem = find(abs(travelTimeEst - ping.travelTime)>0.1);

    xs(Irem) = [];
    ys(Irem) = [];
    zs(Irem) = [];
    tt(Irem) = [];
    ping.travelTime(Irem) = [];
    ping.startTime(Irem) = [];
    travelTimeEst(Irem) = [];
    
    plot(ping.startTime, tt, '.');
    legend('original travel times', 'auto-cleaned')
    title('travel times')
    datetick
    ylabel('time (s)')
    hold off

    fun = @(h)sum((sqrt((h(1)-xs).^2 + (h(2)-ys).^2 + (h(3)-zs).^2)./h(4) - tt).^2);

    lb = [-100, -100, -50, 1450];
    ub = [100, 100, 50, 1550];

    hest = fmincon(fun, [0,0,0, 1500], [], [], [], [], lb, ub)

    % using these values, get new travel time estimate and calculate std:
    residuals = sqrt((hest(1)-xs).^2 + (hest(2)-ys).^2 + (hest(3)-zs).^2)./hest(4) - tt;

    sse = sum(residuals.^2);

    mse = sse./length(tt); % mean squared error (variance)
    stdDev(nh) = sqrt(mse);
    hshift(nh, :) = hest(1:3);
    cnew(nh) = hest(4);
    numPings(nh) = length(tt);

    [hLatLonZ_new(nh, 1), hLatLonZ_new(nh, 2)] = xy2latlon_wgs84(hest(1), hest(2), hlocEst(1), hlocEst(2));
    hLatLonZ_new(nh, 3) = hlocEst(3) + hshift(nh, 3);
end
