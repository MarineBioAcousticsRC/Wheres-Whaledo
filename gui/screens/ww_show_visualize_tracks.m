function ww_show_visualize_tracks()

% ww_show_visualize_tracks()
%
% selection screen for visualizing tracks

global PARAMS HANDLES

ww_clear_HANDLES_ui_content();
HANDLES.fig.main.Name = PARAMS.project.Software + " v" + PARAMS.project.Version + ...
    " - " + PARAMS.project.ProjectName + " Visualize Cleaned Tracks";

% ---- root layout ----
root = uigridlayout(HANDLES.ui.content,[2 1]);
root.RowHeight = {40,'1x'};
root.ColumnWidth = {'1x'};
root.Padding = [20 20 20 20];
root.RowSpacing = 12;

% ---- top bar ----
topbar = uigridlayout(root,[1 4]);
topbar.Layout.Row = 1;
topbar.ColumnWidth = {160,220,'1x',1};
topbar.Padding = [0 0 0 0];

HANDLES.ui.workflow.btnHome = uibutton(topbar,'push', ...
    'Text',"← Project Workflow", ...
    'FontSize',12, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn', @(~,~) ww_show_workflow());
HANDLES.ui.workflow.btnHome.Layout.Row = 1;
HANDLES.ui.workflow.btnHome.Layout.Column = 1;

% ---- main content ----
main = uigridlayout(root,[3 2]);
main.Layout.Row = 2;
main.RowHeight = {60,40,'1x'};
main.ColumnWidth = {'1x','1x'};
main.Padding = [0 0 0 0];
main.RowSpacing = 12;
main.ColumnSpacing = 18;

% ---- title ----
HANDLES.ui.viz.title = uilabel(main, ...
    'Text',"Visualize Cleaned Tracks", ...
    'FontSize',24, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
HANDLES.ui.viz.title.Layout.Row = 1;
HANDLES.ui.viz.title.Layout.Column = [1 2];

% ---- column headers ----
HANDLES.ui.viz.colTitleDeploy = uilabel(main, ...
    'Text',"Visualize tracks across a deployment", ...
    'FontSize',16, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
HANDLES.ui.viz.colTitleDeploy.Layout.Row = 2;
HANDLES.ui.viz.colTitleDeploy.Layout.Column = 1;

HANDLES.ui.viz.colTitleEnc = uilabel(main, ...
    'Text',"Visualize tracks within individual encounters", ...
    'FontSize',16, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
HANDLES.ui.viz.colTitleEnc.Layout.Row = 2;
HANDLES.ui.viz.colTitleEnc.Layout.Column = 2;

% -------------------------------------------------------------------------
% left column: deployment plots
% -------------------------------------------------------------------------
deployPanel = uipanel(main);
deployPanel.Layout.Row = 3;
deployPanel.Layout.Column = 1;

deploy = uigridlayout(deployPanel,[8 4]);
deploy.Padding = [15 15 15 15];
deploy.RowSpacing = 10;
deploy.ColumnSpacing = 10;
deploy.ColumnWidth = {200,'1x','1x','1x'};
deploy.RowHeight = {36,36,36,36,36,36,'1x',44};

% row 1: checkboxes for figure type
lbl = uilabel(deploy,'Text',"Plot type:",'HorizontalAlignment','right');
lbl.Layout.Row = 1;
lbl.Layout.Column = 1;

HANDLES.ui.viz.depSpaghetti = uicheckbox(deploy, ...
    'Text',"Spaghetti plot", ...
    'Value',true);
HANDLES.ui.viz.depSpaghetti.Layout.Row = 1;
HANDLES.ui.viz.depSpaghetti.Layout.Column = 2;

HANDLES.ui.viz.depDensity = uicheckbox(deploy, ...
    'Text',"Track density heatmap", ...
    'Value',false,...
    'ValueChangedFcn',@onToggleDensity);
HANDLES.ui.viz.depDensity.Layout.Row = 1;
HANDLES.ui.viz.depDensity.Layout.Column = 3;

% row 2: path to cleaned encounters
lbl = uilabel(deploy,'Text',"Path to cleaned encounters:",'HorizontalAlignment','right');
lbl.Layout.Row = 2;
lbl.Layout.Column = 1;

if isfolder(PARAMS.projectSaveFolder+"\cleaned_encounters")
    HANDLES.ui.viz.inPath = uieditfield(deploy,'text', ...
        'Value',PARAMS.projectSaveFolder+"\cleaned_encounters");
else
    HANDLES.ui.viz.inPath = uieditfield(deploy,'text', ...
        'Placeholder',"Choose or type a folder path...");
end
HANDLES.ui.viz.inPath.Layout.Row = 2;
HANDLES.ui.viz.inPath.Layout.Column = [2 3];

HANDLES.ui.viz.btnBrowseCleaned = uibutton(deploy,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn', @(btn,evt) onBrowseFolder(btn,evt,HANDLES.ui.viz.inPath));
HANDLES.ui.viz.btnBrowseCleaned.Layout.Row = 2;
HANDLES.ui.viz.btnBrowseCleaned.Layout.Column = 4;

% row 3: separate by species or all tracks on the same figure
lbl = uilabel(deploy,'Text',"Species plotting:",'HorizontalAlignment','right');
lbl.Layout.Row = 3;
lbl.Layout.Column = 1;

HANDLES.ui.viz.sepSp = uidropdown(deploy, ...
    'Items',{'Separate by species','Combine all species'}, ...
    'Value','Separate by species');
HANDLES.ui.viz.sepSp.Layout.Row = 3;
HANDLES.ui.viz.sepSp.Layout.Column = [2 4];

% row 4
lbl = uilabel(deploy,'Text',"Select colormap:",'HorizontalAlignment','right');
lbl.Layout.Row = 4;
lbl.Layout.Column = 1;

HANDLES.ui.viz.colormap = uidropdown(deploy, ...
    'Items',{'dense','thermal','haline','solar','ice','gray','deep','algae','matter','turbid','speed','amp','tempo','rain'}, ...
    'Value','dense');
HANDLES.ui.viz.colormap.Layout.Row = 4;
HANDLES.ui.viz.colormap.Layout.Column = [2 4];

% row 5
lbl = uilabel(deploy,'Text',"Bathymetry contour step (m):",'HorizontalAlignment','right');
lbl.Layout.Row = 5;
lbl.Layout.Column = 1;

HANDLES.ui.viz.cStep = uieditfield(deploy,'text', ...
    'Value','25');
HANDLES.ui.viz.cStep.Layout.Row = 5;
HANDLES.ui.viz.cStep.Layout.Column = [2 4];

% row 5: bin size for density (if selected)
HANDLES.ui.viz.lblBinDen = uilabel(deploy, ...
    'Text',"Density bin size (m):", ...
    'HorizontalAlignment','right');
HANDLES.ui.viz.lblBinDen.Layout.Row = 6;
HANDLES.ui.viz.lblBinDen.Layout.Column = 1;

HANDLES.ui.viz.binDen = uieditfield(deploy,'text', ...
    'Value',"100");
HANDLES.ui.viz.binDen.Layout.Row = 6;
HANDLES.ui.viz.binDen.Layout.Column = [2 4];
% hide until movie box is selected
HANDLES.ui.viz.lblBinDen.Visible = 'off';
HANDLES.ui.viz.binDen.Visible = 'off';

% row 6
HANDLES.ui.viz.lblStatus = uilabel(deploy, ...
    'Text',"Status:", ...
    'HorizontalAlignment','right');
HANDLES.ui.viz.lblStatus.Layout.Row = 7;
HANDLES.ui.viz.lblStatus.Layout.Column = 1;

HANDLES.ui.viz.status = uilabel(deploy, ...
    'Text',"", ...
    'HorizontalAlignment','left');
HANDLES.ui.viz.status.Layout.Row = 7;
HANDLES.ui.viz.status.Layout.Column = [2 4];

% row 8: plot button
HANDLES.ui.viz.btnPlotDeploy = uibutton(deploy,'push', ...
    'Text',"Plot", ...
    'FontSize',14, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn',@onPlotDeploy);
HANDLES.ui.viz.btnPlotDeploy.Layout.Row = 8;
HANDLES.ui.viz.btnPlotDeploy.Layout.Column = [2 3];

% -------------------------------------------------------------------------
% right column: encounter plots
% -------------------------------------------------------------------------
encPanel = uipanel(main);
encPanel.Layout.Row = 3;
encPanel.Layout.Column = 2;

enc = uigridlayout(encPanel,[10 4]);
enc.Padding = [15 15 15 15];
enc.RowSpacing = 10;
enc.ColumnSpacing = 10;
enc.ColumnWidth = {200,'1x','1x','1x'};
enc.RowHeight = {36,36,36,36,36,36,36,36,'1x',44};

% row 1: checkboxes for plot type
lbl = uilabel(enc,'Text',"Plot type:",'HorizontalAlignment','right');
lbl.Layout.Row = 1;
lbl.Layout.Column = 1;

HANDLES.ui.viz.encType = uibuttongroup(enc);
HANDLES.ui.viz.encType.Layout.Row = 1;
HANDLES.ui.viz.encType.Layout.Column = [2 4];

HANDLES.ui.viz.encType.SelectionChangedFcn = @onEncounterTypeChanged;

HANDLES.ui.viz.encSpag = uiradiobutton(HANDLES.ui.viz.encType, ...
    'Text','Spaghetti plot', ...
    'Value',true, ...
    'Position',[10 5 220 22]);

HANDLES.ui.viz.encMovie = uiradiobutton(HANDLES.ui.viz.encType, ...
    'Text','Movie (.mp4)', ...
    'Position',[240 5 120 22]);

% row 2: path to specific encounter
lbl = uilabel(enc,'Text',"Path to selected encounter:",'HorizontalAlignment','right');
lbl.Layout.Row = 2;
lbl.Layout.Column = 1;

HANDLES.ui.viz.whalePath = uieditfield(enc,'text', ...
    'Placeholder',"Choose or type a whale file path...");
HANDLES.ui.viz.whalePath.Layout.Row = 2;
HANDLES.ui.viz.whalePath.Layout.Column = [2 3];

HANDLES.ui.viz.whaleBtnBrowse = uibutton(enc,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn', @(btn,evt) onBrowseFolder(btn,evt,HANDLES.ui.viz.whalePath));
HANDLES.ui.viz.whaleBtnBrowse.Layout.Row = 2;
HANDLES.ui.viz.whaleBtnBrowse.Layout.Column = 4;

% row 3: color by species, whale #, time
lbl = uilabel(enc,'Text',"Color by:",'HorizontalAlignment','right');
lbl.Layout.Row = 3;
lbl.Layout.Column = 1;

HANDLES.ui.viz.encColorBy = uidropdown(enc, ...
    'Items',{'Whale number','Species','Time (normalized per track)'}, ...
    'Value','Whale number');
HANDLES.ui.viz.encColorBy.Layout.Row = 3;
HANDLES.ui.viz.encColorBy.Layout.Column = [2 4];
HANDLES.ui.viz.encColorBy.ValueChangedFcn = @onColorByChanged;

% row 4: bathymetry step
HANDLES.ui.viz.cEncStepLbl = uilabel(enc,'Text',"Bathymetry contour step (m):",'HorizontalAlignment','right');
HANDLES.ui.viz.cEncStepLbl.Layout.Row = 4;
HANDLES.ui.viz.cEncStepLbl.Layout.Column = 1;

HANDLES.ui.viz.cEncStep = uieditfield(enc,'text', ...
    'Value','25');
HANDLES.ui.viz.cEncStep.Layout.Row = 4;
HANDLES.ui.viz.cEncStep.Layout.Column = [2 4];

% row 5: colormap selection
HANDLES.ui.viz.encColorsLabel = uilabel(enc,...
    'Text',"Select colormap:",...
    'HorizontalAlignment','right');
HANDLES.ui.viz.encColorsLabel.Layout.Row = 5;
HANDLES.ui.viz.encColorsLabel.Layout.Column = 1;

HANDLES.ui.viz.encColors = uidropdown(enc, ...
    'Items',{'dense','thermal','haline','solar','ice','gray','deep','algae','matter','turbid','speed','amp','tempo','rain'}, ...
    'Value','dense');
HANDLES.ui.viz.encColors.Layout.Row = 5;
HANDLES.ui.viz.encColors.Layout.Column = [2 4];

onColorByChanged(HANDLES.ui.viz.encColorBy,[]);

% row 6: azimuth view for movie
HANDLES.ui.viz.lblMovieAz = uilabel(enc, ...
    'Text',"Azimuth viewing angles:", ...
    'HorizontalAlignment','right');
HANDLES.ui.viz.lblMovieAz.Layout.Row = 6;
HANDLES.ui.viz.lblMovieAz.Layout.Column = 1;

HANDLES.ui.viz.movieAz = uieditfield(enc,'text', ...
    'Value',"[-20 20]");
HANDLES.ui.viz.movieAz.Layout.Row = 6;
HANDLES.ui.viz.movieAz.Layout.Column = [2 4];

HANDLES.ui.viz.lblMovieAz.Visible = 'off';
HANDLES.ui.viz.movieAz.Visible = 'off';

% row 7: elevation view for movie
HANDLES.ui.viz.lblMovieEl = uilabel(enc, ...
    'Text',"Elevation viewing angles:", ...
    'HorizontalAlignment','right');
HANDLES.ui.viz.lblMovieEl.Layout.Row = 7;
HANDLES.ui.viz.lblMovieEl.Layout.Column = 1;

HANDLES.ui.viz.movieEl = uieditfield(enc,'text', ...
    'Value',"[15 0]");
HANDLES.ui.viz.movieEl.Layout.Row = 7;
HANDLES.ui.viz.movieEl.Layout.Column = [2 4];

HANDLES.ui.viz.lblMovieEl.Visible = 'off';
HANDLES.ui.viz.movieEl.Visible = 'off';

% row 8: output for .mp4 (if selected)
HANDLES.ui.viz.lblMovieOutPath = uilabel(enc, ...
    'Text',"Save path:", ...
    'HorizontalAlignment','right');
HANDLES.ui.viz.lblMovieOutPath.Layout.Row = 8;
HANDLES.ui.viz.lblMovieOutPath.Layout.Column = 1;

HANDLES.ui.viz.movieOutPath = uieditfield(enc,'text', ...
    'Placeholder',"Type a save path for your movie...");
HANDLES.ui.viz.movieOutPath.Layout.Row = 8;
HANDLES.ui.viz.movieOutPath.Layout.Column = [2 4];

% hide until movie box is selected
HANDLES.ui.viz.lblMovieOutPath.Visible = 'off';
HANDLES.ui.viz.movieOutPath.Visible = 'off';
onEncounterTypeChanged([],struct('NewValue',HANDLES.ui.viz.encSpag))

% row 9: status
HANDLES.ui.viz.lblStatus = uilabel(enc, ...
    'Text',"Status:", ...
    'HorizontalAlignment','right');
HANDLES.ui.viz.lblStatus.Layout.Row = 9;
HANDLES.ui.viz.lblStatus.Layout.Column = 1;

HANDLES.ui.viz.encStatus = uilabel(enc, ...
    'Text',"", ...
    'HorizontalAlignment','left');
HANDLES.ui.viz.encStatus.Layout.Row = 9;
HANDLES.ui.viz.encStatus.Layout.Column = [2 4];

% row 10: plot button
HANDLES.ui.viz.btnPlotEnc = uibutton(enc,'push', ...
    'Text',"Plot", ...
    'FontSize',14, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn',@onPlotEncounter);
HANDLES.ui.viz.btnPlotEnc.Layout.Row = 10;
HANDLES.ui.viz.btnPlotEnc.Layout.Column = [2 3];

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

    function onEncounterTypeChanged(~,event)
        if event.NewValue == HANDLES.ui.viz.encMovie
            HANDLES.ui.viz.lblMovieOutPath.Visible = 'on';
            HANDLES.ui.viz.movieOutPath.Visible = 'on';
            HANDLES.ui.viz.encColorBy.Items = {'Whale number','Species'};
            HANDLES.ui.viz.encColorBy.Value = 'Whale number';
            HANDLES.ui.viz.encColors.Visible = 'off';
            HANDLES.ui.viz.encColorsLabel.Visible = 'off';
            HANDLES.ui.viz.cEncStepLbl.Visible = 'off';
            HANDLES.ui.viz.cEncStep.Visible = 'off';
            HANDLES.ui.viz.lblMovieAz.Visible = 'on';
            HANDLES.ui.viz.movieAz.Visible = 'on';
            HANDLES.ui.viz.lblMovieEl.Visible = 'on';
            HANDLES.ui.viz.movieEl.Visible = 'on';
        else
            HANDLES.ui.viz.lblMovieOutPath.Visible = 'off';
            HANDLES.ui.viz.movieOutPath.Visible = 'off';
            HANDLES.ui.viz.encColorBy.Items = { ...
                'Whale number', ...
                'Species', ...
                'Time (normalized per track)'};
            HANDLES.ui.viz.encColorBy.Value = 'Whale number';
            HANDLES.ui.viz.cEncStepLbl.Visible = 'on';
            HANDLES.ui.viz.cEncStep.Visible = 'on';
            HANDLES.ui.viz.lblMovieAz.Visible = 'off';
            HANDLES.ui.viz.movieAz.Visible = 'off';
            HANDLES.ui.viz.lblMovieEl.Visible = 'off';
            HANDLES.ui.viz.movieEl.Visible = 'off';
        end
    end

    function onColorByChanged(src,event)
        showColormap = strcmp(src.Value,'Time (normalized per track)');
        HANDLES.ui.viz.encColors.Visible = showColormap;
        HANDLES.ui.viz.encColorsLabel.Visible = showColormap;
    end

    function onToggleDensity(src,~)
        if src.Value
            HANDLES.ui.viz.lblBinDen.Visible = 'on';
            HANDLES.ui.viz.binDen.Visible = 'on';
        else
            HANDLES.ui.viz.lblBinDen.Visible = 'off';
            HANDLES.ui.viz.binDen.Visible = 'off';
        end
    end

    function onPlotDeploy(~,~)

        if HANDLES.ui.viz.depSpaghetti.Value
            HANDLES.ui.viz.status.Text = "Generating spaghetti figure...";
            drawnow
            % close all
            ww_plot_deployment_spaghetti()
            HANDLES.ui.viz.status.Text = "Spaghetti figure complete.";
        end
        if HANDLES.ui.viz.depDensity.Value
            HANDLES.ui.viz.status.Text = "Generating density figure...";
            drawnow
            % close all
            ww_plot_deployment_density()
            HANDLES.ui.viz.status.Text = "Density figure complete.";
        end
    end

    function onPlotEncounter(~,~)
        if HANDLES.ui.viz.encSpag.Value
            HANDLES.ui.viz.encStatus.Text = "Generating spaghetti figure...";
            drawnow
            % close all
            ww_plot_encounter_spaghetti()
            HANDLES.ui.viz.encStatus.Text = "Spaghetti figure complete.";
        end
        if HANDLES.ui.viz.encMovie.Value
            HANDLES.ui.viz.encStatus.Text = "Generating movie...";
            drawnow
            ww_make_encounter_movie()
            HANDLES.ui.viz.encStatus.Text = "Movie complete.";
        end
    end

end
