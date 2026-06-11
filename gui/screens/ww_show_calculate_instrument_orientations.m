function ww_show_calculate_instrument_orientations()

% ww_show_instrument_orientations()
%
% function to open the calculate instrument orientation screen
% the user will be able to calculate for the first time, or recalculate,
% instrument orientation files for a given 4ch.
%
% this function and the functions it calls will need to be updated for
% vertical arays

global PARAMS HANDLES
ww_clear_HANDLES_ui_content(); % clear old ui handles
HANDLES.fig.main.Name = PARAMS.project.Software + " v" + PARAMS.project.Version + " - " + PARAMS.project.ProjectName + " Calculate Instrument Orientation";

% root layout: top bar + main content
root = uigridlayout(HANDLES.ui.content,[6 1]);
root.ColumnWidth = {'1x'};
root.RowHeight = {40, 50, '1x',36, 10, 44};
root.Padding   = [15 12 15 12];
root.RowSpacing = 8;

% ---- top bar (home button) ----
topbar = uigridlayout(root,[1 4]);
topbar.Layout.Row = 1;
topbar.ColumnWidth = {160,220,'1x',1};
topbar.Padding = [0 0 0 0];

HANDLES.ui.workflow.btnHome = uibutton(topbar,'push', ...
    'Text',"← Project Workflow", ...
    'FontSize', 12, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn', @(~,~) ww_show_workflow());
HANDLES.ui.workflow.btnHome.Layout.Row = 1;
HANDLES.ui.workflow.btnHome.Layout.Column = 1;

% ---- title (its own root row) ----
titleLbl = uilabel(root, ...
    'Text',"Calculate instrument orientation", ...
    'FontSize',28, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
titleLbl.Layout.Row = 2;

% ---- form grid: 9 rows x 4 cols ----
form = uigridlayout(root,[10 4]);
form.Layout.Row = 3;
form.Padding = [20 0 100 0];
form.RowSpacing = 8;
form.ColumnSpacing = 12;

% label | input1 | input2 | input3/browse
form.ColumnWidth = {220,'1x','1x','1x'};
form.RowHeight = repmat({36},1,11);

% selection for TTGPS or AIS
lbl = uilabel(form,'Text',"Method:",'HorizontalAlignment','right');
lbl.Layout.Row = 1;
lbl.Layout.Column = 1;
HANDLES.ui.calc.method = uibuttongroup(form, ...
    'SelectionChangedFcn', @onModeChanged);
HANDLES.ui.calc.method.Layout.Row = 1;
HANDLES.ui.calc.method.Layout.Column = [2 4];
HANDLES.ui.calc.rbTTGPS = uiradiobutton(HANDLES.ui.calc.method, ...
    'Text',"from TTGPS", ...
    'Position',[10 6 120 22]);
HANDLES.ui.calc.rbAIS = uiradiobutton(HANDLES.ui.calc.method, ...
    'Text',"from AIS", ...
    'Position',[150 6 120 22]);
HANDLES.ui.calc.method.BackgroundColor = [0.7804    0.9137    1.0000];   % light blue
% HANDLES.ui.calc.method.BackgroundColor = [0.7608    0.8392    0.7059];   % light green
HANDLES.ui.calc.method.SelectedObject = HANDLES.ui.calc.rbTTGPS; % sets the default

% ---- row 1: Path to xwav files ----
lbl = uilabel(form,'Text',"Path to xwav files:",'HorizontalAlignment','right');
lbl.Layout.Row = 2; lbl.Layout.Column = 1;
HANDLES.ui.calc.xwavPath = uieditfield(form,'text', ...
    'Placeholder',"Choose or type a folder path...");
HANDLES.ui.calc.xwavPath.Layout.Row = 2;
HANDLES.ui.calc.xwavPath.Layout.Column = [2 3];
HANDLES.ui.calc.btnBrowseXwav = uibutton(form,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn',@onBrowseFolder);
HANDLES.ui.calc.btnBrowseXwav.Layout.Row = 2;
HANDLES.ui.calc.btnBrowseXwav.Layout.Column = 4;

% ---- row 2: Path to ship files ----
HANDLES.ui.calc.lblShipPath = uilabel(form,'Text',"Path to TTGPS files:",'HorizontalAlignment','right');
HANDLES.ui.calc.lblShipPath.Layout.Row = 3;
HANDLES.ui.calc.lblShipPath.Layout.Column = 1;
HANDLES.ui.calc.shipPath = uieditfield(form,'text', ...
    'Placeholder',"Choose or type a file path...");
HANDLES.ui.calc.shipPath.Layout.Row = 3;
HANDLES.ui.calc.shipPath.Layout.Column = [2 3];
HANDLES.ui.calc.btnBrowseShip = uibutton(form,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn',@onBrowseFile);
HANDLES.ui.calc.btnBrowseShip.Layout.Row = 3;
HANDLES.ui.calc.btnBrowseShip.Layout.Column = 4;

% ---- row 3: Instrument Name ----
lbl = uilabel(form,'Text',"Instrument Name:",'HorizontalAlignment','right');
lbl.Layout.Row = 4; lbl.Layout.Column = 1;
HANDLES.ui.calc.instrumentName = uieditfield(form,'text', ...
    'Placeholder',"e.g., SOCAL_W_01_WE");
HANDLES.ui.calc.instrumentName.Layout.Row = 4;
HANDLES.ui.calc.instrumentName.Layout.Column = [2 4];   % span all input columns

% ---- row 4: lat / lon / depth ----
lbl = uilabel(form,'Text',"Instrument location:",'HorizontalAlignment','right');
lbl.Layout.Row = 5; lbl.Layout.Column = 1;
HANDLES.ui.calc.lat = uieditfield(form,'text', 'Placeholder',"Lat (°N)");
HANDLES.ui.calc.lat.Layout.Row = 5;
HANDLES.ui.calc.lat.Layout.Column = 2;
HANDLES.ui.calc.lon = uieditfield(form,'text', 'Placeholder',"Lon (°E)");
HANDLES.ui.calc.lon.Layout.Row = 5;
HANDLES.ui.calc.lon.Layout.Column = 3;
HANDLES.ui.calc.depth = uieditfield(form,'text', 'Placeholder',"Depth (m)");
HANDLES.ui.calc.depth.Layout.Row = 5;
HANDLES.ui.calc.depth.Layout.Column = 4;

% ---- row 5: date + sound speed ----
lbl = uilabel(form,'Text',"Localization date:",'HorizontalAlignment','right');
lbl.Layout.Row = 6; lbl.Layout.Column = 1;
HANDLES.ui.calc.locDate = uieditfield(form,'text', 'Placeholder',"yyyyMMdd");
HANDLES.ui.calc.locDate.Layout.Row = 6;
HANDLES.ui.calc.locDate.Layout.Column = 2;

lbl = uilabel(form,'Text',"Sound speed (m/s):",'HorizontalAlignment','right');
lbl.Layout.Row = 6; lbl.Layout.Column = 3;
HANDLES.ui.calc.soundSpeed = uieditfield(form,'text', 'Placeholder',"1490");
HANDLES.ui.calc.soundSpeed.Layout.Row = 6;
HANDLES.ui.calc.soundSpeed.Layout.Column = 4;

% ---- row 6: load seg + xcov window ----
lbl = uilabel(form,'Text',"Load segment (s):",'HorizontalAlignment','right');
lbl.Layout.Row = 7; lbl.Layout.Column = 1;
HANDLES.ui.calc.loadSeg = uieditfield(form,'text', 'Value',"30");
HANDLES.ui.calc.loadSeg.Layout.Row = 7;
HANDLES.ui.calc.loadSeg.Layout.Column = 2;

lbl = uilabel(form,'Text',"Xcov window (s):",'HorizontalAlignment','right');
lbl.Layout.Row = 7; lbl.Layout.Column = 3;
HANDLES.ui.calc.xcovWin = uieditfield(form,'text', 'Value',"1");
HANDLES.ui.calc.xcovWin.Layout.Row = 7;
HANDLES.ui.calc.xcovWin.Layout.Column = 4;

% ---- row 7: bandpass filter edges  ----
lbl = uilabel(form,'Text',"Bandpass filter edges (Hz):",'HorizontalAlignment','right');
lbl.Layout.Row = 8; lbl.Layout.Column = 1;
HANDLES.ui.calc.bpLow = uieditfield(form,'text', 'Value',"100");
HANDLES.ui.calc.bpLow.Layout.Row = 8;
HANDLES.ui.calc.bpLow.Layout.Column = 2;
HANDLES.ui.calc.bpHigh = uieditfield(form,'text', 'Value',"10000");
HANDLES.ui.calc.bpHigh.Layout.Row = 8;
HANDLES.ui.calc.bpHigh.Layout.Column = 3;

% ---- progress bar ----
progressRow = uigridlayout(root,[1 4]);
progressRow.Layout.Row = 4;
progressRow.Layout.Column = 1;
progressRow.ColumnWidth = {'1x', 120, 420, '1x'};   % <-- flex | label | bar | flex
progressRow.Padding = [0 0 0 0];
HANDLES.ui.calc.progressLabel = uilabel(progressRow, ...
    'Text',"Calculating TDOAs", ...
    'HorizontalAlignment','right', ...
    'FontAngle','italic');
HANDLES.ui.calc.progressLabel.Layout.Column = 2;
barContainer = uipanel(progressRow, ...
    'BackgroundColor',[0.92 0.92 0.92], ...
    'BorderType','none');
barContainer.Layout.Column = 3;
barFill = uipanel(barContainer, ...
    'BackgroundColor',[0.20 0.45 0.85], ...
    'BorderType','none');
HANDLES.ui.calc.progressRow = progressRow;
HANDLES.ui.calc.progressContainer = barContainer;
HANDLES.ui.calc.progressFill = barFill;
HANDLES.ui.calc.progressRow.Visible = 'off';
drawnow;

% ---- bottom buttons ----
btnRow = uigridlayout(root,[1 4]);
btnRow.Layout.Row = 6;
btnRow.Padding = [0 0 0 0];
btnRow.ColumnSpacing = 10;
btnRow.ColumnWidth = {'1x',240,40,240,'1x'};

if isfield(PARAMS.project, 'InstrumentOrientationRelPath') % if we've already calculated orientations
    btnBack = uibutton(btnRow,'push', ...
        'Text',"Back", ...
        'ButtonPushedFcn',@(~,~)ww_show_view_instrument_orientations()); % go back to existing orientations
    btnBack.Layout.Column = 2;
else % if we need to calculate them
    btnBack = uibutton(btnRow,'push', ...
        'Text',"Back", ...
        'ButtonPushedFcn',@(~,~)ww_show_workflow()); % go back to project workflow
    btnBack.Layout.Column = 2;
end

btnSave = uibutton(btnRow,'push', ...
    'Text',"Calculate", ...
    'FontWeight','bold', ...
    'ButtonPushedFcn',@onCalculate);
btnSave.Layout.Column = 4;

drawnow;

% ---- callback functions ----
    function onBrowseFolder(~,~) % open file explorer to select save directory
        startDir = pwd;
        folder = uigetdir(startDir, "Select xwav disk");
        if isequal(folder,0); return; end
        HANDLES.ui.calc.xwavPath.Value = folder;
        figure(HANDLES.fig.main);
        drawnow;
    end

    function onBrowseFile(~,~) % open file explorer to select a file
        startDir = pwd;
        [fname, fpath] = uigetfile('*.*', "Select file", startDir);
        if isequal(fname,0); return; end
        HANDLES.ui.calc.shipPath.Value = fullfile(fpath, fname);
        figure(HANDLES.fig.main);
        drawnow;
    end

    function onModeChanged(src,event)
        selected = string(event.NewValue.Text);   % "from TTGPS" or "from AIS"
        switch selected
            case "from TTGPS"
                HANDLES.ui.calc.lblShipPath.Text = "Path to TTGPS file:";
            case "from AIS"
                HANDLES.ui.calc.lblShipPath.Text = "Path to AIS file:";
        end
    end

    function onCalculate(~,~)

        % save HANDLES inputs in PARAMS file
        if ~isfield(PARAMS.project, 'InstrumentOrientationParams')
            PARAMS.project.InstrumentOrientationParams = struct(); % initialize an empty field, if one doesn't yet exist
        end
        instrumentName = HANDLES.ui.calc.instrumentName.Value;
        instrumentField = matlab.lang.makeValidName(instrumentName);

        PARAMS.project.InstrumentOrientationParams.(instrumentField).FromTTGPS = HANDLES.ui.calc.rbTTGPS.Value;
        PARAMS.project.InstrumentOrientationParams.(instrumentField).FromAIS = HANDLES.ui.calc.rbAIS.Value;
        PARAMS.project.InstrumentOrientationParams.(instrumentField).XwavPath = HANDLES.ui.calc.xwavPath.Value;
        PARAMS.project.InstrumentOrientationParams.(instrumentField).ShipFilePath = HANDLES.ui.calc.shipPath.Value;
        PARAMS.project.InstrumentOrientationParams.(instrumentField).InstrumentName = HANDLES.ui.calc.instrumentName.Value;
        PARAMS.project.InstrumentOrientationParams.(instrumentField).InstrumentLocation.Lat_DegN = str2num(HANDLES.ui.calc.lat.Value);
        PARAMS.project.InstrumentOrientationParams.(instrumentField).InstrumentLocation.Lon_DegE = str2num(HANDLES.ui.calc.lon.Value);
        PARAMS.project.InstrumentOrientationParams.(instrumentField).InstrumentLocation.Depth_m = str2num(HANDLES.ui.calc.depth.Value);
        PARAMS.project.InstrumentOrientationParams.(instrumentField).LocalizationDate = HANDLES.ui.calc.locDate.Value;
        PARAMS.project.InstrumentOrientationParams.(instrumentField).SoundSpeed_ms = str2num(HANDLES.ui.calc.soundSpeed.Value);
        PARAMS.project.InstrumentOrientationParams.(instrumentField).LoadSegment_s = str2num(HANDLES.ui.calc.loadSeg.Value);
        PARAMS.project.InstrumentOrientationParams.(instrumentField).XcovWindow_s = str2num(HANDLES.ui.calc.xcovWin.Value);
        PARAMS.project.InstrumentOrientationParams.(instrumentField).bpLow_Hz = str2num(HANDLES.ui.calc.bpLow.Value);
        PARAMS.project.InstrumentOrientationParams.(instrumentField).bpHigh_Hz = str2num(HANDLES.ui.calc.bpHigh.Value);

        % put in something here to save the PARAMS
        project = PARAMS.project; save(PARAMS.projectSaveFolder + project.ConfigRelFilePath,'project');
        % run instrument orientations calculation code
        ww_calculate_instrument_orientations();

    end

end
