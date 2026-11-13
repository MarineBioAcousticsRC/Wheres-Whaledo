function ww_show_brushTDOA_hydPosInv(Tship, lat, lon, Txwav, TDOA, shipTDOA, prevBrush)

% ww_show_brushTDOA_hydPosInv(Tship, lat, lon, Txwav, TDOA, shipTDOA)
%   brush ship TDOAs built from the ship track and cross-correlation output
% ww_show_brushTDOA_hydPosInv([], [], [], [], [], [], prevBrush)
%   resume from a previously saved brushing (prevBrush), e.g. the struct
%   saved in PARAMS.project.InstrumentOrientationParams.(instrument)

global PARAMS HANDLES
ww_clear_HANDLES_ui_content();

HANDLES.fig.main.Name = PARAMS.project.Software + " v" + PARAMS.project.Version + ...
    " - " + PARAMS.project.ProjectName + " BrushTDOA";

% build params for brushing on top of ship TDOA params, or resume from a
% previous brushing without rebuilding
if nargin >= 7 && ~isempty(prevBrush)
    TDOAbrush = prevBrush;
else
    TDOAbrush = ww_build_TDOAbrush(Tship, lat, lon, Txwav, TDOA, shipTDOA);
end
setappdata(HANDLES.fig.main,'TDOAbrush',TDOAbrush); % store with figure so callbacks can access

