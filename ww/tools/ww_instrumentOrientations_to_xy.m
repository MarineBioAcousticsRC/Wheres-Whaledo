function [h0 h1 h2 H c] = ww_instrumentOrientations_to_xy()

% ww_instrumentOrientations_to_xy()
%
% function to take instrument orientation information and convert this to
% xy positions rather than lat/lon, relative to some origin point
% outputs:
%   - h0: 1 x 3 vector, reference position for each 4channel; this
%           reference position is the mean between each 4ch
%   - h1 and h2: 1 x 3 vector, xy position for each 4ch

global PARAMS

% load in instrument orientation information
ioFiles = dir(PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+"\*harp4chParams.mat");
if numel(ioFiles) > 2 % if we have extra files
    msg = "More than two instrument orientation files found in: " + ...
        PARAMS.projectSaveFolder + ...
        PARAMS.project.InstrumentOrientationRelPath + ...
        ". Remove superfluous files and try again.";
    fprintf('%s\n', msg)
    return
else
    hydLoc{1} = load(fullfile(ioFiles(1).folder,ioFiles(1).name));
    hydLoc{2} = load(fullfile(ioFiles(2).folder,ioFiles(2).name));
end

% calculate h0
h0 = mean([hydLoc{1}.recLoc; hydLoc{2}.recLoc]);

% convert hydrophone locations to meters
[h1(1), h1(2)] = ww_convert_latlon2xy_wgs84(hydLoc{1}.recLoc(1), hydLoc{1}.recLoc(2), h0(1), h0(2));
h1(3) = abs(h0(3))-abs(hydLoc{1}.recLoc(3));

[h2(1), h2(2)] = ww_convert_latlon2xy_wgs84(hydLoc{2}.recLoc(1), hydLoc{2}.recLoc(2), h0(1), h0(2));
h2(3) = abs(h0(3))-abs(hydLoc{2}.recLoc(3));

% save rleative hydrophone positions
H{1} = hydLoc{1}.H;
H{2} = hydLoc{2}.H;

% save sound speeds
c{1} = hydLoc{1}.c;
c{2} = hydLoc{2}.c;