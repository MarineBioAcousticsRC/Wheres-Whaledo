% ww_calculate_enc_from_ID_files
%
% LMB 02/24/2026
% you need DetEdit in your path for this!
% from ID files, calculate encounters to run the Where'sWhaledo detector on

IDpath = dir(''); % paste your ID folder path here
filePrefix = ''; % enter the prefix name to match
spCode = ''; % species code to match, e.g. Gg or Zc
fileOut = ''; % path and name for output .csv file

%settings
p.gth =  .5;    % gap time in hrs between sessions
p.minBout = 0;  % minimum bout duration in seconds
p.ltsaMax = 6;  % ltsa maximum duration per session

fileMatchIdx = find(~cellfun(@isempty,regexp(fileList,filePrefix))>0); % grab files in the folder with the matching prefix
matchingFile = fileList(fileMatchIdx);
clicks = [];

for f = 1: length(matchingFile)

    fprintf('Loading file: %s\n',matchingFile{f});
    load(fullfile(IDpath,matchingFile{f}))

    if isrow(zID)
        zID = zID';
    end

    idxMatch = find(strcmp(mySpID,spCode)); 
    matchLabels = zID(:,2) == idxMatch;
    clicks = [clicks;zID(matchLabels,1)];

end

[nb,eb,sb,bd] = calculate_bouts(clicks,p); % this function is in DetEdit

startNumEnc = sb;
endNumEnc = eb;
encN = (1:nb)';

startEnc = datetime(sb,'ConvertFrom','datenum','Format','dd-MMM-20yy HH:mm:ss'); 
endEnc = datetime(eb,'ConvertFrom','datenum','Format','dd-MMM-20yy HH:mm:ss');
encDur = endEnc-startEnc;

bwEnc = timetable(startEnc,endEnc,encDur,encN,startNumEnc,endNumEnc);
writetimetable(bwEnc,fileOut)