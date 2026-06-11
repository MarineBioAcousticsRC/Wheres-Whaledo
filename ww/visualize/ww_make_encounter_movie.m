function ww_make_encounter_movie()

% ww_make_encounter_movie()
%
% make 3D encounter movie from whale_struct files.

global PARAMS HANDLES brushing

[h0, h1, h2, ~, ~] = ww_instrumentOrientations_to_xy(); hloc = [h1; h2];
[~, ~, z, levels, x, y] = ww_GMRT_bathy(str2num(HANDLES.ui.viz.cEncStep.Value),h0); % get bathymetry data

% start plotting!
df = dir(HANDLES.ui.viz.whalePath.Value+"\*whale_struct.mat");
if ~isempty(df)
    load(fullfile(df.folder,df.name))
else
    fprintf('No whale struct found within selected encounter subfolder.')
    return
end

% movie settings
dt = 1; % seconds between movie frames
extraTime = 180; % seconds after last localization
movieProfile = 'MPEG-4';

az = str2num(HANDLES.ui.viz.movieAz.Value);
el = str2num(HANDLES.ui.viz.movieEl.Value);

viewStart = [az(1) el(1)];
viewEnd   = [az(2) el(2)];

tstart = NaT;
tend = NaT;

if strcmp(HANDLES.ui.viz.encColorBy.Value,'Species')
    firstSp = cellfun(@(t) t.('Species')(1), whale, 'UniformOutput', false);
    unqSpecies = unique([firstSp{:}],'stable');
end

for wn = 1:numel(whale)

    Iuse = find(~isnan(whale{wn}.wlocSmooth(:,1)));

    if isempty(Iuse)
        continue
    end

    tstart = min(tstart,whale{wn}.TDet(Iuse(1)));
    tend = max(tend,whale{wn}.TDet(Iuse(end)));

end

% movie time vector
tplot = (tstart:seconds(dt):tend+seconds(extraTime)).';

% interpolate tracks onto movie time vector
whaleI = cell(size(whale));
gaps = cell(size(whale));

for wn = 1:numel(whale)

    for ndim = 1:3
        whaleI{wn}.wloc(:,ndim) = interp1( ...
            whale{wn}.TDet, ...
            whale{wn}.wlocSmooth(:,ndim), ...
            tplot);
    end

    whaleI{wn}.TDet = tplot;

    [whaleI{wn}.wloc, gaps{wn}] = ww_fill_movie_gaps(whaleI{wn}.wloc);

end

% colors
if strcmp(HANDLES.ui.viz.encColorBy.Value,'Whale number')
    loadParams(PARAMS.path.repo+"\ww\verify\brushing_colors\brushing_pastel")
    colorMat = brushing.params.colorMat;
elseif strcmp(HANDLES.ui.viz.encColorBy.Value,'Species')
    loadParams(PARAMS.path.repo+"\ww\verify\brushing_colors\brushing.params")
    colorMat = brushing.params.colorMat;
end

% axis limits based on tracks
allXYZ = [];

for wn = 1:numel(whaleI)
    allXYZ = [allXYZ; whaleI{wn}.wloc];
end

xyMax = max(abs(allXYZ(:,1:2)),[],'all','omitnan');
xyLim = ceil(xyMax/500)*500;

zSub = z(find(x > xyLim*-1 & x < xyLim),find(y > xyLim*-1 & y < xyLim));

zMin = floor(min([allXYZ(:,3)+h0(3); zSub(:)],[],'omitnan')/10)*10;
zMax = ceil(max([allXYZ(:,3)+h0(3); hloc(:,3)+h0(3)],[],'omitnan')/100)*100;

% view interpolation
viewVec(1,:) = linspace(viewStart(1),viewEnd(1),length(tplot));
viewVec(2,:) = linspace(viewStart(2),viewEnd(2),length(tplot));

% output file
outFile = fullfile(HANDLES.ui.viz.movieOutPath.Value,[df.name(1:end-4) '_movie.mp4']);

v = VideoWriter(outFile,movieProfile);
open(v)

fig = figure('Name',[df.name ' movie']);
set(fig,'Position',[100 100 800 800],'color','white')

