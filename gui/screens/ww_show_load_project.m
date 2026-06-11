function ww_show_load_project()

% ww_show_load_project
%
% pick an existing project folder, find metatdata.mat file, and load values
% into PARAMS.project. triggers the project workflow screen.

global PARAMS HANDLES

PARAMS.projectSaveFolder = uigetdir(pwd, "Select Project Folder");

HANDLES.fig.main.Visible = 'off';
HANDLES.fig.main.Visible = 'on';
drawnow;

cfgFile = dir(PARAMS.projectSaveFolder + "\**\config\*_metadata.mat"); % config file

if numel(cfgFile) == 1 % if we found one metadata file
    project = load(fullfile(cfgFile(1).folder,cfgFile(1).name)); % load config file into global PARAMS
    PARAMS.project = project.project;
    ww_show_workflow();  % pull up the next screen

elseif isempty(cfgFile) % if we didn't find a metadata file
    uialert(HANDLES.fig.main, ...
        "Could not find a project metadata .txt file in:" + newline + ...
        "  " + PARAMS.projectSaveFolder + newline + newline + ...
        "Expected one of:" + newline + ...
        "  config\project_metadata.txt" + newline + ...
        "  config\*_metadata.txt", ...
        "Metadata file not found");
    return

elseif numel(cfgFile) > 1 % if we found multiple config files (yikes)
    uialert(HANDLES.fig.main, ...
        "Found multiple project metadata .txt files in:" + newline + ...
        "  " + PARAMS.projectSaveFolder + newline + newline + ...
        "You may only provide one config file per project.", ...
        "Multiple metadata files found");
    return
end

end