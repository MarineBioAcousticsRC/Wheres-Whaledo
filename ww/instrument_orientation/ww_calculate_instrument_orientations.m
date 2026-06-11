function ww_calculate_instrument_orientations()

% ww_calculate_instrument_orientations()
%
% function to calculate instrument orientations from GPS files, either
% TTGPS or AIS format

global PARAMS HANDLES;

% first step is to read the GPS info, save shipLatLon info
if HANDLES.ui.calc.rbTTGPS.Value % if we're using TTGPS files
    [lat, lon, Tship] = ww_read_TTGPS(HANDLES.ui.calc.shipPath.Value, HANDLES.ui.calc.locDate.Value);
elseif HANDLES.ui.calc.rbAIS.Value % if we're using AIS files
    [lat, lon, Tship] = ww_read_AIS(HANDLES.ui.calc.shipPath.Value, HANDLES.ui.calc.locDate.Value);
end

if isfield(PARAMS.project, 'InstrumentOrientationRelPath') % if we already have a path for instrument orientation
    save(PARAMS.projectSaveFolder + PARAMS.project.InstrumentOrientationRelPath + "\" + HANDLES.ui.calc.instrumentName.Value + "_shipLatLon.mat", "lat","lon","Tship");
else
    % construct a path to save these
    projPrecalcRoot = fullfile(PARAMS.projectSaveFolder, "instrument_orientation");
    if ~isfolder(projPrecalcRoot)
        mkdir(projPrecalcRoot);
    end
    PARAMS.project.InstrumentOrientationRelPath = "\instrument_orientation";
    save(projPrecalcRoot + "\" + HANDLES.ui.calc.instrumentName.Value + "_shipLatLon.mat", "lat","lon","Tship");
end


% next, calculate TDOA
[Txwav, TDOA, shipTDOA] = ww_calculate_tdoa_ship(Tship(1), Tship(end), HANDLES.ui.calc.xwavPath.Value);
save(PARAMS.projectSaveFolder + PARAMS.project.InstrumentOrientationRelPath + "\" + HANDLES.ui.calc.instrumentName.Value + "_shipTDOA.mat", "Txwav", "TDOA","shipTDOA");

ww_show_brushTDOA_hydPosInv(Tship, lat, lon, Txwav, TDOA, shipTDOA) % show brushTDOA interface

end

function [Lat, Lon, T] = ww_read_TTGPS(filepathname, ymd)

% ww_read_TTPGS
%
% nested function for reading TTGPS files

% convert date input to expected format
ymd = [str2double(ymd(3:4)),str2double(ymd(5:6)),str2double(ymd(7:8))];

fid = fopen(filepathname);
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
                T(n) = datetime([ymd, str2num(tline(timeloc:timeloc+1)), ...
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
                T(n) = datetime([ymd, str2num(tline(timeloc:timeloc+1)), ...
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
fclose(fid); % close file

% remove redundant readings
[Tu, ia, ~] = unique(T); % get indices of unique readings
Lat = Lat(ia);
Lon = Lon(ia);
T = T(ia);

end

function [Lat, Lon, T] = ww_read_AIS(filepathname, ymd)

% ww_read_AIS
%
% nested helper function for reading AIS files

data = readtable(filepathname);
Lat = data.LAT';
Lon = data.LON';

date = extractBefore(string(data.BaseDateTime),'T');
date = strrep(string(date),' ',''); % remove spaces
tm = extractAfter(string(data.BaseDateTime),'T');

T = strcat(date,tm);
T = datetime(T,'inputformat','yyyy-MM-ddHH:mm:ss')-years(2000);
T = T';

end