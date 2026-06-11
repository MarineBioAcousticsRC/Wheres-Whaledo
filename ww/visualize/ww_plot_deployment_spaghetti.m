function ww_plot_deployment_spaghetti()

% ww_plot_deployment_spaghetti()
%
% function for plotting a spaghetti plot for the whole deployment
% color by species or combine them all into one figure

global PARAMS HANDLES

[h0, h1, h2, ~, ~] = ww_instrumentOrientations_to_xy();
[~, ~, z, levels, x, y] = ww_GMRT_bathy(str2num(HANDLES.ui.viz.cStep.Value),h0); % get bathymetry data

% start plotting!
df = dir(HANDLES.ui.viz.inPath.Value+"\enc*");
cmap = cmocean(HANDLES.ui.viz.colormap.Value); % cmocean colormaps!
ranges = zeros(2,2); % preallocate array to save max/min track ranges for adjusting axis limits

if strcmp(HANDLES.ui.viz.sepSp.Value,'Separate by species') % if we need to separate by species

    figs = containers.Map('KeyType','char','ValueType','any');

    for j = 1:numel(df) % for each encounter

        thisEnc = dir(df(j).folder+"\"+df(j).name+"\*whale_struct.mat");
        if ~isempty(thisEnc)
            load(fullfile(thisEnc.folder,thisEnc.name));
        end

        for wn = 1:numel(whale) % for each whale

            key = whale{wn}.Species(1); % grab latin species name for this whale

            % make the figure for this species if it doesn't exist already
            if ~isKey(figs,key)

                figs(key) = figure('Name',key);
                hold on
                contour(x, y, z', levels,'black','showtext','on')
                % plot(h1(1),h1(2),'s','markeredgecolor','black','markerfacecolor','black','markersize',6);
                % plot(h2(1),h2(2),'s','markeredgecolor','black','markerfacecolor','black','markersize',6);
                colormap(cmap) % set colormap for tracks
                title(key)
                xlabel('W-E Distance (m)')
                ylabel('S-N Distnace (m)')

            else
                figure(figs(key))
            end

            % plot this whale onto the correct figure
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
    end

     plot(h1(1),h1(2),'s','markeredgecolor','white','markerfacecolor','black','markersize',6);
     plot(h2(1),h2(2),'s','markeredgecolor','white','markerfacecolor','black','markersize',6);

     % set axis limits
     figVals = values(figs);
     for f = 1:numel(figVals)
         figure(figVals{f})
         rangeMax = max(abs(ranges),[],'all');
         rangeLims = [ceil(rangeMax/1000)*-1000 ceil(rangeMax/1000)*1000]; % round to nearest kilometer
         xlim(rangeLims)
         ylim(rangeLims)
         cb = colorbar;
         cb.Ticks = [];
         clim([0 1])
         ylabel(cb,'Normalized Track Time (start → end)')
     end

elseif strcmp(HANDLES.ui.viz.sepSp.Value,'Combine all species') % otherwise put them all on one figure

    figure;
    hold on
    contour(x, y, z',levels,'black','showtext','on');
    colormap(cmap) % set colormap for tracks
    xlabel('W-E Distance (m)')
    ylabel('N-S Distnace (m)')

    for j = 1:numel(df) % for each encounter

        thisEnc = dir(df(j).folder+"\"+df(j).name+"\*whale_struct.mat");
        if ~isempty(thisEnc)
            load(fullfile(thisEnc.folder,thisEnc.name));
        end

        for wn = 1:numel(whale) % for each whale

            % plot this whale onto the correct figure
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
    end

    plot(h1(1),h1(2),'s','markeredgecolor','white','markerfacecolor','black','markersize',6);
    plot(h2(1),h2(2),'s','markeredgecolor','white','markerfacecolor','black','markersize',6);

    % set axis limits
    rangeMax = max(abs(ranges),[],'all');
    rangeLims = [ceil(rangeMax/1000)*-1000 ceil(rangeMax/1000)*1000]; % round to nearest kilometer
    xlim(rangeLims)
    ylim(rangeLims)
    cb = colorbar;
    cb.Ticks = [];
    clim([0 1])
    ylabel(cb,'Normalized Track Time (start → end)')

end

% % set axis limits for all open figures
% % square, round to the nearest 10 m
% rangeMax = max(abs(ranges),[],'all');
% rangeLims = [ceil(rangeMax/1000)*-1000 ceil(rangeMax/1000)*1000]; % round to nearest kilometer
% 
% f = findall(groot,'Type','figure');
% 
% for k = 1:numel(f)-1
%     ax = findall(f(k),'Type','axes');
%     set(ax,'XLim',rangeLims,'YLim',rangeLims)
%     clim(ax,[0 1]);
%     cb = colorbar;
%     cb.Ticks = [];
%     ylabel(cb,'Normalized Track Time (start → end)')
% end
% 


