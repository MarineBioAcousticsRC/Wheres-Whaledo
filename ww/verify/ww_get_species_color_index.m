function cidx = ww_get_species_color_index(spName)
% ww_get_species_color_index(spName)
%
% Returns a stable color-row index (into ww_get_species_colorMat(), the
% fixed brushing.params palette) for a given species name. The first
% time a species is seen it's assigned the next available color and
% that assignment is remembered (on the global brushing struct) for the
% rest of the session, so the same species always gets the same color
% everywhere it's displayed -- the Mean Normalized Spectra plot, and
% Brush DOA/the legend when toggled to "Species label". Wraps back
% through the available color rows if there are more species than
% colors.

global brushing

if ~isfield(brushing,'sp2cidx') || ~isa(brushing.sp2cidx,'containers.Map')
    brushing.sp2cidx = containers.Map('KeyType','char','ValueType','double');
end

if ismissing(spName)
    spName = "NaN"; % treat a missing string the same as the unlabeled sentinel
end
key = char(spName);

if strcmp(key, "NaN")
    cidx = 1; % reserved gray ("acoustic data" row) -- always used for unlabeled/no species, never handed out to a real species
    return
end

nColors = size(ww_get_species_colorMat(),1);

if ~isKey(brushing.sp2cidx, key)
    % start at 4, not 3: row 3 in brushing.params is also [0.6 0.6 0.6],
    % the same gray reserved for "NaN" above, so a real species should
    % never land there and risk looking identical to unlabeled
    next = 4;
    if brushing.sp2cidx.Count > 0
        next = max(cell2mat(values(brushing.sp2cidx))) + 1;
    end
    if next > nColors
        next = 4 + mod(next-4, max(1, nColors-3)); % wrap through 4:nColors
    end
    brushing.sp2cidx(key) = next;
end

cidx = brushing.sp2cidx(key);

end
