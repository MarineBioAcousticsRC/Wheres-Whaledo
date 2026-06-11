function ww_plot_deployment_density()

% ww_plot_deployment_density()
%
% function for plotting a track density plot for the whole deployment
% color by species or combine them all into one figure

global PARAMS HANDLES

[h0, h1, h2, ~, ~] = ww_instrumentOrientations_to_xy();
[~, ~, z, levels, x, y] = ww_GMRT_bathy(str2num(HANDLES.ui.viz.cStep.Value),h0); % get bathymetry data

df = dir(HANDLES.ui.viz.inPath.Value + "\enc*");

cmap = cmocean(HANDLES.ui.viz.colormap.Value);
cmap = vertcat([1 1 1],cmap);

% grid settings
binSize = str2num(HANDLES.ui.viz.binDen.Value); % meters
xEdges = -15000:binSize:15000;
yEdges = -15000:binSize:15000;

if strcmp(HANDLES.ui.viz.sepSp.Value,'Separate by species')
    grids = containers.Map('KeyType','char','ValueType','any');
elseif strcmp(HANDLES.ui.viz.sepSp.Value,'Combine all species')
    grdf = zeros(length(yEdges)-1,length(xEdges)-1);
end

for j = 1:numel(df)

    thisEnc = dir(df(j).folder + "\" + df(j).name + "\*whale_struct.mat");

    if isempty(thisEnc)
        fprintf('No whale struct found in %s\n',df(j).name)
        continue
    end

    load(fullfile(thisEnc.folder,thisEnc.name))

    for wn = 1:numel(whale)

        % species key
        key = whale{wn}.Species(1);
       
        % interpolate to 1-second spacing
        tstart = whale{wn}.TDet(1);
        tend   = whale{wn}.TDet(end);
        ti = tstart:seconds(1):tend;

        xi = interp1(whale{wn}.TDet, whale{wn}.wlocSmooth(:,1), ti);
        yi = interp1(whale{wn}.TDet, whale{wn}.wlocSmooth(:,2), ti);

        % bin positions
        xBin = discretize(xi,xEdges);
        yBin = discretize(yi,yEdges);

        good = ~isnan(xBin) & ~isnan(yBin);

        if ~any(good)
            continue
        end

        % one count per occupied bin per whale track
        occupied = unique([yBin(good)' xBin(good)'],'rows');

        grdt = zeros(length(yEdges)-1,length(xEdges)-1);

        for k = 1:size(occupied,1)
            grdt(occupied(k,1),occupied(k,2)) = 1;
        end

        if strcmp(HANDLES.ui.viz.sepSp.Value,'Separate by species')

            if ~isKey(grids,key)
                grids(key) = zeros(length(yEdges)-1,length(xEdges)-1);
            end

            grids(key) = grids(key) + grdt;

        elseif strcmp(HANDLES.ui.viz.sepSp.Value,'Combine all species')

            grdf = grdf + grdt;

        end

    end

    clear whale

end

% plot results
if strcmp(HANDLES.ui.viz.sepSp.Value,'Separate by species')

    speciesKeys = keys(grids);

    for s = 1:numel(speciesKeys)

        key = speciesKeys{s};
        thisGrid = grids(key);

        figure('Name',key)
        h = imagesc(xEdges,yEdges,thisGrid);
        set(gca,'YDir','normal')
        set(h,'AlphaData',thisGrid > 0)

        hold on
        contour(x,y,z',levels,'black','showtext','on')

        plot(h1(1),h1(2),'s', ...
            'markeredgecolor','white', ...
            'markerfacecolor','black', ...
            'markersize',6)

        plot(h2(1),h2(2),'s', ...
            'markeredgecolor','white', ...
            'markerfacecolor','black', ...
            'markersize',6)

        colormap(cmap)
        caxis([1 max(thisGrid,[],'all')]);
        cb = colorbar;
        ylabel(cb,'Number of tracks')

        title(key)
        xlabel('W-E Distance (m)')
        ylabel('S-N Distance (m)')

        axis equal
        [row,col] = find(thisGrid > 0);
        xmin = xEdges(min(col));
        xmax = xEdges(max(col)+1);
        ymin = yEdges(min(row));
        ymax = yEdges(max(row)+1);
        rangeMax = max(abs([xmin xmax ymin ymax]));
        rangeLims = ceil(rangeMax/1000)*[-1000 1000];
        xlim(rangeLims)
        ylim(rangeLims)

    end

elseif strcmp(HANDLES.ui.viz.sepSp.Value,'Combine all species')

    figure
    h = imagesc(xEdges,yEdges,grdf);
    set(gca,'YDir','normal')
    set(h,'AlphaData',grdf > 0)

    hold on
    contour(x,y,z',levels,'black','showtext','on')

    plot(h1(1),h1(2),'s', ...
        'markeredgecolor','white', ...
        'markerfacecolor','black', ...
        'markersize',6)

    plot(h2(1),h2(2),'s', ...
        'markeredgecolor','white', ...
        'markerfacecolor','black', ...
        'markersize',6)

    colormap(cmap)
    caxis([1 max(grdf,[],'all')]);
    cb = colorbar;
    ylabel(cb,'Number of tracks')

    xlabel('W-E Distance (m)')
    ylabel('S-N Distance (m)')

    axis equal
    [row,col] = find(grdf > 0);
    xmin = xEdges(min(col));
    xmax = xEdges(max(col)+1);
    ymin = yEdges(min(row));
    ymax = yEdges(max(row)+1);
    rangeMax = max(abs([xmin xmax ymin ymax]));
    rangeLims = ceil(rangeMax/1000)*[-1000 1000];
    xlim(rangeLims)
    ylim(rangeLims)

end

end