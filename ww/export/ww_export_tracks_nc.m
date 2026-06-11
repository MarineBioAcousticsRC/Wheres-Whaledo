function ww_export_tracks_nc()

% ww_export_tracks_nc(opts)
%
% function to export cleaned tracks as .nc files optimized for archive in a
% DRYAD repository

global PARAMS HANDLES

% calculate reference location for position data
insoPath = dir(PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+"\*harp4chParams.mat");
for k = 1:numel(insoPath)
    load(fullfile(insoPath(k).folder,insoPath(k).name));
    hydLoc{k} = recLoc;
end
if numel(hydLoc) == 1
    h0 = hydLoc{1};
elseif numel(hydLoc) == 2
    h0 = mean([hydLoc{1};hydLoc{2}]);
end
ref_lat = h0(1);
ref_lon = h0(2);
ref_depth = h0(3);

% load the encounter table
enc = readtable(HANDLES.ui.export.encPath.Value);

% load in and format data
fileDir = dir(HANDLES.ui.export.inPath.Value);

for j = 3:numel(fileDir) % for each saved track folder

    wd = dir([fileDir(j).folder,'\',fileDir(j).name,'\*whale_struct.mat']);
    if ~isempty(wd) % if we have a saved whale struct in this folder

        % grab the encounter number from the file name
        trackNum = regexp(wd(1).name,'enc(\d+)_(\d+)_(\d+)_to_(\d+)_(\d+)','tokens','once');

        % construct the metadata
        outfile = [HANDLES.ui.export.outPath.Value,'\ww_localized_tracks_enc',num2str(trackNum{1}),'_',num2str(trackNum{2}),'_',num2str(trackNum{3}),'_to_',num2str(trackNum{4}),'_',num2str(trackNum{5}),'.nc'];
        deployment_id = PARAMS.project.DataSourceName;
        author = HANDLES.ui.export.authorName.Value;
        email = HANDLES.ui.export.opt1.Value;
        doi = HANDLES.ui.export.opt2.Value;
        matchIdx = find(enc.encN==str2num(trackNum{1}));
        effort_start = [char(enc.startEnc(matchIdx)),' UTC'];
        effort_end = [char(enc.endEnc(matchIdx)),' UTC'];
        inst = PARAMS.project.ArrayOption + " HARP";

        % add the data        
        load(fullfile(wd(1).folder,wd(1).name)) % load the whale struct

        % for each whale, group info into arrays
        time = [];
        wloc = [];
        wlocSmooth = [];
        cix = [];
        ciy = [];
        ciz = [];
        wnum = [];
        species = [];
        for wn = 1:numel(whale)
            time = [time;whale{wn}.TDet];
            wloc = [wloc;whale{wn}.wloc];
            wlocSmooth = [wlocSmooth;whale{wn}.wlocSmooth];
            cix = [cix;whale{wn}.CIx];
            ciy = [ciy;whale{wn}.CIy];
            ciz = [ciz;whale{wn}.CIz];
            wnum = [wnum;repmat(wn,length(whale{wn}.TDet),1)];
            species = whale{wn}.Species;
        end
        ci = [cix,ciy,ciz]; % combine confidence intervals into one variable
        posix = posixtime(time); % convert datenums to posix time
        wnum = int32(wnum); % convert to integer
        
        % deal with species strings
        species_char = char(species);
        strlen = size(species_char,2);

        % define variables and dimensions
        nccreate(outfile,'time','Dimensions',{'time',length(posix)},'Datatype','double');
        nccreate(outfile,'position','Dimensions',{'time',length(posix),'xyz',3,},'Datatype','double');
        nccreate(outfile,'smoothed_position','Dimensions',{'time',length(posix),'xyz',3},'Datatype','double');
        nccreate(outfile,'confidence_interval', 'Dimensions',{'time',length(posix),'xupper xlower yupper ylower zupper zlower',6,},'Datatype','double');
        nccreate(outfile,'whale_number','Dimensions',{'time',length(posix)},'Datatype','int32');
        nccreate(outfile,'whale_species','Dimensions',{'time',length(posix),'name_strlen',strlen},'Datatype','char');
        
        % write data
        ncwrite(outfile,'time',posix);
        ncwrite(outfile,'position',wloc);
        ncwrite(outfile,'smoothed_position',wlocSmooth);
        ncwrite(outfile,'confidence_interval',ci);
        ncwrite(outfile,'whale_number',wnum);
        ncwrite(outfile,'whale_species',species_char);

        % add global metadata
        ncwriteatt(outfile,'/','deployment_id', deployment_id);
        ncwriteatt(outfile,'/','author',author);
        ncwriteatt(outfile,'/','author_contact',email);
        ncwriteatt(outfile,'/','doi',doi);
        ncwriteatt(outfile,'/','effort_start',effort_start);
        ncwriteatt(outfile,'/','effort_end',effort_end);
        ncwriteatt(outfile,'/','reference_latitude',ref_lat);
        ncwriteatt(outfile,'/','reference_longitude',ref_lon);
        ncwriteatt(outfile,'/','reference_depth_m',abs(ref_depth));
        ncwriteatt(outfile,'/','instrument_type',inst);

        % add file creation timestamp
        ncwriteatt(outfile,'/','file_write_date',datestr(now,'dd-mmm-yyyy HH:MM:ss UTC'));

        % add variable attributes
        % time
        ncwriteatt(outfile,'time','units','seconds since 1970-01-01 00:00:00 UTC');
        ncwriteatt(outfile,'time','long_name','POSIX timestamp');

        % position
        ncwriteatt(outfile,'position','units','meters');
        ncwriteatt(outfile,'position','long_name','XYZ position in m relative to reference location (lat/lon/depth)');

        % smoothed_position
        ncwriteatt(outfile,'smoothed_position','units','meters');
        ncwriteatt(outfile,'smoothed_position','long_name','smoothed XYZ position in m relative to reference location (lat/lon/depth)')

        % ci
        ncwriteatt(outfile,'confidence_interval','units','meters');
        ncwriteatt(outfile,'confidence_interval','long_name','confidence interval for XYZ position (x upper, x lower, y upper, y lower, z upper, z lower)');

        % whale_number
        ncwriteatt(outfile,'whale_number','long_name','identification number for each localized individual whale in this encounter')
        ncwriteatt(outfile,'whale_number','comment','each entry corresponds to a single timestamp')

        % species
        ncwriteatt(outfile,'whale_species','long_name','Latin species name for each tracked whale')

    end


end

end