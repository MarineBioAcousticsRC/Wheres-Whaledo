function [detTable, f] = detectClicks_4ch(tstart, tend, XH, H, c, tf, paramFile)

global detParam
loadParams(paramFile)

spd = 60*60*24;
detParam.twin = 30; % 30 second window

t1 = tstart;
t2 = t1 + detParam.twin/spd;

if isfield(XH, 'deploymentName')
    wbtext = ['Running detector on ', XH.deploymentName];
else
    wbtext = 'Running detector';
end
wb = waitbar(0, wbtext);

% design filter:
if length(detParam.fc)==1
    [b, a] = ellip(4,0.1,40,detParam.fc*2/detParam.fs,'high');
else
    [b, a] = ellip(4,0.1,40,detParam.fc.*2/detParam.fs);
end

% calculate FFT parameters + transfer function offset, functions from Triton
detParam.fftSize = ceil(detParam.fs * detParam.frameLengthUs / 1E6);
detParam.fftWindow = hann(detParam.fftSize)';
buff = detParam.buffer*detParam.fs; % calculate the number of samples to buffer on either side of the peak
N = length(detParam.fftWindow);
lowSpecIdx = round(detParam.bpRanges(1)/detParam.fs*detParam.fftSize);
highSpecIdx = round(min(detParam.bpRanges(2),detParam.fs/2)/detParam.fs*detParam.fftSize);
detParam.specRange = lowSpecIdx:highSpecIdx;
detParam.tfFullFile = tf; % file path to transfer function
detParam = sp_fn_interp_tf(detParam);
f = 0:((detParam.fs/2)/1000)/((N/2)):((detParam.fs/2)/1000);
f = f(detParam.specRange);
sub = 10*log10(detParam.fs/N);

detTable = table;

idet = 1; % counter for number of detections
ierr = 0; % error counter
while t2<=tend
    try
       % [x, t] = readxwavSegment(t1, t2, XH);
       [x,t] = quickxwavRead(t1, t2, detParam.fs, XH);
    catch
        ierr = ierr+1;
        fprintf('\nerror in readxwavSegment, skipping segment (error counter=%d)\n', ierr)
        t1 = t2;
        t2 = t1 + detParam.twin/spd;
        continue
    end
    xf = filtfilt(b, a, x);
    if max(xf)>=detParam.th
        [pks, ind] = findpeaks(xf(:,1), 'minPeakHeight', detParam.th, 'minPeakDistance', detParam.minPkDist);
        tdet = t1 + ind/detParam.fs/spd; % times of detections

        specClickTf = nan(length(pks),length(detParam.specRange));
        peakFr = nan(length(pks));
        ppSignal = nan(length(pks));

        % calculate click paramters for these detections
        % code modified from Triton, SPICE Detector remora
        for i = 1:length(ind) % for each detection

            cStart = ind(i)-buff; % start sample to grab
            cEnd = ind(i)+buff; % end sample to grab
            if cEnd > size(xf,1) % catch in case the peak is right at the end of the data window
                cEnd = size(xf,1);
            end

            % click spectrum
            % pull out filtered click timeseries
            clickBuff = xf(cStart:cEnd,1)'; % grab data
            winLength = length(clickBuff); % calculate window length
            wind = hann(winLength); % calcualte window
            wClick = zeros(1,N); % preallocate
            wClick = clickBuff.*wind.'; % window click
            spClick = 20*log10(abs(fft(wClick,N))); % calculate spectra
            spClickSub = spClick-sub; % account for bin width
            spClickSub = spClickSub(:,1:N/2); % reduce data to first half of spectra
            specClickTf(i,:) = spClickSub(detParam.specRange)+detParam.xfrOffset; % add tf offset

            % calculate peak frequency
            [valMx, posMx] = max(specClickTf(i,:));
            peakFr(i) = f(posMx); %peak frequency in kHz

            % calculate ppRL
            % find lowest and highest number in timeseries (counts) and add those
            high = max(clickBuff);
            low = min(clickBuff);
            ppCount = high+abs(low);
            % calculate dB value of counts and add transfer function value at peak
            % frequency to get ppSignal (dB re 1uPa)
            P = 20*log10(ppCount);
            peakLow = floor(peakFr(i));
            fLow=find(f>=peakLow);
            % add PtfN transfer function at peak frequency to P
            tfPeak = detParam.xfrOffset(fLow(1));
            ppSignal(i) = P+tfPeak;

            % calculate TDOA for each detection
            i1 = max([1, ind(i) - detParam.maxdn]);
            i2 = min([length(xf), ind(i) + detParam.maxdn]);

            xclk = xf(i1:i2, :);
            [xc, lags] = xcov(xclk);

            tdoa = [0,0,0,0,0,0];
            xamp = tdoa;
            for pn = 1:length(detParam.xcRow) % iterate through each hydrophone pair

                % find 3 biggest peaks in xcov
                [xcpks, Nloc] = findpeaks(xc(:, detParam.xcRow(pn)), 'MinPeakDistance', 12, 'NPeaks', 3', 'SortStr', 'descend');

                if (0.9*xcpks(1))>xcpks(2) % largest peak is significantly bigger than 2nd largest
                    tdoa(pn) = lags(Nloc(1))/detParam.fs;
                    xamp(pn) = xcpks(1);
                else % largest peak is not much bigger than 2nd largest - reflection likely causing ambiguity
                    % sort peaks chronologically
                    [NlocSort, IND] = sort(Nloc, 'ascend');
                    tdoa(pn) = lags(NlocSort(2))/detParam.fs;
                    xamp(pn) = xcpks(IND(2));
                end

            end
            doa = H\(tdoa.'.*c);
            doa = doa./sqrt(sum(doa.^2));

            el = 180 - acosd(doa(3));
            az = atan2d(doa(2), doa(1));

            tempTable = table(tdet(i), pks(i), [az, el], doa.', tdoa, xamp, specClickTf(i,:), peakFr(i), ppSignal(i), ...
                'VariableNames', {'TDet', 'DAmp', 'Ang', 'DOA', 'TDOA', 'XAmp', 'Spectra', 'PeakFr', 'ppRL'});

            %         detTable.('XAmp')(idet, :) = xamp;
            %         detTable.('TDOA')(idet, :) = tdoa;
            %         detTable.('DOA')(idet, :) = doa.';
            %         detTable.('Ang')(idet, :) = [az, el];
            %         detTable.('DAmp')(idet) = pks(i);
            %         detTable.('TDet')(idet) = tdet(i);

            detTable = [detTable; tempTable];

            idet = idet+1;
        end
    end

    calcPerc = (t2-tstart)/(tend-tstart);
    waitbar(calcPerc, wb, wbtext);

    t1 = t2;
    t2 = t1 + detParam.twin/spd;
end

close(wb)

detTable.('Label') = num2str(zeros(size(detTable.('TDet'))));
detTable.('color') = 2.*ones(size(detTable.('TDet')));
detTable.('Species') = num2str(nan(size(detTable.('TDet'))));
