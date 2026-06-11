function ww_run_detect_localize()

% ww_run_detect_localize()
%
% nested helper function to run the detection/localization steps

global PARAMS HANDLES

% add in a few other parameters that don't need to be customized:
PARAMS.project.DetectionLocalizationParams.twin = 30; % length of xwav data to be read in at a time
PARAMS.project.DetectionLocalizationParams.xcRow = [2, 3, 4, 7, 8, 12]; % which xcov columns to use for TDOA
PARAMS.project.DetectionLocalizationParams.frameLengthUs = 2000; % default for FFT calculation, from Triton SPICE remora
project = PARAMS.project; save(PARAMS.projectSaveFolder + project.ConfigRelFilePath,'project'); % update config file
detParam = PARAMS.project.DetectionLocalizationParams; % save for easier referencing within this function

% load in instrument orientations + relevant metadata
paramsFiles = dir(PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+"\*harp4chParams.mat");
instruments = extractBefore(string({paramsFiles.name}),'_harp4chParams.mat');
for j = 1:numel(paramsFiles)
    H{j} = load(fullfile(paramsFiles(j).folder,paramsFiles(j).name));
    XH{j} = ww_build_xwav_dir(detParam.(instruments(j)).xwavPath); % build directory of files
end

% show progress bar on ui
HANDLES.ui.detect.progressRow.Visible = 'on';
HANDLES.ui.detect.progressLabel.Text = "Running detector...";
HANDLES.ui.detect.progressFill.Position = [1 0 0 0];
drawnow;

% set up parallel pool
pool = gcp('nocreate');
if ~isempty(pool)
    delete(pool); % shut down existing pools
end
parpool('local',detParam.parpool); % start new ones with desired size

% initialize output folder
if ~isfolder(detParam.SavePath)
    mkdir(detParam.SavePath);
end

% if we have ID files, set up to compare
if detParam.IDcheck
    IDdir = dir(detParam.IDpath+"\*ID*.mat"); % find all ID files
    for ins = 1:numel(instruments)
        IDdir = IDdir(contains(string({IDdir.name}),instruments(ins)),:); % check to make sure they match this ensemble
        if numel(IDdir) == 0 % if we didn't find any matching files
            fprintf("No ID files matching instrument "+instruments(ins)+" found in your ID directory. Skipping ID label integration steps for this instrument. \n")
        else
            allID.(instruments(ins)) = [];
            fileIdx.(instruments(ins)) = [];
            for id = 1:numel(IDdir)
                thisFile = load(fullfile(IDdir(id).folder,IDdir(id).name));
                allID.(instruments(ins)) = [allID.(instruments(ins));thisFile.zID];
                fileIdx.(instruments(ins)) = [fileIdx.(instruments(ins)); repmat(id,size(thisFile.zID,1),1)];
                allLabels.(instruments(ins)).Labels{id} = thisFile.mySpID;
            end
        end
    end
end

% load the encounter file
encFile = readtable(detParam.EncPath);

