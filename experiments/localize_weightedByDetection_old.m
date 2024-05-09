%% click by click fine-tdoa calculation
load('clickByClick_roughTDOA_180611_1030.mat')

% load other detections
load('detections_brushDOA180611_1030')

% load drift data:
load('D:\SOCAL_E_63\xwavTables\drift') % drift (sec) and tdrift (datenum) for EW, EN, ES relative to EE

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

txcwin = .004;
fs4ch = 100e3;
fs1ch = 200e3;
fs(1) = fs4ch;
fs(2) = fs4ch;
fs(3) = fs1ch;
fs(4) = fs1ch;

spd = 60*60*24;
xcovInd = [2,3,4,7,8,12]; % indicices of xcov output to use for TDOA pairs
maxTDOA_lrg = 1500/1480 + max(max(abs(drift))); % max large ap tdoa

% filter parameters
fc = 20e3;
% filter coeff's:
for iarr = 1:4
    [b{iarr}, a{iarr}] = ellip(4,0.1,40,fc*2/fs(iarr),'high');
end
arrno = 2; % primary array
otherArrays = 1:4;
otherArrays(arrno) = [];

% indTDOAshift = indices of TDOA corresponding to needed shift in time for clicks to
% align. For example, if the primary array is 2, then to align the clicks,
% instrument 3 will need to be shifted by TDOA(idet, 4) since the 4th
% column represents pair 2-3.
% signTDOAshift is the sign, necessary because if instrument 2 is primary
% array, then pair 1-2 will need to be inverted to 2-1 for the shift to
% go in the correct direction.
if arrno == 1
    indTDOAshift = [1, 2, 3];
    signTDOAshift = [1, 1, 1];
elseif arrno==2
    indTDOAshift = [1, 4, 5];
    signTDOAshift = [-1, 1, 1];
end

%%
for wn = unique(label)
    detno = 0;
    Iwn = find(label==wn);

    % initialize
    whale{wn-1}.TDet = zeros(length(Iwn), 1);
    whale{wn-1}.DAmp = zeros(length(Iwn), 4);
    whale{wn-1}.XAmp = zeros(length(Iwn), 6);
    whale{wn-1}.TDOA = zeros(length(Iwn), 6);
    whale{wn-1}.xcSNR = zeros(length(Iwn), 6);

    for iwn = 1:length(Iwn)
        %         tic
        tstart = TDet(Iwn(iwn)) - txcwin/2/spd; % beginning time of window to be read in

        % determine window of time to read in:
        t1 = tstart;
        t2 = t1 + txcwin/spd;

        % read in data for primary array
        [xtemp, t{arrno}] = quickxwavRead(t1, t2, fs(arrno), XH{arrno});
        t{arrno} = t{arrno}; % correct read-in time vector to actual time (relative to primary array)
        x{arrno} = filtfilt(b{iarr}, a{iarr}, xtemp); % filter

        for ia = 1:length(otherArrays)
            iarr = otherArrays(ia);
            tshift = signTDOAshift(ia)*TDOA(Iwn(iwn), indTDOAshift(ia)); % time shift
            % determine window of time to read in:
            t1 = tstart - tshift/spd;
            t2 = t1 + txcwin/spd;
            [xtemp, t{iarr}] = quickxwavRead(t1, t2, fs(iarr), XH{iarr});
            x{iarr} = filtfilt(b{iarr}, a{iarr}, xtemp); % filter
        end

        % !!!!!!! Maybe implement delay and sum here at a later point? !!!!
        sigLength = min([length(t{3}), length(t{4})]);
        X = zeros(sigLength, 4);
        X(:, 1) = interpft(x{1}(:, 1), sigLength);
        X(:, 2) = interpft(x{2}(:, 1), sigLength);
        X(:, 3) = x{3}(1:sigLength);
        X(:, 4) = x{4}(1:sigLength);

        [xc, lags] = xcov(X);
        [xcmax, ixcmax] = max(xc);
        tdoa = TDOA(Iwn(iwn), :) + lags(ixcmax(xcovInd))./fs(3);

        % calculate "SNR" of xcov output
        for ixc = 1:length(xcovInd)
            indSig = (-18:18) + ixcmax(xcovInd(ixc)); % indices of signal (+/- 18 samples around peak)
            indSig(indSig<1) = []; % remove indices less that 1
            psig = sum(xc(indSig, xcovInd(ixc)).^2)./length(indSig); % power of signal

            indNoise = setdiff(1:length(xc), indSig);
            pnoise = sum(xc(indNoise, xcovInd(ixc)).^2)./length(indNoise); % power of noise

            xcsnr(ixc) = psig/pnoise;
        end

        detno = detno + 1;
        whale{wn-1}.TDet(detno) = TDet(Iwn(iwn));
        whale{wn-1}.DAmp(detno, :) = max(X);
        whale{wn-1}.XAmp(detno, :) = xcmax(xcovInd);
        whale{wn-1}.TDOA(detno, :) = tdoa;
        whale{wn-1}.xcSNR(detno, :) = xcsnr;
        %         howLongItTake(detno) = toc;
    end
