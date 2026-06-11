function [x, y] = ww_convert_latlon2xy_wgs84(Lat, Lon, Lat0, Lon0)

% ww_convert_latlon2xy_wgs84()
%
% function to convert lat and lon values into xy grid values, based on
% wgs84Ellipsoid geodesic earth.
% inputs:
%   - lat (vector of lat values)
%   - lon (vector of lon values)
%   - Lat0 (reference latitude)
%   - Lon0 (reference longitude)
% outputs:
%   - x (vector of x values for your grid)
%   - y (vactor of y values for your gird)

[arclen, az] = distance(Lat0, Lon0, Lat, Lon, wgs84Ellipsoid);

x = arclen.*sind(az);
y = arclen.*cosd(az);

end