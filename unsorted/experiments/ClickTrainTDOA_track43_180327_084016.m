% step through 30 seconds at a time, brushdet, validate detections, click train corr, coarse localization
trackName = 'track43_180327_084016'

tdir = dir(['*det*', trackName, '*.mat']); 
load(tdir.name)

% encounterStart = min([min(DET{1}.TDet), min(DET{2}.TDet)]);
% encounterEnd = max([max(DET{1}.TDet), max(DET{2}.TDet)]);
encounterStart = min(DET{2}.TDet);
encounterEnd = max(DET{2}.TDet);
%% Run detector for single channels

% load in xwav tables
XH{1} = load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EE_C4_xwavLookupTable.mat');
XH{2} = load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EW_C4_xwavLookupTable.mat');
XH{3} = load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EN_xwavLookupTable.mat');
XH{4} = load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_ES_xwavLookupTable.mat');

DET{1} = outDet1;
DET{2} = outDet2;
% % SOCAL_E_63_EN
% [DET{3}] = detectClicks_1ch(encounterStart, encounterEnd, XH{3}.xwavTable, 'detClicks_1ch.params');
% 
% % SOCAL_E_63_ES
% [DET{4}] = detectClicks_1ch(encounterStart, encounterEnd, XH{4}.xwavTable, 'detClicks_1ch.params');
% 
% DET = fixAngle(DET);
% 
% save(tdir.name, 'DET')

global brushing
loadParams('brushing.params')
spd = 24*60*60;
fsct = 100e3;
maxLag = round(fsct*2000/1500);
twin = 60; % window length for click train
N = 1024;
Wk = hann(N/4);
xcovInd = [2,3,4,7,8,12];

xct = zeros(twin*fsct, 4);

encStart = min([DET{1}.TDet(1), DET{2}.TDet(1)]);
encEnd = min([DET{1}.TDet(end), DET{2}.TDet(end)]);

arrno = 2; % which array's labels are being used
TDet = [];
TDOA = [];
detCount = 0;
for wn = unique(DET{arrno}.color).'
    Ilab = find(DET{arrno}.color==wn);

    for ndet = 1:length(Ilab); % iterate through each detection
        tdet = DET{arrno}.TDet(Ilab(ndet));

        tstart = tdet - twin/(spd*2);
        tend = tdet + twin/(spd*2);

        tct = tstart:1/(spd*fsct):tend;
        xct = zeros(length(tct), 4);

        Iwn = find(DET{arrno}.TDet>=tstart & DET{arrno}.TDet<=tend & DET{arrno}.color==wn);
        for i = 1:length(Iwn)
            [~, ind] = min(abs(tct-DET{arrno}.TDet(Iwn(i))));
            xct(ind, arrno) = 1;
        end

        xctHann(:, arrno) = conv(Wk, xct(:, arrno));

        if arrno==1
            otherArrays = [2,3,4];
        elseif arrno==2
            otherArrays = [1,3,4];
        end

        for ia = 1:3
            Iwn = find(DET{otherArrays(ia)}.TDet>=tstart & DET{otherArrays(ia)}.TDet<=tend);
            for i = 1:length(Iwn)
                [~, ind] = min(abs(tct-DET{otherArrays(ia)}.TDet(Iwn(i))));
                xct(ind, otherArrays(ia)) = 1;
            end
            xctHann(:, otherArrays(ia)) = conv(Wk, xct(:, otherArrays(ia)));
        end
        if 0 % plot or not
            figure(1)
            for ih = 1:4
                subplot(4,1,ih)
                plot(xctHann(:, ih))
            end
        end
        [xctCorr, lags] = xcorr(xctHann, maxLag);

        tdoa = -99.*ones(1,length(xcovInd)); % initialize with -99 so I can easily remove faulty TDOAs
        xcpk = zeros(1, 3);

        if arrno == 1 % if primary array is AR1:
            % pair 1-2, 2-3, and 1-4:
            for np = 1:3
                [pk, imax] = max(xctCorr(:, xcovInd(np)));
                if pk>150
                    tdoa(np) = lags(imax)./fsct;
                    xcpk(np) = pk;
                    
                end
            end

            % pair 2-3:
            if (tdoa(1)~=-99) && (tdoa(2)~=-99)
                tdoa(4) = tdoa(2)-tdoa(1);
            end

            % pair 2-4:
            if (tdoa(1)~=-99) && (tdoa(3)~=-99)
                tdoa(4) = tdoa(3)-tdoa(1);
            end

            % pair 3-4:
            if (tdoa(3)~=-99) && (tdoa(2)~=-99)
                tdoa(6) = tdoa(3)-tdoa(2);
            end
        elseif arrno==2 % if primary array is AR2:
            % pair 1-2:
            [pk, imax] = max(xctCorr(:, xcovInd(1)));
            if pk>150
                tdoa(1) = lags(imax)./fsct;
                xcpk(1) = pk;
            end

            % pair 2-3:
            [pk, imax] = max(xctCorr(:, xcovInd(4)));
            if pk>150
                tdoa(4) = lags(imax)./fsct;
                xcpk(2) = pk;
            end

            % pair 2-4:
            [pk, imax] = max(xctCorr(:, xcovInd(5)));
            if pk>150
                tdoa(5) = lags(imax)./fsct;
                xcpk(3) = pk;
            end

            % pair 1-3:
            if (tdoa(1)~=-99) && (tdoa(4)~=-99)
                tdoa(2) = tdoa(1)+tdoa(4);
            end

            % pair 1-4:
            if (tdoa(1)~=-99) && (tdoa(5)~=-99)
                tdoa(3) = tdoa(1)+tdoa(5);
            end

            % pair 3-4:
            if (tdoa(4)~=-99) && (tdoa(5)~=-99)
                tdoa(6) = tdoa(5)-tdoa(4);
            end
        end


        detCount = detCount + 1;
        TDet(detCount) = tdet;
        TDOA(detCount, :) = tdoa;
        XCTpk(detCount, :) = xcpk;
        label(detCount) = wn;

    end

