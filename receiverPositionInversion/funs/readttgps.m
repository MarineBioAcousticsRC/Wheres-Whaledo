function [Lat, Lon, T] = readttgps(filepathname, ymd)
% Reads in the GPS locations of the ship for typical ttgps files 
% 
fid = fopen(filepathname)

tline = fgetl(fid);
n = 0;
while  ischar(tline)
    commaLoc = find(tline==',');
    if length(tline)>6
        namestr = tline(1:6);
        switch namestr
            case '$GPGGA'
                n=n+1;
                timeloc = commaLoc(1)+1;
                latloc = commaLoc(2)+1;
                nsloc = commaLoc(3) + 1;
                lonloc = commaLoc(4)+1;
                ewloc = commaLoc(5) + 1;
                
                T(n) = datenum([ymd, str2num(tline(timeloc:timeloc+1)), ...
                    str2num(tline(timeloc+2:timeloc+3)), str2num(tline(timeloc+4:timeloc+5))]);
                
                if tline(nsloc)=='N'
                    latsign = 1;
                elseif tline(nsloc)=='S'
                    latsign = -1;
                else
                    fprintf(['error: line', num2str(n), '\n', tline, '\nN/S hemisphere read incorrectly'])
                end
                
                
                if tline(ewloc)=='E'
                    lonsign = 1;
                elseif tline(ewloc)=='W'
                    lonsign = -1;
                else
                    fprintf(['error: line', num2str(n), '\n', tline, '\nE/W hemisphere read incorrectly'])
                end
                
                Lat(n) = latsign.*(str2num(tline(latloc:latloc+1)) + str2num(tline(latloc+2:nsloc-2))/60);
                Lon(n) = lonsign.*(str2num(tline(lonloc:lonloc+2)) + str2num(tline(lonloc+3:ewloc-2))/60);
                
                
            case '$PHGGA'
                n=n+1;
                timeloc = commaLoc(1)+1;
                latloc = commaLoc(2)+1;
                nsloc = commaLoc(3) + 1;
                lonloc = commaLoc(4)+1;
                ewloc = commaLoc(5) + 1;
                
                T(n) = datenum([ymd, str2num(tline(timeloc:timeloc+1)), ...
                    str2num(tline(timeloc+2:timeloc+3)), str2num(tline(timeloc+4:timeloc+5))]);
                
                if tline(nsloc)=='N'
                    latsign = 1;
                elseif tline(nsloc)=='S'
                    latsign = -1;
                else
                    fprintf(['error: line', num2str(n), '\n', tline, '\nN/S hemisphere read incorrectly'])
                end
                
                
                if tline(ewloc)=='E'
                    lonsign = 1;
                elseif tline(ewloc)=='W'
                    lonsign = -1;
                else
                    fprintf(['error: line', num2str(n), '\n', tline, '\nE/W hemisphere read incorrectly'])
                end
                
                Lat(n) = latsign.*(str2num(tline(latloc:latloc+1)) + str2num(tline(latloc+2:nsloc-2))/60);
                Lon(n) = lonsign.*(str2num(tline(lonloc:lonloc+2)) + str2num(tline(lonloc+3:ewloc-2))/60);
                
        end
    end
    tline = fgetl(fid);
end

fclose(fid)

%% Remove redundant readings

[Tu, ia, ~] = unique(T); % get indices of unique readings

Lat = Lat(ia);
Lon = Lon(ia);
T = T(ia);
