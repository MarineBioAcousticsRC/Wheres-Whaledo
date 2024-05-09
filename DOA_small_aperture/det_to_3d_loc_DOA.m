%% det_to_3d_loc_DOA
% using the DOA approach, convert the azimuth-elevation values from each
% 4ch array into a 3D location. smooth points
%% run loc3D intersect
% load the params file for this
paramFile = 'C:\Users\Lauren\Documents\GitHub\wheresWhaledo\localize_DOAintersect.params';

% hloc are hydrophone locations, H{1} and H{2} are small ap H matrices.
% create struct containing 4ch H matrices,  
load('F:\Tracking\Instrument_Orientation\SOCAL_W_05\new_4ch_matrices\SOCAL_W_05_WE\SOCAL_W_05_WE_harp4chParams.mat');
h{1} = H;
pos{1} = recLoc;
clear H ; clear recLoc
load('F:\Tracking\Instrument_Orientation\SOCAL_W_05\new_4ch_matrices\SOCAL_W_05_WS\SOCAL_W_05_WS_harp4chPar.mat');
h{2} = H;
pos{2} = recLoc;
clear H; clear recLoc

df = dir(['F:\Tracking\Erics_detector\SOCAL_W_05\new\cleaned_tracks']); % directory of folders containing files
% i = 1; %% the row number in df of the track you're looking at

 for i = 1:length(df) % for each track
    
     myFile = dir([df(i).folder,'\',df(i).name,'\*brushDOA.mat']); % load the folder name
     if isempty(myFile)
         myFile = dir([df(i).folder,'\',df(i).name,'\*.mat']); % load the folder name
         rename = strcat(extractBefore(myFile.name,'.mat'),'_brushDOA.mat')
         movefile([myFile.folder,'\',myFile.name],[myFile.folder,'\',rename]) % rename the file
         myFile = dir([df(i).folder,'\',df(i).name,'\*brushDOA.mat']); % load the folder name
     end
     trackNum = extractAfter(myFile.folder,'cleaned_tracks\'); % grab the track num for naming later
     load(fullfile([myFile.folder,'\',myFile.name])); % load the file
     whale = loc3D_DOAintersect_includeCI(DET, pos, h{1}, h{2}, paramFile);
     saveas(gcf,[myFile.folder,'\',trackNum,'_loc3D_DOAfig']); % save the fig
     save([char(myFile.folder),'\',char(trackNum),'_loc3D_DOA_whale.mat'],'whale'); % save the whale struct

 end

%% rerun weighted spline

paramFile = 'C:\Users\Lauren\Documents\GitHub\wheresWhaledo\localize_DOAintersect.params';
global LOC_DOA
loadParams(paramFile)
smoothingParam= 1e-8;  

load('F:\Tracking\Instrument_Orientation\SOCAL_W_05\new_4ch_matrices\SOCAL_W_05_WE\SOCAL_W_05_WE_harp4chParams.mat');
hydLoc{1} = recLoc;
clear recLoc
load('F:\Tracking\Instrument_Orientation\SOCAL_W_05\new_4ch_matrices\SOCAL_W_05_WS\SOCAL_W_05_WS_harp4chPar.mat');
hydLoc{2} = recLoc;
h0 = mean([hydLoc{1}; hydLoc{2}]);
% convert hydrophone locations to meters:
[h1(1), h1(2)] = latlon2xy_wgs84(hydLoc{1}(1), hydLoc{1}(2), h0(1), h0(2));
h1(3) = abs(h0(3))-abs(hydLoc{1}(3));

[h2(1), h2(2)] = latlon2xy_wgs84(hydLoc{2}(1), hydLoc{2}(2), h0(1), h0(2));
h2(3) = abs(h0(3))-abs(hydLoc{2}(3));

for i = 1:length(df)
    myFile = dir([df(i).folder,'\',df(i).name,'\*whale.mat']); % load the folder name
    trackNum = extractAfter(myFile(1).folder,'cleaned_tracks\'); % grab the track num for naming later
    load(fullfile([myFile(1).folder,'\',myFile(1).name])); % load the file
    
    [whale, wfit] = weightedSplineFit(whale, smoothingParam);
    
    figure
    scatter3(h1(1), h1(2), h1(3), 24, 'k^', 'filled')
    hold on
    scatter3(h2(1), h2(2), h2(3), 24, 'k^', 'filled')
    for wn = 1:length(whale)
        if isempty(whale{wn}) % if no whale with this num
            continue
        else
        plot3(whale{wn}.wlocSmooth(:,1),whale{wn}.wlocSmooth(:,2),whale{wn}.wlocSmooth(:,3),'color',LOC_DOA.colorMat(wn+2, :))
        end
    end
    
    saveas(gcf,[myFile.folder,'\',trackNum,'_loc3D_DOA_smoothedfig']); % save the fig
    save([myFile.folder,'\',trackNum,'_loc3D_DOA_whale'],'whale'); % save the whale struct

    close all
end