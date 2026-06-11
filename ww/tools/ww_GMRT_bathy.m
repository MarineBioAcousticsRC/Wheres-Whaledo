function [lat, lon, z, levels, x, y] = ww_GMRT_bathy(zstep,h0)

% ww_GMRT_bathy()
%
% function to convert GMRT bathy data into plotting format.
% inputs:
%   - zstep (desired interval for contour lines)
%   - h0 (centerpoint, [lat lon depth])
% outputs:
%   - lat (vector of lat values)
%   - lon (vector of lon values)
%   - z (gridded depth matrix)
%   - levels (vector of depths to draw contour lines in m)
%   - x (vector of x values for your grid)
%   - y (vector of y values for your grid)

global PARAMS

% make a folder for bathymetry if there isn't already one
if ~isfolder(PARAMS.projectSaveFolder+"\bathymetry")
    mkdir(PARAMS.projectSaveFolder+"\bathymetry");
end

% look for a bathymetry file
bathyFile = dir(PARAMS.projectSaveFolder+"\bathymetry\GMRT_bathy.nc");

% download some bathymetry data from GMRT, if we don't already have it
if isempty(bathyFile)
    % bounds
    north = h0(1)+0.5; south = h0(1)-0.5;
    west = h0(2)-0.5; east = h0(2)+0.5;

    % output file
    outFile = PARAMS.projectSaveFolder+"\bathymetry\GMRT_bathy.nc";

    % GMRT GridServer URL
    url = sprintf(['https://www.gmrt.org/services/GridServer?' ...
    'north=%.6f&south=%.6f&west=%.6f&east=%.6f&' ...
    'layer=topo&format=coards&resolution=high'], ...
        north, south, west, east);

    opts = weboptions('Timeout',120); % set timeout to 2 minutes
    try
        websave(outFile,url,opts); % download
    catch ME
        fprintf('Bathymetry download from GMRT failed:\n%s\n',ME.message)
        return
    end
    bathyFile = dir(PARAMS.projectSaveFolder+"\bathymetry\GMRT_bathy.nc");

end

% extract data from the file
lat = ncread(fullfile(bathyFile.folder,bathyFile.name),'lat');
lon = ncread(fullfile(bathyFile.folder,bathyFile.name),'lon');
z = ncread(fullfile(bathyFile.folder,bathyFile.name),'altitude');

% define levels for contour lines
levels = [floor(min(z,[],'all')/zstep)*zstep:zstep:0];

% convert lat/lons to x/y for better zoomed plotting
[x,~] = ww_convert_latlon2xy_wgs84(h0(1).*ones(size(lon)), lon, h0(1), h0(2));
[~,y] = ww_convert_latlon2xy_wgs84(lat, h0(2).*ones(size(lat)), h0(1), h0(2));
