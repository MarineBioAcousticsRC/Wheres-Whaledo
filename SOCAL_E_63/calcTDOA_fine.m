function calcTDOA_fine(trackName, foldername, arrno)

saveFileName = [trackName, '_fineTDOA_', 'Array', num2str(arrno)];

% load detection file:
detDir = dir(fullfile(foldername, ['*det*', trackName, '*.mat']));
load(fullfile(detDir.folder, detDir.name));

% load partial sigma values
load('D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\sigmaValues.mat')

% get brushing params (for plotting consistently with other functions)
global brushing
loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\brushing.params')

% xwav tables:
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EE_C4_xwavLookupTable');
XH{1} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EW_C4_xwavLookupTable');
XH{2} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EN_xwavLookupTable');
XH{3} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_ES_xwavLookupTable');
XH{4} = xwavTable;

% load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m
% h = [0,0,0; h];

txcwin = .004;  % size of window loaded in around each detection
% txcwin = .01;
fs(1) = 100e3;  % sampling rate of HARP 1
fs(2) = 100e3;  % sampling rate of HARP 2
fs(3) = 200e3;  % sampling rate of HARP 3
fs(4) = 200e3;  % sampling rate of HARP 4
maxSigLength = (max(fs)*txcwin); % maximum length in samples of acoustic data in window around each detection
pulseLength4ch = 64; % click duration in 4ch instruments, samples
spd = 60*60*24; % seconds per day, for converting datenum to seconds
xcovInd = [2,3,4,7,8,12]; % indicices of xcov output to use for TDOA pairs
% maxTDOA_lrg = 1500/1480 + .4; % max large ap tdoa
% maxLags_lrg = ceil(maxTDOA_lrg*fs(4)) + pulseLength4ch*2; % maximum number of lags for large ap TDOA (samples)
maxTDOA_sml = 1.1/1480; % max small ap TDOA
maxLags_sml = ceil(maxTDOA_sml*fs(1)) + pulseLength4ch; % maximum number of lags for small ap TDOA (samples)
SNRthresh = 1; % minimum SNR used in calculations
th = 30; % threshold for detector on non-primary array

% filter parameters
fc = 20e3; % filter cutoff frequency
bandWidth4ch = (fs(1)/2-fc);
bandWidth1ch = 80e3-fc;

% calculate filter coef's for each instrument:
for iarr = 1:4
    [b{iarr}, a{iarr}] = ellip(4,0.1,40,fc*2/fs(iarr),'high');
end

% assign indices of other arrays
if arrno==1
    otherArrays = [2,3,4];  % indices of DET containing other arrays besides the primary array
    tdoaSign = [-1, -1, -1]; % sign swap on TDOA (depending on order of hydrophone pairs)

    % which hydrophone pairs are used in each CTC TDOA:
%     hpairCTC(1, :) = [1, 2];
%     hpairCTC(2, :) = [1, 3];
%     hpairCTC(3, :) = [1, 4];

    % when converting CTC TDOA (only between primary array and other
    % arrays) and TDOA for comparison with model (every possible hydrophone
    % pair), we need to know which arrays are accounted for and which need
    % to be caclulated:
%     ctcPairs = [1,2,3]; % which TDOA indices are already calculated
%     otherPairs = [4,5,6]; % which ones need to be obtained

elseif arrno==2
    otherArrays = [1,3,4];  % indices of DET containing other arrays besides the primary array
    tdoaSign = [1, -1, -1]; % sign swap on TDOA (depending on order of hydrophone pairs...
    %   i.e., if 1-2 then no change, if 2-1 then tdoaSign=-1)

    % which hydrophone pairs are used in each TDOA:
%     hpairCTC(1, :) = [1, 2];
%     hpairCTC(2, :) = [2, 3];
%     hpairCTC(3, :) = [2, 4];

%     ctcPairs = [1,4,5]; % which TDOA indices are already calculated
%     otherPairs = [2,3,6]; % which ones need to be obtained

end

% which indices of model TDOAs include each array's small aperture:
smallTDOAInd{1} = 1:6;
smallTDOAInd{2} = 7:12;
largeTDOAInd = 13:18;

% which hydrophone pairs are used in each large ap TDOA:
hpair(1, :) = [1, 2];
hpair(2, :) = [1, 3];
hpair(3, :) = [1, 4];
hpair(4, :) = [2, 3];
hpair(5, :) = [2, 4];
hpair(6, :) = [3, 4];

%% load detection files and click-train files:

