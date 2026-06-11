function init_ww_gui

% function to launch the Where'sWhaledo GUI.
% creates ONE content container for all screens, and updates display based on
% user inputs from click buttons on the interface

global PARAMS HANDLES

% close existing GUI, if found
if isfield(HANDLES,'fig') && isfield(HANDLES.fig,'main') && isvalid(HANDLES.fig.main)
    close(HANDLES.fig.main)
end

% open main GUI window and position it in a smart way
HANDLES.fig.main = uifigure('name', PARAMS.software_name + " v" + PARAMS.software_ver); % name this window Where'sWhaledo with version no
screen = get(groot,'ScreenSize'); % grab screen dims
w = PARAMS.ui.wFrac * screen(3); % scale width to screen
h = PARAMS.ui.hFrac * screen(4); % scale height to screen
margin = PARAMS.ui.marginFrac * screen(3); % define margin relative to screen
x = screen(1) + margin; % define x position
y = screen(2) + screen(4) - h - margin; % define y position
HANDLES.fig.main.Position = [x y w h]; % set fig position using params above

% create one content container for all screens
HANDLES.ui.content = uigridlayout(HANDLES.fig.main,[1 1]);
HANDLES.ui.content.Padding = [0 0 0 0];

ww_show_home(); % generate the home screen within the content container