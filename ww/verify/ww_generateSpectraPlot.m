function ww_generateSpectraPlot(mode, DET, f, Ind)
% ww_generateSpectraPlot(mode, DET, f, Ind)
%
% Creates or updates a "Spectra Summary" figure:
%   mode = 'init'     : create/validate figure and axes; does not plot data
%   mode = 'species'  : update mean spectra curves grouped by DET{arr}.Species
%   mode = 'selected' : update mean spectra of currently selected points (Ind)
%
% Inputs:
%   DET: 1x2 cell array of tables, each with .Spectra and .Species
%   f: frequency vector (1xF)
%   Ind: (only for mode='selected') cell Ind{1}, Ind{2} indices
%
% Notes:
%   - Does NOT modify DET.
%   - Stores state using setappdata(fig,'spectraState',S) like your legend function.
%   - Always uses the fixed brushing.params palette (ww_get_species_colorMat.m),
%     regardless of whatever palette Brush DOA's "Whale number" mode has
%     currently loaded into brushing.params.colorMat. ww_get_species_color_index.m
%     provides a stable species->color mapping shared with Brush DOA/the
%     legend when they're toggled to "Species label", so colors match there too.

    global brushing

    colorMat = ww_get_species_colorMat();

    % -------- find or create figure --------
    fig = findall(0, 'Type', 'figure', 'Name', 'Spectra Summary');
    if isempty(fig) || ~isvalid(fig)
        fig = figure('Name', 'Spectra Summary', ...
            'NumberTitle','off', ...
            'MenuBar','none', ...
            'Position',brushing.params.spectraPos);
    end

    % -------- load existing state --------
    S = [];
    if isappdata(fig,'spectraState')
        S = getappdata(fig,'spectraState');
    end

    % -------- create graphics if needed --------
    needCreate = isempty(S) || ~isfield(S,'ax') || isempty(S.ax) || ~isvalid(S.ax);

    if needCreate
        clf(fig);

        S.ax = axes('Parent', fig);
        hold(S.ax,'on');
        grid(S.ax,'on');
        xlabel(S.ax,'Frequency (kHz)');
        ylabel(S.ax,'Normalized Amplitude');
        ylim(S.ax,[0 1]);
        title(S.ax,'Mean Normalized Spectra');

        % Lines for selected spectra (always exist; start as NaN)
        S.selLine = gobjects(2,1);
        S.selLine(1) = plot(S.ax, f, nan(size(f)), 'k-',  'LineWidth', 3, 'DisplayName','Selected (Array 1)');
        S.selLine(2) = plot(S.ax, f, nan(size(f)), 'k--', 'LineWidth', 3, 'DisplayName','Selected (Array 2)');

        % Species lines map: speciesName -> line handle
        S.spLineMap = containers.Map('KeyType','char','ValueType','any');

    else
        % update frequency vector on existing selected lines if needed
        for a = 1:2
            if isgraphics(S.selLine(a))
                if ~isempty(S) && isfield(S,'f') && ~isempty(S.f)
                    f = S.f;
                elseif numel(S.selLine(a).XData) ~= numel(f)
                    set(S.selLine(a),'XData',f,'YData',nan(size(f)));
                else
                    set(S.selLine(a),'XData',f);
                end
            end
        end
    end

    % -------- dispatch mode --------
    mode = lower(string(mode));
    switch mode
        case "init"
            % nothing else

        case "species"
            % update (or create) species mean curves
            S = local_updateSpeciesMeans(fig, S, DET, f, colorMat);

        case "selected"
            % update the selected curves only
            S = local_updateSelectedMeans(S, DET, f, Ind);

        otherwise
            error('ww_generateSpectraPlot:UnknownMode', 'Unknown mode: %s', mode);
    end

    % keep selected lines on top
    if isgraphics(S.selLine(1)); uistack(S.selLine(1),'top'); end
    if isgraphics(S.selLine(2)); uistack(S.selLine(2),'top'); end

    % enforce normalized y-axis every update (not just on figure creation),
    % in case this figure survived from a previous track with a different scale
    ylim(S.ax,[0 1]);

    % -------- save state --------
    S.mode = mode;
    S.f = f;
    setappdata(fig,'spectraState',S);
end

