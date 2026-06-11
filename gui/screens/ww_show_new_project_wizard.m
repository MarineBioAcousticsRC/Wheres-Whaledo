function ww_show_new_project_wizard(mode)

% ww_show_new_project_wizard
% 
% ww_show_new_project_wizard("new") --> to create a new project
% ww_show_new_project_wizard("edit) --> to update metadata for an existing
% project

global PARAMS HANDLES

ww_clear_HANDLES_ui_content(); % clear old ui handles
if mode == "new"
    HANDLES.fig.main.Name = PARAMS.software_name + " v" + PARAMS.software_ver + " - Create a New Project";
elseif mode == "edit"
    HANDLES.fig.main.Name = PARAMS.project.Software + " v" + PARAMS.project.Version + " - " + PARAMS.project.ProjectName + " Edit Project Metadata";
end

% main screen layout
gl = uigridlayout(HANDLES.ui.content,[3 1]);
gl.RowHeight = {80,'1x',60};
gl.Padding = [30 30 30 30];
gl.RowSpacing = 12;

% title
titleLbl = uilabel(gl, ...
    'Text',"Create New Project", ...
    'FontSize',28, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
titleLbl.Layout.Row = 1;

% form grid: 9 rows x 3 cols
form = uigridlayout(gl,[9 3]);
form.Layout.Row = 2;
form.Padding = [0 0 0 0];
form.RowSpacing = 12;
form.ColumnSpacing = 12;
form.ColumnWidth = {220,'1x',120};   % label | input | browse/empty
form.RowHeight = {36,36,36,36,36,36,36,100,100};

% ---- Row 1: Project Save Folder ----
lbl = uilabel(form,'Text',"Project Save Folder:",'HorizontalAlignment','right');
lbl.Layout.Row = 1; lbl.Layout.Column = 1;
if mode == "new"
HANDLES.ui.wizard.saveFolder = uieditfield(form,'text', ...
    'Placeholder',"Choose or type a folder path...");
elseif mode == "edit"
HANDLES.ui.wizard.saveFolder = uieditfield(form,'text', ...
    'Value',fileparts(PARAMS.projectSaveFolder));
end
HANDLES.ui.wizard.saveFolder.Layout.Row = 1;
HANDLES.ui.wizard.saveFolder.Layout.Column = 2;
HANDLES.ui.wizard.btnBrowse = uibutton(form,'push', ...
    'Text',"Browse...", ...
    'ButtonPushedFcn',@onBrowseFolder);
HANDLES.ui.wizard.btnBrowse.Layout.Row = 1;
HANDLES.ui.wizard.btnBrowse.Layout.Column = 3;

% ---- Row 2: Project Name ----
lbl = uilabel(form,'Text',"Project Name:",'HorizontalAlignment','right');
lbl.Layout.Row = 2; lbl.Layout.Column = 1;
if mode == "new"
HANDLES.ui.wizard.projectName = uieditfield(form,'text', ...
    'Placeholder',"e.g., Lauren'sTrackingProject");
elseif mode == "edit"
HANDLES.ui.wizard.projectName = uieditfield(form,'text', ...
    'Value',PARAMS.project.ProjectName);
end
HANDLES.ui.wizard.projectName.Layout.Row = 2;
HANDLES.ui.wizard.projectName.Layout.Column = 2;
sp = uilabel(form,'Text',"");
sp.Layout.Row = 2; sp.Layout.Column = 3;

% ---- Row 3: UserId ----
lbl = uilabel(form,'Text',"UserId:",'HorizontalAlignment','right');
lbl.Layout.Row = 3; lbl.Layout.Column = 1;
if mode =="new"
HANDLES.ui.wizard.userId = uieditfield(form,'text', ...
    'Placeholder',"e.g., lbaggett");
elseif mode == "edit"
HANDLES.ui.wizard.userId = uieditfield(form,'text', ...
    'Value',PARAMS.project.UserId);
end
HANDLES.ui.wizard.userId.Layout.Row = 3;
HANDLES.ui.wizard.userId.Layout.Column = 2;
sp = uilabel(form,'Text',"");
sp.Layout.Row = 3; sp.Layout.Column = 3;

% ---- Row 4: Data Source (string) + type dropdown ----
lbl = uilabel(form,'Text',"Data Source:",'HorizontalAlignment','right');
lbl.Layout.Row = 4; lbl.Layout.Column = 1;
if mode == "new"
HANDLES.ui.wizard.dataSource = uieditfield(form,'text', ...
    'Placeholder',"e.g., SOCAL_W_01");
HANDLES.ui.wizard.dataSourceType = uidropdown(form, ...
    'Items', ["Deployment","Ensemble"], ...
    'Value', "Ensemble");
elseif mode == "edit"
HANDLES.ui.wizard.dataSource = uieditfield(form,'text', ...
    'Value',PARAMS.project.DataSourceName);
HANDLES.ui.wizard.dataSourceType = uidropdown(form, ...
    'Items', ["Deployment","Ensemble"], ...
    'Value',PARAMS.project.DataSourceType);
end
HANDLES.ui.wizard.dataSource.Layout.Row = 4;
HANDLES.ui.wizard.dataSource.Layout.Column = 2;
HANDLES.ui.wizard.dataSourceType.Layout.Row = 4;
HANDLES.ui.wizard.dataSourceType.Layout.Column = 3;

% ---- Row 5: Array configuration dropdowns ----
lbl = uilabel(form,'Text',"Array configuration:",'HorizontalAlignment','right');
lbl.Layout.Row = 5; 
lbl.Layout.Column = 1;
if mode == "new"
HANDLES.ui.wizard.arrayConfig = uidropdown(form, ...
    'Items', ["Horizontal","Vertical"], ...
    'Value', "Horizontal");
HANDLES.ui.wizard.arrayConfigOption = uidropdown(form, ...
    'Items', ["1 4ch","2 4ch"], ...
    'Value', "2 4ch");
elseif mode == "edit"
HANDLES.ui.wizard.arrayConfig = uidropdown(form, ...
    'Items', ["Horizontal","Vertical","Glider"], ...
    'Value', PARAMS.project.ArrayConfiguration);
HANDLES.ui.wizard.arrayConfigOption = uidropdown(form, ...
    'Items', ["1 4ch","2 4ch"], ...
    'Value', PARAMS.project.ArrayOption);
end
HANDLES.ui.wizard.arrayConfig.Layout.Row = 5;
HANDLES.ui.wizard.arrayConfig.Layout.Column = 2;
HANDLES.ui.wizard.arrayConfigOption.Layout.Row = 5;
HANDLES.ui.wizard.arrayConfigOption.Layout.Column = 3;

% ---- Row 6: Software ----
lbl = uilabel(form,'Text',"Software:",'HorizontalAlignment','right');
lbl.Layout.Row = 6; 
lbl.Layout.Column = 1;
if mode == "new"
HANDLES.ui.wizard.softwareName = uitextarea(form, ...
    'value',PARAMS.software_name);
elseif mode == "edit"
HANDLES.ui.wizard.softwareName = uitextarea(form, ...
    'value',PARAMS.project.Software);
end
HANDLES.ui.wizard.softwareName.Layout.Row = 6;
HANDLES.ui.wizard.softwareName.Layout.Column = 2;
sp = uilabel(form,'Text',"");
sp.Layout.Row = 6;
sp.Layout.Column = 3;

% ---- Row 7: Software Version ----
lbl = uilabel(form,'Text',"Software version:",'HorizontalAlignment','right');
lbl.Layout.Row = 7; 
lbl.Layout.Column = 1;
if mode == "new"
HANDLES.ui.wizard.softwareVersion = uitextarea(form, ...
    'Value',PARAMS.software_ver);
elseif mode == "edit"
HANDLES.ui.wizard.softwareVersion = uitextarea(form, ...
    'Value',PARAMS.project.Version);
end
HANDLES.ui.wizard.softwareVersion.Layout.Row = 7;
HANDLES.ui.wizard.softwareVersion.Layout.Column = 2;
sp = uilabel(form,'Text',"");
sp.Layout.Row = 7;
sp.Layout.Column = 3;

% ---- Row 8: On-effort species (free text) ----
lbl = uilabel(form,'Text',"On-effort species:",'HorizontalAlignment','right');
lbl.Layout.Row = 8; 
lbl.Layout.Column = 1;
if mode == "new"
HANDLES.ui.wizard.onEffortSpecies = uitextarea(form, ...
    'Placeholder',"Enter one Latin species name per line OR comma-separated (e.g. Ziphius cavirostris, Berardius bairdii)");
elseif mode == "edit"
HANDLES.ui.wizard.onEffortSpecies = uitextarea(form, ...
    'Value',PARAMS.project.OnEffortSpecies);
end    
HANDLES.ui.wizard.onEffortSpecies.Layout.Row = 8;
HANDLES.ui.wizard.onEffortSpecies.Layout.Column = 2;
sp = uilabel(form,'Text',"");
sp.Layout.Row = 8;
sp.Layout.Column = 3;

% ---- Row 9: Abstract (free text) ----
lbl = uilabel(form,'Text',"Abstract:",'HorizontalAlignment','right');
lbl.Layout.Row = 9; 
lbl.Layout.Column = 1;
if mode == "new"
HANDLES.ui.wizard.abstract = uitextarea(form, ...
    'Placeholder',"Enter a working abstract for this project. You can always update your abstract later.");
elseif mode == "edit"
 HANDLES.ui.wizard.abstract = uitextarea(form, ...
    'Value',PARAMS.project.Abstract);   
end
HANDLES.ui.wizard.abstract.Layout.Row = 9;
HANDLES.ui.wizard.abstract.Layout.Column = 2;
sp = uilabel(form,'Text',"");
sp.Layout.Row = 9;
sp.Layout.Column = 3;

% ---- Bottom buttons ----
btnRow = uigridlayout(gl,[1 5]);
btnRow.Layout.Row = 3;
btnRow.Padding = [0 0 0 0];
btnRow.ColumnSpacing = 10;
btnRow.ColumnWidth = {'1x',140,140,140,'1x'};

% first button, go back to a previous page
if mode == "new" % the ww home page, if this is a new project
btnBack = uibutton(btnRow,'push', ...
    'Text',"Back", ...
    'ButtonPushedFcn',@(~,~)ww_show_home());
btnBack.Layout.Column = 2;
elseif mode == "edit" % or the project workflow page, if we're editing
btnBack = uibutton(btnRow,'push', ...
    'Text',"Back", ...
    'ButtonPushedFcn',@(~,~)ww_show_workflow());
btnBack.Layout.Column = 2;
end

% second button, save inputs
btnSave = uibutton(btnRow,'push', ...
    'Text',"Save", ...
    'FontWeight','bold', ...
    'ButtonPushedFcn',@onSave);
btnSave.Layout.Column = 4;

drawnow;

% ---- callback functions ----
    function onBrowseFolder(~,~) % open file explorer to select save directory
        startDir = string(HANDLES.ui.wizard.saveFolder.Value);
        if strlength(startDir)==0 || ~isfolder(startDir)
            startDir = pwd;
        end
        folder = uigetdir(startDir, "Select Project Save Folder");
        if isequal(folder,0); return; end
        HANDLES.ui.wizard.saveFolder.Value = folder;
        figure(HANDLES.fig.main);
        drawnow;
    end

    function onSave(~,~) % save inputs in the project and in global variables, open project home
        % read values from UI
        projectName = string(strtrim(HANDLES.ui.wizard.projectName.Value));
        PARAMS.projectSaveFolder = strtrim(HANDLES.ui.wizard.saveFolder.Value)+"\"+projectName;
        userId = string(strtrim(HANDLES.ui.wizard.userId.Value));
        dataSource = string(strtrim(HANDLES.ui.wizard.dataSource.Value));
        dataSourceType = string(HANDLES.ui.wizard.dataSourceType.Value);  % Deployment/Ensemble
        arrayConfig = string(HANDLES.ui.wizard.arrayConfig.Value);     % Horizontal/Vertical/Glider
        arrayConfigOpt = string(HANDLES.ui.wizard.arrayConfigOption.Value); % "1"/"2"
        softwareName = string(HANDLES.ui.wizard.softwareName.Value);
        softwareVersion = string(HANDLES.ui.wizard.softwareVersion.Value);
        % species (textarea): one per line OR comma-separated
        lines = string(HANDLES.ui.wizard.onEffortSpecies.Value);
        raw = join(lines, newline);
        parts = split(raw, [",", newline]);
        onEffortSpecies = strtrim(parts);
        onEffortSpecies(onEffortSpecies=="") = [];
        onEffortSpecies = unique(onEffortSpecies,'stable');
        % end species parsing
        abstract = string(HANDLES.ui.wizard.abstract.Value);

        % ---- some catches for empty inputs ----
        if strlength(PARAMS.projectSaveFolder)==0
            uialert(HANDLES.fig.main,"Please choose a valid Project Save Folder.","Invalid folder");
            return
        end
        if strlength(projectName)==0
            uialert(HANDLES.fig.main,"Please enter a Project Name.","Missing field");
            return
        end
        if strlength(userId)==0
            uialert(HANDLES.fig.main,"Please enter a UserId.","Missing field");
            return
        end
        % catch for project directory already existing
        % projectDir = fullfile(PARAMS.projectSaveFolder, projectName);
        if isfolder(PARAMS.projectSaveFolder) && mode == "new"
            choice = uiconfirm(HANDLES.fig.main,...
                "The project folder already exists." + newline + ...
                "Do you want to save a backup of the existing folder and create a new project under the same name?", ...
                "Project folder exists", ...
                "Options",{'Backup and Create New','Cancel'}, ...
                'DefaultOption',2, ...
                'CancelOption',2);
            if choice == "Cancel"
                return % return to the wizard to change it
            elseif choice =="Backup and Create New" % if we really do want to make another called the same thing
                backupDir = PARAMS.projectSaveFolder + "_backup_" + string(datetime("now","Format","yyyyMMdd_HHmmss"));
                movefile(PARAMS.projectSaveFolder, backupDir);
                mkdir(PARAMS.projectSaveFolder);
            end
        end
        % ---- end catches ----

        % build a project struct
        if mode == "new"
            project = struct(); 
        elseif mode == "edit"
            load([PARAMS.projectSaveFolder+PARAMS.project.ConfigRelFilePath]);
        end
        project.ProjectName = projectName;
        project.UserId = userId;
        if mode == "new"
            project.Created = datetime("now");
        elseif mode == "edit"
            project.Updated = datetime("now");
        end
        project.Software = softwareName;
        project.Version = softwareVersion;
        % project.ProjectDir = "\" + projectName;
        project.DataSourceName = dataSource;
        project.DataSourceType = dataSourceType;
        project.ArrayConfiguration = arrayConfig;
        project.ArrayOption = arrayConfigOpt;
        project.OnEffortSpecies = onEffortSpecies;
        project.Abstract = abstract;

        % create project directory
        if ~isfolder(PARAMS.projectSaveFolder)
            mkdir(PARAMS.projectSaveFolder);
        end

        % make a config subfolder
        cfgDir = fullfile(PARAMS.projectSaveFolder, "config");
        if ~isfolder(cfgDir)
            mkdir(cfgDir);
        end

        cfgFile = fullfile(cfgDir, project.ProjectName + "_metadata.mat"); % config file name
        project.ConfigRelFilePath = extractAfter(cfgFile,PARAMS.projectSaveFolder); % save config file path for later
        save(cfgFile,'project'); % save the inputted metadata
        PARAMS.project = project; % store this inputted info into global PARAMS

        ww_show_workflow();  % pull up the next screen
    end


end