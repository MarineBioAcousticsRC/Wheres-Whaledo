function colorMat = ww_get_species_colorMat()
% ww_get_species_colorMat
%
% Returns the fixed color palette used for species-based coloring:
% brushing_colors/brushing.params, always -- regardless of whatever
% palette is currently loaded into brushing.params.colorMat for
% Brush DOA's "Whale number" mode. Used by the Mean Normalized Spectra
% plot (always) and by Brush DOA/the legend when toggled to
% "Species label", so species colors are identical everywhere.
%
% Loaded once per session and cached on brushing.speciesColorMat.

global brushing PARAMS

if ~isfield(brushing,'speciesColorMat') || isempty(brushing.speciesColorMat)
    filename = PARAMS.path.repo + "\ww\verify\brushing_colors\brushing.params";
    tmp = struct();
    tmp.colorMat = [];
    fid = fopen(filename,'r');
    while ~feof(fid)
        tline = fgets(fid);
        tline = strrep(tline, 'brushing.params.', 'tmp.');
        eval(tline);
    end
    fclose(fid);
    brushing.speciesColorMat = tmp.colorMat;
end

colorMat = brushing.speciesColorMat;

end
