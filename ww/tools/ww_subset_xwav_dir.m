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
%
% If the time of interest starts or ends outside the xwav data, or in a gap
% between raw files, it is trimmed to the recorded data. If there is no
% recorded data in the time of interest at all, XH is returned empty (and
% the other outputs are empty too), so the caller can skip it.

global PARAMS

% empty outputs, returned if there is no data in the time of interest
startSample = [];
endSample = [];
rfTimes = {};
rfSamples = {};
fs = [];

% candidate xwavs from the start times in their names: the last file that
% starts at or before tstart (it may contain tstart) through the last file
% that starts at or before tend
xwavNameStarts = regexp({XH.name}, '\d{6}_\d{6}','match','once'); % find the start times from the xwav names, use this to subset initially
xwavNameStarts = datenum(datetime(xwavNameStarts, 'inputformat','yyMMdd_HHmmss')-years(2000));
first = find(xwavNameStarts <= tstart, 1, 'last');
if isempty(first) % time of interest starts before the first xwav
    first = 1;
end
last = find(xwavNameStarts <= tend, 1, 'last');
if isempty(last) % time of interest ends before the first xwav starts
    XH = XH([]);
    return
end
XH = XH(first:last);

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
fs = hdr.SampleRate; % assumes all xwavs have the same sample rate

% trim the time of interest to the recorded data: if it starts or ends
% outside the xwavs or in a gap between raw files, move it to the nearest
% recorded sample
allRf = vertcat(rfTimes{:});
rfStart = find(allRf(:,2) > tstart, 1, 'first'); % first raw file still recording after tstart
rfEnd = find(allRf(:,1) < tend, 1, 'last'); % last raw file that starts before tend
if isempty(rfStart) || isempty(rfEnd) || rfStart > rfEnd % no recorded data in the time of interest
    XH = XH([]);
    rfTimes = {};
    rfSamples = {};
    fs = [];
    return
end
tstart = max(tstart, allRf(rfStart,1));
tend = min(tend, allRf(rfEnd,2));

% drop candidate files that don't overlap the trimmed time of interest
keepF = endXwavs > tstart & startXwavs < tend;
XH = XH(keepF);
startXwavs = startXwavs(keepF);
endXwavs = endXwavs(keepF);
rfTimes = rfTimes(keepF);
rfSamples = rfSamples(keepF);

% calculate the start/end samples to read for each
startSample = ones(numel(XH),1);
endSample = cellfun(@sum,rfSamples);

% first, for start sample
btwnIdx = find(tstart >= startXwavs & tstart <= endXwavs, 1); % find xwav we start within
rfbtwnIdx = find(tstart >= rfTimes{btwnIdx}(:,1) & tstart <= rfTimes{btwnIdx}(:,2), 1); % find rf we start within
sDiff = (tstart - rfTimes{btwnIdx}(rfbtwnIdx,1)) * PARAMS.conversion.spd * fs;
aggSamples = sum(rfSamples{btwnIdx}(1:rfbtwnIdx-1)); % samples in raw files before this one
startSample(btwnIdx) = max(1, round(aggSamples + sDiff));

% now, for end sample
btwnIdx = find(tend >= startXwavs & tend <= endXwavs, 1); % find xwav we end within
rfbtwnIdx = find(tend >= rfTimes{btwnIdx}(:,1) & tend <= rfTimes{btwnIdx}(:,2), 1); % find rf we end within
sDiff = (tend - rfTimes{btwnIdx}(rfbtwnIdx,1)) * PARAMS.conversion.spd * fs;
aggSamples = sum(rfSamples{btwnIdx}(1:rfbtwnIdx-1));
endSample(btwnIdx) = min(endSample(btwnIdx), round(aggSamples + sDiff));

end
