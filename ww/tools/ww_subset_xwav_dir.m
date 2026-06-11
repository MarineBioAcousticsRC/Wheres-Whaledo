function [XH, startSample, endSample, rfTimes, rfSamples, fs] = ww_subset_xwav_dir(XH, tstart, tend)

% ww_subset_xwav_dir()
% 
% function to subset a directory of xwav files based on your specified
% start and end time
%
% [XH, startSample, endSample, fs] = ww_subset_xwav_dir(xwavPath, tstart, tend)
%   inputs: XH (directory of xwav files), tstart (datenum, start time of
%       interest), tend (datenum, end time of interest)
%   outputs: XH (subsetted directory of xwav files), startSample (which
%       sample within xwav file to start), endSample (which sample within xwav
%       file to end), fs (sample rate from xwavs)

global PARAMS

% find which xwav files are within the times of interest
xwavNameStarts = regexp({XH.name}, '\d{6}_\d{6}','match','once'); % find the start times from the xwav names, use this to subset initially
xwavNameStarts = datenum(datetime(xwavNameStarts, 'inputformat','yyMMdd_HHmmss')-years(2000));
idx = find(xwavNameStarts>=tstart & xwavNameStarts<=tend);
idx = [idx(1)-1:1:idx(end)]; % shift back a bin to get the file before
XH = XH(idx,:);

% read the xwav headers
startXwavs = nan(numel(XH),1);
endXwavs = nan(numel(XH),1);
rfTimes = cell(numel(XH),1);
rfSamples = cell(numel(XH),1);

for f = 1:numel(XH) % read headers, save relevant timing info
    hdr = ww_read_xwav_header(fullfile(XH(f).folder,XH(f).name));
    startXwavs(f) = hdr.raw.dnumStart(1);
    endXwavs(f) = hdr.raw.dnumEnd(end);
    rfTimes{f} = [hdr.raw.dnumStart', hdr.raw.dnumEnd'];
    rfSamples{f} = hdr.raw.rawSamples;
end

% calculate the start/end samples to read for each
startSample = ones(numel(XH),1);
endSample = cellfun(@sum,rfSamples);

% first, for start sample
btwnIdx = find(isbetween(tstart,startXwavs,endXwavs)); % find xwav we start within
rfbtwnIdx = find(isbetween(tstart,rfTimes{btwnIdx}(:,1),rfTimes{btwnIdx}(:,2))); % find rf we start within
tDiff = (tstart - rfTimes{btwnIdx}(rfbtwnIdx,1)) * PARAMS.conversion.spd;
sDiff = tDiff * hdr.SampleRate;

if rfbtwnIdx == 1 % if we're within the first raw file
    startSample(btwnIdx) = sDiff;
else % if we're in a subsequent raw file
    rfBefore = rfbtwnIdx - 1;
    aggSamples = sum(rfSamples{btwnIdx}([1:1:rfBefore]));
    startSample(btwnIdx) = aggSamples + sDiff;
end

% now, for end sample
btwnIdx = find(isbetween(tend,startXwavs,endXwavs)); % find xwav we start within
rfbtwnIdx = find(isbetween(tend,rfTimes{btwnIdx}(:,1),rfTimes{btwnIdx}(:,2))); % find rf we start within
tDiff = (tend - rfTimes{btwnIdx}(rfbtwnIdx,1)) * PARAMS.conversion.spd;
sDiff = tDiff * hdr.SampleRate;

if rfbtwnIdx == 1 % if we're within the first raw file
    endSample(btwnIdx) = sDiff;
else % if we're in a subsequent raw file
    rfBefore = rfbtwnIdx - 1;
    aggSamples = sum(rfSamples{btwnIdx}([1:1:rfBefore]));
    endSample(btwnIdx) = aggSamples + sDiff;
end

fs = hdr.SampleRate; % assumes all xwavs have the same sample rate

end