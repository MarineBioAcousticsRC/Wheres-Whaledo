function [detTable] = detectClicks_4ch(tstart, tend, XH, paramFile)

global detParam
loadParams(paramFile)

spd = 60*60*24;
detParam.twintwin = 30; % 30 second window;

t1 = tstart;
t2 = t1 + detParam.twin/spd;

% design filter:

if length(detParam.fc)==1
    [b, a] = ellip(4,0.1,40,detParam.fc*2/detParam.fs,'high');
else
    [b, a] = ellip(4,0.1,40,detParam.fc.*2/detParam.fs);
end

detTable = table;

idet = 1; % counter for number of detections

while t2<=tend
    [x, t] = readxwavSegment(t1, t2, XH);
    
    xf = filtfilt(b, a, x);

    [pks, ind] = findpeaks(xf(:,1), 'minPeakHeight', detParam.th, 'minPeakDistance', detParam.minPkDist);
    
    tdet = t1 + ind/detParam.fs/spd; % times of detections

    detTable.('DAmp')(idet:idet+length(pks)-1) = pks;
    detTable.('TDet')(idet:idet+length(pks)-1) = tdet;

    % calculate TDOA for each detection
    for i = 1:length(ind)
        i1 = max([1, ind(i) - detParam.maxdn]);
        i2 = min([length(xf), ind(i) + detParam.maxdn]);

        xclk = xf(i1:i2, :);
        [xc, lags] = xcov(xclk);

        [xamp, ilags] = max(xc(:, detParam.xcRow));

        detTable.('XAmp')(idet, :) = xamp;
        detTable.('TDOA')(idet, :) = lags(ilags)./detParam.fs;
        
        idet = idet+1;
    end
    
    t1 = t2;
    t2 = t1 + detParam.twin;
end

