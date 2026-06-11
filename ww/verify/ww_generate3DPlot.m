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
    rotate3d(fig, 'on');    % optional: enable mouse rotation
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
        for wn = 1:numel(whale)
            wloc = whale{wn}.wloc;
            h = scatter3(S.ax, wloc(:,1), wloc(:,2), wloc(:,3)+brushing.h0(3), ...
                24, brushing.params.colorMat(wn+2,:), 'filled');
            h.Parent = S.hWhaleGroup;
        end

        view(S.ax, 3);
        axis(S.ax, 'vis3d');
        drawnow limitrate

end

% -------- save state --------
S.mode = mode;
setappdata(fig,'state3D',S);
end

