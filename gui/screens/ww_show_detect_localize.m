function ww_show_detect_localize()

% ww_show_detect_localize()
%
% function to display detection GUI screen

global PARAMS HANDLES

% catch if the instrument orientations are messed up
if numel(dir(PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+"\*harp4chParams.mat"))>str2num(extractBetween(PARAMS.project.ArrayOption,1,1))
  uialert(HANDLES.fig.main,"You have more instrument orientations in the folder than defined in your project metadata: "+PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+". Remove extra files before running the detector.","Too many instrument orientations");
  return
end

ww_clear_HANDLES_ui_content(); % clear old ui handles
HANDLES.fig.main.Name = PARAMS.project.Software + " v" + PARAMS.project.Version + " - " + PARAMS.project.ProjectName + " Detect and Localize";

% root layout: top bar + main content
root = uigridlayout(HANDLES.ui.content,[8 1]);
root.RowHeight = {40, 54, '1x', 1, 1, 1, 44, 54};  % form gets the '1x'
root.ColumnWidth = {'1x'};
root.Padding = [20 20 20 20];
root.RowSpacing = 12;

% ---- top bar (home and workflow button) ----
topbar = uigridlayout(root,[1 4]);
topbar.Layout.Row = 1;
topbar.ColumnWidth = {160,220,'1x',1};   % left | spacer | tiny right
topbar.Padding = [0 0 0 0];
% whaledo home button
HANDLES.ui.workflow.btnHome = uibutton(topbar,'push', ...
    'Text',"← Where'sWhaledo Home", ...
    'FontSize', 12, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn', @(~,~) ww_show_home());
HANDLES.ui.workflow.btnHome.Layout.Row = 1;
HANDLES.ui.workflow.btnHome.Layout.Column = 1;
% project workflow button
HANDLES.ui.workflow.btnHome = uibutton(topbar,'push', ...
    'Text',"← Project Workflow", ...
    'FontSize', 12, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn', @(~,~) ww_show_workflow());
HANDLES.ui.workflow.btnHome.Layout.Row = 1;
HANDLES.ui.workflow.btnHome.Layout.Column = 2;

% ---- title ----
titleLbl = uilabel(root, ...
    'Text',"Detect + Localize Encounters", ...
    'FontSize',28, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
titleLbl.Layout.Row = 2;

% ---- form grid: 11 rows x 3 cols ----
form = uigridlayout(root,[6 5]);
form.Layout.Row = 3;
form.Layout.Column = 1;

% label | input(left) | input(right)
form.ColumnWidth = {240,'1x','1x','1x','1x'};
form.RowHeight   = { ...
    20, ...   % row 1  (options checkboxes)
    30, ...   % row 2  (encounter input)
    30, ...   % row 3  (save path input)
    20, ...   % row 4  (ID input)
    190, ...  % row 5  (block for each instrument)
    190, ...   % row 6  (detection params)
    };
form.Padding = [0 0 0 0];
form.RowSpacing = 10;
form.ColumnSpacing = 12;

% ---------------- Row 1: one row, checkboxes ----------------
lbl = uilabel(form,'Text',"Options:",'HorizontalAlignment','right');
lbl.Layout.Row = 1; lbl.Layout.Column = 1;

cbRow = uigridlayout(form,[1 2]);
cbRow.Layout.Row = 1; cbRow.Layout.Column = [2 5];
cbRow.ColumnWidth = {'1x','1x','1x','1x','1x'};
cbRow.Padding = [0 0 0 0];
cbRow.ColumnSpacing = 12;

HANDLES.ui.detect.cb1 = uicheckbox(cbRow,'Text',"Import species labels from ID files",'ValueChangedFcn',@onToggleExtraField);
HANDLES.ui.detect.cb2 = uicheckbox(cbRow,'Text',"Overwrite existing output");

% ---------------- Rows 2–3: two rows, text input ----------------
lbl = uilabel(form,'Text',"Path to encounter file:",'HorizontalAlignment','right');
lbl.Layout.Row = 2; lbl.Layout.Column = 1;
HANDLES.ui.detect.txt1 = uieditfield(form,'text','Placeholder',"Choose or type a folder path...");
HANDLES.ui.detect.txt1.Layout.Row = 2;
HANDLES.ui.detect.txt1.Layout.Column = [2 4];
HANDLES.ui.detect.btnBrowseEnc = uibutton(form,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn',@(btn,evt) onBrowseFile(btn,evt,HANDLES.ui.detect.txt1));
HANDLES.ui.detect.btnBrowseEnc.Layout.Row = 2;
HANDLES.ui.detect.btnBrowseEnc.Layout.Column = 5;

lbl = uilabel(form,'Text',"Path to save outputs:",'HorizontalAlignment','right');
lbl.Layout.Row = 3; lbl.Layout.Column = 1;
HANDLES.ui.detect.txt2 = uieditfield(form,'text','Value',PARAMS.projectSaveFolder+"\detector_output");
HANDLES.ui.detect.txt2.Layout.Row = 3;
HANDLES.ui.detect.txt2.Layout.Column = [2 4];
HANDLES.ui.detect.btnBrowseOut = uibutton(form,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn',@(btn,evt) onBrowseFile(btn,evt,HANDLES.ui.detect.txt2));
HANDLES.ui.detect.btnBrowseOut.Layout.Row = 3;
HANDLES.ui.detect.btnBrowseOut.Layout.Column = 5;

% row 4, ID file input
% extra text input (hidden by default)
HANDLES.ui.detect.extraLabel = uilabel(form, ...
    'Text',"Path to ID files:", ...
    'HorizontalAlignment','right');
HANDLES.ui.detect.extraLabel.Layout.Row = 4;
HANDLES.ui.detect.extraLabel.Layout.Column = 1;
HANDLES.ui.detect.extraField = uieditfield(form,'text', ...
    'Placeholder',"Choose or type a folder path...");
HANDLES.ui.detect.extraField.Layout.Row = 4;
HANDLES.ui.detect.extraField.Layout.Column = [2 4];
HANDLES.ui.detect.extraLabel.Visible = 'off';
HANDLES.ui.detect.extraField.Visible = 'off';
HANDLES.ui.detect.btnBrowseID = uibutton(form,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn', @(btn,evt) onBrowseFolder(btn,evt,HANDLES.ui.detect.extraField));
HANDLES.ui.detect.btnBrowseID.Layout.Row = 4;
HANDLES.ui.detect.btnBrowseID.Layout.Column = 5;
HANDLES.ui.detect.btnBrowseID.Visible = 'off';

% ---------------- Row 5: two columns, 3 textbox inputs each ----------------
twoColPanel = uipanel(form, ...
    'BorderType','line');
twoColPanel.Layout.Row = 5;
twoColPanel.Layout.Column = [1 5];
% wrapper grid = padding container
twoColWrapper = uigridlayout(twoColPanel,[1 1]);
twoColWrapper.Padding = [12 10 12 10];   % ← THIS is the padding
twoColWrapper.RowHeight = {'1x'};
twoColWrapper.ColumnWidth = {'1x'};
% actual content grid
twoCol = uigridlayout(twoColWrapper,[4 6]);
twoCol.RowHeight = {24,36,36,36};
twoCol.ColumnWidth = {160,'1x','1x',160,'1x','1x'};
twoCol.Padding = [0 0 0 0];
twoCol.RowSpacing = 10;
twoCol.ColumnSpacing = 12;
% up to 2 columns of paired inputs
paramsFiles = dir(PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+"\*harp4chParams.mat");
instruments = extractBefore(string({paramsFiles.name}),'_harp4chParams.mat');
rowLabels = ["Path to xwavs:" "Path to TF:" "Click Params Channel:"];
placeholderText = ["Choose or type a folder path..." "Choose or type a file path..." "e.g. 1"];

for c = 1:str2num(extractBetween(PARAMS.project.ArrayOption,1,1))
    startCol  = 3*(c-1) + 1;
    colLabel  = startCol;
    colField  = startCol + [1 2];     % spans the two "field columns"
    colHeader = startCol + [1 2];
    % header spanning the two columns
    h = uilabel(twoCol,'Text',instruments(c),'FontWeight','bold');
    h.Layout.Row = 1;
    h.Layout.Column = colHeader;
    for r = 1:3
        rr = r + 1; % rows 2..4
        % left label
        lab = uilabel(twoCol,'Text',rowLabels(r),'HorizontalAlignment','right');
        lab.Layout.Row = rr;
        lab.Layout.Column = colLabel;
        if r <= 2
            % field area becomes: [ editfield | browse button ] spanning colField
            cellPanel = uipanel(twoCol,'BorderType','none');
            cellPanel.Layout.Row = rr;
            cellPanel.Layout.Column = colField;
            cellGrid = uigridlayout(cellPanel,[1 2]);
            cellGrid.ColumnWidth = {'1x',90};
            cellGrid.Padding = [0 0 0 0];
            cellGrid.ColumnSpacing = 8;
            HANDLES.ui.detect.inst(c).param(r) = uieditfield(cellGrid,'text', ...
                'Placeholder',placeholderText(r));
            if r == 1
                % browse folder for xwavs
                HANDLES.ui.detect.inst(c).browse(r) = uibutton(cellGrid,'push', ...
                    'Text',"Browse", ...
                    'ButtonPushedFcn', @(btn,evt) onBrowseFolder(btn,evt,HANDLES.ui.detect.inst(c).param(r)));
            else
                % browse file for TF
                HANDLES.ui.detect.inst(c).browse(r) = uibutton(cellGrid,'push', ...
                    'Text',"Browse", ...
                    'ButtonPushedFcn', @(btn,evt) onBrowseFile(btn,evt,HANDLES.ui.detect.inst(c).param(r)));
            end
        else
            % normal text field spanning the two columns (no browse button)
            HANDLES.ui.detect.inst(c).param(r) = uieditfield(twoCol,'text','Value','1');
            HANDLES.ui.detect.inst(c).param(r).Layout.Row = rr;
            HANDLES.ui.detect.inst(c).param(r).Layout.Column = colField;
        end
    end
end

% --- row 6: 2 columns, 4 rows each ----
twoCol2Panel = uipanel(form, ...
    'BorderType','line', ...
    'BackgroundColor',[0.98 0.97 0.97]);
twoCol2Panel.Layout.Row = 6;
twoCol2Panel.Layout.Column = [1 5];
secCGrid = uigridlayout(twoCol2Panel,[1 1]);
secCGrid.Padding = [12 10 12 10];
secCGrid.RowHeight = {'1x'};
secCGrid.ColumnWidth = {'1x'};
twoCol2 = uigridlayout(secCGrid,[3 2]);
twoCol2.RowHeight = repmat({36},1,3);
twoCol2.ColumnWidth = {'1x','1x'};
twoCol2.Padding = [0 0 0 0];
twoCol2.RowSpacing = 10;
twoCol2.ColumnSpacing = 12;
labels = [ ...
    "Bandpass filter edges (Hz)"     "Detection threshold (counts):";
    "Signal duration (µs):"           "Min peak distance (ms):";
    "Max TDOA (ms):"                 "Buffer length (ms):"
    "Bin width (Hz):"    "Parallel Pool Size:"];
% defaults for the NORMAL 3x2 cells
defaults = [ ...
    ""      "28";
    "580"   "5";
    "1"   "0.25"
    "1000"   "2"];
% defaults for the SPECIAL two-box cell (1,1)
bpDefaults = ["20000","50000"];
for r = 1:4
    for c2 = 1:2
        cellPanel = uipanel(twoCol2,'BorderType','none');
        cellPanel.Layout.Row = r;
        cellPanel.Layout.Column = c2;
        if r == 1 && c2 == 1
            % SPECIAL: label | box | box
            cellGrid = uigridlayout(cellPanel,[1 3]);
            cellGrid.Padding = [0 0 0 0];
            cellGrid.ColumnSpacing = 6;
            cellGrid.ColumnWidth = {240,180,180};
            uilabel(cellGrid, ...
                'Text', labels(1,1), ...
                'HorizontalAlignment','right', ...
                'FontSize', 12);
            HANDLES.ui.detect.block2a = uieditfield(cellGrid,'text','Value',bpDefaults(1));
            HANDLES.ui.detect.block2b = uieditfield(cellGrid,'text','Value',bpDefaults(2));
        else
            % NORMAL: label | box
            cellGrid = uigridlayout(cellPanel,[1 2]);
            cellGrid.Padding = [0 0 0 0];
            cellGrid.ColumnSpacing = 6;
            cellGrid.ColumnWidth = {240,360};
            uilabel(cellGrid, ...
                'Text', labels(r,c2), ...
                'HorizontalAlignment','right', ...
                'FontSize', 12);
            HANDLES.ui.detect.block2(r,c2) = uieditfield(cellGrid,'text', ...
                'Value', defaults(r,c2));
        end
    end
end

% ---- row 7: progress bar ----
progressRow = uigridlayout(root,[1 4]);
progressRow.Layout.Row = 7;
progressRow.Layout.Column = 1;
progressRow.ColumnWidth = {'1x', 420, 420, '1x'};   % <-- flex | label | bar | flex
progressRow.Padding = [0 0 0 0];
HANDLES.ui.detect.progressLabel = uilabel(progressRow, ...
    'Text',"Calculating TDOAs", ...
    'HorizontalAlignment','right', ...
    'FontAngle','italic');
HANDLES.ui.detect.progressLabel.Layout.Column = 2;
barContainer = uipanel(progressRow, ...
    'BackgroundColor',[0.92 0.92 0.92], ...
    'BorderType','none');
barContainer.Layout.Column = 3;
barFill = uipanel(barContainer, ...
    'BackgroundColor',[0.20 0.45 0.85], ...
    'BorderType','none');
HANDLES.ui.detect.progressRow = progressRow;
HANDLES.ui.detect.progressContainer = barContainer;
HANDLES.ui.detect.progressFill = barFill;
HANDLES.ui.detect.progressRow.Visible = 'off';
drawnow;
pos = getpixelposition(HANDLES.ui.detect.progressContainer, true);
HANDLES.ui.detect.progressLabel.Text = "Running detector...";
HANDLES.ui.detect.progressFill.Units = 'pixels';
HANDLES.ui.detect.progressFill.Position = [0 0 0 pos(4)];

% ---- bottom buttons ----
btnRow = uigridlayout(root,[1 3]);
btnRow.Layout.Row = 8;
btnRow.Padding = [0 0 0 0];
btnRow.ColumnSpacing = 10;
btnRow.ColumnWidth = {'1x',240,'1x'};

btnSave = uibutton(btnRow,'push', ...
    'Text',"Run Detector", ...
    'FontWeight','bold', ...
    'ButtonPushedFcn',@onCalculate);
btnSave.Layout.Column = 2;

drawnow;

% ---- callback functions ----
    function onBrowseFolder(~,~,targetField) % open file explorer to select save directory
        startDir = pwd;
        folder = uigetdir(startDir, "Select folder");
        if isequal(folder,0); return; end
        targetField.Value = folder;
        figure(HANDLES.fig.main);
        drawnow;
    end

    function onBrowseFile(~,~,targetField) % open file explorer to select a file
        startDir = pwd;
        [fname, fpath] = uigetfile('*.*', "Select file", startDir);
        if isequal(fname,0); return; end
        targetField.Value = fullfile(fpath, fname);
        figure(HANDLES.fig.main);
        drawnow;
    end

    function onToggleExtraField(src,~)
        if src.Value
            HANDLES.ui.detect.extraField.Visible = 'on';
            HANDLES.ui.detect.extraLabel.Visible = 'on';
            HANDLES.ui.detect.btnBrowseID.Visible = 'on';
        else
            HANDLES.ui.detect.extraField.Visible = 'off';
            HANDLES.ui.detect.extraLabel.Visible = 'off';
            HANDLES.ui.detect.extraField.Value = "";
            HANDLES.ui.detect.btnBrowseID.Visible = 'off';
        end
        drawnow;
    end

    function onCalculate(~,~)

        % save HANDLES inputs in PARAMS file
        if ~isfield(PARAMS.project, 'DetectionLocalizationParams')
            PARAMS.project.DetectionLocalizationParams = struct(); % initialize an empty field, if one doesn't yet exist
        end

        PARAMS.project.DetectionLocalizationParams.IDcheck = HANDLES.ui.detect.cb1.Value;
        PARAMS.project.DetectionLocalizationParams.OverwriteCheck = HANDLES.ui.detect.cb2.Value;
        PARAMS.project.DetectionLocalizationParams.EncPath = HANDLES.ui.detect.txt1.Value;
        PARAMS.project.DetectionLocalizationParams.SavePath = HANDLES.ui.detect.txt2.Value;
        PARAMS.project.DetectionLocalizationParams.IDpath = HANDLES.ui.detect.extraField.Value;
        
        for k = 1:length(instruments)
            PARAMS.project.DetectionLocalizationParams.(instruments(k)).xwavPath = HANDLES.ui.detect.inst(k).param(1).Value;
            PARAMS.project.DetectionLocalizationParams.(instruments(k)).TFpath = HANDLES.ui.detect.inst(k).param(2).Value;
            PARAMS.project.DetectionLocalizationParams.(instruments(k)).channel = str2num(HANDLES.ui.detect.inst(k).param(3).Value);
        end

        PARAMS.project.DetectionLocalizationParams.bpEdges = [str2num(HANDLES.ui.detect.block2a.Value) str2num(HANDLES.ui.detect.block2b.Value)];
        PARAMS.project.DetectionLocalizationParams.detThresh_counts = str2num(HANDLES.ui.detect.block2(1,2).Value);
        PARAMS.project.DetectionLocalizationParams.sigDur_us = str2num(HANDLES.ui.detect.block2(2,1).Value);
        PARAMS.project.DetectionLocalizationParams.minPkDist_ms = str2num(HANDLES.ui.detect.block2(2,2).Value);
        PARAMS.project.DetectionLocalizationParams.maxTDOA_ms = str2num(HANDLES.ui.detect.block2(3,1).Value);
        PARAMS.project.DetectionLocalizationParams.bufferLength_ms = str2num(HANDLES.ui.detect.block2(3,2).Value);
        PARAMS.project.DetectionLocalizationParams.binWidth_hz = str2num(HANDLES.ui.detect.block2(4,1).Value);
        PARAMS.project.DetectionLocalizationParams.parpool = str2num(HANDLES.ui.detect.block2(4,2).Value);

        project = PARAMS.project; save(PARAMS.projectSaveFolder + project.ConfigRelFilePath,'project');
        % run detection - localization code
        ww_run_detect_localize()
        ww_show_workflow() % move back to workflow screen when done

    end

end