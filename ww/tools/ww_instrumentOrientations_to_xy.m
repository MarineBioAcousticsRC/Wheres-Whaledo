function [h0 h1 h2 H c] = ww_instrumentOrientations_to_xy()

% ww_instrumentOrientations_to_xy()
%
% function to take instrument orientation information and convert this to
% xy positions rather than lat/lon, relative to some origin point
% outputs:
%   - h0: 1 x 3 vector, reference position for each 4channel; this
%           reference position is the mean between each 4ch, or the
%           position of the 4ch itself if there is only one
%   - h1 and h2: 1 x 3 vector, xy position for each 4ch; h2 is NaN if
%           there is only one 4ch
%   - H and c: cells with one entry per 4ch

global PARAMS

% load in instrument orientation information
ioFiles = dir(PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+"\*harp4chParams.mat");
nArr = numel(ioFiles); % number of 4ch arrays
if nArr > 2 % if we have extra files
    msg = "More than two instrument orientation files found in: " + ...
        PARAMS.projectSaveFolder + ...
        PARAMS.project.InstrumentOrientationRelPath + ...
        ". Remove superfluous files and try again.";
    fprintf('%s\n', msg)
    return
else
    for k = 1:nArr
        hydLoc{k} = load(fullfile(ioFiles(k).folder,ioFiles(k).name));
    end
end

% calculate h0
if nArr == 1 % only one 4ch, use its position as the reference
    h0 = hydLoc{1}.recLoc;
else
    h0 = mean([hydLoc{1}.recLoc; hydLoc{2}.recLoc]);
end

% convert hydrophone locations to meters
[h1(1), h1(2)] = ww_convert_latlon2xy_wgs84(hydLoc{1}.recLoc(1), hydLoc{1}.recLoc(2), h0(1), h0(2));
h1(3) = abs(h0(3))-abs(hydLoc{1}.recLoc(3));

if nArr == 1 % no second 4ch
    h2 = nan(1,3);
else
    [h2(1), h2(2)] = ww_convert_latlon2xy_wgs84(hydLoc{2}.recLoc(1), hydLoc{2}.recLoc(2), h0(1), h0(2));
    h2(3) = abs(h0(3))-abs(hydLoc{2}.recLoc(3));
end

% save rleative hydrophone positions and sound speeds
for k = 1:nArr
    H{k} = hydLoc{k}.H;
    c{k} = hydLoc{k}.c;
end