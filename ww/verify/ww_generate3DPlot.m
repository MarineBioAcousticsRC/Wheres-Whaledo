function ww_generate3DPlot(mode, DET, brushing)
% ww_generate3DPlot(mode, DET)
%
% creates or updates a 3D figure:
%   mode = 'init'     : create/validate figure and axes; does not plot data
%   mode = 'plot'  : update 3D view based on labeled whales
%
% inputs:
%   DET: 1x2 cell array of tables, each with .Spectra and .Species
%   brushing: variable with color map

global PARAMS brushing

% -------- find or create figure --------
fig = findall(0, 'Type', 'figure', 'Name', '3D Positions');
if isempty(fig) || ~isvalid(fig)
    fig = figure('Name', '3D Positions', ...
        'NumberTitle','off', ...
        'MenuBar','none',...
        'Position',brushing.params.pos3D);
end

% -------- load existing state --------
S = [];
if isappdata(fig,'state3D')
    S = getappdata(fig,'state3D');
end

% -------- create graphics if needed --------
needCreate = isempty(S) || ~isfield(S,'ax') || isempty(S.ax) || ~isvalid(S.ax);

if needCreate
    clf(fig);

    S.ax = axes('Parent', fig);
    hold(S.ax,'on');
    grid(S.ax,'on');

    % groups so we can clear whales without touching instruments
    S.hInstGroup  = hggroup('Parent', S.ax);
    S.hWhaleGroup = hggroup('Parent', S.ax);

    [h0, h1, h2, H, c] = ww_instrumentOrientations_to_xy();

    scatter3(S.ax, h1(1), h1(2), h1(3)+h0(3), 24, 'k^', 'filled', 'Parent', S.hInstGroup);
    scatter3(S.ax, h2(1), h2(2), h2(3)+h0(3), 24, 'k^', 'filled', 'Parent', S.hInstGroup);
    zlabel('Depth (m)')
    xlabel('E-W Distance (m)')
    ylabel('N-S Distance (m)')

    view(S.ax, 3);          % default 3D view
    % Modern MATLAB axes have built-in click-drag rotation via the axes'
    % own Interactions property, entirely separate from the legacy mode
    % objects (rotate3d/brush) below -- disable it so those modes are the
    % only interactive behaviors active.
    disableDefaultInteractivity(S.ax);
    % brush-select (drag to select multiple points, same tool the Brush
    % DOA az/el plots use) is the default; 't' toggles over to rotate3d
    % instead, matching Brush DOA's own 'z'/'x' zoom toggle. Brush and
    % rotate3d can't be active at once (both are exclusive MATLAB modes),
    % so only one is ever enabled at a time.
    b = brush(fig);
    b.Enable = 'on';
    r = rotate3d(fig);
    r.Enable = 'off';
    % completing a brush-drag OR a rotate-drag re-enables the mode
    % manager's window listeners as a side effect (same as
    % ww_run_brushDOA.m's own brush setup), which would otherwise
    % silently swallow every keypress after the first drag of either kind
    % -- re-disable them every time either action finishes, not just once
    % here at setup
    b.ActionPostCallback = @local_afterModeAction;
    r.ActionPostCallback = @local_afterModeAction;
    fig.KeyPressFcn = @local_key3D;
    hManager = uigetmodemanager(fig);
    [hManager.WindowListenerHandles.Enabled] = deal(false);
    title(S.ax, "Mode: brush-select");
    axis(S.ax, 'vis3d');    % keeps aspect ratio while rotating

    S.hWhale = gobjects(0);   % handle(s) for whale scatter(s)

    % put these into the global variables so we don't have to recalculate
    brushing.h0 = h0;
    brushing.h1 = h1;
    brushing.h2 = h2;
    brushing.H = H;
    brushing.c = c;
end

% ---- action for modes ----
mode = lower(string(mode));
switch mode
    case "init"
        % nothing else

    case "plot"

        whale = ww_loc3D_DOAintersect_includeCI(DET, brushing);

        % clear ONLY whale graphics
        if isfield(S,'hWhaleGroup') && isgraphics(S.hWhaleGroup)
            delete(allchild(S.hWhaleGroup));
        else
            % fallback if state got stale
            S.hWhaleGroup = hggroup('Parent', S.ax);
        end

        set(S.ax, ...
            'XLimMode','auto','YLimMode','auto','ZLimMode','auto', ...
            'DataAspectRatioMode','auto', ...
            'PlotBoxAspectRatioMode','auto');

        daspect(S.ax,'auto');
        pbaspect(S.ax,'auto');

        % --- plot whales into whale group ---
        % color scheme follows Brush DOA's current toggle (tracked on
        % brushing.colorMode by ww_brushDOA_setColorMode.m), even though
        % whale{wn} is always grouped/associated by whale number
        % regardless of that toggle (see ww_loc3D_DOAintersect_includeCI.m)
        colorMode = "Whale number";
        if isfield(brushing,'colorMode') && ~isempty(brushing.colorMode)
            colorMode = brushing.colorMode;
        end
        if colorMode == "Species label"
            plotColorMat = ww_get_species_colorMat();
        else
            plotColorMat = ww_get_whale_colorMat();
        end

        for wn = 1:numel(whale)
            % skip whales with no cross-array localization yet (empty table, no wloc)
            if isempty(whale{wn}) || ~istable(whale{wn}) || ...
                    ~ismember('wloc', whale{wn}.Properties.VariableNames) || isempty(whale{wn}.wloc)
                continue
            end
            wloc = whale{wn}.wloc;
            if colorMode == "Species label"
                cidx = ww_get_species_color_index(whale{wn}.Species(1));
            else
                cidx = whale{wn}.color(1);
            end
            h = scatter3(S.ax, wloc(:,1), wloc(:,2), wloc(:,3)+brushing.h0(3), ...
                24, plotColorMat(cidx,:), 'filled');
            h.Parent = S.hWhaleGroup;

            % records which array 1/array 2 detections were
            % cross-correlated to produce each plotted point, so
            % local_syncSelectionToBrushDOA can translate a brushed
            % selection here into the matching rows there
            h.UserData = struct('I1', whale{wn}.I1, 'I2', whale{wn}.I2);
        end

        view(S.ax, 3);
        axis(S.ax, 'vis3d');
        drawnow limitrate

