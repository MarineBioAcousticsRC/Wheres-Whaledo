function ww_clear_HANDLES_ui_content()

% ww_clear_HANDLES_ui_content
%
% function to clear the ui content in HANDLES when screens swtich

global HANDLES

if isfield(HANDLES,'ui') && isfield(HANDLES.ui,'content') && ~isempty(HANDLES.ui.content) && isvalid(HANDLES.ui.content)
    kids = HANDLES.ui.content.Children;
    kids = kids(isvalid(kids));
    if ~isempty(kids)
        delete(kids);
    end
end

end