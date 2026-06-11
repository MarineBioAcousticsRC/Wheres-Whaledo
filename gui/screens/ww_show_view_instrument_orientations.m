function ww_show_view_instrument_orientations()

% ww_show_instrument_orientations()
%
% function to open the calculate instrument orientation screen
% the user will be able to view their pre-calculated instrument orientation
% files, and then select to recalculate if they wish to.

global PARAMS HANDLES

% catch if the instrument orientations are messed up
if numel(dir(PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+"\*harp4chParams.mat"))>str2num(extractBetween(PARAMS.project.ArrayOption,1,1))
  uialert(HANDLES.fig.main,"You have more instrument orientations in the folder than defined in your project metadata: "+PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+". Remove extra files before viewing orientations.","Too many instrument orientations");
  return
end

ww_clear_HANDLES_ui_content(); % clear old ui handles
HANDLES.fig.main.Name = PARAMS.project.Software + " v" + PARAMS.project.Version + " - " + PARAMS.project.ProjectName + " View Instrument Orientation";

% root layout: top bar + main content
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

% recalculate positions button
HANDLES.ui.workflow.btnEditMeta = uibutton(topbar,'push', ...
    'Text',"Recalculate instrument orientations", ...
    'FontSize', 12, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn', @(~,~) ww_show_calculate_instrument_orientations());
HANDLES.ui.workflow.btnEditMeta.Layout.Row = 1;
HANDLES.ui.workflow.btnEditMeta.Layout.Column = 2;

% ---- main content: two columns (one for each instrument) ----
array = ww_load_instrument_orientations(); % load instrument orientations
if numel(array) > 2 % if are more than two files in here
    uialert(HANDLES.fig.main,"More than two instrument configuration files found in folder, please remove superfluous files.","Too many files");
    return
end

main = uigridlayout(root,[1 2]);
main.Layout.Row = 2;
main.ColumnWidth = {'1x','1x'};
main.RowHeight = {'1x'};
main.Padding = [0 0 0 0];
main.ColumnSpacing = 16;

% ---- build instrument panels in a loop ----
HANDLES.ui.orient.panel = gobjects(1,2);
HANDLES.ui.orient.ax1   = gobjects(1,2);
HANDLES.ui.orient.ax2   = gobjects(1,2);

for k = 1:numel(array)

    if k <= numel(array) && ~isempty(array{k})
        % Build your per-instrument text inside the loop
        infoText = {
            "File name: " + string(array{k}.FileName)
            "Array configuration: " + string(PARAMS.project.ArrayConfiguration)
            "Sound speed: " + string(array{k}.c) + " m/s"
            "Instrument coordinates:"
            "  Latitude: "  + string(array{k}.recLoc(1)) + "°N"
            "  Longitude: " + string(array{k}.recLoc(2)) + "°E"
            "  Depth: "     + string(array{k}.recLoc(3)) + " m"
            };
    end

    [HANDLES.ui.orient.panel(k), HANDLES.ui.orient.ax1(k), HANDLES.ui.orient.ax2(k)] = ...
        ww_build_instrument_panel(main, k, infoText);

    % plot figures here
    axLoc = HANDLES.ui.orient.ax1(k);   % first plot area in column k
    axDH  = HANDLES.ui.orient.ax2(k);   % second plot area in column k

    % plot 3D array elements
    cla(axLoc);
    hold(axLoc, 'on');
    for np = 1:4
        plot3(axLoc, ...
            array{k}.recPos(np,1), ...
            array{k}.recPos(np,2), ...
            array{k}.recPos(np,3), ...
            '.', 'markersize', 35);
    end
    pairs = nchoosek(1:4, 2); % dashed lines between pairs
    for p = 1:size(pairs,1)
        i = pairs(p,1);
        j = pairs(p,2);
        plot3(axLoc, ...
            array{k}.recPos([i j],1), ...
            array{k}.recPos([i j],2), ...
            array{k}.recPos([i j],3), ...
            'LineStyle',':', ...
            'Color',[0.5 0.5 0.5], ...
            'LineWidth',2);   % dashed black line
    end
    hold(axLoc, 'off');
    legend(axLoc, {'Rec 1','Rec 2','Rec 3','Rec 4'}, 'Location','best');
    title(axLoc, 'Receiver Locations in relation to receiver 1');
    xlabel(axLoc, 'E-W (m)');
    ylabel(axLoc, 'N-S (m)');
    zlabel(axLoc, 'Depth (m)');
    grid(axLoc, 'on');
    view(axLoc, 3);
    axis(axLoc,'equal');
    % axis(axLoc, 'tight');
    % view(axLoc,-45,25);

    % plot distances between hydrophones
    dh = sqrt(sum(array{k}.H.^2, 2));
    dhCI95 = sqrt(sum(array{k}.CI95.^2)); % confidence interval (scalar)

    cla(axDH);
    hold(axDH, 'on');
    errorbar(axDH, 1:6, dh, dhCI95.*ones(size(dh)), dhCI95.*ones(size(dh)), 'linewidth', 1.5,'Color',[0.5 0.5 0.5]);
    plot(axDH, dh, '.', 'markersize', 25,'MarkerFaceColor','black','markeredgecolor','black');
    hold(axDH, 'off');
    title(axDH, 'Distance between hydrophones');
    ylabel(axDH, 'Distance (m)');
    xlabel(axDH, 'Hydrophone pair');
    xticks(axDH, 1:6);
    xticklabels(axDH, {'1-2','1-3','1-4','2-3','2-4','3-4'});
    grid(axDH, 'on');

end

drawnow;

end

function array = ww_load_instrument_orientations()

% ww_load_instrument_orientations
% nested helper function to load in the instrument orientations based
% on the folder specified in the user params
% also load in the metadata into the 

global PARAMS % load global variables

orientationsDir = dir(PARAMS.projectSaveFolder + PARAMS.project.InstrumentOrientationRelPath + "\*harp4chParams.mat"); % find orintation files in specified directory
for j = 1:numel(orientationsDir) % for each file
    array{j} = load(fullfile(orientationsDir(j).folder,orientationsDir(j).name)); % save the data
    array{j}.FileName = orientationsDir(j).name; % save the file name
end

end

function [panel, ax1, ax2] = ww_build_instrument_panel(parent, col, infoText)

% ww_build_instrument_panel()
%
% helper function to build text displays/figures for instrument
% orientations

panel = uipanel(parent, 'Title', "");
panel.Layout.Row = 1;
panel.Layout.Column = col;

gl = uigridlayout(panel, [3 1]);
gl.RowHeight = {110, '3x', '1x'};   % text | plot1 | plot2
gl.Padding = [12 10 12 12];
gl.RowSpacing = 10;

% text (editable off)
txt = uitextarea(gl, ...
    'Value', cellstr(infoText), ...
    'Editable', 'off');
txt.Layout.Row = 1;
txt.Layout.Column = 1;

% axes 1
ax1 = uiaxes(gl);
ax1.Layout.Row = 2;

% axes 2
ax2 = uiaxes(gl);
ax2.Layout.Row = 3;

end
