function [x, t] = quickxwavRead(tstart, tend, fs, xwavTable)
% [x, t] = quickxwavRead(tstart, tend, fs, xwavTable)
% Assumes time intervals do not vary. Don't use if the raw file time stamps
% have not been verified as consistent time intervals.

spd = 60*60*24;

nx1 = find(tstart>=xwavTable.('startTime'), 1, 'last'); % first xwav
nx2 = find(tend>=xwavTable.('startTime'), 1, 'last'); % last xwav

dnx = nx2-nx1 + 1;

if dnx==1 % data contained in one xwav
    ind(1) = round((tstart-xwavTable.('startTime')(nx1))*spd*fs)+1;
    ind(2) = round((tend-xwavTable.('startTime')(nx1))*spd*fs);
    [x, ~] = audioread(fullfile(xwavTable.('inpath'){nx1}, xwavTable.('infile'){nx1}), ind, 'native');

    t = tstart + (1:length(x))/fs/spd;

elseif dnx==2 % data span 2 xwavs

    % first xwav
    info = audioinfo(fullfile(xwavTable.('inpath'){nx1}, xwavTable.('infile'){nx1}));
    ind(1) = round((tstart-xwavTable.('startTime')(nx1))*spd*fs);
    ind(2) = info.TotalSamples;

    [x1, ~] = audioread(fullfile(xwavTable.('inpath'){nx1}, xwavTable.('infile'){nx1}), ind, 'native');

    t1 = tstart + (1:length(x1))/fs/spd;

    % second xwav
    ind(1) = 1;
    ind(2) = round((tend-xwavTable.('startTime')(nx2))*spd*fs);

    [x2, ~] = audioread(fullfile(xwavTable.('inpath'){nx2}, xwavTable.('infile'){nx2}), ind, 'native');

    t2 = tstart + (1:length(x2))/fs/spd;

    x = [x1; x2];
    t = [t1, t2];

else % data span 3 or more xwavs. Probably a bad thing unless it's been significantly decimated
    x = [];
    t = [];

    % first xwav
    info = audioinfo(fullfile(xwavTable.('inpath'){nx1}, xwavTable.('infile'){nx1}));
    ind(1) = round((tstart-xwavTable.('startTime')(nx1))*spd*fs)+1;
    ind(2) = info.TotalSamples;

    [x, ~] = audioread(fullfile(xwavTable.('inpath'){nx1}, xwavTable.('infile'){nx1}), ind, 'native');
    t = tstart + (1:length(x))/fs/spd;

    for nx = nx1+1:nx2-1
        [xpart, ~] = audioread(fullfile(xwavTable.('inpath'){nx}, xwavTable.('infile'){nx}), 'native');
        tpart = tstart + (1:length(xpart))/fs/spd;

        x = [x; xpart];
        t = [t, tpart];
    end

    % last xwav
    ind(1) = 1;
    ind(2) = round((tend-xwavTable.('startTime')(nx2))*spd*fs);

    [xpart, ~] = audioread(fullfile(xwavTable.('inpath'){nx1}, xwavTable.('infile'){nx1}), ind, 'native');
    tpart = tstart + (1:length(xpart))/fs/spd;

    x = [x; xpart];
    t = [t, tpart];

end

x = double(x);