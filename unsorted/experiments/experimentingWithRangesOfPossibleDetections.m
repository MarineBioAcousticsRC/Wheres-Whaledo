clear all
close all
%% User inputs:

arrno = 2;  % which array is primary array (must be a 4ch)
% trackName = '180611_1030';
% trackName = 'track19_180323_104620';
% trackName = 'track43_180327_084016' % base name of track
trackName = 'track78_180402_132525';
% trackName = 'track268_180505_123443';

% detFolder = 'D:\MATLAB_addons\gitHub\wheresWhaledo\experiments';  % folder containing detection file
detFolder = ['D:\SOCAL_E_63\tracking\interns2022\AMS_Datasets\', trackName];
trackFolder = ['D:\SOCAL_E_63\tracking\interns2022\AMS_Datasets\', trackName];   % folder where CTC TDOA is saved and where track will be saved
saveFileName = [trackName, '_loc_', 'Array', num2str(arrno)];

% load drift data:
load('D:\SOCAL_E_63\xwavTables\drift') % drift (sec) and tdrift (datenum) for EW, EN, ES relative to EE

% load partial sigma values
load('D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\sigmaValues.mat')

% load coarse grid model:
% Mcoarse = load('B:\TDOAmodel_200dx200dy50dz.mat');
Mcoarse = load('B:\TDOAmodel_100dx100dy20dz.mat');
% Mcoarse = load('B:\TDOAmodel_100m')
% Mcoarse = load('B:\model_bellhop.mat');
Mcoarse.TDOA(:, 1:12) = -Mcoarse.TDOA(:, 1:12);
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

hydLoc{1} = EEloc;
hydLoc{2} = EWloc;

whaleLocDOA = loc3D_DOAintersect(DET, hydLoc, 'brushing.params', 'interpOff')

% correct for center of model being at EE instead of midway between EE and EW
h0 = mean([hydLoc{1}; hydLoc{2}]);
[hShift(1), hShift(2)] = latlon2xy_wgs84(hydLoc{1}(1), hydLoc{1}(2), h0(1), h0(2));
hShift(3) = h0(3)-hydLoc{1}(3);
for wn = 1:numel(whaleLocDOA)
    whaleLocDOA{wn}.xyz = whaleLocDOA{wn}.xyz - hShift;
end
%% Iterate through whales, each detection, then Localize

xu = unique(Mcoarse.wloc(:, 1));
yu = unique(Mcoarse.wloc(:, 2));
zu = unique(Mcoarse.wloc(:, 3));

% make index matrices for reshaping Lcoarse by unique x, y, z values:

for ix = 1:length(xu)
    Ix(:, ix) = find(Mcoarse.wloc(:,1)==xu(ix));
end

for iy = 1:length(yu)
    Iy(:, iy) = find(Mcoarse.wloc(:,2)==yu(iy));
end


for iz = 1:length(zu)
    Iz(:, iz) = find(Mcoarse.wloc(:,3)==zu(iz));
end

figure(1)
for wn = 1:numel(whale)
    if ~isempty(whale{wn})
        Iuse = find(sum(whale{wn}.IndUsed, 2)>=7);
        if ~isempty(Iuse)
            for ndet = 1:length(Iuse)
                
                TDOA = whale{wn}.TDOA(Iuse(ndet), :);
                sig2 = whale{wn}.sigma(Iuse(ndet), :).^2;
                %             sig2(1:12) = .07;
                %             sig2(13:18) = 345;
                Itdoa = find(whale{wn}.IndUsed(Iuse(ndet), :)==1);
                Lcoarse = (-sum(1./(2*sig2(Itdoa)).*(Mcoarse.TDOA(:, Itdoa)-TDOA(Itdoa)).^2, 2));

                %      Lsml = exp(-1/(2*sig2(1))*sum((Mcoarse.TDOA(:, 1:12)-TDOA(1:12)).^2, 2));
                %       Llrg = exp(-1/(2*sig2(13))*sum((Mcoarse.TDOA(:, 13:18)-TDOA(13:18)).^2, 2));
                %         Lcoarse = Lsml.*Llrg;
                % Lcoarse = Lsml;
                [Lmax, Icoarse] = max(Lcoarse);

                tempwhale{wn}.wloc18_coarse(ndet, :) = Mcoarse.wloc(Icoarse, :);
                tempwhale{wn}.LMSE_coarse(ndet, :) = Lcoarse(Icoarse);
%                 tempwhale{wn}.likelihood(ndet) = Lcoarse(Icoarse).*length(Itdoa);
%                 tempwhale{wn}.likelihood(ndet) = mean(whale{wn}.SNR(ndet, :), 'omitnan');
                tempwhale{wn}.likelihood(ndet) = length(Itdoa);
%                 tempwhale{wn}.likelihood(ndet) = sum(whale{wn}.SNR(ndet, Itdoa));
                tempwhale{wn}.TDet(ndet) = whale{wn}.TDet(Iuse(ndet));

                tempwhale{wn}.Lxmax(ndet, :) = max(Lcoarse(Ix));
                tempwhale{wn}.Lymax(ndet, :) = max(Lcoarse(Iy));
                tempwhale{wn}.Lzmax(ndet, :) = max(Lcoarse(Iz));

                tempwhale{wn}.TDOA(ndet, :) = TDOA;
                tempwhale{wn}.TDOAerr(ndet, :) = abs(Mcoarse.TDOA(Icoarse, :) - TDOA);

                %             modelFile = ['TDOAmodel_10m_n=', num2str(Icoarse, '%05.f')];
                %             Mfine = load(fullfile(MfineFolder, modelFile));
                %
                %             LMSEfine = sum(1./(2*sig2).*(Mfine.TDOA-TDOA).^2, 2);
                %             [~, Ifine] = min(LMSEcoarse);
                %
                %             tempwhale{wn}.wloc18_fine(ndet, :) = Mfine.wloc(Ifine, :);
                %             tempwhale{wn}.LMSE_fine(ndet, :) = LMSEfine(Ifine);
            end

        end
    end
end

%%
figure(1)
wn = 2
Lxmax = tempwhale{wn}.Lxmax - (min(tempwhale{wn}.Lxmax, [], 2));
Lxmax = Lxmax./max(Lxmax, [], 2);
t = (tempwhale{wn}.TDet - tempwhale{wn}.TDet(1)).*24*60;
imagesc(t, xu, Lxmax.')
colorbar
xlabel('Minutes after encounter start')
ylabel('x (m)')
caxis([.9999, 1])
title('Max likelihood in x for each detection')

figure(2)
Lymax = tempwhale{wn}.Lymax - (min(tempwhale{wn}.Lymax, [], 2));
Lymax = Lymax./max(Lymax, [], 2);
t = (tempwhale{wn}.TDet - tempwhale{wn}.TDet(1)).*24*60;
imagesc(t, yu, Lymax.')
colorbar
xlabel('Minutes after encounter start')
ylabel('y (m)')
caxis([.9999, 1])
title('Max likelihood in y for each detection')

figure(3)
Lzmax = tempwhale{wn}.Lzmax - (min(tempwhale{wn}.Lzmax, [], 2));
Lzmax = Lzmax./max(Lzmax, [], 2);
t = (tempwhale{wn}.TDet - tempwhale{wn}.TDet(1)).*24*60;
imagesc(t, zu, Lzmax.')
colorbar
xlabel('Minutes after encounter start')
ylabel('y (m)')
caxis([.9, 1])
title('Max likelihood in z for each detection')

% for wn = 3; %1:numel(tempwhale)
%     if ~isempty(tempwhale{wn})
%
%         for ndet = 1:length(tempwhale{wn}.TDet);
%             t = (tempwhale{wn}.TDet(ndet) - tempwhale{wn}.TDet(1)).*24*60;
%
%             plot3(t.*ones(size(xu)), xu, tempwhale{wn}.Lxmax(ndet, :), 'k')
%             hold on
%             xlabel('time (minutes after encounter start)')
%             ylabel('position (m)')
%             zlabel('Likelihood')
%             title('Max likelihood in x')
%         end
%     end
% end
%
% figure(2)
% for wn = 3; %1:numel(tempwhale)
%     if ~isempty(tempwhale{wn})
%
%         for ndet = 1:length(tempwhale{wn}.TDet);
%             t = (tempwhale{wn}.TDet(ndet) - tempwhale{wn}.TDet(1)).*24*60;
%
%             plot3(t.*ones(size(yu)), yu, tempwhale{wn}.Lymax(ndet, :), 'k')
%             hold on
%             xlabel('time (minutes after encounter start)')
%             ylabel('position (m)')
%             zlabel('Likelihood')
%             title('Max likelihood in y')
%
%         end
%     end
% end
%
% figure(3)
% for wn = 3; %1:numel(tempwhale)
%     if ~isempty(tempwhale{wn})
%
%         for ndet = 1:length(tempwhale{wn}.TDet);
%             t = (tempwhale{wn}.TDet(ndet) - tempwhale{wn}.TDet(1)).*24*60;
%
%             plot3(t.*ones(size(zu)), zu, tempwhale{wn}.Lzmax(ndet, :), 'k')
%             hold on
%             xlabel('time (minutes after encounter start)')
%             ylabel('position (m)')
%             zlabel('Likelihood')
%             title('Max likelihood in z')
%
%         end
%     end
% end
%%
fig = figure(10);
for wn = 1:numel(tempwhale)
    if ~isempty(tempwhale{wn})
        leg{wn} = ['whale ', num2str(wn-1)];
        p{wn} = scatter3(tempwhale{wn}.wloc18_coarse(:, 1), tempwhale{wn}.wloc18_coarse(:, 2), tempwhale{wn}.wloc18_coarse(:, 3), ...
            2 + 40.*(tempwhale{wn}.likelihood-min(tempwhale{wn}.likelihood))./max((tempwhale{wn}.likelihood-min(tempwhale{wn}.likelihood))), ...
            brushing.params.colorMat(wn+1, :).*ones(size(tempwhale{wn}.wloc18_coarse)), 'filled')
        hold on
        %         plot3(tempwhale{wn}.wloc18_coarse(:, 1), tempwhale{wn}.wloc18_coarse(:, 2), tempwhale{wn}.wloc18_coarse(:, 3), ...
        %             'color', brushing.params.colorMat(wn+1, :))

        %         scatter3(tempwhale{wn}.wloc18_fine(:, 1), tempwhale{wn}.wloc18_fine(:, 2), tempwhale{wn}.wloc18_fine(:, 3), ...
        %             40.*(1-(tempwhale{wn}.LMSE_fine-min(tempwhale{wn}.LMSE_fine))./max(tempwhale{wn}.LMSE_fine)), ...
        %             brushing.params.colorMat(wn, :).*ones(size(tempwhale{wn}.wloc18_fine)), 'filled')
        %         plot3(tempwhale{wn}.wloc18_fine(:, 1), tempwhale{wn}.wloc18_fine(:, 2), tempwhale{wn}.wloc18_fine(:, 3))
    end
end
for wn = 1:numel(whaleLocDOA)
    scatter3(whaleLocDOA{wn}.xyz(:, 1), whaleLocDOA{wn}.xyz(:, 2), whaleLocDOA{wn}.xyz(:, 3), [], ...
        brushing.params.colorMat(wn+1, :).*ones(size(whaleLocDOA{wn}.xyz(:, 3))), 'x')
end
scatter3(h(:, 1), h(:, 2), h(:, 3), 'sk')
hold off
fig.WindowState='maximized'
xlabel('E-W (m)')
ylabel('N-S (m)')
zlabel('Depth (m)')

saveas(fig, ['C:\Users\HARP\Desktop\weeklyMeetings\220813\whaleLoc', trackName, 'array', num2str(arrno), 'allWhales'])

%%
for wn = 1:numel(tempwhale)
    try
        tempwhaleLabel(wn) = whale{wn}.label(1);
    catch
        fprintf('no label')
    end
end

for wn = 1:min([numel(tempwhale), numel(whaleLocDOA)])
    colNum = whaleLocDOA{wn}.color;
    Itw = find(tempwhaleLabel==colNum);

    % marker sizes:
    sz = 2 + 50.*(tempwhale{Itw}.likelihood-min(tempwhale{Itw}.likelihood))./max((tempwhale{Itw}.likelihood-min(tempwhale{Itw}.likelihood)));
    colmat = brushing.params.colorMat(colNum, :).*ones(size(tempwhale{Itw}.wloc18_coarse));

    fig = figure(10+wn);
    subplot(3,2,1)
    plot(whaleLocDOA{wn}.t, whaleLocDOA{wn}.xyz(:, 1), 'x', 'color', brushing.params.colorMat(colNum, :))
    hold on
    scatter(tempwhale{Itw}.TDet, tempwhale{Itw}.wloc18_coarse(:, 1), sz, colmat, 'filled')
    hold off
    title('x')
    grid on
    datetick

    subplot(3,2,3)
    plot(whaleLocDOA{wn}.t, whaleLocDOA{wn}.xyz(:, 2), 'x', 'color', brushing.params.colorMat(colNum, :))
    hold on
    scatter(tempwhale{Itw}.TDet, tempwhale{Itw}.wloc18_coarse(:, 2), sz, colmat, 'filled')
    hold off
    title('y')
    grid on
datetick

    subplot(3,2,5)
    plot(whaleLocDOA{wn}.t, whaleLocDOA{wn}.xyz(:, 3), 'x', 'color', brushing.params.colorMat(colNum, :))
    hold on
    scatter(tempwhale{Itw}.TDet, tempwhale{Itw}.wloc18_coarse(:, 3), sz, colmat, 'filled')
    hold off
    title('z')
    grid on
datetick

    subplot(3,2, [2,4,6])
    plot3(whaleLocDOA{wn}.xyz(:, 1), whaleLocDOA{wn}.xyz(:, 2), whaleLocDOA{wn}.xyz(:, 3), 'x', 'color', brushing.params.colorMat(colNum, :));
    hold on
    scatter3(tempwhale{Itw}.wloc18_coarse(:, 1), tempwhale{Itw}.wloc18_coarse(:, 2), tempwhale{Itw}.wloc18_coarse(:, 3), ...
        sz, colmat, 'filled');
    scatter3(h(:, 1), h(:, 2), h(:, 3), 'sk')
    hold off
    legend('DOA intersect', 'TDOA model', 'location', 'southoutside')
    grid on
    xlabel('x')
    ylabel('y')
    zlabel('z')
    fig.WindowState='maximized'
    saveas(fig, ['C:\Users\HARP\Desktop\weeklyMeetings\220813\whaleLoc', trackName,'_array', num2str(arrno), '_whale', num2str(colNum-2)])
end
%%
smPairName{1} = '1-2';
smPairName{2} = '1-3';
smPairName{3} = '1-4';
smPairName{4} = '2-3';
smPairName{5} = '2-4';
smPairName{6} = '3-4';

lrgPairName{1} = 'EE-EW';
lrgPairName{2} = 'EE-EN';
lrgPairName{3} = 'EE-ES';
lrgPairName{4} = 'EW-EN';
lrgPairName{5} = 'EW-ES';
lrgPairName{6} = 'EN-ES';

figure(20)
for wn = 1:numel(whale)
    if ~isempty(whale{wn}) && size(whale{wn}.TDet, 1)>=1
        
        for sp = 1:6
            subplot(6,1,sp)
            plot(whale{wn}.TDet, whale{wn}.TDOA(:, sp), '.', ...
                'color', brushing.params.colorMat(whale{wn}.label(1), :))
            hold on
            title(['Small Ap TDOA, EE, Pair ', smPairName{sp}])
            ylim([-1e-3, 1e-3])
            datetick
        end
    end
end
hold off


figure(21)
for wn = 1:numel(whale)
    if ~isempty(whale{wn})  && size(whale{wn}.TDet, 1)>=1
        for sp = 1:6
            subplot(6,1,sp)
            plot(whale{wn}.TDet, whale{wn}.TDOA(:, sp+6), '.', ...
                'color', brushing.params.colorMat(whale{wn}.label(1), :))
            hold on
            title(['Small Ap TDOA, EW, Pair ', smPairName{sp}])
            datetick
            ylim([-1e-3, 1e-3])
        end
    end
end
hold off


figure(22)
for wn = 1:numel(whale)
    if ~ isempty(whale{wn}) && size(whale{wn}.TDet, 1)>=1
        for sp = 1:6
            subplot(6,1,sp)
            plot(whale{wn}.TDet, whale{wn}.TDOA(:, sp+12), '.', ...
                'color', brushing.params.colorMat(whale{wn}.label(1), :))
            hold on
            title(['Large Ap TDOA, EE, Pair ', lrgPairName{sp}])
            datetick
            ylim([-1, 1])
        end
    end
end
hold off