end

%% Plot TDOA
tmin = [];
tmax = [];
for wn = 1:numel(whale)
    tmin = min([tmin, min(whale{wn}.TDet)]);
    tmax = max([tmax, max(whale{wn}.TDet)]);
end

figure(1)
driftCorrection = [-0.0571, 0.3234, 0.2907, 0.3805, 0.3478, -0.0327];
for pn = 1:6
    sp(pn) = subplot(6,1,pn);
    for wn = 1:numel(whale)
        I = find(whale{wn}.TDOA(:,pn) > -10);
        scatter(whale{wn}.TDet(I), whale{wn}.TDOA(I, pn) + driftCorrection(pn), ...
            24, brushing.params.colorMat(wn+1, :).*(1-.5.*(whale{wn}.TDet(I)-whale{wn}.TDet(1))./max(whale{wn}.TDet-whale{wn}.TDet(1))), 'filled')
        hold on
    end
    hold off
    xlim([tmin, tmax])
    datetick
    grid on
end

linkaxes(sp, 'x')
legend('unlabeled', 'whale 1', 'whale 2')
%% Localize with model
% load coarse model
Mcoarse = load('D:\SOCAL_E_63\tracking\experiments\largeApertureTDOA\TDOAmodel_200m');
MfineFolder = 'D:\SOCAL_E_63\tracking\experiments\largeApertureTDOA\modelFiles_10mFrom200m\';
% set up parameters for LMS (CHECK WITH JOHN ABOUT THESE)
sigmaH_sml = .1e-3; % uncertainty in small ap hydrophone locations
sigmaX_sml = .05e-3; % uncertainty in small ap TDOA
sig_sml = sqrt(sigmaH_sml^2 + sigmaX_sml^2);

sigmaH_lrg = 5e-3; % uncertainty in large ap hydrophone locations
sigmaX_lrg = .3e-3; % uncertainty in large ap TDOA
sig_lrg = sqrt(sigmaH_lrg^2 + sigmaX_lrg^2);

