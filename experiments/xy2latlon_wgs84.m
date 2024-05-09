function [lat, lon] = xy2latlon_wgs84(x, y, lat0, lon0)
% [lat, lon] = xy2latlon_wgs84(x, y, lat0, lon0)
% Converts x and y values into lat and lon values based on the
% wgs84Ellipsoid geodesic earth.
% x and y are in meters
% Lat0 and Lon0 are the lat and lon of the 0,0 point of your grid
% (ers 2022-04-04)

az = atan2d(x, y);
arclen = sqrt(x.^2 + y.^2);
[lat, lon] = reckon(lat0, lon0, arclen, az);