function ww_find_instrument_orientations()

% ww_find_instrument_orientation()
%
% function to check if the ensemble specified by the user in project
% metadata is one for which I've already calculated orientations.

global PARAMS

% first, where should we save instrument orientation info into the project
projPrecalcRoot = fullfile(PARAMS.projectSaveFolder, "instrument_orientation");
if ~isfolder(projPrecalcRoot)
    mkdir(projPrecalcRoot);
end
pattern = string(PARAMS.project.DataSourceName); % file match pattern

% first, look in the project to see if there is a match
projFolders = dir(fullfile(projPrecalcRoot, "*")); % top-level folders under project precalc root
projFolders = projFolders([projFolders.isdir]); % dirs only
projFolders = projFolders(~ismember({projFolders.name},{'.','..'}));
projNames  = string({projFolders.name});
projMatch  = contains(projNames, pattern);
projPaths  = string(fullfile({projFolders(projMatch).folder}, {projFolders(projMatch).name}));

% next, check the repo to see if there's a match
repoFolders = dir(fullfile(PARAMS.path.precalcEnsembles, "*")); % top-level folders in repo precalc root
repoFolders = repoFolders([repoFolders.isdir]);
repoFolders = repoFolders(~ismember({repoFolders.name},{'.','..'}));
repoNames = string({repoFolders.name});
repoMatch = contains(repoNames, pattern);
repoPaths = string(fullfile({repoFolders(repoMatch).folder}, {repoFolders(repoMatch).name}));

% now, we have some logic to choose which one to load
% this is coded to choose the one in your project over the one in the repo,
% in case you've recalculated the orientations
if ~isempty(projPaths) && ~isempty(repoPaths)
    % matches in both -> use project
    PARAMS.project.InstrumentOrientationRelPath = extractAfter(projPrecalcRoot,PARAMS.project.ProjectDir);
    project = PARAMS.project;
    cfgDir = fullfile(PARAMS.projectSaveFolder, "config");
    cfgFile = fullfile(cfgDir, project.ProjectName + "_metadata.mat"); % config file name
    save(cfgFile,'project'); % save the inputted metadata

elseif ~isempty(projPaths) && isempty(repoPaths)
    % only project -> use project
    PARAMS.project.InstrumentOrientationRelPath = extractAfter(projPrecalcRoot,PARAMS.project.ProjectDir);
    project = PARAMS.project;
    cfgDir = fullfile(PARAMS.projectSaveFolder, "config");
    cfgFile = fullfile(cfgDir, project.ProjectName + "_metadata.mat"); % config file name
    save(cfgFile,'project'); % save the inputted metadata

elseif isempty(projPaths) && ~isempty(repoPaths)
    % only repo -> copy from repo into project
    repoMatchedFolder = repoFolders(find(repoMatch, 1));
    srcFolder = fullfile(repoMatchedFolder.folder, repoMatchedFolder.name);
    copyfile(fullfile(srcFolder, '*'), projPrecalcRoot);
    PARAMS.project.InstrumentOrientationRelPath = extractAfter(projPrecalcRoot,PARAMS.projectSaveFolder);
    project = PARAMS.project;
    cfgDir = fullfile(PARAMS.projectSaveFolder, "config");
    cfgFile = fullfile(cfgDir, project.ProjectName + "_metadata.mat"); % config file name
    save(cfgFile,'project'); % save the inputted metadata

end


end
