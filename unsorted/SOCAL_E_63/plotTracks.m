combos(1,:) = [1,1,1,1];    % EWNS
combos(2,:) = [1,1,1,0];    % EWN
combos(3,:) = [1,1,0,1];    % EWS
combos(4,:) = [1,1,0,0];    % EW
combos(5,:) = [1,0,1,1];    % ENS
combos(6,:) = [1,0,1,0];    % EN
combos(7,:) = [1,0,0,1];    % ES
combos(8,:) = [0,1,1,1];    % WNS
combos(9,:) = [0,1,1,0];    % WN
combos(10,:) = [0,1,0,1];   % WS

colorEdge(1,:) = [204, 0, 204];     % EWNS
colorEdge(2,:) = [56, 163, 209];    % EWN
colorEdge(3,:) = [219, 61, 61];     % EWS      
colorEdge(4,:) = [204, 0, 204];     % EW
colorEdge(5,:) = [182, 179, 219];   % ENS
colorEdge(6,:) = [102, 255, 255];   % EN
colorEdge(7,:) = [255, 204, 204];   % ES
colorEdge(8,:) = [102, 0, 102];     % WNS
colorEdge(9,:) = [0, 46, 138];      % WN
colorEdge(10,:) = [101, 11, 11];    % WS  

colorEdge = colorEdge./255;
colorFace = colorEdge;
colorFace(4,:) = [1,1,1];

pair{1} = '1-2';
pair{2} = '1-3';
pair{3} = '1-4';
pair{4} = '2-3';
pair{5} = '2-4';
pair{6} = '3-4';

mrkrSize = 6;

y2k = datenum([2000, 0, 0, 0, 0, 0]);

load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')
hydLoc{1} = hLatLonZ(1,:);
hydLoc{2} = hLatLonZ(2,:);
hydLoc{3} = hLatLonZ(3,:);
hydLoc{4} = hLatLonZ(4,:);

h0 = mean([hydLoc{1}; hydLoc{2}]);

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

figDir = 'D:\SOCAL_E_63\tracking\interns2022\allTracks_localized_pics_separateWhales_negDrift';

