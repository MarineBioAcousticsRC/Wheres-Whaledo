function ww_show_workflow()

% ww_show_workflow()
%
% function to display the project workflow screen for a project
% this screen looks the same for every project, but the screens displayed
% by the buttons here are variable depending on your project metadata

global PARAMS HANDLES

ww_clear_HANDLES_ui_content(); % clear old ui handles
HANDLES.fig.main.Name = PARAMS.project.Software + " v" + PARAMS.project.Version + " - " + PARAMS.project.ProjectName + " Project Workflow";

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

% whaledo home button
HANDLES.ui.workflow.btnHome = uibutton(topbar,'push', ...
    'Text',"← Where'sWhaledo Home", ...
    'FontSize', 12, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn', @(~,~) ww_show_home());
HANDLES.ui.workflow.btnHome.Layout.Row = 1;
HANDLES.ui.workflow.btnHome.Layout.Column = 1;

% edit metadata button
HANDLES.ui.workflow.btnEditMeta = uibutton(topbar,'push', ...
    'Text',"Edit project metadata", ...
    'FontSize', 12, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn', @(~,~) ww_show_new_project_wizard("edit"));
HANDLES.ui.workflow.btnEditMeta.Layout.Row = 1;
HANDLES.ui.workflow.btnEditMeta.Layout.Column = 2;

% ---- main area (centered large buttons) ----
main = uigridlayout(root,[1 3]);
main.Layout.Row = 2;
main.ColumnWidth = {'1x', 700, '1x'};   % center column fixed-ish, sides flexible
main.Padding = [0 0 0 0];

center = uigridlayout(main,[7 1]);
center.Layout.Row = 1;
center.Layout.Column = 2;
center.RowHeight = {30, 70, 70, 70, 70, 70, '1x'};  % header + 4 buttons + spacer
center.Padding = [0 0 0 0];
center.RowSpacing = 14;

% title, display project name
HANDLES.ui.workflow.title = uilabel(center, ...
    'Text', PARAMS.project.ProjectName + " - Project Workflow", ...
    'FontSize', 22, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
HANDLES.ui.workflow.title.Layout.Row = 1;

btnStyle = struct('FontSize',18,'FontWeight','bold'); % styling for buttons

% % first button, triggers instrument orientation screen
if ~isfield(PARAMS.project, 'InstrumentOrientationRelPath') % if we don't already have the path to orientations saved
    ww_find_instrument_orientations(); % find where the files live, if anywhere
end
if isfield(PARAMS.project, 'InstrumentOrientationRelPath') % if we've already calculated them
    HANDLES.ui.workflow.btn1 = uibutton(center,'push', ...
        'Text',"1. View or recalculate instrument orientations", ...
        'FontSize', btnStyle.FontSize, ...
        'FontWeight', btnStyle.FontWeight, ...
        'ButtonPushedFcn', @(~,~) ww_show_view_instrument_orientations());
    HANDLES.ui.workflow.btn1.Layout.Row = 2;
else % if we need to calculate them
    HANDLES.ui.workflow.btn1 = uibutton(center,'push', ...
        'Text',"1. Calculate instrument orientations", ...
        'FontSize', btnStyle.FontSize, ...
        'FontWeight', btnStyle.FontWeight, ...
        'ButtonPushedFcn', @(~,~) ww_show_calculate_instrument_orientations());
    HANDLES.ui.workflow.btn1.Layout.Row = 2;
end

% second button, triggers detection screen
HANDLES.ui.workflow.btn2 = uibutton(center,'push', ...
    'Text',"2. Detect and localize signals for encounters", ...
    'FontSize', btnStyle.FontSize, ...
    'FontWeight', btnStyle.FontWeight, ...
    'ButtonPushedFcn', @(~,~) ww_show_detect_localize());
HANDLES.ui.workflow.btn2.Layout.Row = 3;

% third button, triggers track verification screen
HANDLES.ui.workflow.btn3 = uibutton(center,'push', ...
    'Text',"3. Verify localized tracks", ...
    'FontSize', btnStyle.FontSize, ...
    'FontWeight', btnStyle.FontWeight, ...
    'ButtonPushedFcn', @(~,~) ww_show_verify_tracks());
HANDLES.ui.workflow.btn3.Layout.Row = 4;

% fourth button, triggers track export screen
HANDLES.ui.workflow.btn4 = uibutton(center,'push', ...
    'Text',"4. Export cleaned tracks", ...
    'FontSize', btnStyle.FontSize, ...
    'FontWeight', btnStyle.FontWeight, ...
    'ButtonPushedFcn', @(~,~) ww_show_export_tracks());
HANDLES.ui.workflow.btn4.Layout.Row = 5;

% fifth button, triggers track visualization screen
HANDLES.ui.workflow.btn5 = uibutton(center,'push', ...
    'Text',"5. Visualize cleaned tracks", ...
    'FontSize', btnStyle.FontSize, ...
    'FontWeight', btnStyle.FontWeight, ...
    'ButtonPushedFcn', @(~,~) ww_show_visualize_tracks());
HANDLES.ui.workflow.btn5.Layout.Row = 6;

drawnow; % make sure screen updates

end
