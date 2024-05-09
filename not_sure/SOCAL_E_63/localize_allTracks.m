% global TDOAparam
% loadParams('calcTDOA.params')
colorMat(1, :) = [0.600000, 0.600000, 0.600000]; % acoustic data
colorMat(2, :) = [0.000000, 0.000000, 0.000000]; % Unlabeled detections
colorMat(3, :) = [0.984314, 0.603922, 0.600000]; % Whale 1
colorMat(4, :) = [0.756863, 0.874510, 0.541176]; % Whale 2
colorMat(5, :) = [0.650980, 0.807843, 0.890196]; % Whale 3
colorMat(6, :) = [0.992157, 0.749020, 0.435294]; % Whale 4
colorMat(7, :) = [0.121569, 0.470588, 0.705882]; % Whale 5
colorMat(8, :) = [0.415686, 0.239216, 0.603922]; % Whale 6
colorMat(9, :) = [0.219608, 0.725490, 0.027451]; % Whale 7
colorMat(10, :) = [0.890196, 0.101961, 0.109804]; % Whale 8
colorMat(11, :) = [0.792157, 0.698039, 0.839216]; % Buzzes

% xwav tables:
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EE_C4_xwavLookupTable');
XH{1} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EW_C4_xwavLookupTable');
XH{2} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EN_xwavLookupTable');
XH{3} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_ES_xwavLookupTable');
XH{4} = xwavTable;

%% load H matrices and hydrophone locations

load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')
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

hyd1 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EE_Hmatrix_fromHydLocInversion_210702.mat');
hyd2 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EW_Hmatrix_fromHydLocInversion_210702.mat');

% HEW = H;

% Reorder hydrophones to fit new TDOA order
H1 = [hyd1.hydPos(2,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(3,:)];

H2 = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];


% % load variance data:
% load('D:\MATLAB_addons\gitHub\wheresWhaledo\SOCAL_E_63\sigmaValues.mat')

% load model:
M = load('B:\TDOAmodel_50dx50dy15dz.mat');

% load drift:
load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift.mat');
dp{1} = coeffvalues(Dpoly{1}); % drift coefficients between inst 1 and 2
dp{2} = coeffvalues(Dpoly{2}); % drift coefficients between inst 1 and 3
dp{3} = coeffvalues(Dpoly{3}); % drift coefficients between inst 1 and 4
dp{4} = coeffvalues(Dpoly{4}); % drift coefficients between inst 2 and 3
dp{5} = coeffvalues(Dpoly{5}); % drift coefficients between inst 2 and 4
dp{6} = coeffvalues(Dpoly{6}); % drift coefficients between inst 3 and 4

spd = 60*60*24; % seconds per day (converting from datenum)
numInst = 4; % number of instruments

% define subplot parameters for plotting:
sporder{1} = [1,4];
sporder{2} = [7,10];
sporder{3} = [13,16];
sporder{4} = 2;
sporder{5} = 5;
sporder{6} = 14;
sporder{7} = 17;
for nsp = 1:6
    sporder{nsp + 7} = 3*nsp;
end

figDir = 'D:\SOCAL_E_63\tracking\interns2022\allTracks_localized_pics_negDrift';

df = dir('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\*track*'); % directory of folders containing files
tn = zeros(numel(df), 1);

