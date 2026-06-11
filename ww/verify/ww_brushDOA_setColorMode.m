function ww_brushDOA_setColorMode(mode)
% ww_brushDOA_setColorMode(mode)
%
% helper function for changing the color of detections depending on either
% whale number or species label

global PARAMS brushing DET

switch mode
    case "Whale number"
        loadParams(PARAMS.path.repo+"\ww\verify\brushing_colors\brushing_pastel")
        for lab = 1:numel(DET)
            DET{lab}.color = str2num(DET{lab}.Label) + 2;
        end

    case "Species label"
        loadParams(PARAMS.path.repo+"\ww\verify\brushing_colors\brushing.params")
        unqSp = [];
        for sp = 1:numel(DET)
            unqSp = [unqSp;unique(DET{sp}.Species)];
        end
        unqSp = unique(unqSp);
        for sp = 1:numel(DET)
            for u = 1:length(unqSp)
                spMatch = find(DET{sp}.Species==unqSp(u));
                DET{sp}.color(spMatch) = u + 2;
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
        "Whale 11", "Whale 12", "Whale 13", "Whale 14", "Whale 15"];
elseif mode == "Species label"
    labels = unqSp;
end
ww_generateColorSchemeLegend(brushing, mode, labels)

end
