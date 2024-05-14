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

altDrift = load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift_ADCPonly.mat');

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


% hydLoc{1} = EEloc;
% hydLoc{2} = EWloc;
%
% whaleLocDOA = loc3D_DOAintersect(DET, hydLoc, 'brushing.params', 'interpOff')
%
% % correct for center of model being at EE instead of midway between EE and EW
% h0 = mean([hydLoc{1}; hydLoc{2}]);
% [hShift(1), hShift(2)] = latlon2xy_wgs84(hydLoc{1}(1), hydLoc{1}(2), h0(1), h0(2));
% hShift(3) = h0(3)-hydLoc{1}(3);
% for wn = 1:numel(whaleLocDOA)
%     whaleLocDOA{wn}.xyz = whaleLocDOA{wn}.xyz - hShift;
% end

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

            end

        end


        % calculate DOA intersect for detections on both 4ch
        Idoa = find(sum(whale{wn}.IndUsed(:, 1:12), 2)==12); % find where DOA intersect can be used

        if ~isempty(Idoa)
            whaleLocDOA{wn}.xyz = zeros(length(Idoa), 3);
            whaleLocDOA{wn}.t = zeros(length(Idoa), 1);

            for idoa = 1:length(Idoa)
                tdoa1 = whale{wn}.TDOA(Idoa(idoa), 1:6);
                tdoa2 = whale{wn}.TDOA(Idoa(idoa), 7:12);

                doa1 = (tdoa1.'.*c)\HEE;
                doa2 = (tdoa2.'.*c)\HEW;

                D = [doa1; -doa2];
                R = D.'\(h(2, :) - h(1, :)).';

                w1 = R(1).*doa1 + h(1, :);
                w2 = R(2).*doa2 + h(2, :);

                wloc = (w1+w2)./2;
                whaleLocDOA{wn}.xyz(idoa, :) = wloc;
                whaleLocDOA{wn}.t(idoa) = whale{wn}.TDet(Idoa(idoa));
                
            end
            whaleLocDOA{wn}.color = wn+2;
        end

    end
end

%% Plot X, Y, Z vs T
for wn = 1:numel(tempwhale)
    try
        tempwhaleLabel(wn) = whale{wn}.label(1);
    catch
        fprintf('no label')
    end
end

for wn = 1:min([numel(tempwhale), numel(whaleLocDOA)])

    if ~ isempty(whaleLocDOA{wn}) && ~isempty(tempwhale{wn})
        colNum = whaleLocDOA{wn}.color;
        
        % marker sizes:
        sz = 10 + 50.*(tempwhale{wn}.likelihood-min(tempwhale{wn}.likelihood))./max((tempwhale{wn}.likelihood-min(tempwhale{wn}.likelihood)));
        colmat = brushing.params.colorMat(colNum, :).*ones(size(tempwhale{wn}.wloc18_coarse));

        fig = figure(10+wn);
        subplot(3,2,1)
        scatter(tempwhale{wn}.TDet, tempwhale{wn}.wloc18_coarse(:, 1), sz, colmat, 'filled')
        hold on
        plot(whaleLocDOA{wn}.t, whaleLocDOA{wn}.xyz(:, 1), 'kx')
        hold off
        title('x')
        grid on
        xlim([min(tempwhale{wn}.TDet), max(tempwhale{wn}.TDet)])
        datetick('x', 'keeplimits')

        subplot(3,2,3)
        scatter(tempwhale{wn}.TDet, tempwhale{wn}.wloc18_coarse(:, 2), sz, colmat, 'filled')
        hold on
        plot(whaleLocDOA{wn}.t, whaleLocDOA{wn}.xyz(:, 2), 'kx')
        hold off
        title('y')
        grid on
        xlim([min(tempwhale{wn}.TDet), max(tempwhale{wn}.TDet)])
        datetick('x', 'keeplimits')

        subplot(3,2,5)
        scatter(tempwhale{wn}.TDet, tempwhale{wn}.wloc18_coarse(:, 3), sz, colmat, 'filled')
        hold on
        plot(whaleLocDOA{wn}.t, whaleLocDOA{wn}.xyz(:, 3), 'kx')
        hold off
        title('z')
        xlim([min(tempwhale{wn}.TDet), max(tempwhale{wn}.TDet)])
        grid on
        datetick('x', 'keeplimits')

        subplot(3,2, [2,4,6])
        plot3(whaleLocDOA{wn}.xyz(:, 1), whaleLocDOA{wn}.xyz(:, 2), whaleLocDOA{wn}.xyz(:, 3), 'kx');
        hold on
        scatter3(tempwhale{wn}.wloc18_coarse(:, 1), tempwhale{wn}.wloc18_coarse(:, 2), tempwhale{wn}.wloc18_coarse(:, 3), ...
            sz, colmat, 'filled');
        scatter3(h(:, 1), h(:, 2), h(:, 3), 'sk')
        hold off
        legend('DOA intersect', 'TDOA model', 'location', 'southoutside')
        grid on
        xlabel('x')
        ylabel('y')
        zlabel('z')
        title(['whale ', num2str(wn)])
        axis([-4500, 4500, -4500, 4500, -200, 1000])
        pbaspect([1,1,1])
        fig.WindowState='maximized';
        saveas(fig, ['C:\Users\HARP\Desktop\weeklyMeetings\220813\whaleLoc', trackName,'_array', num2str(arrno), '_whale', num2str(colNum-2)])
    end

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
    title(['whale ', num2str(wn)])
    fig.WindowState='maximized'
    saveas(fig, ['C:\Users\HARP\Desktop\weeklyMeetings\220813\whaleLoc', trackName,'_array', num2str(arrno), '_whale', num2str(colNum-2)])

end


%% Plot TDOA surfaces
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

wn = 2;

% I = find(tempwhale{wn}.likelihood==12);
% ndet = I(1);
% ndet = 163
ndet=1;
=======
I = find(tempwhale{wn}.likelihood==18);
ndet = I(2);


% calculate drift
% Calculate drift:
for idrift = 1:3
    driftCorrection(idrift) = feval(Dpoly{idrift},  tempwhale{wn}.TDet(ndet));
end
driftCorrection(4) = driftCorrection(2) - driftCorrection(1);
driftCorrection(5) = driftCorrection(3) - driftCorrection(1);
driftCorrection(6) = driftCorrection(3) - driftCorrection(2);


fig = figure(21);
set(fig,'units','normalized','outerposition',[0 0 1 1])



[X, Y, Z] = meshgrid(-5000:100:5000, -5000:100:5000, -100:20:1000);



V1 = sqrt((X-h(1, 1)).^2 + (Y-h(1, 2)).^2 + (Z-h(1, 3)).^2) - ...
    sqrt((X-h(2, 1)).^2 + (Y-h(2, 2)).^2 + (Z-h(2, 3)).^2) - ...
    tempwhale{wn}.TDOA(ndet, 13)*c;

p1 = patch(isosurface(X, Y, Z, V1, 0));
set(p1,'FaceColor','red','EdgeColor','none');
hold on

V2 = sqrt((X-h(1, 1)).^2 + (Y-h(1, 2)).^2 + (Z-h(1, 3)).^2) - ...
    sqrt((X-h(3, 1)).^2 + (Y-h(3, 2)).^2 + (Z-h(3, 3)).^2) - ...
    tempwhale{wn}.TDOA(ndet, 14)*c;

p2 = patch(isosurface(X, Y, Z, V2, 0));
set(p2,'FaceColor','blue','EdgeColor','none');


V3 = sqrt((X-h(1, 1)).^2 + (Y-h(1, 2)).^2 + (Z-h(1, 3)).^2) - ...
    sqrt((X-h(4, 1)).^2 + (Y-h(4, 2)).^2 + (Z-h(4, 3)).^2) - ...
    tempwhale{wn}.TDOA(ndet, 15)*c;

p3 = patch(isosurface(X, Y, Z, V3, 0));
set(p3,'FaceColor','green','EdgeColor','none');

V4 = sqrt((X-h(2, 1)).^2 + (Y-h(2, 2)).^2 + (Z-h(2, 3)).^2) - ...
    sqrt((X-h(3, 1)).^2 + (Y-h(3, 2)).^2 + (Z-h(3, 3)).^2) - ...
    tempwhale{wn}.TDOA(ndet, 16)*c;

p4 = patch(isosurface(X, Y, Z, V4, 0));
set(p4,'FaceColor','black','EdgeColor','none');

V5 = sqrt((X-h(2, 1)).^2 + (Y-h(2, 2)).^2 + (Z-h(2, 3)).^2) - ...
    sqrt((X-h(4, 1)).^2 + (Y-h(4, 2)).^2 + (Z-h(4, 3)).^2) - ...
    tempwhale{wn}.TDOA(ndet, 17)*c;

p5 = patch(isosurface(X, Y, Z, V5, 0));
set(p5,'FaceColor','cyan','EdgeColor','none');

V6 = sqrt((X-h(3, 1)).^2 + (Y-h(3, 2)).^2 + (Z-h(3, 3)).^2) - ...
    sqrt((X-h(4, 1)).^2 + (Y-h(4, 2)).^2 + (Z-h(4, 3)).^2) - ...
    tempwhale{wn}.TDOA(ndet, 15)*c;

p6 = patch(isosurface(X, Y, Z, V6, 0));
set(p6,'FaceColor','yellow','EdgeColor','none');

view(3);
camlight

% small ap:
see = HEE\(tempwhale{wn}.TDOA(ndet, 1:6).*c).';
sew = HEW\(tempwhale{wn}.TDOA(ndet, 7:12).*c).';

r = 0:5000;

plot3(see(1).*r, see(2).*r, see(3).*r, 'linewidth', 7)
plot3(sew(1).*r+h(2, 1), sew(2).*r+h(2, 2), sew(3).*r+h(2, 3), 'linewidth', 7)
axis([-5000, 5000, -5000, 5000, -100, 1000])

wloc = tempwhale{wn}.wloc18_coarse(ndet, :);
plot3(wloc(1), wloc(2), wloc(3), 'rx', 'markersize', 25)
hold off

legend('EE-EW', 'EE-EN', 'EE-ES', 'EW-EN', 'EW-ES', 'EN-ES', 'EE small', 'EW small')
xlabel('x')
ylabel('y')
zlabel('z')

%% Expected TDOA based on DOA intersect vs calculated TDOA

for wn = 1:numel(tempwhale)
    if ~isempty(tempwhale{wn})
        Ind = find(sum(isnan(tempwhale{wn}.TDOA), 2)==0);
        if ~isempty(Ind)
            for idet = 1:length(tempwhale{wn}.TDet)
                if sum(isnan(tempwhale{wn}.TDOA(idet,:)))==0 % all instruments used in localization
                    DOA1 = (tempwhale{wn}.TDOA(idet, 1:6).'.*c)\HEE;
                    DOA1 = DOA1./sqrt(sum(DOA1.^2));

                    DOA2 = (tempwhale{wn}.TDOA(idet, 7:12).'.*c)\HEW;
                    DOA2 = DOA2./sqrt(sum(DOA2.^2));

                    D = [DOA1; -DOA2];
                    R = D.'\(h(2, :)-h(1, :)).';

                    w1 = R(1).*DOA1 + h(1, :);
                    w2 = R(2).*DOA2 + h(2, :);

                    wloc = (w1+w2)./2;
                    tempwhale{wn}.DOAint_wloc(idet, :) = wloc;
                    tempwhale{wn}.DOAint_w1(idet, :) = w1;
                    tempwhale{wn}.DOAint_w2(idet, :) = w2;

                    doa1exp = wloc-h(1, :);
                    doa1exp = doa1exp./sqrt(sum(doa1exp.^2));

                    tempwhale{wn}.expTDOA(idet, 1:6) = (HEE*doa1exp.').';

                    doa2exp = wloc-h(2, :);
                    doa2exp = doa2exp./sqrt(sum(doa2exp.^2));

                    tempwhale{wn}.expTDOA(idet, 7:12) = (HEW*doa2exp.').';

                    rngs = sqrt(sum((h-wloc).^2, 2)); % ranges to each instrument

                    tempwhale{wn}.expTDOA(idet, 13) = (rngs(1)-rngs(2))/c;
                    tempwhale{wn}.expTDOA(idet, 14) = (rngs(1)-rngs(3))/c;
                    tempwhale{wn}.expTDOA(idet, 15) = (rngs(1)-rngs(4))/c;
                    tempwhale{wn}.expTDOA(idet, 16) = (rngs(2)-rngs(3))/c;
                    tempwhale{wn}.expTDOA(idet, 17) = (rngs(2)-rngs(4))/c;
                    tempwhale{wn}.expTDOA(idet, 18) = (rngs(3)-rngs(4))/c;


                end
            end

            figure(21+wn)
            for sp = 1:6
                subplot(6,1,sp)
                %     plot(tempwhale{wn}.TDOA(Ind, sp + 12))
                %     hold on
                %     plot(tempwhale{wn}.expTDOA(Ind, sp + 12))
                %     hold off
                histogram(abs(tempwhale{wn}.TDOA(Ind, sp+12)-tempwhale{wn}.expTDOA(Ind, sp+12)), ...

                    'BinWidth', .0001)
                hold on
                stem(abs(driftCorrection(sp)), 5)
                hold off
                title(['TDOA error, pair ', num2str(sp), '; whale ', num2str(wn)])
                %                 xlim([0, .1])

            end
            legend('TDOA error', 'drift correction')
        end
    end

end

%% Try undoing drift correction and adding in altDrift correction:


end