iter = 0;
errIter = 0;
for wn = 1:numel(whale)
    for idet = 1:length(whale{wn}.TDet)
        tic
        % ****************** coarse localization: ******************

        % /start Large aperture:/
        tdoa_lrg = whale{wn}.TDOA(idet, :); % large aperture TDOA

        % determine which HARPs to use:
        Iuse_lrg = find(tdoa_lrg>-10); % large ap TDOAs that haven't been tagged as invalid
        if length(Iuse_lrg)>1
            M = length(Iuse_lrg); % number of large aperture TDOAs used

            % Determine drift correction
            for idrift = 1:3
                [~, driftCorrection(idrift)] = clockDriftCorrection(whale{wn}.TDet(idet), tdrift, drift(idrift, :));
            end
            driftCorrection(4) = driftCorrection(2) - driftCorrection(1);
            driftCorrection(5) = driftCorrection(3) - driftCorrection(1);
            driftCorrection(6) = driftCorrection(3) - driftCorrection(2);

            tdoaCalc_lrg = whale{wn}.TDOA(idet, Iuse_lrg) + driftCorrection(Iuse_lrg);
            tdoaMod_lrg = Mcoarse.TDOA(:, Iuse_lrg + 12);

            % Max likelihood, large aperture:
            Llrg = (2*pi*sig_lrg^2)^(-M/2).*exp((-1/(2*sig_lrg^2)).*sum((tdoaMod_lrg - tdoaCalc_lrg).^2, 2));

            % /end Large aperture/
            % -----------------------------------------------------------
            % /start Small aperture:/
            Iuse_sml = 1:12;
            if arrno==1 % if array 1 is primary array

                [tdetDif(1), I1] = min(abs(DET{1}.TDet(idet)-whale{wn}.TDet));
                tdoa_sml(1:6) = DET{1}.TDOA(I1, :);

                if whale{wn}.TDOA(idet, 1) > -10 % use data from AR2
                    tshift = signTDOAshift(1)*whale{wn}.TDOA(idet, 1); % time shift
                    [tdetDif(2), I2] = min(abs(DET{1}.TDet-(whale{wn}.TDet(idet)- tshift/spd)));
                    tdoa_sml(7:12) = DET{2}.TDOA(I2, :);
                else
                    Iuse_sml(7:12) = [];
                end
            elseif arrno==2 % if array 2 is primary array

                if whale{wn}.TDOA(idet, 1) > -10 % use data from AR1
                    tshift = signTDOAshift(1)*whale{wn}.TDOA(idet, 1); % time shift
                    [tdetDif(1), I1] = min(abs(DET{1}.TDet-(whale{wn}.TDet(idet)- tshift/spd)));
                    tdoa_sml(1:6) = DET{1}.TDOA(I1, :);
                else
                    Iuse_sml(1:6) = [];
                end
                [tdetDif(2), I2] = min(abs(DET{2}.TDet-whale{wn}.TDet(idet)));
                tdoa_sml(7:12) = DET{2}.TDOA(I2, :);

            end
            N = length(Iuse_sml);
            % Max likelihood, small aperture:
            Lsml = (2*pi*sig_sml^2)^(-N/2).*exp((-1/(2*sig_sml^2)).*sum((Mcoarse.TDOA(:, Iuse_sml) - tdoa_sml(Iuse_sml)).^2, 2));

            % /end small aperture/

            % Localize:
            Lcoarse = Llrg.*Lsml;

            [Lmax, Icoarse] = max(Lcoarse);

            if M==6 && N==12
                errIter = errIter + 1;
                minTDOAerr_lrg(errIter, :) =  min((tdoaMod_lrg - tdoaCalc_lrg).^2);
                minTDOAerr_sml(errIter, :) =  min((Mcoarse.TDOA(:, Iuse_sml) - tdoa_sml(Iuse_sml)).^2);
                %          figure
                %          for sp = 1:6
                %              subplot(6,1,sp)
                %              plot((tdoaMod_lrg(:, sp) - tdoaCalc_lrg(sp)).^2)
                %          end
                %          ok = 1
            end

            whale{wn}.wloc_coarse(idet, :) = Mcoarse.wloc(Icoarse, :);
            whale{wn}.Lmax_coarse(idet) = Lmax;
            whale{wn}.Lmax_lrg_coarse(idet) = Llrg(Icoarse);
            whale{wn}.Lmax_sml_coarse(idet) = Lsml(Icoarse);

            % ****************** fine localization: ******************
            modelFile = ['TDOAmodel_10m_n=', num2str(Icoarse, '%05.f')];
            Mfine = load(fullfile(MfineFolder, modelFile));

            Llrg = (2*pi*sig_lrg^2)^(-M/2).*exp((-1/(2*sig_lrg^2)).*sum((Mfine.TDOA(:, Iuse_lrg + 12) - tdoaCalc_lrg).^2, 2));
            Lsml = (2*pi*sig_sml^2)^(-N/2).*exp((-1/(2*sig_sml^2)).*sum((Mfine.TDOA(:, Iuse_sml) - tdoa_sml(Iuse_sml)).^2, 2));

            Lfine = Llrg.*Lsml;

            [Lmax, Ifine] = max(Lfine);

            whale{wn}.wloc_fine(idet, :) = Mfine.wloc(Ifine, :);
            whale{wn}.Lmax_fine(idet) = Lmax;
            whale{wn}.Lmax_lrg_fine(idet) = Llrg(Ifine);
            whale{wn}.Lmax_sml_fine(idet) = Lsml(Ifine);


            iter = iter+1;
            iterTime(iter) = toc;
        else
            whale{wn}.wloc_coarse(idet, :) = nan(1,3);
            whale{wn}.Lmax_coarse(idet) = nan;
            whale{wn}.Lmax_lrg_coarse(idet) = nan;
            whale{wn}.Lmax_sml_coarse(idet) = nan;
            whale{wn}.wloc_fine(idet, :) = nan(1,3);
            whale{wn}.Lmax_fine(idet) = nan;
            whale{wn}.Lmax_lrg_fine(idet) = nan;
            whale{wn}.Lmax_sml_fine(idet) = nan;
        end
    end
