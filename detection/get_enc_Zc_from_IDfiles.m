%get_enc_from_TPWS
% read ID file start time detections, find edges of encounters where
% detections are less than 0.5 h apart
% create a table:
%   - startSnipped and endSnipped: 1h range before and after encounter times
%   - startEnc and endEnc: start and end times of encounters, 
%   - encDur: duration encounters
%   - encN: order encounters as it appears in detEdit
%
% @asolsonaberga@ucsd.edu


clear all
% TPWS file
%TPWSpath = 'G:\Shared drives\SOCAL_Habitat_Modeling\TPWS_RevA-B_Zc\SOCAL_H\SOCAL67H_Cuviers_TPWS2.mat';
IDpath = 'F:\AI_Classification\TPWS\SOCAL_E_63_ES\ID';
filePrefix = 'SOCAL_E_63_ES';


%settings
p.gth =  .5;    % gap time in hrs between sessions
p.minBout = 0;  % minimum bout duration in seconds
p.ltsaMax = 6;  % ltsa maximum duration per session


fileList = cellstr(ls(IDpath));

% Find the file name that matches the p.filePrefix
fileMatchIdx = find(~cellfun(@isempty,regexp(fileList,filePrefix))>0);
% if isempty(fileMatchIdx)
%     % if no matches, throw error
%     error(sprintf('No files matching file prefix ''%s'' found!',filePrefix))
% elseif length(fileMatchIdx)>1
%     % if more than one match, throw error
%     error(sprintf('Multiple TPWS files match the file prefix ''%s''.\n Make the prefix more specific.',filePrefix))
% end

matchingFile = fileList(fileMatchIdx);
zcClicks = [];

for f = 1: length(matchingFile)

    fprintf('Loading file: %s\n',matchingFile{f});
    load(fullfile(IDpath,matchingFile{f}))

    if isrow(zID)
        zID = zID';
    end

    idxZc = find(strcmp(mySpID,'Zc')); % put in your desired species ID here, Zc is Ziphius cavirostris
    zcLabels = zID(:,2) == idxZc;
    % zcLabels = zID(:,2) == 9; % weird clicks
    % zcLabels = zID(:,2) == 10; % bw43
    zcClicks = [zcClicks;zID(zcLabels,1)];

end

[nb,eb,sb,bd] = calculate_bouts(zcClicks,p);

startNumEnc = sb;
endNumEnc = eb;
encN = (1:nb)';

startEnc = datetime(sb,'ConvertFrom','datenum','Format','dd-MMM-20yy HH:mm:ss'); 
endEnc = datetime(eb,'ConvertFrom','datenum','Format','dd-MMM-20yy HH:mm:ss');
encDur = endEnc-startEnc;
startSnipped = startEnc - hours(1);
endSnipped = endEnc + hours(1);

bwEnc = timetable(startSnipped,endSnipped,startEnc,endEnc,encDur,encN,startNumEnc,endNumEnc);

% filter for the times where the 4ch instruments were in the water
% (SOCAL_H_72 only)
% depSt = datenum('01-Jul-2021 19:40:00');
% bwEncIdx = find(bwEnc.startNumEnc >= depSt);
% bwEnc = bwEnc(find(bwEnc.startNumEnc >= depSt),:);
% (SOCAL_H_74 only)
% depSt = datenum('10-Jun-2022 20:32:00');
% bwEncIdx = find(bwEnc.startNumEnc >= depSt);
% bwEnc = bwEnc(find(bwEnc.startNumEnc >= depSt),:);

% filter for encounters that are at least 10 minutes long
bwEnc = bwEnc(find(bwEnc.encDur >= duration([00 10 00])),:);

% sortedbwEnc = sortrows(bwEnc,'encDur','descend');
sortedbwEnc = bwEnc;
% writetimetable(sortedbwEnc,'T:\site_SN\SOCAL_SN_62\TPWS\ID\SOCAL_SN_62_Zc.csv')
% writetable(sortedbwEnc,'G:\Shared drives\Lauren Baggett MS\')

% save("F:\AI_Classification\TPWS\SOCAL_H_74_HE\ID\SOCAL_H_74_HE_EncTable",'bwEnc')
 save(['G:\Shared drives\Lauren Baggett MS\AI_Classification\Time_Tables\Zc\SOCAL_E_63_ES\SOCAL_E_63_ES_encounterTimes.mat'],'bwEnc','sortedbwEnc')