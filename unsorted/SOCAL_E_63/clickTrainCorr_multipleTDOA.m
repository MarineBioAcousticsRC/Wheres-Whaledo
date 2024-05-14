function clickTrainCorr_multipleTDOA(trackName, foldername, arrno)

saveFileName = [trackName, '_CTC_', 'Array', num2str(arrno)];

% Other settings:
fsct = 10e3;                            % sampling rate of click train
c = 1488.4;                             % speed of sound, m/s
maxLag = round(fsct*(2000/1500 + .4));  % Maximum lags in xcorr
twin = 30;                              % window length for click train
Nhann = (10e-3)*fsct;                   % Length of the Hanning window used in place of clicks
Wk = hann(Nhann);                       % Hanning window used to replace all clicks
maxNumTDOA = 4;                         % maximum possible TDOAs to save per pair per detection

% peaks of click train correlation must be above this value (2*Nhann
% corresponds to ~2 clicks aligning well in the xcorr step):%
minXcorrPeak = 2*Nhann;
%% Locate and load detection file
detDir = dir(fullfile(foldername, ['*det*', trackName, '*.mat']));
load(fullfile(detDir.folder, detDir.name))

encounterStart = min(DET{arrno}.TDet);  % Start of encounter
encounterEnd = max(DET{arrno}.TDet);    % End of encounter

%% Set parameters for CTC

global brushing
loadParams('brushing.params') % load parameters for plotting
spd = 24*60*60; % seconds per day, convert datenum to seconds

% assign indices of other arrays
if arrno==1
    otherArrays = [2,3,4];  % indices of DET containing other arrays besides the primary array
    xcorrCol = [2,3,4];     % Columns of xcorr output used for TDOA calculation

    % which hydrophone pairs are used in each TDOA:
    hpair{1} = '1-2';
    hpair{2} = '1-3';
    hpair{3} = '1-4';
elseif arrno==2
    otherArrays = [1,3,4];  % indices of DET containing other arrays besides the primary array
    xcorrCol = [2,7,8];     % Columns of xcorr output used for TDOA calculation

    % which hydrophone pairs are used in each TDOA:
    hpair{1} = '1-2';
    hpair{2} = '2-3';
    hpair{3} = '2-4';
end

%% remove detections that are too close together
% If multiple detections fall within one Hanning window, then after
% convolving the delta functions with the Hanning window the output will be
% >1. This would bias these detections in the cross-correlation and can
% produce false TDOAs.

% the minimum time difference of arrival allowed to prevent multiple
% detections falling within one Hanning window:
mindt = Nhann/fsct;

% Iterate over each array and remove detections that are too close to
% preceding detections:
for ih = 1:numel(DET)
    Irem = find(diff(DET{ih}.TDet)<mindt/spd);  % indices of detections to remove
    DET{ih}(Irem, :) = [];                      % remove detections
end

%% Iterate over each detection in arrno and perform click-train correlation