% identify .mat file with 'det' and trackname in its filename:
detDir = dir(fullfile(foldername, ['*det*', trackName, '*.mat']));
load(fullfile(detDir.folder, detDir.name)) % Detection data

% load click train correlation data:
% identify .mat file with 'CTC', trackname, and array number in its filename:
ctcDir = dir(fullfile(foldername, [trackName,'*CTC_Array', num2str(arrno), '*.mat']));
load(fullfile(ctcDir.folder, ctcDir.name));
CTC = whale; % Click train correlation data

clear whale

% %% calculate fine TDOA and determine most likely whale position
for wn = 1:numel(CTC) % iterate through each whale number
    if ~isempty(CTC{wn})
        % remove detections which didn't produce any good TDOAs:
        numBad = sum(CTC{wn}.TDOA(:,:,1)==-99, 2); % Number of TDOAs for each detection which were no good
        Irem = find(numBad==3); % Detections where all 3 TDOAs were bad
        CTC{wn}.TDOA(Irem, :, :) = [];
        CTC{wn}.TDet(Irem) = [];
        CTC{wn}.SNR(Irem, :, :) = [];
        CTC{wn}.XCTpk(Irem, :, :) = [];

        % replace -99 values with nan
        [row, col] = find(CTC{wn}.TDOA(:, :, 1) <-20);
        CTC{wn}.TDOA(row, col, 1) = nan;
        CTC{wn}.XCTpk(row, col, 1) = nan;
        CTC{wn}.SNR(row, col, 1) = nan;

        % initialize new variables:
        whale{wn}.TDOA = nan(length(CTC{wn}.TDet), 18);
        whale{wn}.SNR = nan(length(CTC{wn}.TDet), 18);
        whale{wn}.TDet = CTC{wn}.TDet;
        whale{wn}.wlocCoarse = nan(length(CTC{wn}.TDet), 3);
        whale{wn}.wlocFine = nan(length(CTC{wn}.TDet), 3);
        whale{wn}.LMSEcoarse = nan(length(CTC{wn}.TDet), 1);
        whale{wn}.LMSEfine = nan(length(CTC{wn}.TDet), 1);
        whale{wn}.TDOAErrorCoarse = nan(length(CTC{wn}.TDet), 18);
        whale{wn}.TDOAErrorFine = nan(length(CTC{wn}.TDet), 18);
        whale{wn}.IndUsed = zeros(length(CTC{wn}.TDet), 18);
        whale{wn}.label = CTC{wn}.label;
        for ndet = 1:length(CTC{wn}.TDet) % iterate through each remaining detection

            % *****************************************************************
            %  STEP 1: Pull in acoustic data and calculate TDOAs and SNR
            % *****************************************************************
            TDOA = nan(1, 18);                  % initialize TDOAs
            SNR = nan(1, 18);                   % initialize SNRs

            X = zeros(maxSigLength, 4);         % initialize matrix for all instruments' data

            % load data for primary array
            tstartPrimaryArray = CTC{wn}.TDet(ndet)-txcwin/spd/2;   % beginning of period around click
            tendPrimaryArray = tstartPrimaryArray + txcwin/spd;                 % end of period around click
            [x, t{arrno}] = quickxwavRead(tstartPrimaryArray, tendPrimaryArray, fs(arrno), XH{arrno}); % load data and time vector (x and t)
            xf = filtfilt(b{arrno}, a{arrno}, x); % filtered time series around detection



            % *** calculate small ap TDOA and SNR: ***
            [tdetDif, Idet] = min(abs(DET{arrno}.TDet-CTC{wn}.TDet(ndet)));
            [xcsml, lags] = xcov(xf, maxLags_sml);

            if spd*tdetDif<1e-3 && DET{arrno}.color(Idet)==CTC{wn}.label(ndet) % this is the correct detection
                TDOA(smallTDOAInd{arrno}) = DET{arrno}.TDOA(Idet, :);

                ndoa = round(TDOA(smallTDOAInd{arrno}).*fs(arrno)); % TDOA in samples

                for ixcov = 1:length(xcovInd)
                    indNDOA = find(lags==ndoa(ixcov));
                    
                    % indices of signal:
                    indSig = max([1, indNDOA-pulseLength4ch/2]):min([length(xcsml), (indNDOA+pulseLength4ch/2)]);
                    % indices of noise:
                    indNoise = 1:length(xcsml); % all indices
                    indNoise(indSig) = []; % remove indices of signal
                    sigPk2Pk = range(xcsml(indSig, xcovInd(ixcov)));
                    noisePk2Pk = range(xcsml(indNoise, xcovInd(ixcov)));
                    SNR(smallTDOAInd{arrno}(ixcov)) = sigPk2Pk/noisePk2Pk;
                end

            end

            % upsample four channel data and put all instruments into one matrix
            xi = interpft(xf(:, 1), maxSigLength);     % upsample primary array's data
            X(:, arrno) = xi;                      % put into matrix of all acoustic data

            % determine which CTC TDOAs were good:
            Igood = find(~isnan(CTC{wn}.TDOA(ndet, :, 1)));

            % iterate through each instrument with a "good" TDOA and pull in
            % acoustic data:
            for ia = 1:length(Igood)

                thisInstNo = otherArrays(Igood(ia)); % which array is being accessed in this loop
                thisTDOAno = Igood(ia); % which column in TDOA is being used

                tstart = tstartPrimaryArray + tdoaSign(thisTDOAno)*CTC{wn}.TDOA(ndet, thisTDOAno, 1)/spd;
                tend = tstart + txcwin/spd;
                [x, t{thisInstNo}] = quickxwavRead(tstart, tend, ...
                    fs(thisInstNo), XH{thisInstNo});             % load data and time vector (x and t)
                xf = filtfilt(b{thisInstNo}, a{thisInstNo}, x);  % filter and save data

                if fs(thisInstNo)==100e3 % if this is 4ch data, upsample and put into X
                    
                    if max(xf(:, 1) >th) % test to see if click is higher than threshold, if not don't bother with it
                        xi = interpft(xf(:, 1), maxSigLength); % upsample array's data
                        X(:, thisInstNo) = xi;                             % put into matrix of all acoustic data

                        % calculate small aperture TDOA:
                        [tdetDif, Idet] = min(abs(DET{thisInstNo}.TDet+tdoaSign(thisTDOAno)*CTC{wn}.TDOA(ndet, thisTDOAno, 1)/spd-CTC{wn}.TDet(ndet)));
                        [xcsml, lags] = xcov(xf, maxLags_sml);

