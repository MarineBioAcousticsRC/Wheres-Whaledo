function ww_plot_encounter_spaghetti()

% ww_plot_encounter_spaghetti()
%
% function for plotting a spaghetti plot for a single encounter
% color by species or by whale number

global PARAMS HANDLES brushing

[h0, h1, h2, ~, ~] = ww_instrumentOrientations_to_xy();
[~, ~, z, levels, x, y] = ww_GMRT_bathy(str2num(HANDLES.ui.viz.cEncStep.Value),h0); % get bathymetry data

% start plotting!
df = dir(HANDLES.ui.viz.whalePath.Value+"\*whale_struct.mat");
ranges = zeros(2,2); % preallocate array to save max/min track ranges for adjusting axis limits
if ~isempty(df)
    load(fullfile(df.folder,df.name))
else
    fprintf('No whale struct found within selected encounter subfolder.')
    return
end

% start plotting
f = figure;
contour(x, y, z', levels,'black','showtext','on')
hold on
plot(h1(1),h1(2),'s','markeredgecolor','black','markerfacecolor','black','markersize',6);
plot(h2(1),h2(2),'s','markeredgecolor','black','markerfacecolor','black','markersize',6);
hold on
if strcmp(HANDLES.ui.viz.encColorBy.Value,'Whale number')
    loadParams(PARAMS.path.repo+"\ww\verify\brushing_colors\brushing_pastel")
    for wn = 1:numel(whale)
        plot(whale{wn}.wlocSmooth(:,1),whale{wn}.wlocSmooth(:,2),'Color',brushing.params.colorMat(wn+2,:),...
            'linewidth',2)

        % grab ranges for axis limits later
        thisMax = max(whale{wn}.wlocSmooth);
        thisMin = min(whale{wn}.wlocSmooth);
        if thisMin(1)<ranges(1,1)
            ranges(1,1) = thisMin(1);
        end
        if thisMin(2)<ranges(2,1)
            ranges(2,1) = thisMin(2);
        end
        if thisMax(1)>ranges(1,2)
            ranges(1,2) = thisMax(1);
        end
        if thisMax(2)>ranges(2,2)
            ranges(2,2) = thisMax(2);
        end
    end

    rangeMax = max(abs(ranges),[],'all');
    rangeLims = [ceil(rangeMax/1000)*-1000 ceil(rangeMax/1000)*1000]; % round to nearest kilometer

    ax = findall(f,'Type','axes');
    set(ax,'XLim',rangeLims,'YLim',rangeLims)
    xlabel('W-E Distance (m)')
    ylabel('S-N Distnace (m)')

elseif strcmp(HANDLES.ui.viz.encColorBy.Value,'Species')

    loadParams(PARAMS.path.repo+"\ww\verify\brushing_colors\brushing.params")
    tmp = cellfun(@(t) t.Species(1), whale, 'UniformOutput', false);
    uniqueSpecies = unique([tmp{:}],'stable');

    for wn = 1:numel(whale)
        spcMatch = find(strcmp(whale{wn}.Species(1),uniqueSpecies));
        plot(whale{wn}.wlocSmooth(:,1),whale{wn}.wlocSmooth(:,2),'Color',brushing.params.colorMat(spcMatch+2,:),...
            'linewidth',2)

        % grab ranges for axis limits later
        thisMax = max(whale{wn}.wlocSmooth);
        thisMin = min(whale{wn}.wlocSmooth);
        if thisMin(1)<ranges(1,1)
            ranges(1,1) = thisMin(1);
        end
        if thisMin(2)<ranges(2,1)
            ranges(2,1) = thisMin(2);
        end
        if thisMax(1)>ranges(1,2)
            ranges(1,2) = thisMax(1);
        end
        if thisMax(2)>ranges(2,2)
            ranges(2,2) = thisMax(2);
        end
    end

    % plot dummy variables for legend
    for j = 1:numel(uniqueSpecies)
        dum(j) = plot(nan,nan,'color',brushing.params.colorMat(j+2,:),'linewidth',2);
    end
    
    % restrict ranges
    rangeMax = max(abs(ranges),[],'all');
    rangeLims = [ceil(rangeMax/1000)*-1000 ceil(rangeMax/1000)*1000]; % round to nearest kilometer

    ax = findall(f,'Type','axes');
    set(ax,'XLim',rangeLims,'YLim',rangeLims)
    xlabel('W-E Distance (m)')
    ylabel('S-N Distnace (m)')
    legend(dum,uniqueSpecies)

elseif strcmp(HANDLES.ui.viz.encColorBy.Value,'Time (normalized per track)')

    colormap(cmocean(HANDLES.ui.viz.encColors.Value));

    for wn = 1:numel(whale)
        
        nTime = cumsum(diff(whale{wn}.TDet))/(whale{wn}.TDet(end)-whale{wn}.TDet(1));
        patch([whale{1,wn}.wlocSmooth(2:end,1);nan], [whale{1,wn}.wlocSmooth(2:end,2);nan],[nTime;nan],'facecolor','none','edgecolor','interp','linewidth',2)

        % grab ranges for axis limits later
        thisMax = max(whale{wn}.wlocSmooth);
        thisMin = min(whale{wn}.wlocSmooth);
        if thisMin(1)<ranges(1,1)
            ranges(1,1) = thisMin(1);
        end
        if thisMin(2)<ranges(2,1)
            ranges(2,1) = thisMin(2);
        end
        if thisMax(1)>ranges(1,2)
            ranges(1,2) = thisMax(1);
        end
        if thisMax(2)>ranges(2,2)
            ranges(2,2) = thisMax(2);
        end
    end
    
    % restrict ranges
    rangeMax = max(abs(ranges),[],'all');
    rangeLims = [ceil(rangeMax/1000)*-1000 ceil(rangeMax/1000)*1000]; % round to nearest kilometer

    ax = findall(f,'Type','axes');
    set(ax,'XLim',rangeLims,'YLim',rangeLims)
    xlabel('W-E Distance (m)')
    ylabel('S-N Distnace (m)')
    clim(ax,[0 1]);
    cb = colorbar;
    cb.Ticks = [];
    ylabel(cb,'Normalized Track Time (start → end)')

end