for wn = unique(DET{arrno}.color).'
    if wn<=2 % unlabled points = 2, skip these detections
        continue
    end
    Ilab = find(DET{arrno}.color==wn); % detections labeled wn

    % initialize output variables:
    whale{wn-2}.TDet = -99.*ones(size(Ilab));
    whale{wn-2}.TDOA = -99.*ones(length(Ilab), length(xcorrCol), maxNumTDOA); % Time Difference of Arrival
    whale{wn-2}.XCTpk = whale{wn-2}.TDOA;   % peak values of xcorr output
    whale{wn-2}.SNR = whale{wn-2}.TDOA;     % Signal-to-noise ratio
    whale{wn-2}.label = ones(length(Ilab), 1); % whale label

    for ndet = 1:length(Ilab) % iterate through each detection in primary array

        tdet = DET{arrno}.TDet(Ilab(ndet)); % Time of current detection

        tstart = tdet - twin/(spd*2);       % window start time
        tend = tdet + twin/(spd*2);         % window end time

        tct = tstart:1/(spd*fsct):tend;     % time vector of the click trains
        xct = zeros(length(tct), 4);        % click trains, initialized to zeros

        % *****************************************************************
        % Generate click-train time series for primary array (arrno):
        % *****************************************************************

        % indices of detections within window & labeled as wn:
        Iwn = find(DET{arrno}.TDet>=tstart & DET{arrno}.TDet<=tend & DET{arrno}.color==wn);

        for i = 1:length(Iwn) % Iterate over detections and generate click train
            % index of time vector tct that is closest to detection time:
            [~, ind] = min(abs(tct-DET{arrno}.TDet(Iwn(i))));

            % Replace index of detection in click train with 1 :
            xct(ind, arrno) = 1;
        end

        % xct(:, arrno) is now a vector of impulses at detection times.

        % Convolve xct with the Hanning window Wk to produce click train
        % used in xcorr:
        xctHann(:, arrno) = conv(Wk, xct(:, arrno)); % click train w/ Hanning windows

        % iterate over other arrays and generate click train
        for ia = 1:length(otherArrays)

            % Indices of detections within window:
            Iwn = find(DET{otherArrays(ia)}.TDet>=tstart & DET{otherArrays(ia)}.TDet<=tend);

            for i = 1:length(Iwn)
                % index of time vector tct that is closest to detection time:
                [~, ind] = min(abs(tct-DET{otherArrays(ia)}.TDet(Iwn(i))));

                % Replace index of detection in click train with 1:
                xct(ind, otherArrays(ia)) = 1;

            end

            % xct(:, otherArrays(ia)) is now a vector of impulses at detection times.

            % Convolve xct with the Hanning window Wk to produce click train
            % used in xcorr:
            xctHann(:, otherArrays(ia)) = conv(Wk, xct(:, otherArrays(ia)));
        end

        % cross-correlate click trains and calculate TDOAs, peaks of xcorr,
        % and SNR:
        [tdoa, xcpk, snr] = calcTDOA_CTC(xctHann, maxLag, xcorrCol, maxNumTDOA, minXcorrPeak, Nhann, fsct);

        whale{wn-2}.TDet(ndet) = tdet;          % Detection time
        whale{wn-2}.TDOA(ndet, :, :) = tdoa;    % TDOA
        whale{wn-2}.XCTpk(ndet, :, :) = xcpk;   % Peak of Xcorr
        whale{wn-2}.SNR(ndet, :, :) = snr;      % SNR
        whale{wn-2}.label(ndet) = wn;           % whale number (label)

    end

end
save(fullfile(foldername, saveFileName), 'whale') % save data

%% Generate plot of detections

fig = figure(3);
for np = 1:3
    sp(np) = subplot(3, 1, np);
    for wn = 1:numel(whale)
        if ~isempty(whale{wn})
            Iplt = find(whale{wn}.TDOA(:, np, 1)~=-99); % indices of "good" detections (not set to -99)
            leg{wn} = ['Whale ', num2str(wn)]; % make legend entry
            if ~isempty(Iplt)

                for nt = 1:maxNumTDOA
                    Iplt = find(whale{wn}.TDOA(:, np, nt)~=-99);
                    scatter(whale{wn}.TDet(Iplt), whale{wn}.TDOA(Iplt, np, nt), ...
                        80.*whale{wn}.XCTpk(Iplt, np, nt)./max(max(max(whale{wn}.XCTpk))), ...  % Scale each detection by the peak of Xcorr
                        brushing.params.colorMat(wn+2, :).*ones(length(Iplt), 3), 'filled'); % assign colors based on label
                    hold on
                end
            end
        end
    end
    hold off
    title(['Pair ', hpair{np}, ', window length = ', num2str(twin), ' s'])
    ylabel('TDOA')
    xlabel('Time')
    xlim([encounterStart, encounterEnd])
    datetick
end
% fig('Colormap', brushing.params.colorMat)
% colorbar


