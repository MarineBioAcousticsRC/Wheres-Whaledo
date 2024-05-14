combos(1,:) = [1,1,1,1];    % two 4ch; two 1ch
combos(2,:) = [1,1,1,0];    % two 4ch; N 1ch
combos(3,:) = [1,1,0,1];    % two 4ch; S 1ch
combos(4,:) = [1,1,0,0];    % two 4ch; no 1ch
combos(5,:) = [1,0,1,1];    % E 4ch; two 1ch
combos(6,:) = [1,0,1,0];    % E 4ch; N 1ch
combos(7,:) = [1,0,0,1];    % E 4ch; S 1ch
combos(8,:) = [0,1,1,1];    % W 4ch; two 1ch
combos(9,:) = [0,1,1,0];    % W 4ch; N 1ch
combos(10,:) = [0,1,0,1];   % W 4ch; S 1ch

shape{1} = '*';
shape{2} = 'x';
shape{3} = '+';
shape{4} = 'o';
shape{5} = '*';
shape{6} = 'x';
shape{7} = '+';
shape{8} = '*';
shape{9} = 'x';
shape{10} = '+';

blue = [10, 156, 255]./255;
green = [10, 213, 76]./255;
yellow = [250, 230, 0]./255;

col(1:4,:) = green.*ones(4,3);
col(5:7,:) = yellow.*ones(3,3);
col(8:10,:) = blue.*ones(3,3);

pair{1} = '1-2';
pair{2} = '1-3';
pair{3} = '1-4';
pair{4} = '2-3';
pair{5} = '2-4';
pair{6} = '3-4';

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

figDir = 'D:\SOCAL_E_63\tracking\interns2022\allTracks_localized_pics_separateWhales';

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

                
                for cn = 1:numel(shape)

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
                        plot3(whale{wn}.TDet(Idet), whale{wn}.wloc((Idet),1), ...
                            -ones(size(Idet)), shape{cn}, 'MarkerEdgeColor', col(cn,:))
                        grid on
                        datetick
                        ylabel('E-W (m)')
                        view(0, 90)
                        title('Whale position')

                        subplot(3,3,4)
                        plot3([whale{wn}.TDet(Idet),whale{wn}.TDet(Idet)].', whale{wn}.CIy(Idet, :).', ...
                            -ones(size(whale{wn}.CIy(Idet,:))), 'Color', [.6, .6, .6])
                        hold on
                        plot3([whale{wn}.TDet(Idet),whale{wn}.TDet(Idet)].', whale{wn}.CIy(Idet, :).', ...
                            -ones(size(whale{wn}.CIy(Idet,:))), '_', 'MarkerEdgeColor', [.6, .6, .6])
                        plot3(whale{wn}.TDet(Idet), whale{wn}.wloc((Idet), 2), ...
                            -ones(size(Idet)), shape{cn}, 'MarkerEdgeColor', col(cn,:))
                        grid on
                        datetick
                        ylabel('N-S (m)')
                        view(0, 90)

                        subplot(3,3,7)
                        plot3([whale{wn}.TDet(Idet),whale{wn}.TDet(Idet)].', abs(h0(3)) - whale{wn}.CIz(Idet, :).', ...
                            -ones(size(whale{wn}.CIz(Idet,:))), 'Color', [.6, .6, .6])
                        hold on
                        plot3([whale{wn}.TDet(Idet),whale{wn}.TDet(Idet)].', abs(h0(3)) - whale{wn}.CIz(Idet, :).', ...
                            -ones(size(whale{wn}.CIz(Idet,:))), '_', 'MarkerEdgeColor', [.6, .6, .6])
                        plot3(whale{wn}.TDet(Idet), abs(h0(3)) - whale{wn}.wloc((Idet), 3), ...
                            -ones(size(Idet)), shape{cn}, 'MarkerEdgeColor', col(cn,:))
                        axis ij
                        grid on
                        datetick
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
                            plot(whale{wn}.TDet(Idet(Iuse), 1), az, shape{cn}, 'MarkerEdgeColor', col(cn,:))
                            hold on
                            datetick
                            grid on
                            title('Array 1')
                            ylabel('Azimuth ^\circ')

                            subplot(4, 3, 5)
                            plot(whale{wn}.TDet(Idet(Iuse), 1), el, shape{cn}, 'MarkerEdgeColor', col(cn,:))
                            hold on
                            datetick
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
                            plot(whale{wn}.TDet(Idet(Iuse), 1), az, shape{cn}, 'MarkerEdgeColor', col(cn,:))
                            hold on
                            datetick
                            grid on
                            title('Array 2')
                            ylabel('Azimuth ^\circ')

                            subplot(4, 3, 11)
                            plot(whale{wn}.TDet(Idet(Iuse), 1), el, shape{cn}, 'MarkerEdgeColor', col(cn,:))
                            hold on
                            datetick
                            grid on
                            ylabel('Elevation ^\circ')
                        end


                        % TDOA plots
                        for sp = 1:6
                            subplot(6,3,3*sp)
                            plot(whale{wn}.TDet(Idet), whale{wn}.TDOA(Idet, sp+12), ...
                                shape{cn}, 'MarkerEdgeColor', col(cn,:))
                            hold on
                            datetick
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
            close(fig)
        end
    end
end