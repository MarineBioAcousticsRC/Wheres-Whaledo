function [x, t, fs] = ww_read_xwav(filePath, samples, rfTimes, rfSamples) % read in xwav data

% ww_read_xwav()
% 
% function to read xwav information. takes into account raw file start and
% end times; safe to use with non-continuous xwav data.
% 
%   inputs:
%       - filePath (path to xwav file)
%       - samples (1 x 2 vector with sample to start read and sample
%           to end read)
%       - rfTimes (n x 2 vector of datenums containing start/end times 
%           of each raw file in your xwav)
%   outputs:
%       - x (data)
%       - t (datetime for each sample)
%       - fs (sample rate

% read in xwav data
[x,fs] = audioread(filePath,samples,'native');
x = double(x); % convert to double from integer

% calculate timestamps from rf times
rfCumSum = [0 cumsum(rfSamples)];
startRf = discretize(samples(1),rfCumSum); % which rf do we start
endRf = discretize(samples(2),rfCumSum); % which rf do we end
if startRf == endRf % if it's the same rf
    t0 = datetime(rfTimes(startRf,1),'convertfrom','datenum');
    t = t0 + seconds((samples(1)-rfCumSum(startRf):samples(2)-rfCumSum(startRf)) / fs); t = t';
elseif (endRf - startRf) == 1 % if we span two files
    t0 = datetime(rfTimes(startRf,1),'convertfrom','datenum');
    ta = t0 + seconds((samples(1)-rfCumSum(startRf):rfSamples(startRf)) / fs); ta = ta';
    t0 = datetime(rfTimes(endRf,1),'convertfrom','datenum');
    tb = t0 + seconds((1:samples(2)-rfCumSum(endRf)) / fs); tb = tb';
    t = [ta; tb];
else % if we span more files, there's probably something wrong
    keyboard
end


end