saveas(fig, fullfile(foldername, saveFileName), 'fig') % save figure

close(fig)
end
%%
function [tdoa, xcpk, snr] = calcTDOA_CTC(xct, maxLag, xcovInd, maxNumTDOA, minXcorrPeak, Nhann, fsct)
% [tdoa, xcpk, snr] = calcTDOA_CTC(xctCorr, xcovInd, maxNumTDOA, fsct)
% calculates the tdoa, peak of xcorr (xcpk), and SNR of a click train
% inputs:
% xct is the click train
% maxLag is the maximum lag of the xcorr
% xcovInd is the index of the cross-correlation needed for this hydrophone pair
% maxNumTDOA is the maximum number of TDOAs to save for this detection
% Nhann is the length of the window used in place of the clicks
% fsct is the sampling rate of the click train

% initialize outputs:
tdoa = -99.*ones(1, length(xcovInd), maxNumTDOA); % initialize with -99 so I can easily remove faulty TDOAs
xcpk = zeros(1, length(xcovInd), maxNumTDOA);
snr = xcpk;

[xctCorr, lags] = xcorr(xct, maxLag);

for ipair = 1:length(xcovInd) % iterate over each HARP pair
    if max(xctCorr(:, xcovInd(ipair)))>minXcorrPeak % only save data if peak of xctCorr is higher than 200

        [pks, locs] = findpeaks(xctCorr(:, xcovInd(ipair)), 'SortStr', 'descend', 'minPeakHeight', minXcorrPeak, 'NPeaks', maxNumTDOA);
        if length(pks)>2
            if pks(2)>.8*pks(1)
                npksBig = find(pks>.8*pks(1)); % find indices of peaks bigger than .8 of max peak
                tdoa(1, ipair, 1:max(npksBig)) = lags(locs(npksBig))/fsct;
                xcpk(1, ipair, 1:max(npksBig)) = pks(npksBig);

                % calculate SNR:
                snr = zeros(size(xcpk));
                for ipk = 1:length(npksBig)
                    noiseInd = 1:length(xctCorr); % indices of 'noise'
                    detInd = locs(npksBig(ipk)); % index of detection
                    sigInd = max([1, detInd-Nhann/2]):min([length(xctCorr), detInd+Nhann/2]); % indices of signal
                    noiseInd(sigInd) = []; % remove indices of signal from noise

                    sigPow = mean(xctCorr(sigInd, xcovInd(ipair)).^2); % power of signal
                    noisePow =  mean(xctCorr(noiseInd, xcovInd(ipair)).^2); % power of "noise" (false peaks)

                    snr(1, ipair, ipk) = sigPow/noisePow;
                end
            else
                tdoa(1, ipair, 1) = lags(locs(1))./fsct;
                xcpk(1, ipair, 1) = pks(1);

                % calculate SNR:
                noiseInd = 1:length(xctCorr); % indices of 'noise'
                detInd = locs(1);
                sigInd = max([1, detInd-Nhann/2]):min([length(xctCorr), detInd+Nhann/2]); % indices of signal
                noiseInd(sigInd) = []; % remove indices of signal from noise

                sigPow = mean(xctCorr(sigInd).^2);
                noisePow =  mean(xctCorr(noiseInd).^2);

                snr(1, ipair, 1) = sigPow/noisePow;
            end
        elseif length(pks)==1
            tdoa(1, ipair, 1) = lags(locs)./fsct;
            xcpk(1, ipair, 1) = pks;

            % calculate SNR:
            noiseInd = 1:length(xctCorr); % indices of 'noise'
            detInd = locs;
            sigInd = max([1, detInd-Nhann/2]):min([length(xctCorr), detInd+Nhann/2]); % indices of signal
            noiseInd(sigInd) = []; % remove indices of signal from noise

            sigPow = mean(xctCorr(sigInd).^2);
            noisePow =  mean(xctCorr(noiseInd).^2);

            snr(1, ipair, 1) = sigPow/noisePow;
        end

    end
end
end