nstart = 1;
for ndf = nstart:numel(df)
%     for ndf = 61
    tic
    fprintf(['file ', num2str(ndf), '. ', num2str(100*ndf/numel(df)), '%% done\n'])
    clear whale
    d = dir(fullfile(df(ndf).folder, [df(ndf).name, '\*fineTDOA*.mat']));
    if ~isempty(d)
        load(fullfile(d.folder, d.name))
        newName = [d.name(1:end-12), 'localized'];

        %         whale = calcVariance(whale, XH, sig2_H1, sig2_H2, sig2_lrg, c, 'calcTDOA.params', 'detClicks_4ch.params');

        whale = localize(whale, hloc, H1, H2, dp);

        fig = figure(101);
        fig.WindowState = 'maximized';

        tmin = nan;
        tmax = nan;
        for wn = 1:numel(whale)
            
            tmin = min([tmin, min(min(whale{wn}.TDet))]);
            tmax = max([tmax, max(max(whale{wn}.TDet))]);

            CI{1} = abs(whale{wn}.CIx-whale{wn}.wloc(:,1));
            CI{2} = abs(whale{wn}.CIy-whale{wn}.wloc(:,2));
            CI{3} = abs(whale{wn}.CIz-whale{wn}.wloc(:,3));

            for nc = 1:3

                subplot(6,3,sporder{nc})

                plot(min(whale{wn}.TDetAll.'), whale{wn}.wloc(:, nc), '.', 'color', colorMat(wn+2, :))
                hold on
                %                 e = errorbar(min(whale{wn}.TDetAll.'), whale{wn}.wloc(:, nc), CI{nc}(:, 1), CI{nc}(:, 2));
                %                 e.Color = colorMat(wn+2, :);
                %                 set([e.Bar, e.Line], 'ColorType', 'truecoloralpha', 'ColorData', [e.Line.ColorData(1:3); 255*.1])
                xlim([tmin, tmax])

                grid on
                datetick('x', 'HH:MM','keeplimits')
                hold on

                if nc==1
                    title('Whale locations, X')
                elseif nc==2
                    title('Whale locations, Y')
                elseif nc==3
                    title('Whale locations, Z')
                end

            end

            Iuse = find(~isnan(whale{wn}.TDOA(:, 1)));
            az = zeros(size(Iuse));
            el = az;
            for i = 1:length(Iuse)
                doa = whale{wn}.TDOA(Iuse(i), 7:12).'\H2;
                doa = doa./sqrt(sum(doa.^2));
                el(i) = 180 - acosd(doa(3));
                az(i) = atan2d(doa(2), doa(1));
            end
            subplot(6, 3, sporder{4})
            plot(whale{wn}.TDet(Iuse, 1), az, '.', 'color', colorMat(wn+2, :))
            hold on
            title('EE Angle')
            datetick
            ylabel('az')

            subplot(6, 3, sporder{5})
            plot(whale{wn}.TDet(Iuse, 1), el, '.', 'color', colorMat(wn+2, :))
            datetick
            hold on
            ylabel('el')

            Iuse = find(~isnan(whale{wn}.TDOA(:, 7)));
            az = zeros(size(Iuse));
            el = az;
            for i = 1:length(Iuse)
                doa = whale{wn}.TDOA(Iuse(i), 7:12).'\H2;
                doa = doa./sqrt(sum(doa.^2));
                el(i) = 180 - acosd(doa(3));
                az(i) = atan2d(doa(2), doa(1));
            end
            subplot(6, 3, sporder{6})
            plot(whale{wn}.TDet(Iuse, 1), az, '.', 'color', colorMat(wn+2, :))
            hold on
            title('EW Angle')
            datetick
            ylabel('az')

            subplot(6, 3, sporder{7})
            plot(whale{wn}.TDet(Iuse, 1), el, '.', 'color', colorMat(wn+2, :))
            hold on
            datetick
            ylabel('el')

            for sp = 1:6
                subplot(6, 3, sporder{7+sp})
                plot(whale{wn}.TDet, whale{wn}.TDOA(:, 12+sp), '.', 'color', colorMat(wn+2, :))
                datetick
                hold on
                if sp==1
                    title('Large ap TDOA')
                end
            end

            
        end

        sgtitle(datestr(min(min(whale{wn}.TDet)), 'yy-mmm-dd'))

        save(fullfile(d.folder, newName), 'whale')

        saveas(fig, fullfile(d.folder, newName), 'jpg')
        saveas(fig, fullfile(d.folder, newName), 'fig')
        saveas(fig, fullfile(figDir, newName), 'jpg')
        saveas(fig, fullfile(figDir, newName), 'fig')

        close(fig)
    end
end