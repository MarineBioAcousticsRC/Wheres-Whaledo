clear global
close all force
clear all
tracksFolder = 'D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\'

% trackNum = 30; % former large group
% trackNum = 172;
trackNum = 179; % Dolphin
% trackNum = 216; large group
% trackNum = 600; % unambiguous


% trackNum = 666;

% TSTART = datenum([18 05 31 06 21 00]);
% TEND = datenum([18 05 31 07 50 00]);

dfolder = dir([tracksFolder, '*track', num2str(trackNum), '_*'])

% if ~isempty(dfolder)
%     crash
% end
%     startTime = datestr(TSTART, '_yymmdd_HHMMSS')
%     mkdir([tracksFolder, 'track', num2str(trackNum), startTime])
%     dfolder = dir([tracksFolder, '*track', num2str(trackNum), '_*'])
%     dfile.folder = [tracksFolder, 'track', num2str(trackNum), startTime];
%     trackName = ['track', num2str(trackNum), startTime];
% end
dfile.folder = fullfile(dfolder.folder, dfolder.name);
dfile = dir([dfolder.folder, '\', dfolder.name, '\*ericMod.mat'])

load(fullfile(dfile.folder, dfile.name))

trackName = dfolder.name;

%  calculate new start/end times:
TSTART = min([DET{1}.TDet; DET{2}.TDet]) - .1/24;
TEND = max([DET{1}.TDet; DET{2}.TDet]) + .1/24;



%%
global brushing
loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\brushing.params')

c = 1488.4; % speed of sound
spd = 60*60*24;

% load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')
load('D:\SOCAL_E_63\xwavTables\instrumentLocs_new.mat')
hydLoc{1} = hLatLonZ(1,:);
hydLoc{2} = hLatLonZ(2,:);
hydLoc{3} = hLatLonZ(3,:);
hydLoc{4} = hLatLonZ(4,:);

h0 = mean([hydLoc{1}; hydLoc{2}]);

% convert hydrophone locations to meters:
[h1(1), h1(2)] = latlon2xy_wgs84(hydLoc{1}(1), hydLoc{1}(2), h0(1), h0(2));
h1(3) = abs(h0(3))-abs(hydLoc{1}(3));

[h2(1), h2(2)] = latlon2xy_wgs84(hydLoc{2}(1), hydLoc{2}(2), h0(1), h0(2));
h2(3) = abs(h0(3))-abs(hydLoc{2}(3));

[h3(1), h3(2)] = latlon2xy_wgs84(hydLoc{3}(1), hydLoc{3}(2), h0(1), h0(2));
h3(3) = abs(h0(3))-abs(hydLoc{3}(3));

[h4(1), h4(2)] = latlon2xy_wgs84(hydLoc{4}(1), hydLoc{4}(2), h0(1), h0(2));
h4(3) = abs(h0(3))-abs(hydLoc{4}(3));

hloc = [h1;h2;h3;h4];

% xwav tables:
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EE_C4_xwavLookupTable');
XH{1} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EW_C4_xwavLookupTable');
XH{2} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EN_xwavLookupTable');
XH{3} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_ES_xwavLookupTable');
XH{4} = xwavTable;

hyd1 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EE_Hmatrix_new.mat');
hyd2 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EW_Hmatrix_new.mat');

% HEW = H;

% Reorder hydrophones to fit new TDOA order (needed at SOCAL_E because sometimes I make things confusing even for myself)
H{1} = [hyd1.hydPos(2,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(3,:)];

H{2} = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];

% load drift:
load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift.mat');
dp{1} = coeffvalues(Dpoly{1}); % drift coefficients between inst 1 and 2
dp{2} = coeffvalues(Dpoly{2}); % drift coefficients between inst 1 and 3
dp{3} = coeffvalues(Dpoly{3}); % drift coefficients between inst 1 and 4
dp{4} = coeffvalues(Dpoly{4}); % drift coefficients between inst 2 and 3
dp{5} = coeffvalues(Dpoly{5}); % drift coefficients between inst 2 and 4
dp{6} = coeffvalues(Dpoly{6}); % drift coefficients between inst 3 and 4

fs(1:2) = 100e3;
fs(3:4) = 200e3;

for nh = 1:4
    global detParam
    if nh<=2
        loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\detClicks_4ch.params');
    else
        loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\detClicks_1ch.params');
    end
    [b{nh}, a{nh}] = ellip(4,0.1,40,detParam.fc*2/detParam.fs,'high');
end


%% Determine threshold of detection
tstart = TSTART;

% for nh = 1:4
%     cont = 'c';
%     while ~strcmp(cont, 'q')
%         [x, t] = quickxwavRead(tstart, tstart + 60/spd, fs(nh), XH{nh});
%         xf = filtfilt(b{nh}, a{nh}, x(:,1));
%         figure(21)
%         plot(t, xf)
%         title(['Instrument ', num2str(nh)])
% 
%         cont = input('\nEnter ''q'' to move to next instrument\n''n'' to examine next minute\n''p'' to examine previous minute: ', 's');
% 
%         switch cont
%             case 'n'
%                 tstart = tstart + 60/spd;
%             case 'p'
%                 tstart = tstart - 60/spd;
%             case 'q'
%                 continue
%         end
%     end
% end

%% run detector on 4ch
for n = 1:2
    DET{n} = detectClicks_4ch(TSTART, TEND, XH{n}, H{n}, c, 'D:\MATLAB_addons\gitHub\wheresWhaledo\detClicks_4ch.params')
end

save(fullfile(dfile.folder, [trackName, '_noEdits']), 'DET')

%% rerun brushDOA
% load(['D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track600_180611_110414\SOCAL_E_63_', trackName, '_ericMod_detections.mat'])
% load(fullfile(dfile.folder, [trackName, '_noEdits']))
load(fullfile(dfile.folder, [trackName, '_ericEdits']))

for nd = 1:2
        DET{nd}.Ang((DET{nd}.Ang(:,1)<0),1) = DET{nd}.Ang((DET{nd}.Ang(:,1)<0),1) + 360;
end

% [DET{1}, DET{2}] = brushDOA(DET{1}, DET{2})

% wnDisp = [ 3,4]; % which whales to display
% Iw1 = find(ismember(DET{1}.color, wnDisp+2));
% DETtemp{1} = DET{1}(Iw1, :);
% 
% Iw2 = find(ismember(DET{2}.color, wnDisp+2));
% DETtemp{2} = DET{2}(Iw2, :);
% 
% [DETtemp{1}, DETtemp{2}] = brushDOA(DETtemp{1}, DETtemp{2});
% 
% DET{1}.color(Iw1) = DETtemp{1}.color;
% DET{2}.color(Iw2) = DETtemp{2}.color;

% plot each whale one at a time
% wnums = unique([DET{1}.color; DET{2}.color]);
% wnums(wnums>3) = [];
% wnums = [3, 4] + 2;
% for wn = 1:length(wnums)
%     Iw1 = find(DET{1}.color==wnums(wn));
%     DETtemp{1} = DET{1}(Iw1, :);
% 
%     Iw2 = find(DET{2}.color==wnums(wn));
%     DETtemp{2} = DET{2}(Iw2, :);
% 
%     [DETtemp{1}, DETtemp{2}] = brushDOA(DETtemp{1}, DETtemp{2});
% 
%     DET{1}.color(Iw1) = DETtemp{1}.color;
%     DET{2}.color(Iw2) = DETtemp{2}.color;
% end

[DET{1}, DET{2}] = brushDOA(DET{1}, DET{2});

save(fullfile(dfile.folder, [trackName, '_ericEdits']), 'DET')

%%

for n = 3:4
    DET{n} = detectClicks_1ch(TSTART, TEND, XH{n}, 'D:\MATLAB_addons\gitHub\wheresWhaledo\detClicks_1ch.params')
end

save(fullfile(dfile.folder, [trackName, '_ericEdits']), 'DET')

%%
load(fullfile(dfile.folder, [trackName, '_ericEdits']))

colNum = length(unique(DET{1}.color))
for wn = 1:colNum
    [CTC{wn}, ~]  = clickTrainCorr(DET, wn, [1,2], [1,2], [3,4]);
end

save(fullfile(dfile.folder, [trackName, '_CTC']), 'CTC', 'DET')
%%
load(fullfile(dfile.folder, [trackName, '_CTC']))
whale = calcTDOAfromCTC(CTC, XH);

save(fullfile(dfile.folder, [trackName, '_TDOA']), 'whale')

%% Localize
load(fullfile(dfile.folder, [trackName, '_TDOA']))
% load(fullfile(dfile.folder, [trackName, '_localized_cleaned']))
whale = localize(whale, hloc, H, dp, 'D:\MATLAB_addons\gitHub\wheresWhaledo\localize_interpOff.params');
save(fullfile(dfile.folder, [trackName, '_localized']), 'whale')
%% brush TDOA
load(fullfile(dfile.folder, [trackName, '_localized']))
% load(fullfile(dfile.folder, [trackName, '_localized_cleaned']))
% whale = brushTDOA(whale, H);

% run brushTDOA for one whale at a time:
for wn = 1:numel(whale)
    wtemp{1} = whale{wn};
    if ~isempty(wtemp{1})
        wtemp = brushTDOA(wtemp, H);
        whale{wn} = wtemp{1};
    end
end


whale = localize(whale, hloc, H, dp, 'D:\MATLAB_addons\gitHub\wheresWhaledo\localize.params');
save(fullfile(dfile.folder, [trackName, '_localized_cleaned']), 'whale')
%% smooth
load(fullfile(dfile.folder, [trackName, '_localized_cleaned']))
for wn = 1:numel(whale)
    if ~isempty(whale{wn})
        [~, Isort] = sort(whale{wn}.TDet);
        whale{wn} = whale{wn}(Isort, :);
    end
end


[whale, wfit] = weightedSplineFit(whale, 2e-8);

figure(99)
for sp = 1:3

    for wn = 1:numel(whale)
        if isempty(whale{wn})
            continue
        end
        Iplot = find(~isnan(whale{wn}.wloc(:,1)));
        subplot(3,1,sp)
        scatter(whale{wn}.TDet(Iplot), whale{wn}.wloc(Iplot, sp), 15, ones(size(Iplot))*brushing.params.colorMat(wn+2, :), 'MarkerFaceAlpha', .2);
        hold on
        plot(whale{wn}.TDet(Iplot), whale{wn}.wlocSmooth(Iplot, sp), 'k-', 'linewidth', 2);
        datetick
    end
    hold off
end

save(fullfile(dfile.folder, [trackName, '_localized_cleaned']), 'whale')

%

figure(100)
for wn = 1:numel(whale)
    if ~isempty(whale{wn})
        Iplot = find(~isnan(whale{wn}.wlocSmooth(:,1)));
        scatter3(whale{wn}.wlocSmooth(Iplot, 1), whale{wn}.wlocSmooth(Iplot, 2), whale{wn}.wlocSmooth(Iplot, 3), 12, ones(size(Iplot)).*brushing.params.colorMat(wn+2,:), 'filled')
        hold on
    end
end
hold off
grid on
% axis([-4000, 4000, -4000, 4000])
% axis([-900, 900, -2200, -400])
% axis([-2000, -2000, 0, 0])
pbaspect([1,1,1])

figure(101)
for wn = 1:numel(whale)
    if isempty(whale{wn})
        continue
    end
    Iplot = find(~isnan(whale{wn}.wlocSmooth(:,1)));
    scatter(whale{wn}.wloc(Iplot, 1), whale{wn}.wloc(Iplot, 2), 12, ones(size(Iplot)).*brushing.params.colorMat(wn+2,:), 'filled', 'markerFaceAlpha', .5)
    hold on
    plot(whale{wn}.wlocSmooth(Iplot, 1), whale{wn}.wlocSmooth(Iplot, 2), 'color', brushing.params.colorMat(wn+2,:), 'linewidth', 3)
end
hold off
grid on
% axis([-900, 900, -2200, -400])
% axis([-4000, 4000, -4000, 4000])
% axis([-2000, 0, -2000, 0])
pbaspect([1,1,1])

%% Recalculate CI based on wlocSmooth
load(fullfile(dfile.folder, [trackName, '_localized_cleaned']))
% Nlrg = 6; % number of large ap TDOAs
% global LOC
% loadParams('localize.params')
% sig2sml = LOC.sig_sml.^2;
% sig2lrg = LOC.sig_lrg.^2;
% for wn = 1:numel(whale)
%     if isempty(whale{wn})
%         continue
%     end
%     Iuse = find(~isnan(whale{wn}.wlocSmooth(:,1)));
%     whale{wn}.CIxSmooth = nan(size(whale{wn}.CIx));
%     whale{wn}.CIySmooth = nan(size(whale{wn}.CIy));
%     whale{wn}.CIzSmooth = nan(size(whale{wn}.CIz));
%     whale{wn}.wlocSmooth_Alt = nan(size(whale{wn}.wlocSmooth));
%     for i = 1:length(Iuse)
%         TDOA = whale{wn}.TDOA(Iuse(i), :);
%         wloc = whale{wn}.wlocSmooth(Iuse(i), :);
% 
%         Isml = find(~isnan(TDOA(1:12))); % indices of small ap used
%         Ilrg = find(~isnan(TDOA(13:end)))+12; % indices of large ap used
% 
%         Asml = (2*pi*sig2sml)^(-length(Isml)/2); % coefficient of small ap
%         Alrg = (2*pi*sig2lrg)^(-length(Ilrg)/2); % coefficient of large ap
% 
%         TDOA = whale{wn}.TDOA(Iuse(i), :);
%         drift = zeros(1, Nlrg);
%         for ntdoa = 1:Nlrg
%             drift(ntdoa) = polyval(dp{ntdoa}, whale{wn}.TDet(Iuse(i)));
%         end
%         TDOA(13:end) = TDOA(13:end) + LOC.driftSign.*drift;
% 
%         [CIx, CIy, CIz] = calcCI(TDOA, wloc, hloc, H{1}, H{2}, Asml, Alrg, LOC);
%         whale{wn}.CIxSmooth(Iuse(i), :) = CIx;
%         whale{wn}.CIySmooth(Iuse(i), :) = CIy;
%         whale{wn}.CIzSmooth(Iuse(i), :) = CIz;
%     
%     end
% end
% 
% for wn = 1:numel(whale)
%     whale{wn}.CIxSmooth = smoothdata(whale{wn}.CIx);
%     whale{wn}.CIySmooth = smoothdata(whale{wn}.CIy);
%     whale{wn}.CIzSmooth = smoothdata(whale{wn}.CIz);
% end
save(fullfile(dfile.folder, [trackName, '_localized_cleaned']), 'whale', 'wfit')

%%
for wn = 1:numel(whale)
    if isempty(whale{wn})
        continue
    end
%      Iuse = find(sum(~isnan(whale{wn}.TDOA), 2)>=7 & sum(~isnan(whale{wn}.TDOA), 2)<12 & ~isnan(whale{wn}.wlocSmooth(:,1)));
    Iuse = find(~isnan(whale{wn}.wloc(:,1)))
%     Iuse = find(sum(~isnan(whale{wn}.TDOA), 2)>=12 & ~isnan(whale{wn}.wlocSmooth(:,1)));
%     Irem = find(abs(whale{wn}.CIxSmooth(Iuse, 2) -whale{wn}.CIxSmooth(Iuse, 1))>1000 | abs(whale{wn}.CIySmooth(Iuse, 2) -whale{wn}.CIySmooth(Iuse, 1))>1000);
%     Iuse(Irem) = [];
    
if isempty(Iuse)
    continue
end
    figure(120+wn)
    subplot(3,1,1)
%     plot(whale{wn}.TDet(Iuse), whale{wn}.CIx(Iuse, :), 'k.')
%     hold on
    plot(whale{wn}.TDet(Iuse), whale{wn}.CIxSmooth(Iuse, :), 'b.')
    hold on
%     plot(whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse,1), 'x')
    hold on
    plot(whale{wn}.TDet(Iuse), whale{wn}.wlocSmooth(Iuse,1), 'o')
    hold off
    datetick

    subplot(3,1,2)
%     plot(whale{wn}.TDet(Iuse), whale{wn}.CIy(Iuse, :), 'k.')
%     hold on
    plot(whale{wn}.TDet(Iuse), whale{wn}.CIySmooth(Iuse, :), 'b.')
    hold on
%     plot(whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse,2), 'x')
    hold on
    plot(whale{wn}.TDet(Iuse), whale{wn}.wlocSmooth(Iuse,2), 'o')
    hold off
    datetick

    subplot(3,1,3)
%     pl(1) = plot(whale{wn}.TDet(Iuse), whale{wn}.CIz(Iuse,1), 'k.');
%     hold on
%     plot(whale{wn}.TDet(Iuse), whale{wn}.CIz(Iuse,2), 'k.');
        pl(2) = plot(whale{wn}.TDet(Iuse), whale{wn}.CIzSmooth(Iuse,1), 'b.');
        hold on
    plot(whale{wn}.TDet(Iuse), whale{wn}.CIzSmooth(Iuse,2), 'b.');
%     pl(3) = plot(whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse,3), 'x');
    pl(4) = plot(whale{wn}.TDet(Iuse), whale{wn}.wlocSmooth(Iuse,3), 'o');
        hold off
%     lstr = {'old CI', 'new CI', 'wlocSmooth'};
%     legend(pl, lstr)
    datetick
end

%%
% wn = 2;
% dn = floor(min(whale{wn}.TDet)) + datenum([0, 0, 0, 21,30, 00]);
% Irem = find(whale{wn}.CIySmooth(:,1)<-800 & whale{wn}.TDet > dn)
% whale{wn}(Irem, :) = [];