function ww_show_home()

% ww_show_home()
%
% opens the Where'sWhaledo home screen

global PARAMS HANDLES

ww_clear_HANDLES_ui_content(); % clear old ui handles
HANDLES.fig.main.Name = PARAMS.software_name + " v" + PARAMS.software_ver + " Home"; % rename figure screen

% define the layout
HANDLES.ui.home.gl = uigridlayout(HANDLES.ui.content,[4 1]);
gl = HANDLES.ui.home.gl;
gl.RowHeight = {80,'1x',80,50};
gl.Padding = [30 30 30 30];
gl.RowSpacing = 10;

% add text
HANDLES.ui.title = uilabel(gl, ...
    'Text', "Welcome to " + string(PARAMS.software_name) + " v" + string(PARAMS.software_ver) + "!", ...
    'FontSize', 36, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');
HANDLES.ui.title.Layout.Row = 1; % make sure this displays in row 1

% add the Where'sWhaledo logo
wwlogo = fullfile(PARAMS.path.images,"Where'sWhaledo_logo.jpg"); % path in repo to logo png
if exist(wwlogo,'file') % if it found the logo
    HANDLES.ui.wwlogo = uiimage(gl, 'imagesource', wwlogo);
    HANDLES.ui.wwlogo.ScaleMethod = "fit";
else % if we couldn't find the png
    HANDLES.ui.wwlogoMissing = uilabel(gl,'text','Where''sWhaledo logo not found in: ' + string(wwlogo), ...
        'horizontalalignment','center'); % add in some placeholder text
end
if isfield(HANDLES,'ui')
    f = fieldnames(HANDLES.ui); % find ui fields
    HANDLES.ui.(f{end}).Layout.Row = 2;  % find most recently created field, put it in row 2
end

% add in push buttons for creating a new project/loading an existing
% one
HANDLES.ui.btnGrid = uigridlayout(gl,[1,4]); % make two columns for two buttons with empty padding columns
HANDLES.ui.btnGrid.Layout.Row = 3; % put buttons in third row
HANDLES.ui.btnGrid.Padding = [0 0 0 0]; % pad buttons
HANDLES.ui.btnGrid.ColumnSpacing = 12; % define column spacing
HANDLES.ui.btnGrid.ColumnWidth = {'1x', 400, 400, '1x'}; % scale width to screen
HANDLES.ui.btnNew = uibutton(HANDLES.ui.btnGrid,'push', ...
    'Text',"Create New Project", ...
    'FontSize', 24, ...
    'FontWeight','bold',...
    'ButtonPushedFcn', @(~,~) ww_show_new_project_wizard("new"));
HANDLES.ui.btnNew.Layout.Row = 1;
HANDLES.ui.btnNew.Layout.Column = 2;

HANDLES.ui.btnLoad = uibutton(HANDLES.ui.btnGrid,'push', ...
    'Text',"Load Existing Project", ...
    'FontSize', 24, ...
    'FontWeight','bold',...
    'ButtonPushedFcn', @(~,~) ww_show_load_project());
HANDLES.ui.btnLoad.Layout.Row = 1;
HANDLES.ui.btnLoad.Layout.Column = 3;

% add the MBARC logo
mbarclogo = fullfile(PARAMS.path.images,"MBARC_2019.png"); % path in repo to logo png
if exist(mbarclogo,'file') % if it found the logo
    HANDLES.ui.mbarclogo = uiimage(gl, 'imagesource', mbarclogo);
    HANDLES.ui.mbarclogo.ScaleMethod = "fit";
else % if we couldn't find the png
    HANDLES.ui.mbarclogoMissing = uilabel(gl,'text','MBARC logo not found in: ' + string(wwlogo), ...
        'horizontalalignment','center'); % add in some placeholder text
end
if isfield(HANDLES,'ui')
    f = fieldnames(HANDLES.ui); % find ui fields
    HANDLES.ui.(f{end}).Layout.Row = 4;  % find most recently created field, put it in row 2
end

end