% ======================================================================
function S = local_updateSpeciesMeans(fig, S, DET, f, colorMat)
% Compute mean spectrum per species across both arrays, plot/update one line per species.
% Uses the shared species->color mapping from ww_get_species_color_index.m.

    % gather spectra+species across arrays
    allSp = strings(0,1);
    allSpec = [];

    for arr = 1:numel(DET)
        if isempty(DET{arr}) || ~istable(DET{arr})
            continue
        end
        if ~ismember('Spectra', DET{arr}.Properties.VariableNames) || ...
           ~ismember('Species', DET{arr}.Properties.VariableNames)
            continue
        end

        Sp = local_getSpectraNumeric(DET{arr});
        if isempty(Sp)
            continue
        end

        sp = string(DET{arr}.Species(:));
        bad = ismissing(sp) | (strlength(sp)==0);
        sp(bad) = "NaN"; % same unlabeled sentinel as ww_brushDOA_setColorMode.m,
                          % so these rows get the shared reserved gray, not a
                          % phantom "species" with no Brush DOA/legend counterpart

        % if any rows have empty spectra (NaNs) still fine for mean
        if numel(sp) ~= size(Sp,1)
            % mismatch -> skip this array rather than error
            continue
        end

        allSp   = [allSp; sp];
        allSpec = [allSpec; Sp];
    end

    if isempty(allSp)
        return
    end

    % unique species present now
    uSp = unique(allSp);

    % delete species lines that no longer exist
    existing = S.spLineMap.keys;
    for ii = 1:numel(existing)
        k = existing{ii};
        if ~ismember(string(k), uSp)
            h = S.spLineMap(k);
            if isgraphics(h); delete(h); end
            remove(S.spLineMap, k);
        end
    end

    % update/create each species line
    for i = 1:numel(uSp)
        nm = uSp(i);
        idx = (allSp == nm);
        y = mean(allSpec(idx,:), 1);
        y = local_normalizeSpectra(y); % renormalize the mean curve itself to [0,1]

        k = char(nm);
        cidx = ww_get_species_color_index(nm); % shared with Brush DOA coloring
        rgb = colorMat(cidx,:);

        if isKey(S.spLineMap, k) && isgraphics(S.spLineMap(k))
            h = S.spLineMap(k);
            set(h,'XData',f,'YData',y,'Color',rgb);
        else
            h = plot(S.ax, f, y, 'LineWidth', 2, 'DisplayName', k);
            set(h,'Color',rgb);
            S.spLineMap(k) = h;
        end
    end

    drawnow limitrate
end

% ======================================================================
function S = local_updateSelectedMeans(S, DET, f, Ind)
% Update the two "selected" mean curves from indices Ind{1}, Ind{2}.

    % Array 1
    y1 = nan(size(f));
    if ~isempty(Ind{1}) && ~isempty(DET{1}) && istable(DET{1}) && ismember('Spectra', DET{1}.Properties.VariableNames)
        Sp1 = local_getSpectraNumeric(DET{1});
        if ~isempty(Sp1) && max(Ind{1}) <= size(Sp1,1)
            y1 = local_normalizeSpectra(mean(Sp1(Ind{1},:), 1)); % renormalize the mean curve itself to [0,1]
        end
    end
    if isgraphics(S.selLine(1))
        set(S.selLine(1),'XData',f,'YData',y1);
    end

    % Array 2
    y2 = nan(size(f));
    if ~isempty(Ind{2}) && ~isempty(DET{2}) && istable(DET{2}) && ismember('Spectra', DET{2}.Properties.VariableNames)
        Sp2 = local_getSpectraNumeric(DET{2});
        if ~isempty(Sp2) && max(Ind{2}) <= size(Sp2,1)
            y2 = local_normalizeSpectra(mean(Sp2(Ind{2},:), 1)); % renormalize the mean curve itself to [0,1]
        end
    end
    if isgraphics(S.selLine(2))
        set(S.selLine(2),'XData',f,'YData',y2);
    end

    drawnow limitrate
end

% ======================================================================
function Sp = local_normalizeSpectra(Sp)
% Min-max normalizes each detection's spectrum (row) to the range [0, 1],
% so mean/species curves reflect spectral shape rather than absolute
% received level.

    if isempty(Sp)
        return
    end
    lo = min(Sp, [], 2, 'omitnan');
    hi = max(Sp, [], 2, 'omitnan');
    rng = hi - lo;
    rng(rng==0) = 1; % avoid divide-by-zero for a flat/constant row
    Sp = (Sp - lo) ./ rng;
end

% ======================================================================
function Sp = local_getSpectraNumeric(T)
% Returns spectra as numeric [N x F] for a table row-wise.
% Supports numeric matrix or cell array of row vectors.

    Sp = [];
    if isempty(T) || ~istable(T) || ~ismember('Spectra', T.Properties.VariableNames)
        return
    end

    Scol = T.('Spectra');

    if isnumeric(Scol)
        Sp = Scol;
        return
    end

    if iscell(Scol)
        % try fast path
        try
            Sp = cell2mat(Scol);
            return
        catch
            % safe path
            n = numel(Scol);
            first = find(~cellfun(@isempty,Scol), 1, 'first');
            if isempty(first)
                return
            end
            F = numel(Scol{first});
            Sp = nan(n,F);
            for ii = 1:n
                if ~isempty(Scol{ii})
                    Sp(ii,:) = Scol{ii}(:).';
                end
            end
        end
    end
end
