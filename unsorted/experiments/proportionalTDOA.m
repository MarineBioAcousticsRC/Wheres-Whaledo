clear all
close all
%% User inputs:

arrno = 2;  % which array is primary array (must be a 4ch)
% trackName = '180611_1030';
trackName = 'track19_180323_104620';
% trackName = 'track43_180327_084016' % base name of track
% trackName = 'track78_180402_132525';
% trackName = 'track268_180505_123443';

% detFolder = 'D:\MATLAB_addons\gitHub\wheresWhaledo\experiments';  % folder containing detection file
detFolder = ['D:\SOCAL_E_63\tracking\interns2022\AMS_Datasets\', trackName];
trackFolder = ['D:\SOCAL_E_63\tracking\interns2022\AMS_Datasets\', trackName];   % folder where CTC TDOA is saved and where track will be saved
saveFileName = [trackName, '_loc_', 'Array', num2str(arrno)];

% load drift data:
load('D:\SOCAL_E_63\xwavTables\drift') % drift (sec) and tdrift (datenum) for EW, EN, ES relative to EE
altDrift = load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift_ADCPonly.mat');
% load partial sigma values
load('D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\sigmaValues.mat')

% load coarse grid model:
% Mcoarse = load('B:\TDOAmodel_200dx200dy50dz.mat');
M = load('B:\TDOAmodel_100dx100dy20dz.mat');
MRT(:, 1:5) = M.TDOA(:, 1)./M.TDOA(:, 2:6);
MRT(:, 6:9) = M.TDOA(:, 2)./M.TDOA(:, 3:6);
MRT(:, 10:12) = M.TDOA(:, 3)./M.TDOA(:, 4:6);
MRT(:, 13:14) = M.TDOA(:, 4)./M.TDOA(:, 5:6);
MRT(:, 15) = M.TDOA(:, 5)./M.TDOA(:, 6);


% Mcoarse = load('B:\TDOAmodel_40dx40dy20dz.mat');
% Mcoarse = load('B:\TDOAmodel_100m')
% Mcoarse = load('B:\model_bellhop.mat');
M.TDOA(:, 1:12) = -M.TDOA(:, 1:12);
MfineFolder = 'B:\modelFiles_10mFrom200m'; % folder containing fine grid model

% load hydrophone locations:
load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m
h = [0,0,0; h];

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
if numel(detDir)>1
    load(fullfile(detDir(1).folder, detDir(1).name)) % Detection data
else
    load(fullfile(detDir.folder, detDir.name)) % Detection data
end
% load fine TDOA data:
% identify .mat file with 'fineTDOA', trackname, and array number in its filename:
tdoaDir = dir(fullfile(trackFolder, [trackName,'*fineTDOA*Array', num2str(arrno), '*.mat']));
load(fullfile(tdoaDir(1).folder, tdoaDir(1).name));

%% Calculate DOA intersect track

% EE:
EEdep = [32.65871	-119.47711	-1325.5285];    % deployment location
EErec = [32.65879	-119.47705	-1319.6305];    % recovery location
[EEx, EEy] = latlon2xy_wgs84(EEdep(1), EEdep(2), EErec(1), EErec(2)); % difference between deployment and recover
EEdiff = sqrt(EEx^2 + EEy^2 + (EEdep(3)-EErec(3)).^2); % distance between dep and rec
EEloc = mean([EEdep(1:3); EErec(1:3)]); % Location used in model

% EW:
EWdep = [32.65646	-119.48815	-1330.1631];
EWrec = [32.65632	-119.48814	-1323.6842];
[EWx, EWy] = latlon2xy_wgs84(EWdep(1), EWdep(2), EWrec(1), EWrec(2));
EWdiff = sqrt(EWx^2 + EWy^2 + (EWdep(3)-EWrec(3)).^2);
EWloc = mean([EWdep(1:3); EWrec(1:3)]);


hyd1 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EE_Hmatrix_new.mat');
hyd2 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EW_Hmatrix_new.mat');

% HEW = H;

% Reorder hydrophones to fit new TDOA order
HEE = [hyd1.recPos(2,:)-hyd1.recPos(1,:);
    hyd1.recPos(3,:)-hyd1.recPos(1,:);
    hyd1.recPos(4,:)-hyd1.recPos(1,:);
    hyd1.recPos(3,:)-hyd1.recPos(2,:);
    hyd1.recPos(4,:)-hyd1.recPos(2,:);
    hyd1.recPos(4,:)-hyd1.recPos(3,:)];

HEE = hyd1.H;

HEW = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];

c = 1488.4;

load('D:\SOCAL_E_63\xwavTables\drift') % drift (sec) and tdrift (datenum) for EW, EN, ES relative to EE
driftTDOA(:, 1) = drift(1, :).';
driftTDOA(:, 2) = drift(2, :).';
driftTDOA(:, 3) = drift(3, :).';
driftTDOA(:, 4) = drift(2, :).' - drift(1, :).';
driftTDOA(:, 5) = drift(3, :).' - drift(1, :).';
driftTDOA(:, 6) = drift(3, :).' - drift(2, :).';

figure(10)
for wn = 1:numel(whale)
    if ~isempty(whale{wn})
        Iuse = find(sum(whale{wn}.IndUsed, 2)==18);
        if ~isempty(Iuse)
            for ndet = 1:length(Iuse)
                [~, idrift] = min((tdrift - whale{wn}.TDet(Iuse(ndet))).^2);
                tdoa = whale{wn}.TDOA(Iuse(ndet), 13:18);
                tdoa = tdoa + driftTDOA(idrift, :);
                RT(1:5) = tdoa(1)./tdoa(2:6);
                RT(6:9) = tdoa(2)./tdoa(3:6);
                RT(10:12) = tdoa(3)./tdoa(4:6);
                RT(13:14) = tdoa(4)./tdoa(5:6);
                RT(15) = tdoa(5)/tdoa(6);

                [mdiff, Iloc] = min(sum((MRT-RT).^2, 2));

                W{wn}.wloc(ndet, :) = M.wloc(Iloc, :);
                
                % calculate DOA intersect:
                tdoa1 = whale{wn}.TDOA(Iuse(ndet), 1:6);
                tdoa2 = whale{wn}.TDOA(Iuse(ndet), 7:12);

                doa1 = (tdoa1.'.*c)\HEE;
                doa2 = (tdoa2.'.*c)\HEW;

                D = [doa1; -doa2];
                R = D.'\(h(2, :) - h(1, :)).';

                w1 = R(1).*doa1 + h(1, :);
                w2 = R(2).*doa2 + h(2, :);

                W{wn}.wlocDOA = (w1+w2)./2;

            end
            scatter3(W{wn}.wloc(:, 1), W{wn}.wloc(:,2), W{wn}.wloc(:,3), 'filled')
            hold on
            scatter3(W{wn}.wlocDOA(:, 1), W{wn}.wlocDOA(:,2), W{wn}.wlocDOA(:,3), 'x')
        end
    end
end
hold off
