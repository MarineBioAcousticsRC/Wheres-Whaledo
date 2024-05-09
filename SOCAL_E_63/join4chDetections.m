dfolder = dir('D:\SOCAL_E_63\tracking\interns2022\processAsIs\*track*');

% associate whales on different arrays

% ideas: CTC then auto-associate that way

fpath = 'D:\SOCAL_E_63\tracking\interns2022\processAsIs\track147_180416_160254_mod_AMS4_corrAngle';
fname1 = 'track147_180416_160254_mod_AMS4_corrAngle_3Dloc_Array1.mat';
fname2 = 'track147_180416_160254_mod_AMS4_corrAngle_3Dloc_Array2.mat';

load('D:\SOCAL_E_63\tracking\interns2022\processAsIs\track30_180324_205700_mod_AMS2_corrAngle\SOCAL_E_63_detections_track30_180324_205700_mod_AMS2_corrAngle.mat')

T1 = load(fullfile(fpath, fname1));
T2 = load(fullfile(fpath, fname2));

load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m

h = [0,0,0; h];
h(3:4, 3) = h(3:4, 3) + 10;


hyd1 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EE_Hmatrix_new.mat');
hyd2 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EW_Hmatrix_new.mat');

% HEW = H;

% Reorder hydrophones to fit new TDOA order
HEE = [hyd1.recPos(2,:)-hyd1.recPos(1,:);
    hyd1.recPos(3,:)-hyd1.recPos(1,:);
    hyd1.recPos(4,:)-hyd1.recPos(1,:);
    hyd1.recPos(3,:)-hyd1.recPos(2,:);
    hyd1.recPos(4,:)-hyd1.recPos(2,:);
    hyd1.recPos(4,:)-hyd1.recPos(3,:)];

HEW = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];

c = 1488.4;
spd = 24*60*60;
fsct = 10e3;
Nhann = (10e-3)*fsct;                   % Length of the Hanning window used in place of clicks
Wk = hann(Nhann);                       % Hanning window used to replace all clicks
maxLag = round(fsct*(2000/1500 + .4));  % Maximum lags in xcorr

%%
% correlate the click trains for individual whales. Whichever lines up the
% best assume is the same whale.
numWhale1 = numel(T1.whale);
numWhale2 = numel(T2.whale);

for wn1 = 1:numWhale1
    % break the track up into 60 sec windows
    score = zeros(1, numWhale2);
    tstart = T1.whale{wn1}.TDet(1);
    tend = tstart + 60/spd;

    while tstart<T1.whale{wn1}.TDet(end)
        tct = tstart:1/(spd*fsct):tend;

        X = zeros(length(tct), numWhale2+1);

        I1 = find(T1.whale{wn1}.TDet>=tstart & T1.whale{wn1}.TDet<=tend); % indices on array 1 of detections in this window
        for ndet = 1:length(I1)
            [~, ind] = min((tct-T1.whale{wn1}.TDet(I1(ndet))).^2);
            X(ind, 1) = 1;

        end
        Xwk(:, 1) = conv(X(:, 1), Wk); % click train convolved w/ hanning window

        for wn2 = 1:numWhale2
            I2 = find(T2.whale{wn2}.TDet>=tstart & T2.whale{wn2}.TDet<=tend); % indices on array 2 of detections in this window
            for ndet = 1:length(I2)

                [~, ind] = min((tct-T2.whale{wn2}.TDet(I2(ndet))).^2);
                X(ind, wn2+1) = 1;

            end
            Xwk(:, wn2+1) = conv(X(:, wn2+1), Wk);

        end

        %         nsp = size(Xwk, 2);
        %         for sp = 1:nsp
        %             subplot(nsp, 1, sp)
        %             plot(Xwk(:, sp))
        %         end

        [XCT, lags] = xcorr(Xwk, maxLag);

        pks = max(XCT(:, 2:numWhale2+1));

        score = score + pks;

        tstart = tend;
        tend = tstart + 60/spd;
    end

    [bestScore1(wn1), bestMatch1(wn1)] = max(score);

end

% repeat associations using other aray
for wn2 = 1:numWhale2
    % break the track up into 60 sec windows
    score = zeros(1, numWhale1);
    tstart = T2.whale{wn2}.TDet(1);
    tend = tstart + 60/spd;

    while tstart<T2.whale{wn2}.TDet(end)
        tct = tstart:1/(spd*fsct):tend;

        X = zeros(length(tct), numWhale1+1);

        I2 = find(T2.whale{wn1}.TDet>=tstart & T2.whale{wn1}.TDet<=tend); % indices on array 1 of detections in this window
        for ndet = 1:length(I2)
            [~, ind] = min((tct-T2.whale{wn1}.TDet(I2(ndet))).^2);
            X(ind, 1) = 1;

        end
        Xwk(:, 1) = conv(X(:, 1), Wk); % click train convolved w/ hanning window

        for wn1 = 1:numWhale1
            I1 = find(T1.whale{wn1}.TDet>=tstart & T1.whale{wn1}.TDet<=tend); % indices on array 2 of detections in this window
            for ndet = 1:length(I1)

                [~, ind] = min((tct-T1.whale{wn1}.TDet(I1(ndet))).^2);
                X(ind, wn1+1) = 1;

            end
            Xwk(:, wn1+1) = conv(X(:, wn1+1), Wk);

        end

        %         nsp = size(Xwk, 2);
        %         for sp = 1:nsp
        %             subplot(nsp, 1, sp)
        %             plot(Xwk(:, sp))
        %         end

        [XCT, lags] = xcorr(Xwk, maxLag);

        pks = max(XCT(:, 2:numWhale1+1));

        score = score + pks;

        tstart = tend;
        tend = tstart + 60/spd;
    end

    [bestScore2(wn2), bestMatch2(wn2)] = max(score);

end

% PROBLEM!!!!!
% If one whale isn't present in array 2, this association won't work.
% This only works if all whale are present on both arrays. I need to
% think this through more.
%
% Maybe if I repeat the correlation using the other array, and only
% take the ones that match on both arrays? Or have a minimum score that
% is considered a "true" association?
%
% Test to see if association worked:
% if length(bestMatch)==length(unique(bestMatch))
%     for wn=1:numWhale1
%         whale{wn}.TDOA = [T1.whale{wn}.TDOA; T2.whale{bestMatch(wn)}.TDOA];
%         whale{wn}.TDOA = [T1.whale{wn}.TDOA; T2.whale{bestMatch(wn)}.TDOA];
%         whale{wn}.TDOA = [T1.whale{wn}.TDOA; T2.whale{bestMatch(wn)}.TDOA];
%         whale{wn}.TDOA = [T1.whale{wn}.TDOA; T2.whale{bestMatch(wn)}.TDOA];
%     end
% end