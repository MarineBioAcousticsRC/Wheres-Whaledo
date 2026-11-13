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
rfCumSum = [0 cumsum(rfSamples(:)')];
t = NaT(1,samples(2)-samples(1)+1);
for r = 1:numel(rfSamples)
    aa = max(samples(1),rfCumSum(r)+1);
    bb = min(samples(2),rfCumSum(r+1));
    if aa <= bb
        t(aa-samples(1)+1:bb-samples(1)+1) = datetime(rfTimes(r,1),'convertfrom','datenum') + seconds(((aa:bb)-rfCumSum(r)-1)/fs);
    end
end


end