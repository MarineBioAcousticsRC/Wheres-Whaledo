
c = 1488.4; % speed of sound
spd = 60*60*24;

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

far = 12e3; % frequency of ping from acoustic release on instrument
fs4 = 100e3;
fs1 = 200e3;

c = 1488.4;

[b4, a4] = ellip(4,0.1,40,[far-1000, far+1000]*2/fs4,'bandpass');
[b1, a1] = ellip(4,0.1,40,[far-1000, far+1000]*2/fs1,'bandpass');


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

R(1) = sqrt(sum( ((hloc(1, :)-hloc(2, :)).^2) ));
R(2) = sqrt(sum( ((hloc(1, :)-hloc(3, :)).^2) ));
R(3) = sqrt(sum( ((hloc(1, :)-hloc(4, :)).^2) ));
R(4) = sqrt(sum( ((hloc(2, :)-hloc(3, :)).^2) ));
R(5) = sqrt(sum( ((hloc(2, :)-hloc(4, :)).^2) ));
R(6) = sqrt(sum( ((hloc(3, :)-hloc(4, :)).^2) ));

tt = R./c;

%% Start/end times of localization events on each instrument
EEstart = datenum([18, 03, 16, 00, 40, 07]);
EEend = datenum([18, 03, 16, 02, 07, 15]);

EWstart = datenum([18, 03, 15, 21, 36, 30]);
EWend = datenum([18, 03, 16, 00, 13, 50]);

ENstart = datenum([18, 03, 16, 03, 41, 54]);
ENend = datenum([18, 03, 16, 04, 35, 59]);

ESstart = datenum([18, 03, 16, 02, 17, 05]);
ESend = datenum([18, 03, 16, 03, 34, 10]);



% for EE as emitter
% process:
% 1) use emitting instrument as primary detector, so I can set threshold
% really high and eliminate false detections.
% 2) take detection times from step 1, and using expected travel times find
% corresponding detections on other instruments
% 3) figure out how much they need to shift to be synchronized
% 4) do the same with other instruments as emitters, see if the time offset
% is the same. Can use this to determine speed of sound AND clock drift
tic
detCount = 0;
detCountPrev = 1;

TDOA = [];
TDOAee = [];
TDOAew = [];
TDet = [];
%% EE

thee = 2.9e4; % threshold for detector
th = 1e3;

tstart = EEstart;
tend = tstart + 30/spd;

while tend <= EEend
    
    [xee30, tee30] = readxwavSegment(tstart, tend, XH{1});
    
    % get detections on primary array
    ndetTemp = find(xee30(:,1)>thee);
    
    if ~isempty(ndetTemp)
        idet = find(diff(ndetTemp)>1000);
        ndetee = ndetTemp([1; idet+1]);
        tdetee = tee30(ndetee);
        
        tdoa = nan(length(tdetee), 6);
        tdoaEE = tdoa;
        tdoaEW = tdoa;
        for n = 1:length(tdetee)
            detCount = detCount+1;
            
            t1 = tdetee(n) - .1/spd;
            t2 = tdetee(n) + 1/spd;
            
            [xee, tee] = readxwavSegment(t1, t2, XH{1});
            xfee = filtfilt(b4, a4, xee);
            [xc, lags] = xcov(xfee);
            [~, nx] = max(xc(:, [2,3,4,7,8,12]));
            tdoaEE(n, :) = lags(nx)./fs4;
                        
            [xew, tew] = readxwavSegment(t1, t2, XH{2});
            xfew = filtfilt(b4, a4, xew);
            [xc, lags] = xcov(xfee);
            [~, nx] = max(xc(:, [2,3,4,7,8,12]));
            tdoaEW(n, :) = lags(nx)./fs4;

            [xen, ten] = readxwavSegment(t1, t2, XH{3});
            xfen = filtfilt(b1, a1, xen);
            
            [xes, tes] = readxwavSegment(t1, t2, XH{4});
            xfes = filtfilt(b1, a1, xes);
            
            
            % TDOA calc: 
            [xc, lags] = xcov(xfee(:,1), xfew(:,1));
            [~, nx] = max(xc);
            
            tdoa(n, 1) = lags(nx)/fs4;
            
            % decimate by factor of 2:
            xden = xfen(2:2:end);
            xdes = xfes(2:2:end);
            
            % cross covariate:
            [xc, lags] = xcov(xfee(:,1), xden);
            [~, nx] = max(xc);
            tdoa(n, 2) = lags(nx)/fs4;
          
            [xc, lags] = xcov(xfee(:,1), xdes);
            [~, nx] = max(xc);
            tdoa(n, 3) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfew(:,1), xden);
            [~, nx] = max(xc);
            tdoa(n, 4) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfew(:,1), xdes);
            [~, nx] = max(xc);
            tdoa(n, 5) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfen, xfes);
            [~, nx] = max(xc);
            tdoa(n, 6) = lags(nx)/fs1;
            
        end
        TDOA = [TDOA; tdoa];
        TDOAee = [TDOAee; tdoaEE];
        TDOAew = [TDOAew; tdoaEW];
        TDet = [TDet, tdetee];
    end
    tstart = tend;
    tend = tstart + 30/spd;
    
