function [Lat, Lon, T, ping] = readttgpsAndPings(filepathname, ymd, varargin)
% Reads in the GPS locations of the ship for typical ttgps files 
%
fid = fopen(filepathname);

tline = fgetl(fid);
n = 0;
ntt = 0;
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
            
            case 'RNG: T'
                Itime = strfind(tline, 'time = ');
                timeStr = tline(Itime+7:end-5);
                if ~isnan(str2double(timeStr)) & n>0
                    ntt = ntt+1; 
                    ping.travelTime(ntt) = str2double(timeStr);
                    ping.startTime(ntt) = T(n);
                end
        end
    end
    tline = fgetl(fid);
end

fclose(fid)

%% determine if data spans multiple days
[~, Imidnight] = min(T - floor(T)); % point where it crosses midnight 
if ~isempty(Imidnight)
    for im = 1:length(Imidnight)
        T(Imidnight(im):end) = T(Imidnight(im):end) + 1; % add one day to all points after midnight line
    end
end

[~, Imidnight] = min(ping.startTime - floor(ping.startTime)); % point where it crosses midnight 
if ~isempty(Imidnight)
    for im = 1:length(Imidnight)
        ping.startTime(Imidnight(im):end) = ping.startTime(Imidnight(im):end) + 1; % add one day to all points after midnight line
    end
end

%% Remove redundant readings

[Tu, ia, ~] = unique(T); % get indices of unique readings

Lat = Lat(ia);
Lon = Lon(ia);
T = T(ia);


