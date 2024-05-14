dfolder = dir('D:\SOCAL_E_63\tracking\interns2022\processAsIs\*track*');
plotDir = 'D:\SOCAL_E_63\tracking\interns2022\trackAndTDOAplots';
%% load other necessary files:
M = load('B:\TDOAmodel_100dx100dy20dz.mat'); % load model
% get brushing params (for plotting consistently with other functions)
global brushing
loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\brushing.params')

% load hydrophone locations:
load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m
h = [0,0,0; h];

hyd1 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EE_Hmatrix_new.mat');
hyd2 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EW_Hmatrix_new.mat');

% Reorder hydrophones to fit new TDOA order
HEE = [hyd1.recPos(2,:)-hyd1.recPos(1,:);
    hyd1.recPos(3,:)-hyd1.recPos(1,:);
    hyd1.recPos(4,:)-hyd1.recPos(1,:);
    hyd1.recPos(3,:)-hyd1.recPos(2,:);
    hyd1.recPos(4,:)-hyd1.recPos(2,:);
    hyd1.recPos(4,:)-hyd1.recPos(3,:)];

HEW = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];

c = 1488.4;
% c = 1485;
% c = 1501
csml = 1488.4;

% load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift_ADCPonly.mat'); % drift
load('D:\SOCAL_E_63\xwavTables\drift')
driftTDOA(:, 1) = drift(1, :).';
driftTDOA(:, 2) = drift(2, :).';
driftTDOA(:, 3) = drift(3, :).';
driftTDOA(:, 4) = drift(2, :).' - drift(1, :).';
driftTDOA(:, 5) = drift(3, :).' - drift(1, :).';
driftTDOA(:, 6) = drift(3, :).' - drift(2, :).';