end
toc
tExpEE = 0;
tExpEW = tt(1);
tExpEN = tt(2);
tExpES = tt(3);

tdoaExp(1:detCount, 1) = tExpEE - tExpEW;
tdoaExp(1:detCount, 2) = tExpEE - tExpEN;
tdoaExp(1:detCount, 3) = tExpEE - tExpES;
tdoaExp(1:detCount, 4) = tExpEW - tExpEN;
tdoaExp(1:detCount, 5) = tExpEW - tExpES;
tdoaExp(1:detCount, 6) = tExpEN - tExpES;

detCountPrev = detCount + 1;

%% Now EW loc period

tstart = EWstart;
tend = tstart + 30/spd;

thew = 2.9e4;
th = 1e3;


while tend <= EEend
    
    [xew30, tew30] = readxwavSegment(tstart, tend, XH{2});
    
    % get detections on primary array
    ndetTemp = find(xew30(:,1)>thew);
    
    if ~isempty(ndetTemp)
        idet = find(diff(ndetTemp)>1000);
        ndetew = ndetTemp([1; idet+1]);
        tdetew = tew30(ndetew);
        
        tdoa = nan(length(tdetew), 6);
        tdoaEE = tdoa;
        tdoaEW = tdoa;

        for n = 1:length(tdetew)
            detCount = detCount+1;
            
            t1 = tdetew(n) - .1/spd;
            t2 = tdetew(n) + 1/spd;
            
            [xee, tee] = readxwavSegment(t1, t2, XH{1});
            xfee = filtfilt(b4, a4, xee);
            [xc, lags] = xcov(xfee);
            [~, nx] = max(xc(:, [2,3,4,7,8,12]));
            tdoaEE(n, :) = lags(nx)./fs4;

            [xew, tew] = readxwavSegment(t1, t2, XH{2});
            xfew = filtfilt(b4, a4, xew);
            [xc, lags] = xcov(xfew);
            [~, nx] = max(xc(:, [2,3,4,7,8,12]));
            tdoaEW(n, :) = lags(nx)./fs4;

            [xen, ten] = readxwavSegment(t1, t2, XH{3});
            xfen = filtfilt(b1, a1, xen);
            
            [xes, tes] = readxwavSegment(t1, t2, XH{4});
            xfes = filtfilt(b1, a1, xes);
            
            
            % TDOA calc: 
            [xc, lags] = xcov(xfee(:,1), xfew(:,1));
            [~, nx] = max(xc);
            
            tdoa(n, 1) = lags(nx)/fs4;
            
            xden = xfen(2:2:end);
            xdes = xfes(2:2:end);
            
            [xc, lags] = xcov(xfee(:,1), xden);
            [~, nx] = max(xc);
            tdoa(n, 2) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfee(:,1), xdes);
            [~, nx] = max(xc);
            tdoa(n, 3) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfew(:,1), xden);
            [~, nx] = max(xc);
            tdoa(n, 4) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfew(:,1), xdes);
            [~, nx] = max(xc);
            tdoa(n, 5) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfen, xfes);
            [~, nx] = max(xc);
            tdoa(n, 6) = lags(nx)/fs1;
            
        end
        TDOA = [TDOA; tdoa];
        TDOAee = [TDOAee; tdoaEE];
        TDOAew = [TDOAew; tdoaEW];
        TDet = [TDet, tdetew];
    end
    tstart = tend;
    tend = tstart + 30/spd;
    
end
toc
tExpEE = tt(1);
tExpEW = 0;
tExpEN = tt(4);
tExpES = tt(5);