for it = 1:length(tplot)

    clf(fig)

    surf(x,y,z', ...
        'EdgeColor','none')

    hold on
    colormap(cmocean('gray'))
    clim([zMin zMax])

    plot3(hloc(:,1),hloc(:,2),hloc(:,3)+h0(3), ...
        'ks', ...
        'markerfacecolor','white', ...
        'markersize',10)

    for wn = 1:numel(whaleI)

        Iuse = find(whaleI{wn}.TDet <= tplot(it));

        if isempty(Iuse)
            continue
        end

        if strcmp(HANDLES.ui.viz.encColorBy.Value,'Whale number')
            cl = wn;
        elseif strcmp(HANDLES.ui.viz.encColorBy.Value,'Species')
            % match back to species color for this whale
            cl = find(strcmp(unqSpecies,whale{wn}.Species(1)));
        end

        xyz = whaleI{wn}.wloc;
        xyz(:,3) = xyz(:,3) + h0(3);

        ww_plot_movie_track_segments( ...
            xyz, ...
            Iuse, ...
            gaps{wn}, ...
            colorMat(cl+2,:), ...
            3)

    end

    axis([-xyLim xyLim -xyLim xyLim zMin zMax])
    xlabel('E-W [m]')
    ylabel('N-S [m]')
    zlabel('Depth [m]')

    pbaspect([1 1 1])
    grid on
    box on

    title({ ...
        strrep(PARAMS.project.DataSourceName,'_',' '), ...
        [num2str(h0(1)) '°N, ' num2str(h0(2)) '°E']...
        [datestr(tplot(it)+years(2000)), ' UTC']}, ...
        'Interpreter','none')

    view(viewVec(:,it).')

    if strcmp(HANDLES.ui.viz.encColorBy.Value,'Species')
        % plot dummy variables for legend
        for j = 1:numel(unqSpecies)
            dum(j) = plot(nan,nan,'color',brushing.params.colorMat(j+2,:),'linewidth',2);
        end
        legend(dum,unqSpecies,'location','southoutside')
    end

    F = getframe(fig);
    writeVideo(v,F);

end

close(v)
fprintf('Saved movie: %s\n',outFile)

end


function [wlocFilled,gaps] = ww_fill_movie_gaps(wloc)

% Fill internal NaN gaps by linear interpolation for dashed plotting.
% Returns gap start/end indices so those intervals can be plotted as dotted lines.

wlocFilled = wloc;
isBad = isnan(wloc(:,1));

d = diff([false; isBad; false]);
gapStarts = find(d == 1);
gapEnds   = find(d == -1) - 1;

gaps = [];

for g = 1:numel(gapStarts)

    s = gapStarts(g);
    e = gapEnds(g);

    % only fill internal gaps with good points on both sides
    if s == 1 || e == size(wloc,1)
        continue
    end

    if any(isnan(wlocFilled(s-1,:))) || any(isnan(wlocFilled(e+1,:)))
        continue
    end

    for ndim = 1:3
        wlocFilled(s:e,ndim) = interp1( ...
            [s-1 e+1], ...
            [wlocFilled(s-1,ndim) wlocFilled(e+1,ndim)], ...
            s:e);
    end

    gaps = [gaps; s e];

end

end


function ww_plot_movie_track_segments(xyz,Iuse,gaps,thisColor,lw)

% Plot solid sections for observed portions and dotted sections for filled gaps.

if isempty(Iuse)
    return
end

Iuse = Iuse(:);
maxIdx = Iuse(end);

if isempty(gaps)

    good = Iuse(~isnan(xyz(Iuse,1)));

    if ~isempty(good)
        plot3(xyz(good,1),xyz(good,2),xyz(good,3), ...
            '-', ...
            'color',thisColor, ...
            'linewidth',lw)
    end

    return
end

breakPts = unique([1; gaps(:); maxIdx]);
breakPts = breakPts(breakPts >= 1 & breakPts <= maxIdx);

for ii = 1:(numel(breakPts)-1)

    idx = breakPts(ii):breakPts(ii+1);

    idx = idx(idx <= maxIdx);

    if isempty(idx)
        continue
    end

    isGap = any(idx(1) >= gaps(:,1) & idx(end) <= gaps(:,2));

    if isGap
        ls = ':';
    else
        ls = '-';
    end

    plot3(xyz(idx,1),xyz(idx,2),xyz(idx,3), ...
        'linestyle',ls, ...
        'color',thisColor, ...
        'linewidth',lw)

end

end