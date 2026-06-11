function [az, el, doa, tdoa, xamp] = ww_calculate_TDOA_DOA(xf, ind, fs, H, detParam)

% [az, el, doa, tdoa, xamp] = ww_calculate_TDOA_DOA(xf, ind, fs, H,detParam)
%
% function to calculate TDOA and DOA from detections
%
% inputs:
%   - xf: n x 4 array, filtered timeseries for all channels
%   - ind: scalar, index for this detection
%   - fs: scalar, sample rate
%   - H: struct, instrument orientation information
%   - detParam: struct, user parameters as specified in detector
%       configuration gui
% outputs:
%   - az: scalar, azimuth (degrees, 0° = east)
%   - el: scalar, elevation (degrees, 0° = into the seafloor)
%   - doa: 1 x 3, direction-of-arrival (unit vector)
%   - tdoa: 1 x 6, time-difference-of-arrival for each hydrophone pair

% indices for this detection
i1 = max([1, ind - (detParam.maxTDOA_ms*1E-3*fs)]);
i2 = min([length(xf), ind + (detParam.maxTDOA_ms*1E-3*fs)]);

% subset filtered data accordingly, cross-covariance
xclk = xf(i1:i2, :);
[xc, lags] = xcov(xclk);

% calculate TDOA
tdoa = [0,0,0,0,0,0];
xamp = tdoa;
for pn = 1:length(detParam.xcRow) % iterate through each hydrophone pair

    % find 3 biggest peaks in xcov
    [xcpks, Nloc] = findpeaks(xc(:, detParam.xcRow(pn)), 'MinPeakDistance', 12, 'NPeaks', 3', 'SortStr', 'descend');

    if (0.9*xcpks(1))>xcpks(2) % largest peak is significantly bigger than 2nd largest
        tdoa(pn) = lags(Nloc(1))/fs;
        xamp(pn) = xcpks(1);
    else % largest peak is not much bigger than 2nd largest - reflection likely causing ambiguity
        % sort peaks chronologically
        [NlocSort, IND] = sort(Nloc, 'ascend');
        tdoa(pn) = lags(NlocSort(2))/fs;
        xamp(pn) = xcpks(IND(2));
    end

end

% calculate DOA
doa = H.H\(tdoa.'.*H.c);
doa = doa./sqrt(sum(doa.^2));

% convert to az - el values
el = 180 - acosd(doa(3));
az = atan2d(doa(2), doa(1));

end