% ---- build screen ----
gl = uigridlayout(HANDLES.ui.content,[3 1]);
gl.RowHeight = {80,'1x',90};
gl.Padding = [40 40 40 40];
gl.RowSpacing = 16;
HANDLES.ui.brushScreen.title = uilabel(gl, ...
    'Text',"Brush Ship TDOAs", ...
    'FontSize',28, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
HANDLES.ui.brushScreen.title.Layout.Row = 1;
bodyPanel = uipanel(gl,'BorderType','none');
bodyPanel.Layout.Row = 2;
bodyGrid = uigridlayout(bodyPanel,[1 1]);
bodyGrid.Padding = [40 0 40 0];
HANDLES.ui.newscreen.text = uilabel(bodyGrid, ...
    'Text', ...
    "Step 1: Open the Brush TDOA window and brush any obvious outliers." + newline +  ...
    "Click 'Delete brushed' (top of that window) to remove brushed points, or 'Auto-remove' to drop the worst fits." + newline + ...
    "The hydrophone spacings for the points you keep are shown at the top of that window." + newline + newline + ...
    "Step 2: Click Save to compute final hydrophone geometry and export parameters." + newline, ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','center', ...
    'WordWrap','on', ...
    'FontSize',16);
btnRow = uigridlayout(gl,[1 7]);
btnRow.Layout.Row = 3;
btnRow.ColumnWidth = {'1x',220,20,220,20,220,'1x'};
btnRow.Padding = [0 0 0 0];
HANDLES.ui.brushScreen.btnCancel = uibutton(btnRow, ...
    'Text',"Cancel", ...
    'FontSize',16, ...
    'ButtonPushedFcn',@onCancel);
HANDLES.ui.brushScreen.btnCancel.Layout.Column = 2;
HANDLES.ui.brushScreen.btnBrush = uibutton(btnRow, ...
    'Text',"Open Brush Window", ...
    'FontSize',16, ...
    'ButtonPushedFcn',@onOpenBrush);
HANDLES.ui.brushScreen.btnBrush.Layout.Column = 4;
HANDLES.ui.brushScreen.btnSave = uibutton(btnRow, ...
    'Text',"Save & Continue", ...
    'FontSize',16, ...
    'Enable','off', ...                   % enabled after brushing
    'ButtonPushedFcn',@onSaveContinue);
HANDLES.ui.brushScreen.btnSave.Layout.Column = 6;
HANDLES.ui.brushScreen.status = uilabel(gl, ...
    'Text',"", ...
    'HorizontalAlignment','center');

% ---------- callback functions ----------
    function onOpenBrush(~,~) % to open TDOA GUI
        T = getappdata(HANDLES.fig.main,'TDOAbrush');

        ww_run_brushTDOA(T);  % open/refresh figure, returns immediately

        HANDLES.ui.brushScreen.btnSave.Enable = 'on';
        HANDLES.ui.newscreen.text.Text = ...
            "Brush window opened. Brush points, then click 'Delete brushed' or 'Auto-remove' at the top of that window." + newline + ...
            "When you're done, click Save & Continue here.";
    end

    function onCancel(~,~) % leave without saving any brushing changes
        figB = findall(0,'Type','figure','Name','Brush TDOA');
        if ~isempty(figB), close(figB); end
        if isfield(PARAMS.project,'InstrumentOrientationRelPath') && ...
                ~isempty(dir(PARAMS.projectSaveFolder + PARAMS.project.InstrumentOrientationRelPath + "\*harp4chParams.mat"))
            ww_show_view_instrument_orientations(); % back to existing orientations
        else
            ww_show_workflow(); % nothing saved yet
        end
    end

    function onSaveContinue(~,~)

        % if the brush window exists, grab brushed data over unbrushed
        figB = findall(0,'Type','figure','Name','Brush TDOA');
        if ~isempty(figB) && isvalid(figB)
            Tb = getappdata(figB,'TDOAbrush');
            if ~isempty(Tb)
                T = Tb;
            else
                T = getappdata(HANDLES.fig.main,'TDOAbrush');
            end
        else
            T = getappdata(HANDLES.fig.main,'TDOAbrush');
        end

        % calculate final outputs
        T = ww_calcFinalH_fromBrush(T); % the math happens here
        H = T.H;
        recLoc = [T.InstrumentLocation.Lat_DegN T.InstrumentLocation.Lon_DegE T.InstrumentLocation.Depth_m];
        recPos = T.recPos;
        CI95 = T.CI95;
        stdev = T.stdev;
        c = T.SoundSpeed_ms;

        save(PARAMS.projectSaveFolder + PARAMS.project.InstrumentOrientationRelPath + "\" + T.InstrumentName + "_harp4chParams.mat", 'H','recLoc','recPos','CI95','c','stdev');
        close('Brush TDOA')

        % save params used here
        PARAMS.project.InstrumentOrientationParams.(T.InstrumentName) = T; project = PARAMS.project;
        save(PARAMS.projectSaveFolder + PARAMS.project.ConfigRelFilePath,'project')

        % Move to next screen
        ww_show_view_instrument_orientations();

    end
end

function [TDOAbrush] = ww_build_TDOAbrush(Tship, lat, lon, Txwav, TDOA, shipTDOA)

global PARAMS HANDLES

% define some params
TDOAbrush = shipTDOA; % populate saved params forward
TDOAbrush.nPairs = size(TDOA,2); % how many hydrophone pairs do we have?
% get cartesian position of ship in relation to receiver:
[x, y] = ww_convert_latlon2xy_wgs84(lat, lon, TDOAbrush.InstrumentLocation.Lat_DegN, TDOAbrush.InstrumentLocation.Lon_DegE);
d = TDOAbrush.InstrumentLocation.Depth_m; if d>0, d = d*-1; end
R = sqrt(x.^2 + y.^2 + d.^2); % distance between ship and hydrophone
travelTime = seconds(R/TDOAbrush.SoundSpeed_ms); % estimate of travel time between ship and hydrophone
Tship = Tship + travelTime;

% time frame for analysis
t1 = max([Tship(1), Txwav(1)]);
t2 = min([Tship(end), Txwav(end)]);
I = find(Txwav>=t1 & Txwav<=t2); % Find indices where there are overlapping ship and acoustic time stamps
TDOAbrush.t = Txwav(I); % time vector used for interpolation and inversions
TDOAbrush.TDOA = TDOA(I, :);

% Get interpolated ship positions (interpolated to match acoustic time
% stamps)
xi = interp1(Tship, x, TDOAbrush.t);
yi = interp1(Tship, y, TDOAbrush.t);
zi = ones(size(xi)).*abs(TDOAbrush.InstrumentLocation.Depth_m); % positive zi since ship is about hydrophone
Ri = sqrt(xi.^2 + yi.^2 + zi.^2); % distance between ship and hydrophone

% Set up matrices for inversion:
% NOTE: a simpler inversion is used for the brushing GUI portion, where the
% H matrix is solved for using H = S\D. For the final hydrophone positions
% and H matrix, a more precise inversion is used which solves only for the
% hydrophone positions.
if size(xi, 1) == 1
    TDOAbrush.S = ([xi.', yi.', zi.'])./Ri.'; % unit vector pointing from hydrophone to ship
elseif size(xi, 1)>1
    TDOAbrush.S = ([xi, yi, zi])./Ri; % unit vector pointing from hydrophone to ship
end
TDOAbrush.H = (-TDOAbrush.S\(TDOAbrush.TDOA.*TDOAbrush.SoundSpeed_ms)).'; % initial H matrix estimate
% Calculate expected TDOA based on ship locations and assumed H Matrix
TDOAbrush.TDOAexp = -(TDOAbrush.S*TDOAbrush.H.')./TDOAbrush.SoundSpeed_ms;

end

function ww_run_brushTDOA(TDOAbrush)

% ww_run_brush_TDOA
%
% nested helper function, opens another figure for brushing ship TDOAs.
% Points are removed with buttons at the top of the figure. In recent
% MATLAB releases the brush tool swallows key presses (the undocumented
% workaround used before stopped working around R2019b), so the d/a keys
% are kept only as shortcuts where they still get through.

global PARAMS HANDLES

fig = findall(0, 'Type', 'figure', 'Name', 'Brush TDOA');
if isempty(fig) || ~isvalid(fig)
    fig = figure('Name','Brush TDOA','NumberTitle','off', ...
        'Units','normalized','OuterPosition',[0.05 0.07 0.9 0.86]);
else
    figure(fig); clf(fig);
end
setappdata(fig,'TDOAbrush',TDOAbrush);

for np = 1:TDOAbrush.nPairs
    ax = subplot(TDOAbrush.nPairs,1,np,'Parent',fig);
    plot(ax, TDOAbrush.t, TDOAbrush.TDOA(:,np), '.', 'Tag','observed'); hold(ax,'on')
    plot(ax, TDOAbrush.t, TDOAbrush.TDOAexp(:,np), '.', 'Tag','expected'); hold(ax,'off')
    ax.UserData = np; % hydrophone pair shown in this axes
    ylabel(ax, ['pair' num2str(np)])
    grid(ax,'on')
    % no datetick: t is datetime, so the axis formats its own time ticks
end
xlabel(ax,'Time')
legend(ax,'observed','expected')

% buttons for removing points (these work while the brush tool is active)
uicontrol(fig,'Style','pushbutton','String',"Delete brushed (d)", ...
    'Units','normalized','Position',[0.01 0.955 0.18 0.035], ...
    'Callback',@(~,~) deleteBrushed(fig));
uicontrol(fig,'Style','pushbutton','String',"Auto-remove (a)", ...
    'Units','normalized','Position',[0.20 0.955 0.18 0.035], ...
    'Callback',@(~,~) autoRemoveInFig(fig));

% live readout of the hydrophone spacings for the points currently kept
uicontrol(fig,'Style','text','Tag','spacingText','String',"", ...
    'Units','normalized','Position',[0.40 0.952 0.59 0.035], ...
    'HorizontalAlignment','left','FontSize',10, ...
    'BackgroundColor',get(fig,'Color'));
ww_update_spacing_text(fig, TDOAbrush);

% key shortcuts: set before brush mode turns on, so the mode hands them
% back when the brush tool is switched off
set(fig,'KeyPressFcn',@keyPressCallback);
brush(fig,'on')

% older releases: let key presses through while brushing (undocumented,
% fails silently in recent releases, hence the buttons above)
ws = warning('off','all');
try
    hManager = uigetmodemanager(fig);
    [hManager.WindowListenerHandles.Enabled] = deal(false);
    set(fig,'WindowKeyPressFcn',[]);
    set(fig,'KeyPressFcn',@keyPressCallback);
catch
end
warning(ws);

figure(fig); % bring it forward

end

function keyPressCallback(source,eventdata)

% keyPressCallback
%
% nested helper function, keyboard shortcuts for the brushTDOA window

switch eventdata.Key
    case 'd'
        deleteBrushed(source);
    case 'a'
        autoRemoveInFig(source);
    case {'return','enter'}
        uiresume(source);
end
end

function deleteBrushed(fig)

% deleteBrushed
%
% nested helper function: remove every brushed point (in any pair's panel)
% from all pairs, re-estimate H, and refresh the plots

TDOAbrush = getappdata(fig,'TDOAbrush');

Irem = [];
brushLines = findobj(fig,'Tag','observed','-or','Tag','expected');
for k = 1:numel(brushLines)
    bd = brushLines(k).BrushData;
    if ~isempty(bd)
        Irem = [Irem, find(any(bd ~= 0, 1))]; %#ok<AGROW>
    end
end
Irem = unique(Irem);
if isempty(Irem), return; end

TDOAbrush.TDOA(Irem,:) = [];
TDOAbrush.t(Irem)      = [];
TDOAbrush.S(Irem,:)    = [];

c = TDOAbrush.SoundSpeed_ms;
TDOAbrush.H = (-TDOAbrush.S\(TDOAbrush.TDOA.*c)).';
TDOAbrush.TDOAexp = -(TDOAbrush.S*TDOAbrush.H.')./c;

setappdata(fig,'TDOAbrush',TDOAbrush);
ww_update_brush_plots(fig, TDOAbrush);

end

function autoRemoveInFig(fig)

% autoRemoveInFig
%
% nested helper function: run auto-remove on the figure's data

set(fig,'Pointer','watch'); drawnow;
TDOAbrush = autoRemove(getappdata(fig,'TDOAbrush'), fig);
setappdata(fig,'TDOAbrush',TDOAbrush);
set(fig,'Pointer','arrow');

end

function ww_update_brush_plots(fig, TDOAbrush)

% ww_update_brush_plots
%
% nested helper function: redraw observed/expected TDOAs and clear brushing

axs = findobj(fig,'Type','axes');
for k = 1:numel(axs)
    np = axs(k).UserData;
    if isempty(np), continue; end
    set(findobj(axs(k),'Tag','observed'), 'XData',TDOAbrush.t, 'YData',TDOAbrush.TDOA(:,np), 'BrushData',[]);
    set(findobj(axs(k),'Tag','expected'), 'XData',TDOAbrush.t, 'YData',TDOAbrush.TDOAexp(:,np), 'BrushData',[]);
end
ww_update_spacing_text(fig, TDOAbrush);
drawnow

end

function ww_update_spacing_text(fig, TDOAbrush)

% ww_update_spacing_text
%
% nested helper function: show the hydrophone spacings the final inversion
% gives for the points currently kept, so a brushing can be judged before
% saving

h = findobj(fig,'Tag','spacingText');
if isempty(h), return; end
try
    F = ww_calcFinalH_fromBrush(TDOAbrush);
    dh = sqrt(sum(F.H.^2, 2));
    ci = sqrt(sum(F.CI95.^2));
    h.String = sprintf(['Spacing (m)   1-2: %.3f   1-3: %.3f   1-4: %.3f   ' ...
        '2-3: %.3f   2-4: %.3f   3-4: %.3f   (±%.3f, n = %d)'], dh, ci, numel(TDOAbrush.t));
catch
    h.String = "Spacing: not available for the current points";
end

end

function TDOAbrush = autoRemove(TDOAbrush, fig)

% autoRemove
%
% nested helper function to automatically clean

global PARAMS HANDLES

maxIter = floor(length(TDOAbrush.t)/4);

err = abs(TDOAbrush.TDOA - TDOAbrush.TDOAexp);
errstd = std(err);

i = 0;
while max(errstd)>0.01e-3 && i<maxIter
    i = i+1;
    [~, indMax] = max(err,[],1);
    idx = mode(indMax);

    TDOAbrush.TDOA(idx,:) = [];
    TDOAbrush.t(idx)      = [];
    TDOAbrush.S(idx,:)    = [];

    c = TDOAbrush.SoundSpeed_ms;
    TDOAbrush.H = (-TDOAbrush.S\(TDOAbrush.TDOA.*c)).';
    TDOAbrush.TDOAexp = -(TDOAbrush.S*TDOAbrush.H.')./c;

    err = abs(TDOAbrush.TDOA - TDOAbrush.TDOAexp);
    errstd = std(err);
end

ww_update_brush_plots(fig, TDOAbrush);

end

function TDOAbrush = ww_calcFinalH_fromBrush(TDOAbrush)

% nested helper function to calculate final H matrix, with some comments on
% the math from Eric:
%
% This inverts for the optimal position of each hydrophone, rather than the
% H matrix. It's a little more involved and I'm not sure how to explain
% the process in code comments.
%
% The goal is to solve the equation:
% hpos = inv(G'*Rinv*G)*G'*Riv*D
% hpos are the hydrophone positions of h2, h3, and h4 (h1=<0,0,0>)
% stacked in a 9x1 vector;
% D = TDOA*c, or the distance traveled by the wave between receivers
% G are the vectors pointing towards the ship
%
% Example of the math:
% the forward problem for hydrophone pair h2-h3 is:
% d = -s*h
% where d = TDOA*c for that pair, h = h2-h3, and s=unit vector pointing
% towards ship. This breaks out into:
% d = -(h2x-h3x)*sx - (h2y-h3y)*sy - (h2z-h3z)*sz
%   = -h2x*sx + h3x*sx - h2y*sy + h3y*sy - h2z*sz + h3z*sz
% This can be rewritten as a vector g containing the s vector, and a vector
% hpos containing the hydrophone coordinates (where h1=<0,0,0>).
% hpos = [h2x, h2y, h2z, h3x, h3y, h3z, h4x, h4y, h4z];
% g = [-sx, -sy, -sz, sx, sy, sz, 0, 0, 0];
% d = hpos*g will solve the same algebraic problem as d=-s*h
%
% So, the TDOAs are reshaped from an Nx6 matrix into an N*6x1 matrix, where
% the 1st, 7th, 13th, etc elements are for pair h1-h2, the 2nd, 8th, and
% 14th are for h1-h3, and so on.
% G becomes a N*6 x 9 matrix of s as shown with g.

global PARAMS HANDLES

G = zeros(length(TDOAbrush.t)*6, 9);

Ni = 1:6:(length(TDOAbrush.t)*6); % rows corresponding to h1-h2

% pair 1 (h1-h2), where h1=<0,0,0>
G(Ni, [1,2,3]) = TDOAbrush.S;
D(Ni) = TDOAbrush.TDOA(:, 1).*TDOAbrush.SoundSpeed_ms;

% pair 2 (h1-h3), where h1=<0,0,0>
G(Ni+1, [4,5,6]) = TDOAbrush.S;
D(Ni+1) = TDOAbrush.TDOA(:, 2).*TDOAbrush.SoundSpeed_ms;

% pair 3 (h1-h4), where h1=<0,0,0>
G(Ni+2, [7,8,9]) = TDOAbrush.S;
D(Ni+2) = TDOAbrush.TDOA(:, 3).*TDOAbrush.SoundSpeed_ms;

% pair 4 (h2-h3), where h1=<0,0,0>
G(Ni+3, [1,2,3]) = -TDOAbrush.S;
G(Ni+3, [4,5,6]) = TDOAbrush.S;
D(Ni+3) = TDOAbrush.TDOA(:, 4).*TDOAbrush.SoundSpeed_ms;

% pair 5 (h2-h3), where h1=<0,0,0>
G(Ni+4, [1,2,3]) = -TDOAbrush.S;
G(Ni+4, [7,8,9]) = TDOAbrush.S;
D(Ni+4) = TDOAbrush.TDOA(:, 5).*TDOAbrush.SoundSpeed_ms;

% pair 6 (h3-h4), where h1=<0,0,0>
G(Ni+5, [4,5,6]) = -TDOAbrush.S;
G(Ni+5, [7,8,9]) = TDOAbrush.S;
D(Ni+5) = TDOAbrush.TDOA(:, 6).*TDOAbrush.SoundSpeed_ms;

% start doing the inverse
rinv = 1/(TDOAbrush.SoundSpeed_ms*2e-2); % one element in the matrix R^-1
% R^-1 = rinv*I, so apply it as a scalar instead of building a 6N x 6N
% identity matrix (~10 GB for a 1.6 h ship track); same result
GtRinvG = rinv.*(G'*G);

hpos = GtRinvG\(rinv.*(G'*D.'));

% calculate the 95% confidence intervals
Cxx = inv(GtRinvG);
Cxxdiag = diag(Cxx); % autocorrelation
stdev = sqrt(Cxxdiag); % standard deviation

SEM = stdev./sqrt(length(G));

alpha = 1-.95;
ts = tinv([alpha/2, 1-alpha/2], length(G)-1);

CIxyz = hpos + SEM*ts;

h_moves = abs(hpos - CIxyz); % the 95% CI for each hydrophone coordinate.
% It should be the same for every hydrophone, and for above and below each.

CI95 = h_moves(1:3, 1);

% calculate H matrix
H(1, :) = hpos(1:3);                % vector from h1->h2, (i.e. h2-h1 where h1=<0,0,0>)
H(2, :) = hpos(4:6);                % h1->h3
H(3, :) = hpos(7:9);                % h1->h4
H(4, :) = -hpos(1:3) + hpos(4:6);   % h2->h3
H(5, :) = -hpos(1:3) + hpos(7:9);   % h2->h4
H(6, :) = -hpos(4:6) + hpos(7:9);   % h3->h4

TDOAbrush.H = H;
TDOAbrush.recPos(1, :) = [0,0,0];
TDOAbrush.recPos(2, :) = hpos(1:3);
TDOAbrush.recPos(3, :) = hpos(4:6);
TDOAbrush.recPos(4, :) = hpos(7:9);
TDOAbrush.CI95 = CI95;
TDOAbrush.stdev = stdev;

end