for ndf = 1:numel(dfolder)
    if dfolder(ndf).isdir
        fprintf(['Plotting ', dfolder(ndf).name, '. ', num2str(100*ndf/numel(dfolder)), '%% complete.\n'])
        fpn = fullfile(dfolder(ndf).folder, dfolder(ndf).name);
        d = dir(fullfile(fpn, '*3Dloc*.mat'));

        for nd = 1:numel(d)
            try
                load(fullfile(d(nd).folder, d(nd).name))

                newName = d(nd).name;

                fig = figure(1);
                xlm = nan(1, 2);    
                for wn = 1:numel(whale)
                    % get size of dots based on how many arrays they
                    % intersect:
                    
                    if ~ isempty(whale{wn})
                        
                        sz = 10 + 60.*(sum(whale{wn}.IndUsed, 2)-7)./18;

                        % get color of whale:
                        col = brushing.params.colorMat(wn+2, :);

                        % change color brightness/darkness based on time:
                        if ~isempty(whale{wn}.TDet)
                            Iuse = find(sum(whale{wn}.IndUsed, 2)>=7);
                            xlm(1) = min([xlm(1); whale{wn}.TDet(Iuse)]);
                            xlm(2) = max([xlm(2); whale{wn}.TDet(Iuse)]);

                            if ~isempty(Iuse)
                                tscale = (whale{wn}.TDet-(2*whale{wn}.TDet(1)-whale{wn}.TDet(end)))/(2*(whale{wn}.TDet(end)-whale{wn}.TDet(1)));
                                col = tscale*col;
                                sgtitle(newName(1:end-4), 'Interpreter', 'none');
                                sub1 = subplot(6,3,[1, 4]);
                                scatter(sub1, whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse, 1), sz(Iuse), col(Iuse, :), 'filled')
                                xlim([xlm])
                                datetick('x', 'keeplimits')
                                title('x (m)')
                                grid on
                                hold on

                                sub2 = subplot(6,3,[7, 10]);
                                scatter(sub2, whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse, 2), sz(Iuse), col(Iuse, :), 'filled')
                                xlim([xlm])
                                datetick('x', 'keeplimits')
                                title('y (m)')
                                grid on
                                hold on

                                sub3 = subplot(6,3,[13, 16]);
                                scatter(sub3, whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse, 3), sz(Iuse), col(Iuse, :), 'filled')
                                xlim([xlm])
                                datetick('x', 'keeplimits')
                                title('z (m)')
                                grid on
                                hold on
                            end
                            for nt = 1:6
                                sub(nt) = subplot(6,3,3*nt-1);
                                scatter(sub(nt), whale{wn}.TDet(Iuse), whale{wn}.TDOA(Iuse, nt+12), ...
                                    sz(Iuse), col(Iuse, :), 'filled')

                                xlim([xlm])
                                datetick('x', 'keeplimits')
                                ylabel('TDOA')
                                title(['large ap, pair', num2str(nt)])
                                grid on
                                hold on

                            end

                            for i = 1:length(Iuse)
                                doa1 = c*(whale{wn}.TDOA(Iuse(i), 1:6).'\HEE);
                                doa2 = c*(whale{wn}.TDOA(Iuse(i), 7:12).'\HEW);

                                % azimuths:
                                whale{wn}.Ang1(Iuse(i), 1) = atan2d(doa1(2), doa1(1));
                                whale{wn}.Ang2(Iuse(i), 1) = atan2d(doa2(2), doa2(1));

                                % elevations:
                                whale{wn}.Ang1(Iuse(i), 2) = 180-acosd(doa1(3)/sqrt(sum(doa1.^2)));
                                whale{wn}.Ang2(Iuse(i), 2) = 180-acosd(doa2(3)/sqrt(sum(doa2.^2)));
                            end


                            sub7 = subplot(6,3,3);
                            scatter(sub7, whale{wn}.TDet(Iuse), whale{wn}.Ang1(Iuse, 1), ...
                                sz(Iuse), col(Iuse, :), 'filled')

                            xlim([xlm])
                            datetick('x', 'keeplimits')
                            ylabel('angle')
                            title(['Azimuth, EE'])
                            grid on
                            hold on

                            sub8 = subplot(6,3,6);
                            scatter(sub8, whale{wn}.TDet(Iuse), whale{wn}.Ang1(Iuse, 2), ...
                                sz(Iuse), col(Iuse, :), 'filled')

                            xlim([xlm])
                            datetick('x', 'keeplimits')
                            ylabel('angle')
                            title(['Elevation, EE'])
                            grid on
                            hold on

                            sub9 = subplot(6,3,12);
                            scatter(sub9, whale{wn}.TDet(Iuse), whale{wn}.Ang2(Iuse, 1), ...
                                sz(Iuse), col(Iuse, :), 'filled')

                            xlim([xlm])
                            datetick('x', 'keeplimits')
                            ylabel('angle')
                            title(['Azimuth, EW'])
                            grid on
                            hold on

                            sub8 = subplot(6,3,15);
                            scatter(sub8, whale{wn}.TDet(Iuse), whale{wn}.Ang2(Iuse, 2), ...
                                sz(Iuse), col(Iuse, :), 'filled')
                            xlim([xlm])
                            datetick('x', 'keeplimits')
                            ylabel('angle')
                            title(['Elevation, EW'])
                            grid on
                            hold on

                        end
                    end

                end
                fig.WindowState='maximized';
                saveas(fig, fullfile(d(nd).folder, [newName(1:end-4), '_trackAndTDOA']), 'fig')
                saveas(fig, fullfile(d(nd).folder, [newName(1:end-4), '_trackAndTDOA']), 'jpg')
                saveas(fig, fullfile(plotDir, [newName(1:end-4), '_trackAndTDOA']), 'fig')
                saveas(fig, fullfile(plotDir, [newName(1:end-4),  '_trackAndTDOA']), 'jpg')
                close(fig)
            catch ME
                fid = fopen(fullfile(fullfile(d(nd).folder, 'results.txt')), 'a');
                fprintf(fid, ['\nError in calcTracks, array ', num2str(nd), ': ', ME.message, '\n']);
                save(fullfile(d(nd).folder, ['calcTracksError_array', num2str(nd)]), 'ME')
                fclose(fid);
                fprintf(['Error, ', newName, '\n'])
            end
        end

    end

end