end

% -------- save state --------
S.mode = mode;
setappdata(fig,'state3D',S);
end

% ======================================================================
function local_afterModeAction(fig, ~)
% local_afterModeAction
%
% Shared ActionPostCallback for both brush and rotate3d, fired every
% time a brush-drag or a rotate-drag completes. Re-disables the mode
% manager's window listeners (which either mode re-enables as a side
% effect once its action finishes) so 't'/'s' keep working no matter
% which mode you used most recently.

hManager = uigetmodemanager(fig);
[hManager.WindowListenerHandles.Enabled] = deal(false);
fig.KeyPressFcn = @local_key3D;

end

% ======================================================================
function local_key3D(fig, evt)
% local_key3D
%
% 't': toggles between brush-select (default) and rotate3d -- they're
% mutually exclusive MATLAB modes, same as Brush DOA's own 'z'/'x' zoom
% toggle, so only one is ever enabled at a time.
% 's': syncs whatever's currently brush-selected here over to the Brush
% DOA az/el plots (local_syncSelectionToBrushDOA).

switch evt.Key
    case 't'
        r = rotate3d(fig);
        b = brush(fig);
        if strcmp(r.Enable, 'on')
            r.Enable = 'off';
            b.Enable = 'on';
            stateStr = "brush-select";
        else
            b.Enable = 'off';
            r.Enable = 'on';
            stateStr = "rotate";
        end
        ax = findobj(fig, 'Type', 'axes');
        if ~isempty(ax)
            title(ax(1), "Mode: " + stateStr);
        end

    case 's'
        local_syncSelectionToBrushDOA(fig);
end

% once a mode (zoom/pan/rotate3d/brush) is enabled, MATLAB's mode manager
% installs its own window listeners that suppress the figure's own
% KeyPressFcn -- without this, keys would only ever work once (same fix
% ww_run_brushDOA.m uses for its 'z'/'x' zoom toggle)
hManager = uigetmodemanager(fig);
[hManager.WindowListenerHandles.Enabled] = deal(false);
fig.KeyPressFcn = @local_key3D;

end

% ======================================================================
function local_syncSelectionToBrushDOA(fig)
% local_syncSelectionToBrushDOA
%
% Reads whatever points are currently brush-selected (BrushData) across
% all whale scatter series in the 3D plot, looks up the array 1/array 2
% detection rows that were cross-correlated to produce each one (stored
% per-point on each series' UserData by ww_generate3DPlot's "plot" case),
% and selects the union of those rows -- via BrushData, the same
% mechanism the Brush DOA keypress callback reads for "currently
% selected" -- on the Brush DOA az/el plots.

global brushing

if ~isfield(brushing,'hScatter') || numel(brushing.hScatter)~=6 || ~all(isgraphics(brushing.hScatter))
    return
end

S = getappdata(fig, 'state3D');
if isempty(S) || ~isfield(S,'hWhaleGroup') || ~isgraphics(S.hWhaleGroup)
    return
end

bd1 = zeros(1, numel(get(brushing.hScatter(1),'XData')));
bd2 = zeros(1, numel(get(brushing.hScatter(4),'XData')));

whalePts = allchild(S.hWhaleGroup);
for k = 1:numel(whalePts)
    h = whalePts(k);
    if ~isgraphics(h) || isempty(h.BrushData) || ~isstruct(h.UserData)
        continue
    end
    sel = find(h.BrushData ~= 0);
    if isempty(sel)
        continue
    end
    bd1(h.UserData.I1(sel)) = 1;
    bd2(h.UserData.I2(sel)) = 1;
end

for k = 1:3
    set(brushing.hScatter(k), 'BrushData', bd1); % array 1 subplots
end
for k = 4:6
    set(brushing.hScatter(k), 'BrushData', bd2); % array 2 subplots
end

% bring Brush DOA to the front so the newly-selected points are visible
if isfield(brushing,'hFig') && isgraphics(brushing.hFig)
    figure(brushing.hFig);
end
drawnow limitrate

end