%                         if (spd*tdetDif<.1 && DET{thisInstNo}.color(Idet)==CTC{wn}.label(ndet))||spd*tdetDif<1e-3 % this is probably the correct detection
                        if spd*tdetDif<.1

                            TDOA(smallTDOAInd{thisInstNo}) = DET{thisInstNo}.TDOA(Idet, :);

                            ndoa = round(TDOA(smallTDOAInd{thisInstNo}).*fs(thisInstNo)); % TDOA in samples

                            for ixcov = 1:length(xcovInd)
                                indNDOA = find(lags==ndoa(ixcov));
                                
                                % indices of signal:
                                indSig = max([1, indNDOA-pulseLength4ch/2]):min([length(xcsml), (indNDOA+pulseLength4ch/2)]);
                                % indices of noise:
                                indNoise = 1:length(xcsml); % all indices
                                indNoise(indSig) = []; % remove indices of signal
                                sigPk2Pk = range(xcsml(indSig, xcovInd(ixcov)));
                                noisePk2Pk = range(xcsml(indNoise, xcovInd(ixcov)));
                                SNR(smallTDOAInd{thisInstNo}(ixcov)) = sigPk2Pk/noisePk2Pk;
                            end

                        end
                       
                    end
                else % this is 1ch data, put into X
                    X(1:min([maxSigLength, length(xf)]), thisInstNo) = xf(1:min([maxSigLength, length(xf)]));
                end
            end

            % ************ calculate large ap TDOA ***********************
            % time difference of arrival from CTC:
            if arrno ==1
                tdoaCTC(1:3) = CTC{wn}.TDOA(ndet, :, 1);
                tdoaCTC(4) = tdoaCTC(2)-tdoaCTC(1);
                tdoaCTC(5) = tdoaCTC(3)-tdoaCTC(1);
                tdoaCTC(6) = tdoaCTC(3)-tdoaCTC(2);
            elseif arrno==2
                tdoaCTC([1, 4, 5]) = CTC{wn}.TDOA(ndet, :, 1);
                tdoaCTC(2) = tdoaCTC(1)+tdoaCTC(4);
                tdoaCTC(3) = tdoaCTC(1)+tdoaCTC(5);
                tdoaCTC(6) = tdoaCTC(5)-tdoaCTC(4);
            end

            Ibad = find(CTC{wn}.TDOA(ndet, :, 1)<=-50); % bad TDOA
            tdoaCTC(Ibad) = nan(size(Ibad));

            [XC, lags] = xcov(X); % Cross-covariate the data

            for ixcov = 1:length(xcovInd) % iterate through hydrophone pairs and calculate TDOA and SNR
                [~, ipk] = max(XC(:, xcovInd(ixcov)));
                TDOA(largeTDOAInd(ixcov)) = lags(ipk)/fs(4) + tdoaCTC(ixcov);

                % *** calculate SNR ***:
                % indices of signal:
                indSig = max([1, ipk-pulseLength4ch]):min([length(XC), (ipk+pulseLength4ch)]);
                % indices of noise:
                indNoise = 1:length(XC); % all indices
                indNoise(indSig) = []; % remove indices of signal
                sigPk2Pk = range(XC(indSig, xcovInd(ixcov)));
                noisePk2Pk = range(XC(indNoise, xcovInd(ixcov)));
                SNR(largeTDOAInd(ixcov)) = sigPk2Pk/noisePk2Pk;
            end

            TDOA(TDOA<-20) = nan; % replace bad TDOAs with NaN
            SNR(isnan(TDOA)) = nan;