end


%% Plot track
figure(2)
for wn = 1:numel(whale)
    %     scatter3(whale{wn}.wloc_coarse(:, 1)+50.*(rand(size(whale{wn}.wloc_coarse(:,1)))-.5), whale{wn}.wloc_coarse(:, 2)+50.*(rand(size(whale{wn}.wloc_coarse(:,1)))-.5), whale{wn}.wloc_coarse(:, 3)+50.*(rand(size(whale{wn}.wloc_coarse(:,1)))-.5), ...
    %         14, brushing.params.colorMat(wn+1, :).*(1-.5.*(whale{wn}.TDet-whale{wn}.TDet(1))./max(whale{wn}.TDet-whale{wn}.TDet(1))), 'filled')
    scatter3(whale{wn}.wloc_coarse(:, 1), whale{wn}.wloc_coarse(:, 2), whale{wn}.wloc_coarse(:, 3), ...
        14, brushing.params.colorMat(wn+1, :).*(1-.5.*(whale{wn}.TDet-whale{wn}.TDet(1))./max(whale{wn}.TDet-whale{wn}.TDet(1))), 'filled')
    hold on
end
hold off
xlabel('E-W')
ylabel('N-S')
zlabel('height above arrays')

figure(3)
yyaxis left
for wn = 1:numel(whale)
    p(1) = scatter(whale{wn}.TDet, (whale{wn}.Lmax_coarse), 24, brushing.params.colorMat(wn+1, :).*(1-.5.*(whale{wn}.TDet-whale{wn}.TDet(1))./max(whale{wn}.TDet-whale{wn}.TDet(1))), 'o')
    hold on
    p(2) = scatter(whale{wn}.TDet, (whale{wn}.Lmax_lrg_coarse), 24, brushing.params.colorMat(wn+1, :).*(1-.5.*(whale{wn}.TDet-whale{wn}.TDet(1))./max(whale{wn}.TDet-whale{wn}.TDet(1))), 'x')
    p(3) = scatter(whale{wn}.TDet, (whale{wn}.Lmax_sml_coarse), 24, brushing.params.colorMat(wn+1, :).*(1-.5.*(whale{wn}.TDet-whale{wn}.TDet(1))./max(whale{wn}.TDet-whale{wn}.TDet(1))), '^')
end
hold off
ylabel('Max Likelihood')


yyaxis right
for wn = 1:numel(whale)
    p(4) = scatter(whale{wn}.TDet, sqrt(sum(whale{wn}.wloc_coarse.^2, 2)), 'filled')
    hold on
end
ylabel('range')
% hold off
% ylabel('Range to EE, m')
% legend(p, 'L', 'Llrg', 'Lsml', 'Range')

% figure(3)
% for wn = 1:numel(whale)
%     subplot(3,1,1)
%     p(1) = histogram(whale{wn}.Lmax_coarse)
%     title('Lmax Histogram')
%     subplot(3,1,2)
%     p(2) = histogram(whale{wn}.Lmax_lrg_coarse)
%     title('Lmax Large Ap Histogram')
%     subplot(3,1,3)
%     p(3) = histogram(whale{wn}.Lmax_sml_coarse, 10000)
%     title('Lmax Small Ap Histogram')
% end
%%
pairName{1} = 'EE-EW';
pairName{2} = 'EE-EN';
pairName{3} = 'EE-ES';
pairName{4} = 'EW-EN';
pairName{5} = 'EW-ES';
pairName{6} = 'EN-ES';

