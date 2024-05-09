dfolder = dir('D:\SOCAL_E_63\tracking\interns2022\processAsIs\*track*');
plotDir = 'D:\SOCAL_E_63\tracking\interns2022\tracks_fine';
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

                            I = [1,2];
                            for niter = 1:4

                                xvec = linspace(min(M.wloc(I, 1)), max(M.wloc(I, 1)), 70);
                                yvec = linspace(min(M.wloc(I, 2)), max(M.wloc(I, 2)), 70);
                                zvec = linspace(min(M.wloc(I, 3)), max(M.wloc(I, 3)), 70);

                                [M.TDOA, M.wloc] = makeModel(xvec, yvec, zvec, h, HEE, HEW, c); % fine grid

                                L = (-sum(1./(2*sig2(Itdoa)).*(M.TDOA(:, Itdoa)-TDOA(Itdoa)).^2, 2));

                                [~, I] = maxk(L, 1000);
                            end
                            whale{wn}.wloc(ndet, :) = M.wloc(I(1), :);
                            whale{wn}.Lbest(ndet) = L(I(1));
                        end


                    end
                end

                % get size of dots based on how many arrays they
                % intersect:
                sz = 10 + 60.*(sum(whale{wn}.IndUsed, 2)-7)./18;

                % get color of whale:
                col = brushing.params.colorMat(wn+2, :);

                % change color brightness/darkness based on time:
                if ~isempty(whale{wn})
                    sz = 10 + 60.*(sum(whale{wn}.IndUsed, 2)-7)./18;

                    % get color of whale:
                    col = brushing.params.colorMat(wn+2, :);
                    if ~isempty(whale{wn}.TDet)
                        Iuse = find(sum(whale{wn}.IndUsed, 2)>=7);

                        if ~isempty(Iuse)
                            tscale = (whale{wn}.TDet-(2*whale{wn}.TDet(1)-whale{wn}.TDet(end)))/(2*(whale{wn}.TDet(end)-whale{wn}.TDet(1)));
                            col = tscale*col;
                            sgtitle(newName(1:end-4), 'Interpreter', 'none');
                            sub1 = subplot(6,3,[1, 4]);
                            scatter(sub1, whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse, 1), sz(Iuse), col(Iuse, :), 'filled')
                           
                            datetick('x', 'keeplimits')
                            title('x (m)')
                            grid on
                            hold on

                            sub2 = subplot(6,3,[7, 10]);
                            scatter(sub2, whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse, 2), sz(Iuse), col(Iuse, :), 'filled')
                            
                            datetick('x', 'keeplimits')
                            title('y (m)')
                            grid on
                            hold on

                            sub3 = subplot(6,3,[13, 16]);
                            scatter(sub3, whale{wn}.TDet(Iuse), whale{wn}.wloc(Iuse, 3), sz(Iuse), col(Iuse, :), 'filled')
                            
                            datetick('x', 'keeplimits')
                            title('z (m)')
                            grid on
                            hold on
                        end
                        for nt = 1:6
                            sub(nt) = subplot(6,3,3*nt-1);
                            scatter(sub(nt), whale{wn}.TDet(Iuse), whale{wn}.TDOA(Iuse, nt+12), ...
                                sz(Iuse), col(Iuse, :), 'filled')

                            
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

                        
                        datetick('x', 'keeplimits')
                        ylabel('angle')
                        title(['Azimuth, EE'])
                        grid on
                        hold on

                        sub8 = subplot(6,3,6);
                        scatter(sub8, whale{wn}.TDet(Iuse), whale{wn}.Ang1(Iuse, 2), ...
                            sz(Iuse), col(Iuse, :), 'filled')

                        
                        datetick('x', 'keeplimits')
                        ylabel('angle')
                        title(['Elevation, EE'])
                        grid on
                        hold on

                        sub9 = subplot(6,3,12);
                        scatter(sub9, whale{wn}.TDet(Iuse), whale{wn}.Ang2(Iuse, 1), ...
                            sz(Iuse), col(Iuse, :), 'filled')

                        
                        datetick('x', 'keeplimits')
                        ylabel('angle')
                        title(['Azimuth, EW'])
                        grid on
                        hold on

                        sub8 = subplot(6,3,15);
                        scatter(sub8, whale{wn}.TDet(Iuse), whale{wn}.Ang2(Iuse, 2), ...
                            sz(Iuse), col(Iuse, :), 'filled')
                        
                        datetick('x', 'keeplimits')
                        ylabel('angle')
                        title(['Elevation, EW'])
                        grid on
                        hold on
                    end
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

function [TDOA, wloc] = makeModel(xv, yv, zv, h, H1, H2, c)

% make wloc (matrix of whale positions)
[cx, cy, cz] = ndgrid(xv, yv, zv);
wloc = [cx(:), cy(:), cz(:)];

s1 = wloc-h(1, :);
r1 = sqrt(sum(s1.^2, 2)); % range to instrument 1
s1 = s1./r1; % direction vector to instrument 1

s2 = wloc-h(2, :);
r2 = sqrt(sum(s2.^2, 2)); % range to instrument 2
s2 = s2./r2; % direction vector to instrument 2

s3 = wloc-h(3, :);
r3 = sqrt(sum(s3.^2, 2)); % range to instrument 3

s4 = wloc-h(4, :);
r4 = sqrt(sum(s4.^2, 2)); % range to instrument 4

% small aperture TDOAs
TDOA(:, 1:6) = (s1*H1.')./c;
TDOA(:, 7:12) = (s2*H2.')./c;

% large aperture TDOAs
TDOA(:, 13) = (r1-r2)./c;
TDOA(:, 14) = (r1-r3)./c;
TDOA(:, 15) = (r1-r4)./c;
TDOA(:, 16) = (r2-r3)./c;
TDOA(:, 17) = (r2-r4)./c;
TDOA(:, 18) = (r3-r4)./c;

end