%             % *****************************************************************
%             % STEP 2: Calculate drift, sigma values and LMSE w/ coarse model
%             % *****************************************************************
% 
%             % Calculate drift:
%             for idrift = 1:3
%                 driftCorrection(idrift) = feval(Dpoly{idrift},  CTC{wn}.TDet(ndet));
%             end
%             driftCorrection(4) = driftCorrection(2) - driftCorrection(1);
%             driftCorrection(5) = driftCorrection(3) - driftCorrection(1);
%             driftCorrection(6) = driftCorrection(3) - driftCorrection(2);

%             TDOA(13:18) = TDOA(13:18) + driftCorrection;

            sig2_xcov = 1./(bandWidth4ch^2.*SNR);  % variance of the TDOA due to imprecision in cross-covariation
            % Note on above: I only use 4ch bandwidth, because after xcov no energy should remain above 4ch nyquist

            % calculate the variance:
            sig2(1:6) = sig2EE*[ones(1,6); TDOA(1:6).^2; ones(1,6); sig2_xcov(1:6)]; % variance for small ap array 1
            sig2(7:12) = sig2EW*[ones(1,6); TDOA(7:12).^2; ones(1,6); sig2_xcov(7:12)]; % variance for small ap array 2
            sig2(13:18) = sum(sig2lrg.*[ones(1,6); TDOA(13:18).^2; ones(1,6); sig2_xcov(13:18)]);

            Iuse = find(~isnan(TDOA) & TDOA>-20 & SNR>SNRthresh);
            % make sure detection has enough data to ues in localization:
            % Need at least one small ap and one large ap



            %             LMSEcoarse = sum(1./(2*sig2(Iuse)).*(Mcoarse.TDOA(:, Iuse)-TDOA(Iuse)).^2, 2);
            %             IuseLrg = Iuse(Iuse>=13);
            %             Llrg = 1./2*sqrt(sum(sig2(IuseLrg))).*sum((Mcoarse.TDOA(:, IuseLrg)-TDOA(IuseLrg)).^2, 2);
            %             Iusesml = Iuse(Iuse<=12);
            %             Lsml = 1./2*sqrt(sum(sig2(Iusesml))).*sum((Mcoarse.TDOA(:, Iusesml)-TDOA(Iusesml)).^2, 2);
            %
            %             if isempty(Llrg)
            %                 LMSEcoarse = Lsml;
            %             elseif isempty(Lsml)
            %                 LMSEcoarse = Llrg;
            %             else
            %                 LMSEcoarse = Llrg + Lsml;
            %             end
            %             [~, Icoarse] = min(LMSEcoarse);

            % *****************************************************************
            % BEGIN STEP 3: Fine grid LMSE minimization
            % *****************************************************************
            %             modelFile = ['TDOAmodel_10m_n=', num2str(Icoarse, '%05.f')];
            %             Mfine = load(fullfile(MfineFolder, modelFile));

            %             LMSEfine = sum(1./(2*sig2(Iuse)).*(Mfine.TDOA(:, Iuse)-TDOA(Iuse)).^2, 2);

            %             IuseLrg = Iuse(Iuse>=13);
            %             Llrg = 1./2*sqrt(sum(sig2(IuseLrg))).*sum((Mfine.TDOA(:, IuseLrg)-TDOA(IuseLrg)).^2, 2);
            %             Iusesml = Iuse(Iuse<=12);
            %             Lsml = 1./2*sqrt(sum(sig2(Iusesml))).*sum((Mfine.TDOA(:, Iusesml)-TDOA(Iusesml)).^2, 2);

            %             if isempty(Llrg)
            %                 LMSEfine = Lsml;
            %             elseif isempty(Lsml)
            %                 LMSEfine = Llrg;
            %             else
            %                 LMSEfine = Llrg + Lsml;
            %             end
            %             [~, Ifine] = min(LMSEfine);


            whale{wn}.IndUsed(ndet, Iuse) = 1;
            whale{wn}.TDOA(ndet, :) = TDOA;
            whale{wn}.SNR(ndet, :) = SNR;
            whale{wn}.TDet(ndet) =  CTC{wn}.TDet(ndet);
            whale{wn}.sigma(ndet, :) = sqrt(sig2);
            %             whale{wn}.wlocCoarse(ndet, :) = Mcoarse.wloc(Icoarse, :);
            %             whale{wn}.wlocFine(ndet, :) = Mfine.wloc(Ifine, :);
            %             whale{wn}.LMSEcoarse(ndet, :) = LMSEcoarse(Icoarse);
            %             whale{wn}.LMSEfine(ndet, :) = LMSEfine(Ifine);
            %             whale{wn}.TDOAErrorCoarse(ndet, :) = abs(Mcoarse.TDOA(Icoarse, :)-TDOA);
            %             whale{wn}.TDOAErrorFine(ndet, :) = abs(Mfine.TDOA(Ifine, :)-TDOA);
            whale{wn}.label = CTC{wn}.label;
        end
    end
