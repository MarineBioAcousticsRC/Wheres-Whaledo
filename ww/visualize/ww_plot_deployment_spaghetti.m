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

    % track/encounter counts, total and per species
    nTracks = 0;
    nEnc = 0;
    trackCount = containers.Map('KeyType','char','ValueType','double');
    encCount = containers.Map('KeyType','char','ValueType','double');

    for j = 1:numel(df) % for each encounter

        clear whale % so an encounter with no whale struct doesn't reuse the previous one
        thisEnc = dir(df(j).folder+"\"+df(j).name+"\*whale_struct.mat");
        if ~isempty(thisEnc)
            load(fullfile(thisEnc.folder,thisEnc.name));
        end

        if ~exist('whale','var')
            continue
        end

        % remove empty-table entries (whales with no cross-array
        % localization, e.g. ww_loc3D_DOAintersect_includeCI.m leaves
        % these as a bare table with no variables) so indexing into
        % Species/wlocSmooth/etc. below doesn't error
        whale = whale(~cellfun(@isempty, whale));

        if ~isempty(whale)
            nEnc = nEnc + 1;
        end
        encSpecies = strings(0); % species already counted for this encounter

        for wn = 1:numel(whale) % for each whale

            key = whale{wn}.Species(1); % grab latin species name for this whale
            if ismissing(key) % containers.Map keys can't be a missing string
                key = "NaN";
            end

            % update counts
            nTracks = nTracks + 1;
            if ~isKey(trackCount,key)
                trackCount(key) = 0;
                encCount(key) = 0;
            end
            trackCount(key) = trackCount(key) + 1;
            if ~any(encSpecies == key)
                encCount(key) = encCount(key) + 1;
                encSpecies(end+1) = key;
            end

            % make the figures for this species if they don't exist already
            % figs(key) = [XY figure, Z figure]
            if ~isKey(figs,key)

                fXY = figure('Name',key+" XY");
                hold on
                contour(x, y, z', levels,'black','showtext','on')
                % plot(h1(1),h1(2),'s','markeredgecolor','black','markerfacecolor','black','markersize',6);
                % plot(h2(1),h2(2),'s','markeredgecolor','black','markerfacecolor','black','markersize',6);
                colormap(cmap) % set colormap for tracks
                title(key)
                xlabel('W-E Distance (m)')
                ylabel('S-N Distnace (m)')

                fZ = figure('Name',key+" Z");
                hold on
                colormap(cmap) % set colormap for tracks
                title(key)
                xlabel('Elapsed Time (min)')
                ylabel('Depth (m)')

                figs(key) = [fXY fZ];

            end
            thisFigs = figs(key);

            % plot this whale onto the correct XY figure
            figure(thisFigs(1))
            nTime = cumsum(diff(whale{wn}.TDet))/(whale{wn}.TDet(end)-whale{wn}.TDet(1));
            patch([whale{1,wn}.wlocSmooth(2:end,1);nan], [whale{1,wn}.wlocSmooth(2:end,2);nan],[nTime;nan],'facecolor','none','edgecolor','interp','linewidth',2)

            % plot this whale onto the correct Z figure
            figure(thisFigs(2))
            tElapsed = minutes(whale{wn}.TDet - whale{wn}.TDet(1)); % elapsed time since track start
            % depth = abs(h0(3)) - whale{wn}.wlocSmooth(:,3); % wlocSmooth z is relative to reference depth
            patch([tElapsed(2:end);nan], [whale{wn}.wlocSmooth(2:end,3)+h0(3);nan],[nTime;nan],'facecolor','none','edgecolor','interp','linewidth',2)

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

    % print counts
    fprintf('%d tracks across %d encounters\n', nTracks, nEnc);
    spKeys = keys(trackCount);
    for k = 1:numel(spKeys)
        fprintf('    %s: %d tracks across %d encounters\n', spKeys{k}, trackCount(spKeys{k}), encCount(spKeys{k}));
    end

     % set axis limits
     figVals = values(figs);
     for f = 1:numel(figVals)

         % Z figure
         figure(figVals{f}(2))
         xlim([0 inf])
         cb = colorbar;
         cb.Ticks = [];
         clim([0 1])
         ylabel(cb,'Elapsed Track Time (minutes, start → end)')

         % XY figure
         figure(figVals{f}(1))
         plot(h1(1),h1(2),'s','markeredgecolor','white','markerfacecolor','black','markersize',6);
         plot(h2(1),h2(2),'s','markeredgecolor','white','markerfacecolor','black','markersize',6);
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

    fXY = figure('Name',"XY");
    hold on
    contour(x, y, z',levels,'black','showtext','on');
    colormap(cmap) % set colormap for tracks
    xlabel('W-E Distance (m)')
    ylabel('N-S Distnace (m)')

    fZ = figure('Name',"Z");
    hold on
    colormap(cmap) % set colormap for tracks
    xlabel('Elapsed Time (min)')
    ylabel('Depth (m)')

    % track/encounter counts
    nTracks = 0;
    nEnc = 0;

    for j = 1:numel(df) % for each encounter

        clear whale % so an encounter with no whale struct doesn't reuse the previous one
        thisEnc = dir(df(j).folder+"\"+df(j).name+"\*whale_struct.mat");
        if ~isempty(thisEnc)
            load(fullfile(thisEnc.folder,thisEnc.name));
        end

        if ~exist('whale','var')
            continue
        end

        % remove empty-table entries (whales with no cross-array
        % localization, e.g. ww_loc3D_DOAintersect_includeCI.m leaves
        % these as a bare table with no variables) so indexing into
        % wlocSmooth/etc. below doesn't error
        whale = whale(~cellfun(@isempty, whale));

        % update counts
        nTracks = nTracks + numel(whale);
        if ~isempty(whale)
            nEnc = nEnc + 1;
        end

        for wn = 1:numel(whale) % for each whale

            % plot this whale onto the XY figure
            figure(fXY)
            nTime = cumsum(diff(whale{wn}.TDet))/(whale{wn}.TDet(end)-whale{wn}.TDet(1));
            patch([whale{1,wn}.wlocSmooth(2:end,1);nan], [whale{1,wn}.wlocSmooth(2:end,2);nan],[nTime;nan],'facecolor','none','edgecolor','interp','linewidth',2)

            % plot this whale onto the Z figure
            figure(fZ)
            tElapsed = minutes(whale{wn}.TDet - whale{wn}.TDet(1)); % elapsed time since track start
            patch([tElapsed(2:end);nan], [whale{wn}.wlocSmooth(2:end,3)+h0(3);nan],[nTime;nan],'facecolor','none','edgecolor','interp','linewidth',2)

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

    % print counts
    fprintf('%d tracks across %d encounters\n', nTracks, nEnc);

    % Z figure
    figure(fZ)
    xlim([0 inf])
    cb = colorbar;
    cb.Ticks = [];
    clim([0 1])
    ylabel(cb,'Elapsed Track Time (minutes, start → end)')

    % XY figure
    figure(fXY)
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


