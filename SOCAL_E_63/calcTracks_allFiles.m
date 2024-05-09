dfolder = dir('D:\SOCAL_E_63\tracking\interns2022\processAsIs\*track*');
plotDir = 'D:\SOCAL_E_63\tracking\interns2022\tracks_hydDepthNotAdjusted';
%% load other necessary files:
M = load('B:\TDOAmodel_100dx100dy20dz.mat'); % load model
% get brushing params (for plotting consistently with other functions)
global brushing
loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\brushing.params')

% load hydrophone locations:
load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m
h = [0,0,0; h];

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
        fprintf(['Calculating ', dfolder(ndf).name, '. ', num2str(100*ndf/numel(dfolder)), '%% complete.\n'])
        fpn = fullfile(dfolder(ndf).folder, dfolder(ndf).name);
        d = dir(fullfile(fpn, '*fineTDOA*.mat'));
        
        for nd = 1:numel(d)
            try
                load(fullfile(d(nd).folder, d(nd).name))

                newName = replace(d(nd).name, 'fineTDOA', '3Dloc');

                fig = figure(1);
                % iterate through each whale and localize
                for wn = 1:numel(whale)
                    if ~isempty(whale{wn})
                        whale{wn}.wloc = nan([length(whale{wn}.TDet), 3]);
                        whale{wn}.Lbest = nan([length(whale{wn}.TDet), 1]);

                        % find detections that occured on at least 1 4ch and
                        % one other instrument:
                        Iuse = find(sum(whale{wn}.IndUsed, 2)>=7);
                        for ndet = 1:length(Iuse)
                            [~, Idrift] = min((tdrift - whale{wn}.TDet(Iuse(ndet)) ).^2);

                            TDOA = whale{wn}.TDOA(Iuse(ndet), :);
                            TDOA(13:18) = TDOA(13:18) + driftTDOA(Idrift, :);

                            sig2 = whale{wn}.sigma(Iuse(ndet), :).^2;
                            % indices of TDOA pairs which had detections:
                            Itdoa = find(whale{wn}.IndUsed(Iuse(ndet), :)==1);
                            L = (-sum(1./(2*sig2(Itdoa)).*(M.TDOA(:, Itdoa)-TDOA(Itdoa)).^2, 2));

                            [whale{wn}.Lbest(ndet), Ibest] = max(L);

                            whale{wn}.wloc(ndet, :) = M.wloc(Ibest, :);
                            
                        end
                        
                        
                    end
                end
                
                % get size of dots based on how many arrays they
                % intersect:
                sz = 10 + 60.*(sum(whale{wn}.IndUsed, 2)-7)./18;

                % get color of whale:
                col = brushing.params.colorMat(wn+2, :);

                % change color brightness/darkness based on time:
                if ~isempty(whale{wn}.TDet)
                tscale = (whale{wn}.TDet-(2*whale{wn}.TDet(1)-whale{wn}.TDet(end)))/(2*(whale{wn}.TDet(end)-whale{wn}.TDet(1)));
                col = tscale*col;

                sub1 = subplot(3,2,1);
                scatter(sub1, whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse, 1), sz(Iuse), col(Iuse, :), 'filled')
                datetick
                title('x (m)')
                grid on
                hold on
                
                sub2 = subplot(3,2,3);
                scatter(sub2, whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse, 2), sz(Iuse), col(Iuse, :), 'filled')
                datetick
                title('y (m)')
                grid on
                hold on

                sub3 = subplot(3,2,5);
                scatter(sub3, whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse, 3), sz(Iuse), col(Iuse, :), 'filled')
                datetick
                title('z (m)')
                grid on
                hold on

                sub4 = subplot(3,2, [2,4,6]);
                scatter3(sub4, whale{wn}.wloc(Iuse, 1), whale{wn}.wloc(Iuse, 2), whale{wn}.wloc(Iuse, 3), ...
                    sz(Iuse), col(Iuse, :), 'filled')
                axis([-5000, 5000, -5000, 5000, -200, 1000])
                pbaspect([1,1,1])
                xlabel('x')
                ylabel('y')
                zlabel('z')
                hold on
                scatter3(h(:, 1), h(:, 2), h(:, 3), 'sk')
                hold off
                fig.WindowState='maximized';
                saveas(fig, fullfile(d(nd).folder, [newName(1:end-4), '_whale', num2str(wn)]), 'fig')
                saveas(fig, fullfile(d(nd).folder, [newName(1:end-4), '_whale', num2str(wn)]), 'jpg')
                saveas(fig, fullfile(plotDir, [newName(1:end-4), '_whale', num2str(wn)]), 'fig')
                saveas(fig, fullfile(plotDir, [newName(1:end-4), '_whale', num2str(wn)]), 'jpg')
                close(fig)

                save(fullfile(d(nd).folder, newName), 'whale')
                end
            catch ME
                fid = fopen(fullfile(fullfile(d(nd).folder, 'results.txt')), 'a');
                fprintf(fid, ['\nError in calcTracks, array ', num2str(nd), ': ', ME.message, '\n']);
                save(fullfile(d(nd).folder, ['calcTracksError_array', num2str(nd)]), 'ME')
                fclose(fid);
            end
        end

    end

end