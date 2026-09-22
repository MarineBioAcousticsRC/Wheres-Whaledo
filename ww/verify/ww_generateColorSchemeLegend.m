function ww_generateColorSchemeLegend(brushing, mode, labels, colorIdx)
% ww_generateColorSchemeLegend(brushing, mode, labels, colorIdx)
%
% creates (or updates) a small legend figure that shows color boxes with text.
%
% inputs:
%   brushing : your brushing struct (must contain .params.commandLegendPos)
%   mode     : "whale" or "species" (or any string you want)
%   labels   : string array or cellstr of labels to display (one per color row)
%   colorIdx : (optional) the actual brushing.params.colorMat row for each
%              label, same order/length as labels. Defaults to
%              (1:numel(labels))+2, the sequential whale-number scheme --
%              but for species labels this MUST be passed explicitly,
%              since species colors come from ww_get_species_color_index's
%              persistent first-seen assignment, not label position.
%
% notes:
%   - this function stores handles/state using setappdata(fig,'legendState',S).
%   - call it again with new labels/colorIdx to update without recreating.

    if nargin < 4 || isempty(colorIdx)
        colorIdx = (1:numel(labels)).' + 2;
    end

    % find or create figure
    fig = findall(0, 'Type', 'figure', 'Name', 'Legend of Label Colors');
    if isempty(fig) || ~isvalid(fig)
        fig = figure('Name', 'Legend of Label Colors', ...
            'Position', brushing.params.colorLegendPos, ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none');
    end

    % try to load existing state
    S = [];
    if isappdata(fig,'legendState')
        S = getappdata(fig,'legendState');
    end

    % build legend rows
    nRows = numel(labels);
    M = colorIdx(:);

    % If first time (or handles invalid), create graphics; else update
    needCreate = isempty(S) || ~isfield(S,'colIm') || ~isvalid(S.colIm);

    if needCreate
        clf(fig);

        ax = axes('Parent', fig); 
        ax.XTick = [];
        ax.YTick = [];
        ax.Box = 'on';
        colormap(fig, brushing.params.colorMat);

        % ---- CHANGES DROPPED IN: direct colormap indexing (+2 works) ----
        S.colIm = imagesc(ax, 1, M, M);              % keep your y-positions as M
        S.colIm.CDataMapping = 'direct';             % IMPORTANT
        ax.CLim = [1 size(brushing.params.colorMat,1)]; % IMPORTANT
        % ----------------------------------------------------------------

        axis(ax, 'tight');
        fontSize = 13;
        S.txt = gobjects(nRows,1);
        for i = 1:nRows
            S.txt(i) = text(ax, 1, M(i), labels(i), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'Color', 'white', ...
                'FontSize', fontSize);
        end
        title(ax, 'Label Color Scheme');
    else
        % update existing plot without recreating
        colormap(fig, brushing.params.colorMat);

        % ---- CHANGES DROPPED IN: direct colormap indexing (+2 works) ----
        ax = ancestor(S.colIm,'axes');
        set(S.colIm, 'XData', 1, 'YData', M, 'CData', M);
        S.colIm.CDataMapping = 'direct';                  % IMPORTANT
        ax.CLim = [1 size(brushing.params.colorMat,1)];   % IMPORTANT
        % ----------------------------------------------------------------

        fontSize = 13;
        % if fewer/more rows than before, rebuild text handles cleanly
        if ~isfield(S,'txt') || numel(S.txt) ~= nRows || any(~isvalid(S.txt))
            ax = ancestor(S.colIm,'axes');
            % delete old text if exists
            if isfield(S,'txt') && ~isempty(S.txt)
                delete(S.txt(ishandle(S.txt)));
            end
            S.txt = gobjects(nRows,1);
            for i = 1:nRows
                S.txt(i) = text(ax, 1, M(i), labels(i), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'Color', 'white', ...
                    'FontSize', fontSize);
            end
        else
            % just update strings + positions
            for i = 1:nRows
                S.txt(i).String = labels(i);
                S.txt(i).Position = [1, M(i), 0];
                S.txt(i).FontSize = fontSize;
            end
        end
    end

    % save state + current mode
    S.mode = string(mode);
    S.labels = labels;
    S.colorMat = brushing.params.colorMat;
    setappdata(fig, 'legendState', S);

    % this figure is a separate window from whatever UI triggered the
    % mode toggle (and the caller's own drawnow runs before this function
    % is even called), so force a repaint here or the colormap/label
    % changes above can sit unflushed until something else redraws it
    drawnow limitrate
end