end
%%
fig = figure(3);
for np = 1:6
    subplot(6, 1, np)
    Iplt = find(TDOA(:, np)~=-99);
    scatter(TDet(Iplt), TDOA(Iplt, np), 20, brushing.params.colorMat(label(Iplt), :), 'filled')
    title(['Pair ', num2str(np), ', window length = ', num2str(twin), ' s'])
    ylabel('TDOA')
    datetick
end
% test whether label color legend exists
figCol = findall(0, 'Type', 'figure', 'name', 'Legend of Label Colors');
if isempty(figCol)
    generateColorSchemeLegend(brushing) % if legend doesn't exist, generate it
end


saveas(fig, ['clickByClick_windowLength_', num2str(twin), trackName], 'fig')
save(['clickByClick_roughTDOA_', trackName], 'TDet', 'TDOA', 'XCTpk', 'label')

%% Localize on 200 m grid
% load('clickByClick_roughTDOA_180611_1030.mat')
% M200 = load('D:\SOCAL_E_63\tracking\experiments\largeApertureTDOA\TDOAmodel_100m')
% 
% % set up parameters for LMS (CHECK WITH JOHN ABOUT THESE)
% sigmaH_sml = .1e-3; % uncertainty in small ap hydrophone locations
% sigmaX_sml = .05e-3; % uncertainty in small ap TDOA
% sig_sml = sqrt(sigmaH_sml^2 + sigmaX_sml^2);
% 
% sigmaH_lrg = 50e-3; % uncertainty in large ap hydrophone locations
% sigmaX_lrg = 30e-3; % uncertainty in large ap TDOA
% sig_lrg = sqrt(sigmaH_lrg^2 + sigmaX_lrg^2);
% 
% iloc = 0;
% for idet = 1:length(TDet)
% 
%     if sum(TDOA(idet, :)==-99)==0
%         iloc = iloc+1;
%         N = 6; % number of small aperture TDOAs used
%         [~, i1] = min(abs(DET{1}.TDet-TDet(idet)));
%         [~, i2] = min(abs(DET{2}.TDet-(TDet(idet)+TDOA(idet, 1)/spd)));
%         tdoasml = -[DET{1}.TDOA(i1, :), DET{2}.TDOA(i2, :)];
%         Lsml = (2*pi*sig_sml^2)^(-N/2).*exp((-1/(2*sig_sml^2)).*sum((M200.TDOA(:, 1:12) - tdoasml).^2, 2));
% 
%         %         Lsml = (2*pi*sig_sml^2)^(-N/2).*exp(-1/(2*sig_sml^2).*sum((M200.TDOA(:, 7:12) - tdoasml(7:12)).^2, 2));
% 
%         M = 6; % number of large aperture TDOAs used
%         tdoalrg = TDOA(idet, :);
%         Llrg = (2*pi*sig_lrg^2)^(-M/2).*exp((-1/(2*sig_lrg^2)).*sum((M200.TDOA(:, 13:18) - tdoalrg).^2, 2));
% 
%         L = Lsml.*Llrg;
% 
%         [~, im] = max(L);
% 
%         wloc_course(iloc, :) = M200.wloc(im, :);
%         locLabel(iloc) = label(idet);
%     end
% end
% 
% figure(101)
% scatter3(wloc_course(:, 1), wloc_course(:, 2), wloc_course(:, 3), 33, brushing.params.colorMat(locLabel, :), 'filled')
% 
% 
