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


% next, calculate TDOA, or reuse the saved cross-correlation output when
% none of its inputs changed (instrument location and sound speed don't
% enter the cross-correlation, so changing them alone needs no rerun)
tdoaFile = PARAMS.projectSaveFolder + PARAMS.project.InstrumentOrientationRelPath + "\" + HANDLES.ui.calc.instrumentName.Value + "_shipTDOA.mat";
reused = false; reuseMsg = "";
if isfield(HANDLES.ui.calc, 'reuseXcov') && isvalid(HANDLES.ui.calc.reuseXcov) && HANDLES.ui.calc.reuseXcov.Value
    [reused, Txwav, TDOA, shipTDOA, reuseMsg] = ww_reuse_ship_tdoa(tdoaFile, Tship);
end
if ~reused
    [Txwav, TDOA, shipTDOA] = ww_calculate_tdoa_ship(Tship(1), Tship(end), HANDLES.ui.calc.xwavPath.Value);
end
save(tdoaFile, "Txwav", "TDOA","shipTDOA");

ww_show_brushTDOA_hydPosInv(Tship, lat, lon, Txwav, TDOA, shipTDOA) % show brushTDOA interface
if reused % say so on the brushing screen
    fprintf('%s\n', reuseMsg);
    HANDLES.ui.newscreen.text.Text = reuseMsg + newline + newline + HANDLES.ui.newscreen.text.Text;
end

end

function [ok, Txwav, TDOA, shipTDOA, msg] = ww_reuse_ship_tdoa(tdoaFile, Tship)

% ww_reuse_ship_tdoa
%
% nested function: reuse the ship TDOAs saved by an earlier calculation if
% the cross-correlation inputs are unchanged (xwav path, load segment, xcov
% window, bandpass edges) and the saved TDOAs span the current ship track.
% The returned shipTDOA carries the current settings (instrument location,
% sound speed, ...) plus the derived cross-correlation settings.

global PARAMS HANDLES

ok = false; Txwav = []; TDOA = []; shipTDOA = []; msg = "";
if ~isfile(tdoaFile), return; end
cached = load(tdoaFile);
if ~all(isfield(cached, {'Txwav','TDOA','shipTDOA'})) || isempty(cached.Txwav), return; end

current = PARAMS.project.InstrumentOrientationParams.(HANDLES.ui.calc.instrumentName.Value);
old = cached.shipTDOA;

% inputs that change the cross-correlation must match
stripSep = @(p) regexprep(strtrim(char(string(p))), '[\\/]+$', '');
if ~isfield(old, 'XwavPath') || ~strcmp(stripSep(old.XwavPath), stripSep(current.XwavPath)), return; end
numFields = {'LoadSegment_s','XcovWindow_s','bpLow_Hz','bpHigh_Hz'};
for k = 1:numel(numFields)
    if ~isfield(old, numFields{k}) || ~isequal(old.(numFields{k}), current.(numFields{k})), return; end
end

% saved TDOAs must cover the current ship track, allowing for the partial
% xcov windows dropped at the ends
tol = seconds(2*current.XcovWindow_s + 1);
if min(cached.Txwav) > Tship(1) + tol || max(cached.Txwav) < Tship(end) - tol, return; end

ok = true;
Txwav = cached.Txwav;
TDOA = cached.TDOA;
shipTDOA = current;
for fld = ["nxc","nTDOA","ixcov"] % derived cross-correlation settings
    if isfield(old, fld), shipTDOA.(fld) = old.(fld); end
end
info = dir(tdoaFile);
msg = "Reused the ship TDOAs saved " + string(datetime(info.datenum, 'ConvertFrom','datenum', 'Format','yyyy-MM-dd HH:mm')) + ...
    " (cross-correlation skipped). To force a rerun, untick 'Reuse saved ship cross-correlation' on the Calculate screen.";

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

% handle UTC midnight rollover: ymd is the date of the FIRST fix;
% add a day each time the clock jumps backwards by more than 12 h
T = T + days(cumsum([false, diff(T) < -hours(12)]));

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