function ww_brushDOA_setColorMode(mode)
% ww_brushDOA_setColorMode(mode)
%
% helper function for changing the color of detections depending on either
% whale number or species label

global PARAMS brushing DET

% remembered so other windows (e.g. ww_generate3DPlot.m) that get
% refreshed independently of this toggle can match its current setting
brushing.colorMode = mode;

switch mode
    case "Whale number"
        % reset colorMat before reloading -- loadParams only overwrites
        % the rows a file explicitly assigns, so without this, switching
        % from a smaller palette (species mode) back to this one would
        % leave stale extra rows from whichever was loaded before
        brushing.params.colorMat = [];
        loadParams(PARAMS.path.repo+"\ww\verify\brushing_colors\brushing_pastel")
        nColors = size(brushing.params.colorMat,1);

        for lab = 1:numel(DET)
            c = str2double(string(DET{lab}.Label)) + 2;
            invalid = isnan(c) | c<1 | c>nColors;
            if any(invalid)
                warning('%d detection(s) on array %d have an invalid/out-of-range whale label; treating as unlabeled.', sum(invalid), lab);
                c(invalid) = 2; % unlabeled
            end
            DET{lab}.color = c;
        end

    case "Species label"
        % species coloring always uses the fixed brushing.params palette
        % (same one the Mean Normalized Spectra plot always uses), so
        % colors match between that plot and Brush DOA/the legend
        brushing.params.colorMat = ww_get_species_colorMat();

        spAll = cell(numel(DET),1);
        unqSp = [];
        for sp = 1:numel(DET)
            s = string(DET{sp}.Species);
            s(ismissing(s) | strlength(s)==0) = "NaN"; % same catch as ww_generateSpectraPlot.m's gathering
            spAll{sp} = s;
            unqSp = [unqSp;unique(s)];
        end
        unqSp = unique(unqSp);
        for sp = 1:numel(DET)
            for u = 1:length(unqSp)
                spMatch = find(spAll{sp}==unqSp(u));
                % shared species->color mapping (also used by the Mean
                % Normalized Spectra plot), so the same species always
                % gets the same color everywhere
                cidx = ww_get_species_color_index(unqSp(u));
                DET{sp}.color(spMatch) = cidx;
            end
        end

end

% refresh plotted colors
if isempty(DET) || ~isfield(brushing,'hScatter')
    return
end

C1 = brushing.params.colorMat(DET{1}.color, :);
C2 = brushing.params.colorMat(DET{2}.color, :);

set(brushing.hScatter(1),'CData',C1)
set(brushing.hScatter(2),'CData',C1)
set(brushing.hScatter(3),'CData',C1)

set(brushing.hScatter(4),'CData',C2)
set(brushing.hScatter(5),'CData',C2)
set(brushing.hScatter(6),'CData',C2)

drawnow

if mode == "Whale number"
    labels = ["Whale 1", "Whale 2", "Whale 3", "Whale 4", "Whale 5", ...
        "Whale 6", "Whale 7", "Whale 8", "Whale 9", "Whale 10", ...
        "Whale 11", "Whale 12", "Whale 13", "Whale 14", "Whale 15", ...
        "Whale 16", "Whale 17", "Whale 18", "Whale 19", "Whale 20"];
    colorIdx = (1:numel(labels)) + 2;
elseif mode == "Species label"
    labels = unqSp;
    % species colors come from ww_get_species_color_index's persistent
    % first-seen assignment, NOT from each label's position in unqSp --
    % the legend needs each label's actual assigned color, not a guess
    colorIdx = arrayfun(@ww_get_species_color_index, unqSp);
end
ww_generateColorSchemeLegend(brushing, mode, labels, colorIdx)

end
