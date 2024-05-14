ADCP = load('D:\SOCAL_E_63\tracking\experiments\clockSync\ADCP_TDOA_brushed');

AR = load('D:\SOCAL_E_63\tracking\experiments\clockSync\acousticReleaseTDOA_brushed.mat');

%% Instrument locations
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

hyd1 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EE_Hmatrix_fromHydLocInversion_210702.mat');
hyd2 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EW_Hmatrix_fromHydLocInversion_210702.mat');
 %% get expected TDOA from ADCP pings

RR(1) = sqrt(sum((hloc(1,:)-hloc(2,:)).^2));
RR(2) = sqrt(sum((hloc(1,:)-hloc(3,:)).^2));
RR(3) = sqrt(sum((hloc(1,:)-hloc(4,:)).^2));
RR(4) = sqrt(sum((hloc(2,:)-hloc(3,:)).^2));
RR(5) = sqrt(sum((hloc(2,:)-hloc(4,:)).^2));
RR(6) = sqrt(sum((hloc(3,:)-hloc(4,:)).^2));

% with EE as source:
tdoaEEsrc(1) = (0-RR(1))/c;
tdoaEEsrc(2) = (0-RR(2))/c;
tdoaEEsrc(3) = (0-RR(3))/c;
tdoaEEsrc(4) = (RR(1)-RR(2))/c;
tdoaEEsrc(5) = (RR(1)-RR(3))/c;
tdoaEEsrc(6) = (RR(2)-RR(3))/c;

 % with EW as source:
tdoaEWsrc(1) = (RR(1)-0)/c;
tdoaEWsrc(2) = (RR(1)-RR(4))/c;
tdoaEWsrc(3) = (RR(1) - RR(5))/c;
tdoaEWsrc(4) = (0-RR(4))/c;
tdoaEWsrc(5) = (0-RR(5))/c;
tdoaEWsrc(6) = (RR(4)-RR(5))/c;

 % with EN as source:
tdoaENsrc(1) = (RR(2)-RR(4))/c;
tdoaENsrc(2) = (RR(2)-0)/c;
tdoaENsrc(3) = (RR(2) - RR(6))/c;
tdoaENsrc(4) = (RR(4)-0)/c;
tdoaENsrc(5) = (RR(4)-RR(6))/c;
tdoaENsrc(6) = (0-RR(6))/c;

 % with ES as source:
tdoaESsrc(1) = (RR(3)-RR(5))/c;
tdoaESsrc(2) = (RR(3)-RR(6))/c;
tdoaESsrc(3) = (RR(3) - 0)/c;
tdoaESsrc(4) = (RR(5)-RR(6))/c;
tdoaESsrc(5) = (RR(5)-0)/c;
tdoaESsrc(6) = (RR(6)-0)/c;

%%
figure(1)
plot(AR.TDet, AR.TDOA, '.')
hold on
plot([min(AR.TDet), max(AR.TDet)], tdoaESsrc.'*[1,1], ':')
hold off
% datetick

%% define time periods of localization
EEstart = datenum([18 3 16 00 30 00]);
EEend = datenum([18 3 16 2 12 30]);
IEE = find(AR.TDet>=EEstart & AR.TDet<=EEend);

EWstart = datenum([18 3 15 21 30 00]);
EWend = datenum([18 3 16 0 22 00]);
IEW = find(AR.TDet>=EWstart & AR.TDet<=EWend);

ENstart = datenum([18 3 16 03 36 00]);
ENend = datenum([18 3 16 04 48 00]);
IEN = find(AR.TDet>=ENstart & AR.TDet<=ENend);

ESstart = datenum([18 3 16 02 10 00]);
ESend = datenum([18 3 16 03 39 00]);
IES = find(AR.TDet>=ESstart & AR.TDet<=ESend);

figure(1)
subplot(4,1,1)
plot(AR.TDet(IEE), AR.TDOA(IEE, :), '.')
hold on
plot([min(AR.TDet), max(AR.TDet)], tdoaEEsrc.'*[1,1], ':')
hold off


subplot(4,1,2)
plot(AR.TDet(IEW), AR.TDOA(IEW, :), '.')
hold on
plot([min(AR.TDet), max(AR.TDet)], tdoaEWsrc.'*[1,1], ':')
hold off


subplot(4,1,3)
plot(AR.TDet(IEN), AR.TDOA(IEN, :), '.')
hold on
plot([min(AR.TDet), max(AR.TDet)], tdoaENsrc.'*[1,1], ':')
hold off


subplot(4,1,4)
plot(AR.TDet(IES), AR.TDOA(IES, :), '.')
hold on
plot([min(AR.TDet), max(AR.TDet)], tdoaESsrc.'*[1,1], ':')
hold off

%% Error from expected TDOA

er(IEE, :) = AR.TDOA(IEE, :) - tdoaEEsrc;
er(IEW, :) = AR.TDOA(IEW, :) - tdoaEWsrc;
er(IEN, :) = AR.TDOA(IEN, :) - tdoaENsrc;
er(IES, :) = AR.TDOA(IES, :) - tdoaESsrc;

figure(2); 
plot(AR.TDet, AR.TDOA, '.')
hold on
text(min(AR.TDet(IEE)),-.025,'EE as source')
text(min(AR.TDet(IEW)),-.025,'EW as source')
text(min(AR.TDet(IEN)),-.025,'EN as source')
text(min(AR.TDet(IES)),-.025,'ES as source')
hold off
ylabel('Error from expected TDOA (s)')
datetick
legend('EE-EW', 'EE-EN', 'EE-ES', 'EW-EN', 'EW-ES', 'EN-ES')

figure(3); 
plot(AR.TDet, (er), '.')
hold on
text(min(AR.TDet(IEE)),-.025,'EE as source')
text(min(AR.TDet(IEW)),-.025,'EW as source')
text(min(AR.TDet(IEN)),-.025,'EN as source')
text(min(AR.TDet(IES)),-.025,'ES as source')
hold off
ylabel('Error from expected TDOA (s)')
datetick
legend('EE-EW', 'EE-EN', 'EE-ES', 'EW-EN', 'EW-ES', 'EN-ES')