for k = 1:height(encFile) % for each encounter

    % if the user doesn't want to overwrite, check if this encounter file
    % already exists
    if ~detParam.OverwriteCheck
        outFiles = dir(fullfile(detParam.SavePath, '*.mat'));
        hasMatch = any(contains({outFiles.name}, sprintf('enc%d_', encFile.encN(k)))); % note underscore helps avoid enc1 matching enc10
        if hasMatch
            fprintf("Skipping encounter %d/%d (already processed) \n", k, height(encFile));
            continue
        end
    end

    % display the progress bar
    frac = k/height(encFile);
    frac = max(0,min(1,frac));
    pos = HANDLES.ui.detect.progressContainer.Position;
    HANDLES.ui.detect.progressFill.Position = [1 0 pos(3)*frac pos(4)];
    HANDLES.ui.detect.progressLabel.Text = sprintf("Running detector, encounter %d/%d", k, height(encFile));
    drawnow;

    for j = 1:length(instruments) % run this per instrument

        % subset xwav directory
        [XHsub, startSample, endSample, rfTimes, rfSamples, fs] = ww_subset_xwav_dir(XH{j}, datenum(encFile.startEnc(k)-years(2000)), datenum(encFile.endEnc(k)-years(2000))); % subset them based on times of interest

        % design filter params
        if detParam.bpEdges(2) == fs/2 % if the upper limit is the nyquist
            [b, a] = ellip(4,0.1,40,detParam.bpEdges(1)*2/fs,'high'); % highpass filter
            minLen = 3 * max(length(a), length(b));
        elseif detParam.bpEdges(2) < fs/2 % if the upper limit is below the nyquist
            [b, a] = ellip(4,0.1,40,detParam.bpEdges.*2/fs); % highpass filter
            minLen = 3 * max(length(a), length(b));
        else % make the user change their settings
            fprintf("Upper bandpass edge > Nyquist, modify settings and try again. \n")
        end

        % detTable = table;
        detTable = cell(1,numel(XHsub));
        fCell = cell(1,numel(XHsub));

        parfor xv = 1:numel(XHsub) % for each xwav; parallelize here

            dt = table; % local table for this worker
            f = [];   % local frequency vector for this worker

            for s = startSample(xv) : detParam.twin*fs : endSample(xv) % define start

                e = s + detParam.twin*fs - 1; % if we're at the last interval
                if e > endSample(xv)
                    e = endSample(xv);
                end
                [x, t, ~] = ww_read_xwav(fullfile(XHsub(xv).folder,XHsub(xv).name), [round(s) round(e)], rfTimes{xv}, rfSamples{xv}); % read xwav data
                if size(x,1) <= minLen
                    continue
                end
                xf = filtfilt(b, a, x); % filter data

                if max(xf(:,detParam.(instruments(j)).channel))>=detParam.detThresh_counts
                    
                    [pks, ind] = findpeaks(xf(:,detParam.(instruments(j)).channel), 'minPeakHeight', detParam.detThresh_counts, 'minPeakDistance', detParam.minPkDist_ms*1E-3*fs);
                    tdet = t(ind); % times of detections

                    for i = 1:length(ind) % for each detection

                        cStart = ind(i)-((detParam.bufferLength_ms/1E3)*fs); % start sample to grab
                        cEnd = ind(i)+((detParam.bufferLength_ms/1E3)*fs); % end sample to grab
                        if cStart <= 0 % if we went to a sample before 1
                            cStart = 1;
                        end
                        if cEnd > size(xf,1) % catch in case the peak is right at the end of the data window
                            cEnd = size(xf,1);
                        end

                        % pull out filtered click timeseries
                        clickBuff = xf(cStart:cEnd, detParam.(instruments(j)).channel)';

                        % calculate click parameters
                        [specClickTf, peakFr, ppSignal, f] = ww_calculate_click_params(clickBuff, fs, instruments(j), detParam);

                        % TDOA + DOA calculations
                        [az, el, doa, tdoa, xamp] = ww_calculate_TDOA_DOA(xf, ind(i), fs, H{j}, detParam);

                        tempTable = table(tdet(i), pks(i), [az, el], doa.', tdoa, xamp, specClickTf, peakFr, ppSignal, ...
                            'VariableNames', {'TDet', 'DAmp', 'Ang', 'DOA', 'TDOA', 'XAmp', 'Spectra', 'PeakFr', 'ppRL'});

                        dt = [dt;tempTable]; % populate the table for this detection

                    end % close loop for each detection

                end % close for if statement, if we have detections above the threshold

            end % loop for reading xwav chunks

            detTable{xv} = dt; % save to the detTable for this encounter
            fCell{xv} = f;

        end % loop for reading xwav files

        detTable = vertcat(detTable{:}); % combine subtables
        % add in a few more empty columns for brushing
        detTable.('Label') = num2str(zeros(size(detTable.('TDet'))));
        detTable.('color') = 2.*ones(size(detTable.('TDet')));
        detTable.('Species') = num2str(nan(size(detTable.('TDet'))));
        detTable.Species = string(detTable.Species);

        % input species information from ID files, if selected
        if detParam.IDcheck
            if exist('allID','var') % if we found some matching ID files
                if isfield(allID,instruments(j)) % if we have data for this instrument
                    [idxAmatch, idxBmatch] = ww_match_dets_with_ID_files(sort(allID.(instruments(j))(:,1)),datenum(detTable.TDet),1e-6); % find matching timestamps
                    for b = 1:length(idxBmatch)
                        spMatch = allID.(instruments(j))(idxAmatch(b),2);
                        labelMatch = allLabels.(instruments(j)).Labels{fileIdx.(instruments(j))(idxAmatch(b))}{spMatch};
                        detTable.Species(b) = labelMatch;
                    end
                end
            end
        end

        % save info from this instrument
        DET{j} = detTable;
        freq{j} = fCell{1}; % frequency vectors all the same, grab the first one
        p{j} = detParam;

    end

    % save the output for this encounter
    detFileName = [PARAMS.project.DataSourceName+"_detections_enc"+num2str(encFile.encN(k))+"_"+datestr(encFile.startEnc(k),'yymmdd_HHMMSS')+"_to_"+datestr(encFile.endEnc(k),'yymmdd_HHMMSS')+".mat"];
    save(detParam.SavePath+"\"+detFileName,"DET","freq","p")

    % end

end

delete(pool); % close down parallel pools
project = PARAMS.project; save(PARAMS.projectSaveFolder + project.ConfigRelFilePath,'project'); % save params again to project config file

end