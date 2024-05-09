function [detTable] = detectClicks_1ch(tstart, tend, XH, paramFile)

global detParam
loadParams(paramFile)

spd = 60*60*24;
detParam.twin = 30; % 30 second window;

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

% initialize variables
detTable.('DAmp') = zeros(10000, 1);
detTable.('TDet') = zeros(10000, 1);

while t2<=tend
    try
        [x, t] = quickxwavRead(t1, t2, detParam.fs, XH);
    catch
        fprintf('\nerror in quickxwavRead, skipping time frame')
        t1 = t2;
        t2 = t1 + detParam.twin/spd;
        continue
    end
    xf = filtfilt(b, a, x);
    if max(xf)>=detParam.th

        [pks, ind] = findpeaks(xf, 'minPeakHeight', detParam.th, 'minPeakDistance', detParam.minPkDist);

        tdet = t1 + ind/detParam.fs/spd; % times of detections

        if idet+length(pks)-1>length(detTable.('TDet'))

            tempTable = table('Size', [10001, 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'TDet', 'DAmp'});

            detTable = [detTable; tempTable];
        end

        detTable.('DAmp')(idet:idet+length(pks)-1) = pks;
        detTable.('TDet')(idet:idet+length(pks)-1) = tdet;

        idet = idet + length(pks);



    end
    t1 = t2;
    t2 = t1 + detParam.twin/spd;
end

% remove excess rows from initializing table
Irem = find(detTable.('TDet')==0);
detTable(Irem, :) = [];

detTable.('Label') = num2str(zeros(size(detTable.('TDet'))));
detTable.('color') = 2.*ones(size(detTable.('TDet')));