tdoaExp(detCountPrev:detCount, 1) = tExpEE - tExpEW;
tdoaExp(detCountPrev:detCount, 2) = tExpEE - tExpEN;
tdoaExp(detCountPrev:detCount, 3) = tExpEE - tExpES;
tdoaExp(detCountPrev:detCount, 4) = tExpEW - tExpEN;
tdoaExp(detCountPrev:detCount, 5) = tExpEW - tExpES;
tdoaExp(detCountPrev:detCount, 6) = tExpEN - tExpES;

detCountPrev = detCount + 1;

%% Now EN loc period

tstart = ENstart;
tend = tstart + 30/spd;

then = 2.9e4;
th = 1e3;

while tend <= ENend
    
    [xen30, ten30] = readxwavSegment(tstart, tend, XH{3});
    
    % get detections on primary array
    ndetTemp = find(xen30(:,1)>then);
    
    if ~isempty(ndetTemp)
        idet = find(diff(ndetTemp)>1000);
        ndeten = ndetTemp([1; idet+1]);
        tdeten = ten30(ndeten);
        
        tdoa = nan(length(tdeten), 6);
        tdoaEE = tdoa;
        tdoaEW = tdoa;

        for n = 1:length(tdeten)
            detCount = detCount+1;
            
            t1 = tdeten(n) - .1/spd;
            t2 = tdeten(n) + 1/spd;
            
            [xee, tee] = readxwavSegment(t1, t2, XH{1});
            xfee = filtfilt(b4, a4, xee);
            [xc, lags] = xcov(xfee);
            [~, nx] = max(xc(:, [2,3,4,7,8,12]));
            tdoaEE(n, :) = lags(nx)./fs4;

            [xew, tew] = readxwavSegment(t1, t2, XH{2});
            xfew = filtfilt(b4, a4, xew);
            [xc, lags] = xcov(xfew);
            [~, nx] = max(xc(:, [2,3,4,7,8,12]));
            tdoaEW(n, :) = lags(nx)./fs4;

            [xen, ten] = readxwavSegment(t1, t2, XH{3});
            xfen = filtfilt(b1, a1, xen);
            
            [xes, tes] = readxwavSegment(t1, t2, XH{4});
            xfes = filtfilt(b1, a1, xes);
            
            
            % TDOA calc: 
            [xc, lags] = xcov(xfee(:,1), xfew(:,1));
            [~, nx] = max(xc);
            
            tdoa(n, 1) = lags(nx)/fs4;
            
            xden = xfen(2:2:end);
            xdes = xfes(2:2:end);
            
            [xc, lags] = xcov(xfee(:,1), xden);
            [~, nx] = max(xc);
            tdoa(n, 2) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfee(:,1), xdes);
            [~, nx] = max(xc);
            tdoa(n, 3) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfew(:,1), xden);
            [~, nx] = max(xc);
            tdoa(n, 4) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfew(:,1), xdes);
            [~, nx] = max(xc);
            tdoa(n, 5) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfen, xfes);
            [~, nx] = max(xc);
            tdoa(n, 6) = lags(nx)/fs1;
            
        end
        TDOA = [TDOA; tdoa];
        TDOAee = [TDOAee; tdoaEE];
        TDOAew = [TDOAew; tdoaEW];
        TDet = [TDet, tdeten];
    end
    tstart = tend;
    tend = tstart + 30/spd;
    
end
toc
tExpEE = tt(2);
tExpEW = tt(4);
tExpEN = 0;
tExpES = tt(6);

tdoaExp(detCountPrev:detCount, 1) = tExpEE - tExpEW;
tdoaExp(detCountPrev:detCount, 2) = tExpEE - tExpEN;
tdoaExp(detCountPrev:detCount, 3) = tExpEE - tExpES;
tdoaExp(detCountPrev:detCount, 4) = tExpEW - tExpEN;
tdoaExp(detCountPrev:detCount, 5) = tExpEW - tExpES;
tdoaExp(detCountPrev:detCount, 6) = tExpEN - tExpES;

detCountPrev = detCount + 1;

%% Now ES loc period

tstart = ESstart;
tend = tstart + 30/spd;

thes = 2.0e4;
th = 1e3;

