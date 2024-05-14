clear all
%% User inputs:

arrno = 2;  % which array is primary array (must be a 4ch)
% trackName = '180611_1030';
% trackName = 'track43_180327_084016';                                % base name of track
% detFolder = 'D:\SOCAL_E_63\tracking\interns2022\AMS_Datasets\track43_180327_084016';  % folder containing detection file
% trackFolder = 'D:\SOCAL_E_63\tracking\interns2022\AMS_Datasets\track43_180327_084016';   % folder where CTC TDOA is saved and where track will be saved

trackName = 'track19_180323_104620';
% trackName = '180512_032001' % base name of track
% detFolder = 'D:\MATLAB_addons\gitHub\wheresWhaledo\experiments';  % folder containing detection file
detFolder = 'D:\SOCAL_E_63\tracking\interns2022\AMS_Datasets\track19_180323_104620';
trackFolder = 'D:\SOCAL_E_63\tracking\interns2022\AMS_Datasets\track19_180323_104620';   % folder where CTC TDOA is saved and where track will be saved

saveFileName = [trackName, '_loc_', 'Array', num2str(arrno)];

% load drift data:
load('D:\SOCAL_E_63\xwavTables\drift') % drift (sec) and tdrift (datenum) for EW, EN, ES relative to EE

% load partial sigma values
load('D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\sigmaValues.mat')

% load coarse grid model:
Mcoarse = load('B:\TDOAmodel_200dx200dy50dz.mat');
MfineFolder = 'B:\modelFiles_10mFromVariableGridSize'; % folder containing fine grid model

% get brushing params (for plotting consistently with other functions)
global brushing
loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\brushing.params')

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
maxTDOA_lrg = 1500/1480 + max(max(abs(drift))); % max large ap tdoa
maxLags_lrg = ceil(maxTDOA_lrg*fs(4)) + pulseLength4ch*2; % maximum number of lags for large ap TDOA (samples)
maxTDOA_sml = 1.1/1480; % max small ap TDOA
maxLags_sml = ceil(maxTDOA_sml*fs(1)) + pulseLength4ch; % maximum number of lags for small ap TDOA (samples)
SNRthresh = 1; % minimum SNR used in calculations
th = 30; % threshold for detector on non-primary array

% filter parameters
fc = 20e3; % filter cutoff frequency
bandWidth4ch = (fs(1)/2-fc);
bandWidth1ch = 80e3-fc;

% assign indices of other arrays
if arrno==1
    otherArrays = [2,3,4];  % indices of DET containing other arrays besides the primary array
    tdoaSign = [-1, -1, -1]; % sign swap on TDOA (depending on order of hydrophone pairs)

    % which hydrophone pairs are used in each CTC TDOA:
    hpairCTC(1, :) = [1, 2];
    hpairCTC(2, :) = [1, 3];
    hpairCTC(3, :) = [1, 4];

    % when converting CTC TDOA (only between primary array and other
    % arrays) and TDOA for comparison with model (every possible hydrophone
    % pair), we need to know which arrays are accounted for and which need
    % to be caclulated:
    ctcPairs = [1,2,3]; % which TDOA indices are already calculated
    otherPairs = [4,5,6]; % which ones need to be obtained

elseif arrno==2
    otherArrays = [1,3,4];  % indices of DET containing other arrays besides the primary array
    tdoaSign = [1, -1, -1]; % sign swap on TDOA (depending on order of hydrophone pairs...
    %   i.e., if 1-2 then no change, if 2-1 then tdoaSign=-1)

    % which hydrophone pairs are used in each TDOA:
    hpairCTC(1, :) = [1, 2];
    hpairCTC(2, :) = [2, 3];
    hpairCTC(3, :) = [2, 4];

    ctcPairs = [1,4,5]; % which TDOA indices are already calculated
    otherPairs = [2,3,6]; % which ones need to be obtained

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

%% load detection files and fine TDOA files:

% identify .mat file with 'det' and trackname in its filename:
detDir = dir(fullfile(detFolder, ['*det*', trackName, '*.mat']));
load(fullfile(detDir.folder, detDir.name)) % Detection data

% load fine TDOA data:
% identify .mat file with 'fineTDOA', trackname, and array number in its filename:
tdoaDir = dir(fullfile(trackFolder, [trackName,'*fineTDOA*Array', num2str(arrno), '*.mat']));
load(fullfile(tdoaDir.folder, tdoaDir.name));