df = dir('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\*track*'); % directory of folders containing files
nstart = 1;
for ndf = nstart:numel(df)
    d = dir(fullfile(df(ndf).folder, [df(ndf).name, '\*_localized.mat']));
    if ~isempty(d)
        load(fullfile(d.folder, d.name))
        
        
        for wn = 1:numel(whale)
            if ~isempty(whale{wn})
                newName = [d.name(1:end-4), '_whale', num2str(wn)];
                fig = figure(1);
                fig.WindowState = 'maximized';
                tlim = nan(2,1); % limits on time axes
                tlim(1) = min(min(whale{wn}.TDet)); % lower limit on time axes
                tlim(2) = max(max(whale{wn}.TDet)); % upper limit on time axes

                for cn = 1:size(combos, 1)

                    Idet = find(ismember(whale{wn}.Iuse, combos(cn, :), 'rows'));

                    Irem = find((abs(whale{wn}.CIx(Idet, 2)-whale{wn}.CIx(Idet, 1)) >= 1000) ...
                        | (abs(whale{wn}.CIy(Idet, 2)-whale{wn}.CIy(Idet, 1)) >= 1000) ...
                        | (abs(whale{wn}.CIz(Idet, 2)-whale{wn}.CIz(Idet, 1)) >= 500));

                    Idet(Irem) = [];

                    if ~isempty(Idet)


                        % plot x,y,z with Error bars
                        subplot(3,3,1)
                        plot3([whale{wn}.TDet(Idet),whale{wn}.TDet(Idet)].', whale{wn}.CIx(Idet, :).', ...
                            -ones(size(whale{wn}.CIx(Idet,:))), 'Color', [.6, .6, .6])
                        hold on
                        plot3([whale{wn}.TDet(Idet),whale{wn}.TDet(Idet)].', whale{wn}.CIx(Idet, :).', ...
                            -ones(size(whale{wn}.CIx(Idet,:))), '_', 'MarkerEdgeColor', [.6, .6, .6])
                        plot3(whale{wn}.TDet(Idet), whale{wn}.wloc((Idet),1), ones(size(Idet)), 'o', 'markersize', mrkrSize, ...
                            'MarkerEdgeColor', colorEdge(cn,:), 'MarkerFaceColor', colorFace(cn,:))
                        grid on
                        xlim(tlim)
                        datetick('keeplimits')
                        ylabel('E-W (m)')
                        view(0, 90)
                        title('Whale position')

                        subplot(3,3,4)
                        plot3([whale{wn}.TDet(Idet),whale{wn}.TDet(Idet)].', whale{wn}.CIy(Idet, :).', ...
                            -ones(size(whale{wn}.CIy(Idet,:))), 'Color', [.6, .6, .6])
                        hold on
                        plot3([whale{wn}.TDet(Idet),whale{wn}.TDet(Idet)].', whale{wn}.CIy(Idet, :).', ...
                            -ones(size(whale{wn}.CIy(Idet,:))), '_', 'MarkerEdgeColor', [.6, .6, .6])
                        plot3(whale{wn}.TDet(Idet), whale{wn}.wloc((Idet),2), -ones(size(Idet)), 'o', 'markersize', mrkrSize, ...
                            'MarkerEdgeColor', colorEdge(cn,:), 'MarkerFaceColor', colorFace(cn,:))
                        grid on
                        xlim(tlim)
                        datetick('keeplimits')
                        ylabel('N-S (m)')
                        view(0, 90)

                        subplot(3,3,7)
                        plot3([whale{wn}.TDet(Idet),whale{wn}.TDet(Idet)].', abs(h0(3)) - whale{wn}.CIz(Idet, :).', ...
                            -ones(size(whale{wn}.CIz(Idet,:))), 'Color', [.6, .6, .6])
                        hold on
                        plot3([whale{wn}.TDet(Idet),whale{wn}.TDet(Idet)].', abs(h0(3)) - whale{wn}.CIz(Idet, :).', ...
                            -ones(size(whale{wn}.CIz(Idet,:))), '_', 'MarkerEdgeColor', [.6, .6, .6])
                        plot3(whale{wn}.TDet(Idet), abs(h0(3)) - whale{wn}.wloc((Idet),3), ones(size(Idet)), 'o', 'markersize', mrkrSize, ...
                            'MarkerEdgeColor', colorEdge(cn,:), 'MarkerFaceColor', colorFace(cn,:))
                        axis ij
                        grid on
                        xlim(tlim)
                        datetick('keeplimits')
                        ylabel('Depth (m)')
                        view(0, 90)

                        % Az/el plots
                        % calculate Az/el array 1
                        Iuse = find(~isnan(whale{wn}.TDOA(Idet, 1)));
                        if ~isempty(Iuse)
                            az = zeros(size(Iuse));
                            el = az;
                            for i = 1:length(Iuse)
                                doa = whale{wn}.TDOA(Idet(Iuse(i)), 1:6).'\H1;
                                doa = doa./sqrt(sum(doa.^2));
                                el(i) = 180 - acosd(doa(3));
                                az(i) = atan2d(doa(2), doa(1));
                            end
                            subplot(4, 3, 2)
                            plot(whale{wn}.TDet(Idet(Iuse), 1), az, 'o', 'markersize', mrkrSize, ...
                            'MarkerEdgeColor', colorEdge(cn,:), 'MarkerFaceColor', colorFace(cn,:))
                            hold on
                            xlim(tlim)
                            datetick('keeplimits')
                            grid on
                            title('Array 1')
                            ylabel('Azimuth ^\circ')

                            subplot(4, 3, 5)
                            plot(whale{wn}.TDet(Idet(Iuse), 1), el, 'o', 'markersize', mrkrSize, ...
                            'MarkerEdgeColor', colorEdge(cn,:), 'MarkerFaceColor', colorFace(cn,:))
                            hold on
                            xlim(tlim)
                            datetick('keeplimits')
                            grid on
                            ylabel('Elevation ^\circ')
                        end

                        % calculate Az/el array 2
                        Iuse = find(~isnan(whale{wn}.TDOA(Idet, 7)));
                        if ~isempty(Iuse)
                            az = zeros(size(Iuse));
                            el = az;
                            for i = 1:length(Iuse)
                                doa = whale{wn}.TDOA(Idet(Iuse(i)), 7:12).'\H2;
                                doa = doa./sqrt(sum(doa.^2));
                                el(i) = 180 - acosd(doa(3));
                                az(i) = atan2d(doa(2), doa(1));
                            end
                            subplot(4, 3, 8)
                            plot(whale{wn}.TDet(Idet(Iuse), 1), az, 'o', 'markersize', mrkrSize, ...
                            'MarkerEdgeColor', colorEdge(cn,:), 'MarkerFaceColor', colorFace(cn,:))
                            hold on
                            xlim(tlim)
                            datetick('keeplimits')
                            grid on
                            title('Array 2')
                            ylabel('Azimuth ^\circ')

                            subplot(4, 3, 11)
                            plot(whale{wn}.TDet(Idet(Iuse), 1), el, 'o', 'markersize', mrkrSize, ...
                            'MarkerEdgeColor', colorEdge(cn,:), 'MarkerFaceColor', colorFace(cn,:))
                            hold on
                            xlim(tlim)
                            datetick('keeplimits')
                            grid on
                            ylabel('Elevation ^\circ')
                        end


                        % TDOA plots
                        for sp = 1:6
                            subplot(6,3,3*sp)
                            plot(whale{wn}.TDet(Idet), whale{wn}.TDOA(Idet, sp+12), 'o', 'markersize', mrkrSize, ...
                            'MarkerEdgeColor', colorEdge(cn,:), 'MarkerFaceColor', colorFace(cn,:))
                            hold on
                            xlim(tlim)
                            datetick('keeplimits')
                            grid on
                            if sp==1
                                title('Large-ap TDOA')
                            end
                            ylabel(['Pair ', pair{sp}])
                        end

                    end
                end
            end
            ds = datestr(min(min(whale{wn}.TDet)) + y2k, 'yyyy-mmm-dd');
            sgtitle([ds, '; whale ', num2str(wn)])
            saveas(fig, fullfile(figDir, newName), 'jpg')
            saveas(fig, fullfile(figDir, newName), 'fig')
            close(fig)
        end
    end
end