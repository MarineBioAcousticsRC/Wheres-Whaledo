function [x, y] = latlon2xy_wgs84(Lat, Lon, Lat0, Lon0)
% Converts lat and lon values into an x and y grid values based on the
% wgs84Ellipsoid geodesic earth.
% Lat and Lon are the lat and lon values of the grid
% Lat0 and Lon0 are the lat and lon of the 0,0 point of your grid
% (ers 2022-04-04)

[arclen, az] = distance(Lat0, Lon0, Lat, Lon, wgs84Ellipsoid);

x = arclen.*sind(az);
y = arclen.*cosd(az);