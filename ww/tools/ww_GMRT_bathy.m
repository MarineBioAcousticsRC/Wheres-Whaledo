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

% bathymetry file for this project
outFile = PARAMS.projectSaveFolder+"\bathymetry\GMRT_bathy.nc";

% if a previous download saved an error message instead of data, delete it
if isfile(outFile) && ~isNetCDF(outFile)
    fprintf('Existing %s is not a NetCDF file (failed download), downloading again.\n',outFile)
    delete(outFile);
end

% download some bathymetry data from GMRT, if we don't already have it
if ~isfile(outFile)
    % bounds
    north = h0(1)+0.5; south = h0(1)-0.5;
    west = h0(2)-0.5; east = h0(2)+0.5;

    % GMRT GridServer URL. format=coards started returning "error writing
    % nc array" (Oct 2026), so request GMT netcdf format instead
    url = sprintf(['https://www.gmrt.org/services/GridServer?' ...
    'north=%.6f&south=%.6f&west=%.6f&east=%.6f&' ...
    'layer=topo&format=netcdf&resolution=high'], ...
        north, south, west, east);

    opts = weboptions('Timeout',120); % set timeout to 2 minutes
    try
        websave(outFile,url,opts); % download
    catch ME
        error('Bathymetry download from GMRT failed:\n%s',ME.message)
    end
    if ~isNetCDF(outFile) % GMRT returns errors as text with HTTP 200
        msg = strtrim(fileread(outFile));
        delete(outFile);
        error('GMRT did not return bathymetry data. Server response:\n%s\nURL: %s',msg,url)
    end
end

% extract data from the file
info = ncinfo(outFile);
if ismember('altitude',{info.Variables.Name}) % COARDS format (older downloads)
    lat = ncread(outFile,'lat');
    lon = ncread(outFile,'lon');
    z = ncread(outFile,'altitude');
else % GMT netcdf format: flattened grid, north row first, gridline registered
    xr = ncread(outFile,'x_range');
    yr = ncread(outFile,'y_range');
    dims = double(ncread(outFile,'dimension'));
    lon = linspace(xr(1),xr(2),dims(1))';
    lat = linspace(yr(1),yr(2),dims(2))';
    z = reshape(double(ncread(outFile,'z')),dims(1),dims(2)); % [lon x lat], lat descending
    z = fliplr(z); % lat ascending, to match the COARDS layout
end

% define levels for contour lines
levels = [floor(min(z,[],'all')/zstep)*zstep:zstep:0];

% convert lat/lons to x/y for better zoomed plotting
[x,~] = ww_convert_latlon2xy_wgs84(h0(1).*ones(size(lon)), lon, h0(1), h0(2));
[~,y] = ww_convert_latlon2xy_wgs84(lat, h0(2).*ones(size(lat)), h0(1), h0(2));


function tf = isNetCDF(fileName)
% true if the file starts with a NetCDF classic ("CDF") or NetCDF-4/HDF5 signature
fid = fopen(fileName,'r');
if fid < 0
    tf = false;
    return
end
sig = fread(fid,4,'*uint8')';
fclose(fid);
tf = numel(sig) == 4 && (isequal(sig(1:3),uint8('CDF')) || isequal(sig,uint8([137 72 68 70])));