while tend <= ESend
    
    [xes30, tes30] = readxwavSegment(tstart, tend, XH{4});
    
    % get detections on primary array
    ndetTemp = find(xes30(:,1)>thes);
    
    if ~isempty(ndetTemp)
        idet = find(diff(ndetTemp)>1000);
        ndetes = ndetTemp([1; idet+1]);
        tdetes = tes30(ndetes);
        
        tdoa = nan(length(tdetes), 6);
        tdoaEE = tdoa;
        tdoaEW = tdoa;

        for n = 1:length(tdetes)
            detCount = detCount+1;
            
            t1 = tdetes(n) - .1/spd;
            t2 = tdetes(n) + 1/spd;
            
            [xee, tee] = readxwavSegment(t1, t2, XH{1});
            xfee = filtfilt(b4, a4, xee);
            [xc, lags] = xcov(xfee);
            [~, nx] = max(xc(:, [2,3,4,7,8,12]));
            tdoaEE(n, :) = lags(nx)./fs4;

            [xew, tew] = readxwavSegment(t1, t2, XH{2});
            xfew = filtfilt(b4, a4, xew);
            [xc, lags] = xcov(xfew);
            [~, nx] = max(xc(:, [2,3,4,7,8,12]));
            tdoaEW(n, :) = lags(nx)./fs4;

            [xen, ten] = readxwavSegment(t1, t2, XH{3});
            xfen = filtfilt(b1, a1, xen);
            
            [xes, tes] = readxwavSegment(t1, t2, XH{4});
            xfes = filtfilt(b1, a1, xes);
            
            
            % TDOA calc: 
            [xc, lags] = xcov(xfee(:,1), xfew(:,1));
            [~, nx] = max(xc);
            
            tdoa(n, 1) = lags(nx)/fs4;
            
            xden = xfen(2:2:end);
            xdes = xfes(2:2:end);
            
            [xc, lags] = xcov(xfee(:,1), xden);
            [~, nx] = max(xc);
            tdoa(n, 2) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfee(:,1), xdes);
            [~, nx] = max(xc);
            tdoa(n, 3) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfew(:,1), xden);
            [~, nx] = max(xc);
            tdoa(n, 4) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfew(:,1), xdes);
            [~, nx] = max(xc);
            tdoa(n, 5) = lags(nx)/fs4;
            
            [xc, lags] = xcov(xfen, xfes);
            [~, nx] = max(xc);
            tdoa(n, 6) = lags(nx)/fs1;
            
        end
        TDOA = [TDOA; tdoa];
        TDOAee = [TDOAee; tdoaEE];
        TDOAew = [TDOAew; tdoaEW];
        TDet = [TDet, tdetes];
    end
    tstart = tend;
    tend = tstart + 30/spd;
    
end
toc

tExpEE = tt(3);
tExpEW = tt(5);
tExpEN = tt(6);
tExpES = 0;

tdoaExp(detCountPrev:detCount, 1) = tExpEE - tExpEW;
tdoaExp(detCountPrev:detCount, 2) = tExpEE - tExpEN;
tdoaExp(detCountPrev:detCount, 3) = tExpEE - tExpES;
tdoaExp(detCountPrev:detCount, 4) = tExpEW - tExpEN;
tdoaExp(detCountPrev:detCount, 5) = tExpEW - tExpES;
tdoaExp(detCountPrev:detCount, 6) = tExpEN - tExpES;

detCountPrev = detCount + 1;

%%
load('acousticReleaseTDOA_xcov')

figure(1)
for np = 1:6
    subplot(6,1,np)
    plot(TDet, TDOA(:, np), '.')
    hold on
    plot(TDet, tdoaExp(:, np), '.')
    
    plot([EEstart, EEend], [0,0], 'x-', 'markersize', 26)
    plot([EWstart, EWend], [0,0], 'x-', 'markersize', 26)
    plot([ENstart, ENend], [0,0], 'x-', 'markersize', 26)
    plot([ESstart, ESend], [0,0], 'x-', 'markersize', 26)
    
    hold off
    legend('measured', 'expected', 'EE loc period', 'EW loc period', 'EN loc period', 'ES loc period', 'location', 'east outside')
    datetick
    grid on
end

figure(2)
for np = 1:6
    subplot(6,1,np)
    plot(TDet, TDOA(:, np) - tdoaExp(:, np), '.')
    title('measured-expected')
    datetick
    grid on
end

%%

save('acousticReleaseTDOA_xcov', 'TDOA', 'tdoaExp', 'TDet', 'TDOAee', 'TDOAew')
