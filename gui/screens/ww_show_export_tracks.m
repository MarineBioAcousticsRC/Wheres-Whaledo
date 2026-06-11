function ww_show_export_tracks()

% ww_show_export_tracks()
%
% function to display selection screen for track export
% user can choose export type and enter options on a single form

global PARAMS HANDLES

ww_clear_HANDLES_ui_content();
HANDLES.fig.main.Name = PARAMS.project.Software + " v" + PARAMS.project.Version + ...
    " - " + PARAMS.project.ProjectName + " Export Cleaned Tracks";

% ---- root layout: top bar + main content ----
root = uigridlayout(HANDLES.ui.content,[6 1]);
root.ColumnWidth = {'1x'};
root.RowHeight = {40, 50, '1x', 10, 10, 44};
root.Padding = [15 12 15 12];
root.RowSpacing = 8;

% ---- top bar ----
topbar = uigridlayout(root,[1 4]);
topbar.Layout.Row = 1;
topbar.ColumnWidth = {160,220,'1x',1};
topbar.Padding = [0 0 0 0];

HANDLES.ui.workflow.btnHome = uibutton(topbar,'push', ...
    'Text',"← Project Workflow", ...
    'FontSize',12, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn',@(~,~) ww_show_workflow());
HANDLES.ui.workflow.btnHome.Layout.Row = 1;
HANDLES.ui.workflow.btnHome.Layout.Column = 1;

% ---- title ----
titleLbl = uilabel(root, ...
    'Text',"Export cleaned tracks", ...
    'FontSize',28, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
titleLbl.Layout.Row = 2;

% ---- form grid ----
form = uigridlayout(root,[9 4]);
form.Layout.Row = 3;
form.Padding = [20 0 100 0];
form.RowSpacing = 8;
form.ColumnSpacing = 12;
form.ColumnWidth = {220,'1x','1x','1x'};
form.RowHeight = repmat({36},1,8);

% -------------------------------------------------------------------------
% row 1: export type
% -------------------------------------------------------------------------
lbl = uilabel(form,'Text',"Export type:",'HorizontalAlignment','right');
lbl.Layout.Row = 1;
lbl.Layout.Column = 1;

HANDLES.ui.export.type = uibuttongroup(form, ...
    'SelectionChangedFcn', @onModeChanged);
HANDLES.ui.export.type.Layout.Row = 1;
HANDLES.ui.export.type.Layout.Column = [2 4];
HANDLES.ui.export.type.BackgroundColor = [0.7804 0.9137 1.0000]; % light blue

HANDLES.ui.export.rbNc = uiradiobutton(HANDLES.ui.export.type, ...
    'Text',"to .nc", ...
    'Position',[10 6 120 22]);

HANDLES.ui.export.rbXml = uiradiobutton(HANDLES.ui.export.type, ...
    'Text',"to .xml", ...
    'Position',[150 6 120 22]);

HANDLES.ui.export.type.SelectedObject = HANDLES.ui.export.rbNc;

% -------------------------------------------------------------------------
% row 2: input folder
% -------------------------------------------------------------------------
HANDLES.ui.export.lblInPath = uilabel(form, ...
    'Text',"Input folder:", ...
    'HorizontalAlignment','right');
HANDLES.ui.export.lblInPath.Layout.Row = 2;
HANDLES.ui.export.lblInPath.Layout.Column = 1;

if isfolder(PARAMS.projectSaveFolder+"\cleaned_encounters")
    HANDLES.ui.export.inPath = uieditfield(form,'text', ...
    'Value',PARAMS.projectSaveFolder+"\cleaned_encounters");
else
    HANDLES.ui.export.inPath = uieditfield(form,'text', ...
    'Placeholder',"Choose or type a folder path...");
end
HANDLES.ui.export.inPath.Layout.Row = 2;
HANDLES.ui.export.inPath.Layout.Column = [2 3];

HANDLES.ui.export.btnBrowseIn = uibutton(form,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn', @(btn,evt) onBrowseFolder(btn,evt,HANDLES.ui.export.inPath));
HANDLES.ui.export.btnBrowseIn.Layout.Row = 2;
HANDLES.ui.export.btnBrowseIn.Layout.Column = 4;

% -------------------------------------------------------------------------
% row 3: output folder
% -------------------------------------------------------------------------
HANDLES.ui.export.lblOutPath = uilabel(form, ...
    'Text',"Output folder:", ...
    'HorizontalAlignment','right');
HANDLES.ui.export.lblOutPath.Layout.Row = 3;
HANDLES.ui.export.lblOutPath.Layout.Column = 1;

HANDLES.ui.export.outPath = uieditfield(form,'text', ...
    'Placeholder',"Choose or type a folder path...");
HANDLES.ui.export.outPath.Layout.Row = 3;
HANDLES.ui.export.outPath.Layout.Column = [2 3];

HANDLES.ui.export.btnBrowseOut = uibutton(form,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn',@(btn,evt) onBrowseFolder(btn,evt,HANDLES.ui.export.outPath));
HANDLES.ui.export.btnBrowseOut.Layout.Row = 3;
HANDLES.ui.export.btnBrowseOut.Layout.Column = 4;

% -------------------------------------------------------------------------
% row 4: encounter file
% -------------------------------------------------------------------------
HANDLES.ui.export.lblEncPath = uilabel(form, ...
    'Text',"Encounter file:", ...
    'HorizontalAlignment','right');
HANDLES.ui.export.lblEncPath.Layout.Row = 4;
HANDLES.ui.export.lblEncPath.Layout.Column = 1;

if isfield(PARAMS.project,'DetectionLocalizationParams')
    HANDLES.ui.export.encPath = uieditfield(form,'text', ...
        'Value',PARAMS.project.DetectionLocalizationParams.EncPath);
else
    HANDLES.ui.export.encPath = uieditfield(form,'text', ...
        'Placeholder',"Choose or type path to encounter spreadsheet...");
end
HANDLES.ui.export.encPath.Layout.Row = 4;
HANDLES.ui.export.encPath.Layout.Column = [2 3];

HANDLES.ui.export.btnBrowseEnc = uibutton(form,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn',@onBrowseFile);
HANDLES.ui.export.btnBrowseEnc.Layout.Row = 4;
HANDLES.ui.export.btnBrowseEnc.Layout.Column = 4;

% -------------------------------------------------------------------------
% row 5: author name
% -------------------------------------------------------------------------
HANDLES.ui.export.lblAuthorName = uilabel(form, ...
    'Text',"UserId:", ...
    'HorizontalAlignment','right');
HANDLES.ui.export.lblAuthorName.Layout.Row = 5;
HANDLES.ui.export.lblAuthorName.Layout.Column = 1;

HANDLES.ui.export.authorName = uieditfield(form,'text', ...
    'Value',PARAMS.project.UserId);
HANDLES.ui.export.authorName.Layout.Row = 5;
HANDLES.ui.export.authorName.Layout.Column = [2 4];

% -------------------------------------------------------------------------
% row 6: email
% -------------------------------------------------------------------------
HANDLES.ui.export.lblOpt1 = uilabel(form, ...
    'Text',"Email address:", ...
    'HorizontalAlignment','right');
HANDLES.ui.export.lblOpt1.Layout.Row = 6;
HANDLES.ui.export.lblOpt1.Layout.Column = 1;

HANDLES.ui.export.opt1 = uieditfield(form,'text', ...
    'Placeholder',"Email address of responsible party");
HANDLES.ui.export.opt1.Layout.Row = 6;
HANDLES.ui.export.opt1.Layout.Column = [2 4];

% -------------------------------------------------------------------------
% row 7: DOI
% -------------------------------------------------------------------------
HANDLES.ui.export.lblOpt2 = uilabel(form, ...
    'Text',"DOI:", ...
    'HorizontalAlignment','right');
HANDLES.ui.export.lblOpt2.Layout.Row = 7;
HANDLES.ui.export.lblOpt2.Layout.Column = 1;

HANDLES.ui.export.opt2 = uieditfield(form,'text', ...
    'Placeholder',"DOI for DRYAD repository");
HANDLES.ui.export.opt2.Layout.Row = 7;
HANDLES.ui.export.opt2.Layout.Column = [2 4];

% -------------------------------------------------------------------------
% row 7: notes
% -------------------------------------------------------------------------
HANDLES.ui.export.lblOpt3 = uilabel(form, ...
    'Text',"Notes:", ...
    'HorizontalAlignment','right');
HANDLES.ui.export.lblOpt3.Layout.Row = 8;
HANDLES.ui.export.lblOpt3.Layout.Column = 1;

HANDLES.ui.export.opt3 = uieditfield(form, ...
    'Placeholder',"Write here any relevant details from this analysis which should be included with the data.");
HANDLES.ui.export.opt3.Layout.Row = 8;
HANDLES.ui.export.opt3.Layout.Column = [2 4];

% -------------------------------------------------------------------------
% row 8: status
% -------------------------------------------------------------------------
HANDLES.ui.export.lblStatus = uilabel(form, ...
    'Text',"Status:", ...
    'HorizontalAlignment','right');
HANDLES.ui.export.lblStatus.Layout.Row = 9;
HANDLES.ui.export.lblStatus.Layout.Column = 1;

HANDLES.ui.export.status = uilabel(form, ...
    'Text',"", ...
    'HorizontalAlignment','left');
HANDLES.ui.export.status.Layout.Row = 9;
HANDLES.ui.export.status.Layout.Column = [2 4];

% ---- bottom button ----
btnRow = uigridlayout(root,[1 5]);
btnRow.Layout.Row = 6;
btnRow.Padding = [0 0 0 0];
btnRow.ColumnSpacing = 10;
btnRow.ColumnWidth = {'1x',240,'1x'};

btnExport = uibutton(btnRow,'push', ...
    'Text',"Export", ...
    'FontWeight','bold', ...
    'ButtonPushedFcn',@onExport);
btnExport.Layout.Column = 2;

% initialize form for default selection
updateFormForMode("nc");

% -------------------------------------------------------------------------
% callbacks
% -------------------------------------------------------------------------
    function onBrowseFolder(~,~,targetField) % open file explorer to select save directory
        startDir = pwd;
        folder = uigetdir(startDir, "Select folder");
        if isequal(folder,0); return; end
        targetField.Value = folder;
        figure(HANDLES.fig.main);
        drawnow;
    end

    function onBrowseFile(~,~) % open file explorer to select a file
        startDir = pwd;
        [fname, fpath] = uigetfile('*.*', "Select file", startDir);
        if isequal(fname,0); return; end
        HANDLES.ui.export.encPath.Value = fullfile(fpath, fname);
        figure(HANDLES.fig.main);
        drawnow;
    end

    function onModeChanged(~,event)
        selected = string(event.NewValue.Text);

        switch selected
            case "to .nc"
                updateFormForMode("nc");
            case "to .xml"
                updateFormForMode("xml");
        end
    end

    function updateFormForMode(mode)

        switch lower(mode)

            case "nc"
                HANDLES.ui.export.lblOpt1.Text = "Email address:";
                HANDLES.ui.export.opt1.Placeholder = "Email address of responsible party";
                HANDLES.ui.export.opt1.Visible = 'on';
                HANDLES.ui.export.lblOpt1.Visible = 'on';

                HANDLES.ui.export.lblOpt2.Text = "DOI:";
                HANDLES.ui.export.opt2.Placeholder = "DOI for DRYAD repository";
                HANDLES.ui.export.opt2.Visible = 'on';
                HANDLES.ui.export.lblOpt2.Visible = 'on';

                HANDLES.ui.export.lblOpt3.Text = "Notes:";
                HANDLES.ui.export.opt3.Placeholder = "Write here any relevant details from this analysis which should be included with the data.";
                HANDLES.ui.export.opt3.Value = '';
                HANDLES.ui.export.opt3.Visible = 'on';
                HANDLES.ui.export.lblOpt3.Visible = 'on';

            case "xml"
                HANDLES.ui.export.lblOpt1.Text = "Tethys path:";
                HANDLES.ui.export.opt1.Placeholder = "File path to Tethys source code (install at https://tethys.sdsu.edu/install/)";
                HANDLES.ui.export.opt1.Visible = 'on';
                HANDLES.ui.export.lblOpt1.Visible = 'on';

                HANDLES.ui.export.lblOpt2.Text = "Server:";
                HANDLES.ui.export.opt2.Value = "breach.ucsd.edu";
                HANDLES.ui.export.opt2.Visible = 'on';
                HANDLES.ui.export.lblOpt2.Visible = 'on';

                HANDLES.ui.export.lblOpt3.Text = "Port:";
                HANDLES.ui.export.opt3.Value = '9779';
                HANDLES.ui.export.opt3.Visible = 'on';
                HANDLES.ui.export.lblOpt3.Visible = 'on';
        end

        HANDLES.ui.export.currentMode = mode;
        HANDLES.ui.export.status.Text = "";
    end

    function onExport(~,~)

        mode = HANDLES.ui.export.currentMode;
        outPath = HANDLES.ui.export.outPath.Value;

        if strlength(outPath) == 0
            HANDLES.ui.export.status.Text = "Please select an output folder.";
            return
        end

        switch mode
            case "nc"
                
                HANDLES.ui.export.status.Text = "Running .nc export...";
                drawnow
                ww_export_tracks_nc()
                HANDLES.ui.export.status.Text = ".nc export complete.";

            case "xml"
                
                HANDLES.ui.export.status.Text = "Running .xml export...";
                drawnow
                ww_export_tracks_xml()
                HANDLES.ui.export.status.Text = ".xml export complete.";
        end
    end

end