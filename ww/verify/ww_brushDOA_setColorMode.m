function ww_brushDOA_setColorMode(mode)
% ww_brushDOA_setColorMode(mode)
%
% helper function for changing the color of detections depending on either
% whale number or species label

global PARAMS brushing DET

% both modes share one palette, so colors never run off the end of
% whichever file was loaded last (loadParams doesn't clear old rows)
loadParams(PARAMS.path.repo+"\ww\verify\brushing_colors\brushing_pastel")
nColors = size(brushing.params.colorMat,1);

switch mode
    case "Whale number"
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
        unqSp = [];
        for sp = 1:numel(DET)
            unqSp = [unqSp;unique(DET{sp}.Species)];
        end
        unqSp = unique(unqSp);
        for sp = 1:numel(DET)
            for u = 1:length(unqSp)
                spMatch = find(DET{sp}.Species==unqSp(u));
                % wrap through the available color rows if there are more
                % unique species than colors
                cidx = 3 + mod(u-1, max(1, nColors-2));
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
elseif mode == "Species label"
    labels = unqSp;
end
ww_generateColorSchemeLegend(brushing, mode, labels)

end
