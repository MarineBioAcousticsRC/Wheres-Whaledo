function colorMat = ww_get_whale_colorMat()
% ww_get_whale_colorMat
%
% Returns the fixed color palette used for whale-number coloring:
% brushing_colors/brushing_pastel, always -- regardless of whatever
% palette is currently loaded into brushing.params.colorMat for Brush
% DOA's "Species label" mode. Used by the 3D Positions plot (always,
% since whale{wn}.color is a whale-number index, never species-based)
% and by Brush DOA/the legend when toggled to "Whale number".
%
% Loaded once per session and cached on brushing.whaleColorMat.

global brushing PARAMS

if ~isfield(brushing,'whaleColorMat') || isempty(brushing.whaleColorMat)
    filename = PARAMS.path.repo + "\ww\verify\brushing_colors\brushing_pastel";
    tmp = struct();
    tmp.colorMat = [];
    fid = fopen(filename,'r');
    while ~feof(fid)
        tline = fgets(fid);
        tline = strrep(tline, 'brushing.params.', 'tmp.');
        eval(tline);
    end
    fclose(fid);
    brushing.whaleColorMat = tmp.colorMat;
end

colorMat = brushing.whaleColorMat;

end