%% Iterate through whales, each detection, then Localize

% Round 1: only localize detections that were present on all instruments

figure(1)
for wn = 1:numel(whale)
    if ~isempty(whale{wn})
        Iuse = find(sum(whale{wn}.IndUsed, 2)>=7);
        if ~isempty(Iuse)
            for ndet = 1:length(Iuse)
                TDOA = whale{wn}.TDOA(Iuse(ndet), :);
                sig2 = whale{wn}.sigma(Iuse(ndet), :).^2;
                LMSEcoarse = sum(1./(2*sig2).*(Mcoarse.TDOA-TDOA).^2, 2);

                [~, Icoarse] = min(LMSEcoarse);

                tempwhale{wn}.wloc18_coarse(ndet, :) = Mcoarse.wloc(Icoarse, :);
                tempwhale{wn}.LMSE_coarse(ndet, :) = LMSEcoarse(Icoarse);

                modelFile = ['TDOAmodel_10m_n=', num2str(Icoarse, '%05.f')];
                Mfine = load(fullfile(MfineFolder, modelFile));

                LMSEfine = sum(1./(2*sig2).*(Mfine.TDOA-TDOA).^2, 2);
                [~, Ifine] = min(LMSEcoarse);

                tempwhale{wn}.wloc18_fine(ndet, :) = Mfine.wloc(Ifine, :);
                tempwhale{wn}.LMSE_fine(ndet, :) = LMSEfine(Ifine);
            end
        end
    end
end
%%
%% Calculate DOA intersect track

% EE:
EEdep = [32.65871	-119.47711	-1325.5285	4.1544];    % deployment location
EErec = [32.65879	-119.47705	-1319.6305	3.1279];    % recovery location
[EEx, EEy] = latlon2xy_wgs84(EEdep(1), EEdep(2), EErec(1), EErec(2)); % difference between deployment and recover
EEdiff = sqrt(EEx^2 + EEy^2 + (EEdep(3)-EErec(3)).^2); % distance between dep and rec
EEloc = mean([EEdep(1:3); EErec(1:3)]); % Location used in model

% EW:
EWdep = [32.65646	-119.48815	-1330.1631];
EWrec = [32.65632	-119.48814	-1323.6842];
[EWx, EWy] = latlon2xy_wgs84(EWdep(1), EWdep(2), EWrec(1), EWrec(2));
EWdiff = sqrt(EWx^2 + EWy^2 + (EWdep(3)-EWrec(3)).^2);
EWloc = mean([EWdep(1:3); EWrec(1:3)]);

hydLoc{1} = EEloc;
hydLoc{2} = EWloc;
whaleLoc = loc3D_DOAintersect(DET, hydLoc, 'brushing.params')
%%
figure(1)
for wn = 1:numel(tempwhale)
    if ~isempty(tempwhale{wn})
        scatter3(tempwhale{wn}.wloc18_coarse(:, 1), tempwhale{wn}.wloc18_coarse(:, 2), tempwhale{wn}.wloc18_coarse(:, 3), ...
            40.*(2-(tempwhale{wn}.LMSE_coarse-min(tempwhale{wn}.LMSE_coarse))./max(tempwhale{wn}.LMSE_coarse)), ...
            brushing.params.colorMat(wn, :).*ones(size(tempwhale{wn}.wloc18_fine)), 'x')
        hold on
        scatter3(tempwhale{wn}.wloc18_fine(:, 1), tempwhale{wn}.wloc18_fine(:, 2), tempwhale{wn}.wloc18_fine(:, 3), ...
            40.*(1-(tempwhale{wn}.LMSE_fine-min(tempwhale{wn}.LMSE_fine))./max(tempwhale{wn}.LMSE_fine)), ...
            brushing.params.colorMat(wn, :).*ones(size(tempwhale{wn}.wloc18_fine)), 'filled')
%         plot3(tempwhale{wn}.wloc18_fine(:, 1), tempwhale{wn}.wloc18_fine(:, 2), tempwhale{wn}.wloc18_fine(:, 3))
    end
end
scatter3(whaleLoc{1}.xyz(:, 1), whaleLoc{1}.xyz(:, 2), whaleLoc{1}.xyz(:, 3), [], ...
            brushing.params.colorMat(wn+1, :).*ones(size(whaleLoc{1}.xyz(:, 3))), 'x')
       
hold off


xlabel('E-W (m)')
ylabel('N-S (m)')
zlabel('Depth (m)')