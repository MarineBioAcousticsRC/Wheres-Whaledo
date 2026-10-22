% ww_calculate_enc_from_ID_files
%
% LMB 02/24/2026
% you need DetEdit in your path for this!
% from ID files, calculate encounters to run the Where'sWhaledo detector on
%
% Makes one encounter .csv per species in spCodes, named
% <filePrefix>_<species>_encounters<outSuffix>.csv in outDir. encN is the
% chronological encounter number for that species plus the species code,
% e.g. 1_Gg, so encounters stay distinct across species; if sortByDuration is
% true, rows are sorted from shortest to longest encounter (the detector
% runs encounters in row order), but each encounter keeps its encN.

IDpath = ''; % paste your ID folder path here
filePrefix = ''; % enter the prefix name to match
spCodes = {''}; % species codes to make encounters for, e.g. {'Gg','Stenellid','Pm'}
outDir = ''; % folder for output .csv files
outSuffix = ''; % added to the end of each file name, e.g. to note the settings used ('' for none)

%settings
p.gth =  .25;    % gap time in hrs between sessions
p.minBout = 0;  % minimum bout duration in seconds
maxEncDur = 30; % maximum encounter duration in minutes; longer encounters are split into consecutive pieces of this length (Inf = no splitting)
minEncDur = 5; % minimum encounter duration in minutes, applied after splitting (also drops short leftover pieces)
p.ltsaMax = maxEncDur/60; % calculate_bouts splits encounters longer than this (hrs)
sortByDuration = true; % true: sort encounters from shortest to longest; false: keep chronological order

% load all matching ID files once
idFiles = dir(fullfile(IDpath,'*ID*.mat')); % all ID files in the folder
fileList = {idFiles.name};
fileMatchIdx = find(~cellfun(@isempty,regexp(fileList,filePrefix))>0); % grab files in the folder with the matching prefix
matchingFile = fileList(fileMatchIdx);
allID = cell(length(matchingFile),1);
allSpID = cell(length(matchingFile),1);

for f = 1: length(matchingFile)

    fprintf('Loading file: %s\n',matchingFile{f});
    load(fullfile(IDpath,matchingFile{f}),'zID','mySpID')

    if isrow(zID)
        zID = zID';
    end

    allID{f} = zID;
    allSpID{f} = mySpID;

end

if ~isfolder(outDir)
    mkdir(outDir);
end

for s = 1:length(spCodes) % make encounters for each species

    spCode = spCodes{s};
    fprintf('\n--- %s ---\n',spCode)

    % grab click times with this species label (labels can differ per file)
    clicks = [];
    for f = 1:length(matchingFile)
        idxMatch = find(strcmp(allSpID{f},spCode));
        if isempty(idxMatch)
            continue
        end
        clicks = [clicks; allID{f}(allID{f}(:,2) == idxMatch,1)];
    end
    clicks = sort(clicks);

    if isempty(clicks)
        fprintf('No %s clicks found in these ID files, skipping.\n',spCode)
        continue
    end

    [nb,eb,sb,bd] = calculate_bouts(clicks,p); % this function is in DetEdit (also splits encounters longer than maxEncDur)

    % remove encounters shorter than minEncDur
    keep = bd >= minEncDur/(60*24);
    fprintf('Removing %d of %d encounters shorter than %g min\n',sum(~keep),nb,minEncDur)
    sb = sb(keep);
    eb = eb(keep);
    bd = bd(keep);
    nb = length(sb);

    if nb == 0
        fprintf('No %s encounters left after filtering, no file written.\n',spCode)
        continue
    end

    startNumEnc = sb;
    endNumEnc = eb;
    encN = string(1:nb)' + "_" + spCode; % chronological encounter number + species, e.g. "1_Gg"
    Species = repmat(string(spCode),nb,1);

    startEnc = datetime(sb,'ConvertFrom','datenum','Format','dd-MMM-20yy HH:mm:ss');
    endEnc = datetime(eb,'ConvertFrom','datenum','Format','dd-MMM-20yy HH:mm:ss');
    encDur = endEnc-startEnc;

    bwEnc = timetable(startEnc,endEnc,encDur,encN,Species,startNumEnc,endNumEnc);
    if sortByDuration
        bwEnc = sortrows(bwEnc,'encDur'); % shortest first
    end

    fileOut = fullfile(outDir,[filePrefix '_' spCode '_encounters' outSuffix '.csv']);
    writetimetable(bwEnc,fileOut)
    fprintf('Saved %d %s encounters (%s to %s long) to %s\n',nb,spCode,...
        char(min(encDur)),char(max(encDur)),fileOut)

end
