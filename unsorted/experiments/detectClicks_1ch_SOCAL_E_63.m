function [detTable] = detectClicks_1ch(tstart, tend, XH, paramFile)
% the typical detector, but with the ADCP pings removed

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

    [pks, ind] = findpeaks(xf, 'minPeakHeight', detParam.th, 'minPeakDistance', detParam.minPkDist);
    
    tdet = t1 + ind/detParam.fs/spd; % times of detections

    detTable.('DAmp')(idet:idet+length(pks)-1) = pks;
    detTable.('TDet')(idet:idet+length(pks)-1) = tdet;
    
    idet = idet + length(pks);
    t1 = t2;
    t2 = t1 + detParam.twin/spd;
end

detTable.('Label') = zeros(size(detTable.('TDet')));
detTable.('color') = 2.*ones(size(detTable.('TDet')));