end


%% Plot

% figure(1)
% scatter3(h(:, 1), h(:, 2), h(:, 3), 'rs')
% hold on
% for wn = 1:numel(whale)
%     if ~isempty(whale{wn}.TDet)
%         I = find(~isnan(whale{wn}.LMSEfine));
%         scatter3(whale{wn}.wlocCoarse(I, 1), whale{wn}.wlocCoarse(I, 2), whale{wn}.wlocCoarse(I, 3), ...
%             max(whale{wn}.SNR(I).').', brushing.params.colorMat(wn+1, :).*ones(length(I), 1), 'x')
%         scatter3(whale{wn}.wlocFine(I, 1), whale{wn}.wlocFine(I, 2), whale{wn}.wlocFine(I, 3), ...
%             40, brushing.params.colorMat(wn+1, :).*ones(length(I), 1))
%     end
%
% end
% hold off
% xlim([-5000, 5000])
% ylim([-5000, 5000])
% pbaspect([1,1,1])

fig = figure(2);
for sp = 1:6
    subplot(6,1,sp)
    for wn = 1:numel(whale)
        if ~isempty(whale{wn})
            if sp == 1
                title('EE TDOA pairs')
            end
            scatter(whale{wn}.TDet, whale{wn}.TDOA(:, sp), 3.*whale{wn}.SNR(:, sp), 'filled')
            %         I = find(whale{wn}.SNR(:, sp)>1.5);
            hold on
            %         scatter(whale{wn}.TDet(I), whale{wn}.TDOA(I, sp),  'x')
        end
    end
    hold off

end
title('EE TDOA pairs')
saveas(fig, fullfile(foldername, [saveFileName, '_TDOA_EE']))

fig = figure(3);
for sp = 1:6
    subplot(6,1,sp)

    for wn = 1:numel(whale)
        if ~isempty(whale{wn})
            if sp == 1
                title('EW TDOA pairs')
            end
            scatter(whale{wn}.TDet, whale{wn}.TDOA(:, sp+6), 3.*whale{wn}.SNR(:, sp+6), 'filled')
            I = find(whale{wn}.SNR(:, sp)>1.5);
            hold on
            %         scatter(whale{wn}.TDet(I), whale{wn}.TDOA(I, sp),  'x')
        end
    end
    hold off

end
saveas(fig, fullfile(foldername, [saveFileName, '_TDOA_EW']))

fig = figure(4);
for sp = 1:6
    subplot(6,1,sp)
    for wn = 1:numel(whale)
        if ~isempty(whale{wn})
            if sp == 1
                title('large Ap TDOA pairs')
            end
            scatter(whale{wn}.TDet, whale{wn}.TDOA(:, sp+12), 3.*whale{wn}.SNR(:, sp+12), 'filled')
            %         I = find(whale{wn}.SNR(:, sp)>1.5);
            hold on
            %         scatter(whale{wn}.TDet(I), whale{wn}.TDOA(I, sp),  'x')
        end
    end
    
    hold off

end
saveas(fig, fullfile(foldername, [saveFileName, '_TDOA_lrg']))

save(fullfile(foldername, saveFileName), 'whale')