figure(4)
for sp = 1:6
    subplot(6,1,sp)
    histogram(minTDOAerr_lrg(:, sp), 0:1e-8:1.14e-4)
    ylim([0, 1600])
    title(pairName{sp});
    ylabel('counts')
end
xlabel('minimum error between measured and modeled TDOA')

%%

figure(7)
for sp = 1:12
    subplot(6,2,sp)
    histogram(minTDOAerr_sml(:, sp))
    %     ylim([0, 1600])
    title(num2str(sp))
    ylabel('counts')
end
xlabel('minimum error between measured and modeled TDOA')

%% get track w/ old method, compare to new method. See why new one sucks

hydLoc{1} = [32.65879  -119.47705 -1319.6305];
hydLoc{2} = [32.65646  -119.48815 -1330.1631];
hydLoc{3} = [32.66221  -119.48424 -1321.2775];
hydLoc{4} = [32.65352  -119.48446 -1331.3959];
% model defines origin as EE location; loc3d_DOAintersect defines it as
% average of two 4ch locations. Since h1 is origin in model, when I plot
% both model and DOA results together, model must be shifted to match.
h0 = mean([hydLoc{1}; hydLoc{2}]);
[h1(1), h1(2)] = latlon2xy_wgs84(hydLoc{1}(1), hydLoc{1}(2), h0(1), h0(2));
h1(3) = abs(h0(3))-abs(hydLoc{1}(3));

[h2(1), h2(2)] = latlon2xy_wgs84(hydLoc{2}(1), hydLoc{2}(2), h0(1), h0(2));
h2(3) = abs(h0(3))-abs(hydLoc{2}(3));

[h3(1), h3(2)] = latlon2xy_wgs84(hydLoc{3}(1), hydLoc{3}(2), h0(1), h0(2));
h3(3) = abs(h0(3))-abs(hydLoc{3}(3));

[h4(1), h4(2)] = latlon2xy_wgs84(hydLoc{4}(1), hydLoc{4}(2), h0(1), h0(2));
h4(3) = abs(h0(3))-abs(hydLoc{4}(3));

DET_DOA{1} = DET{1};
Ilab = find(DET_DOA{1}.TDet>6737.46);
DET_DOA{1}.color(Ilab) = 4;
DET_DOA{2} = DET{2};
% DET_DOA{1}.DOA = -DET_DOA{1}.DOA;
% DET_DOA{2}.DOA = -DET_DOA{2}.DOA;


whaleLoc_DOA = loc3D_DOAintersect(DET_DOA, hydLoc, 'D:\MATLAB_addons\gitHub\wheresWhaledo\brushing.params');
figure(31)
wn = 2
    p(1) = scatter3(whaleLoc_DOA{wn}.xyz(:, 1), whaleLoc_DOA{wn}.xyz(:, 2), whaleLoc_DOA{wn}.xyz(:, 3), ...
    14, (brushing.params.colorMat(wn+6, :).'.*(1-.5.*(whaleLoc_DOA{wn}.ti-whaleLoc_DOA{wn}.ti(1))./max(whaleLoc_DOA{wn}.ti-whaleLoc_DOA{wn}.ti(1)))).', 'x')

hold on
scatter3(h1(1), h1(2), h1(3), 'k^', 'filled')
scatter3(h2(1), h2(2), h2(3), 'k^', 'filled')
scatter3(h3(1), h3(2), h3(3), 'ko', 'filled')
scatter3(h4(1), h4(2), h4(3), 'ko', 'filled')
axis([-1000, 1000, -1400, 600, -200, 1800])
pbaspect([1,1,1])
for wn = 1:numel(whale)
% wn = 3
p(wn+1) = scatter3(whale{wn}.wloc_fine(:, 1)+h1(1), whale{wn}.wloc_fine(:, 2)+h1(2), whale{wn}.wloc_fine(:, 3)+h1(3), ...
    14, brushing.params.colorMat(wn+2, :).*(1-.5.*(whale{wn}.TDet-whale{wn}.TDet(1))./max(whale{wn}.TDet-whale{wn}.TDet(1))), 'filled')

end
hold off
xlabel('E-W')
ylabel('N-S')
zlabel('height above arrays')
legend(p, 'DOA intersect', 'TDOA model', '2nd whale')

save('track_180611_1030', 'whale')