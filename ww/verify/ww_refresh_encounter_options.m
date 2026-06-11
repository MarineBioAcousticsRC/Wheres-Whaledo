function ww_refresh_encounter_options()
global HANDLES
if isfield(HANDLES,'ui') && isfield(HANDLES.ui,'enc') && isfield(HANDLES.ui.enc,'whaleSpecies')
    % call the stored function handle if you save it (see below)
    if isfield(HANDLES.ui.enc,'refreshWhaleSpeciesFcn') && isa(HANDLES.ui.enc.refreshWhaleSpeciesFcn,'function_handle')
        HANDLES.ui.enc.refreshWhaleSpeciesFcn();
    end
end
end
