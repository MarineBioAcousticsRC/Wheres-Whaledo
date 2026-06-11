function ww_show_verify_tracks()

% ww_show_verify_tracks()
%
% function to display track verification file select screen

global PARAMS HANDLES

ww_clear_HANDLES_ui_content(); % clear old ui handles
HANDLES.fig.main.Name = PARAMS.project.Software + " v" + PARAMS.project.Version + " - " + PARAMS.project.ProjectName + " Verify Tracks";

% ---- root layout: top bar + main content ----
root = uigridlayout(HANDLES.ui.content,[2 1]);
root.RowHeight = {40,'1x'};
root.ColumnWidth = {'1x'};
root.Padding = [20 20 20 20];
root.RowSpacing = 12;

% ---- top bar (home and metadata button) ----
topbar = uigridlayout(root,[1 4]);
topbar.Layout.Row = 1;
topbar.ColumnWidth = {160,220,'1x',1};   % left | spacer | tiny right
topbar.Padding = [0 0 0 0];

% project home button
HANDLES.ui.workflow.btnHome = uibutton(topbar,'push', ...
    'Text',"← Project Workflow", ...
    'FontSize', 12, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn', @(~,~) ww_show_workflow());
HANDLES.ui.workflow.btnHome.Layout.Row = 1;
HANDLES.ui.workflow.btnHome.Layout.Column = 1;

% ---- main content ----
main = uigridlayout(root,[4 1]);
main.Layout.Row = 2;
main.RowHeight = {60, 44, '1x', 60};   % title | path row | list | buttons
main.Padding = [0 0 0 0];
main.RowSpacing = 10;

% ---- title ----
HANDLES.ui.verify.title = uilabel(main, ...
    'Text',"Verify Localized Tracks", ...
    'FontSize', 24, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
HANDLES.ui.verify.title.Layout.Row = 1;

% ---- folder row: label | edit | browse ----
pathRow = uigridlayout(main,[1 3]);
pathRow.Layout.Row = 2;
pathRow.ColumnWidth = {240,'1x',110};
pathRow.ColumnSpacing = 10;
pathRow.Padding = [0 0 0 0];

lbl = uilabel(pathRow,'Text',"Path to detection outputs:",'HorizontalAlignment','right');
lbl.Layout.Row = 1; lbl.Layout.Column = 1;
HANDLES.ui.verify.folderEdit = uieditfield(pathRow,'text','Placeholder','Choose folder path...','ValueChangedFcn', @refreshFileList);
HANDLES.ui.verify.folderEdit.Layout.Row = 1;
HANDLES.ui.verify.folderEdit.Layout.Column = 2;
HANDLES.ui.verify.btnBrowseFolder = uibutton(pathRow,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn',@onBrowseFolder);
HANDLES.ui.verify.btnBrowseFolder.Layout.Row = 1;
HANDLES.ui.verify.btnBrowseFolder.Layout.Column = 3;

% ---- file list ----
HANDLES.ui.verify.fileList = uilistbox(main, ...
    'Items', {}, ...
    'Multiselect','off', ...
    'ValueChangedFcn', @onFileSelected);
HANDLES.ui.verify.fileList.Layout.Row = 3;

% ---- bottom buttons ----
btnRow = uigridlayout(main,[1 3]);
btnRow.Layout.Row = 4;
btnRow.ColumnWidth = {'1x',120,120};
btnRow.Padding = [0 0 0 0];
btnRow.ColumnSpacing = 10;

HANDLES.ui.verify.status = uilabel(btnRow, ...
    'Text',"", ...
    'HorizontalAlignment','left', ...
    'FontAngle','italic');
HANDLES.ui.verify.status.Layout.Column = 1;

HANDLES.ui.verify.btnRefresh = uibutton(btnRow,'push', ...
    'Text',"Refresh", ...
    'ButtonPushedFcn', @refreshFileList);
HANDLES.ui.verify.btnRefresh.Layout.Column = 2;

HANDLES.ui.verify.btnDisplay = uibutton(btnRow,'push', ...
    'Text',"Display", ...
    'Enable','off', ...
    'ButtonPushedFcn', @onDisplay);
HANDLES.ui.verify.btnDisplay.Layout.Column = 3;

% prefill a folder, if the info is saved
hasSavePath = isfield(PARAMS, 'project') && ...
    isfield(PARAMS.project, 'DetectionLocalizationParams') && ...
    isfield(PARAMS.project.DetectionLocalizationParams, 'SavePath');
if hasSavePath && isfolder(PARAMS.project.DetectionLocalizationParams.SavePath)
    HANDLES.ui.verify.folderEdit.Value = PARAMS.project.DetectionLocalizationParams.SavePath;
    refreshFileList();
end

% ---- callbacks ----

    function onBrowseFolder(~,~) % open file explorer to select save directory
        startDir = pwd;
        folder = uigetdir(startDir, "Select detection output folder");
        if isequal(folder,0); return; end
        HANDLES.ui.verify.folderEdit.Value = folder;
        figure(HANDLES.fig.main);
        refreshFileList();
        drawnow;
    end

    function onFileSelected(~,~)
        hasSelection = ~isempty(HANDLES.ui.verify.fileList.Value);
        HANDLES.ui.verify.btnDisplay.Enable = matlab.lang.OnOffSwitchState(hasSelection);
    end

    function refreshFileList(~,~)
        folder = strtrim(string(HANDLES.ui.verify.folderEdit.Value));
        HANDLES.ui.verify.btnDisplay.Enable = 'off';
        HANDLES.ui.verify.fileList.Items = {};
        HANDLES.ui.verify.fileList.Value = {};
        HANDLES.ui.verify.status.Text = "";
        if folder == ""
            HANDLES.ui.verify.status.Text = "Enter a folder path.";
            return
        end
        if ~isfolder(folder)
            HANDLES.ui.verify.status.Text = "Folder not found.";
            return
        end
        d = dir(fullfile(folder, "*"));
        d = d(~[d.isdir]); % files only
        if isempty(d)
            HANDLES.ui.verify.status.Text = "No files found.";
            return
        end
        names = string({d.name});
        names = sort(names);
        HANDLES.ui.verify.fileList.Items = cellstr(names);
        HANDLES.ui.verify.status.Text = sprintf("%d file(s). Select one and click Display.", numel(names));
    end

    function onDisplay(~,~)
        folder = strtrim(string(HANDLES.ui.verify.folderEdit.Value));
        fname  = string(HANDLES.ui.verify.fileList.Value);
        if folder == "" || fname == ""
            return
        end
        fpath = fullfile(folder, fname);
        if ~isfile(fpath)
            HANDLES.ui.verify.status.Text = "Selected file no longer exists.";
            HANDLES.ui.verify.btnDisplay.Enable = 'off';
            return
        end
        HANDLES.ui.verify.status.Text = "Displaying: " + fname;
        S = load(fpath);
        if numel(S.DET) == 1 % if we only have one 4ch
            DET1in = S.DET{1};
            f1in = S.freq{1};
            pin = S.p;
            fprintf("Cleaning detection file: %s\n", fpath); % send a message to the command window
            ww_show_encounter_options(fname)
            [DET1out, ~] = ww_run_brushDOA(DET1in, [], f1in, [], pin);
        elseif numel(S.DET) > 1 % if we have two 4ch
            DET1in = S.DET{1};
            DET2in = S.DET{2};
            if ~isfield(S,'freq')
                S.freq{1} = nan(1,3);
                S.freq{2} = nan(1,3);
            end
            f1in = S.freq{1};
            f2in = S.freq{2};
            if ~isfield(S,'p')
                S.P{1} = nan;
                S.p{2} = nan;
            end
            pin = S.p;
            fprintf("Cleaning detection file: %s\n", fpath); % send a message to the command window
            ww_show_encounter_options(fname)
            [DET1out, DET2out] = ww_run_brushDOA(DET1in, DET2in, f1in, f2in, pin);
        end
    end

end