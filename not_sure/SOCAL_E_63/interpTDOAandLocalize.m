dfolder = dir('D:\SOCAL_E_63\tracking\interns2022\processAsIs\*track*');
plotDir = 'D:\SOCAL_E_63\tracking\interns2022\interpPlots_piecewise';
%% load other necessary files:
M = load('B:\TDOAmodel_100dx100dy20dz.mat'); % load model
% get brushing params (for plotting consistently with other functions)
global brushing
loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\brushing.params')

c = 1488.4;
spd = 60*60*24;

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

% load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift_ADCPonly.mat'); % drift
load('D:\SOCAL_E_63\xwavTables\drift')
driftTDOA(:, 1) = drift(1, :).';
driftTDOA(:, 2) = drift(2, :).';
driftTDOA(:, 3) = drift(3, :).';
driftTDOA(:, 4) = drift(2, :).' - drift(1, :).';
driftTDOA(:, 5) = drift(3, :).' - drift(1, :).';
driftTDOA(:, 6) = drift(3, :).' - drift(2, :).';

% define subplot order (for plotting)
sporder(1:6) = 1:3:18;
sporder(7:12) = 2:3:18;
sporder(13:18) = 3:3:18;
sptitle{1} = 'EE TDOA';
sptitle{6} = 'EW TDOA';
sptitle{13} = 'EE-EW';
sptitle{14} = 'EE-EN';
sptitle{15} = 'EE-ES';
sptitle{16} = 'EW-EN';
sptitle{17} = 'EW-ES';
sptitle{18} = 'EN-ES';

for ndf = 1:numel(dfolder)
    if dfolder(ndf).isdir
        fprintf(['Calculating ', dfolder(ndf).name, '. ', num2str(100*ndf/numel(dfolder)), '%% complete.\n'])
        fpn = fullfile(dfolder(ndf).folder, dfolder(ndf).name);
        d = dir(fullfile(fpn, '*fineTDOA*.mat'));

        for nd = 1:numel(d)
            try
                load(fullfile(d(nd).folder, d(nd).name))

                newName = replace(d(nd).name, 'fineTDOA', '3Dloc');

                % iterate through each whale and localize
                for wn = 1:numel(whale)
                    if ~isempty(whale{wn})
                        if ~isempty(whale{wn}.TDet)
                            whale{wn}.wloc = nan([length(whale{wn}.TDet), 3]);
                            whale{wn}.Lbest = nan([length(whale{wn}.TDet), 1]);

                            % Determine which TDOAs had sufficient
                            % detections for interpolation

                            numDet = sum(~isnan(whale{wn}.TDOA), 1);

                            whale{wn}.TDeti = (whale{wn}.TDet(1):1/spd:whale{wn}.TDet(end)).';


                            % initialize smoothed data:
%                             whale{wn}.TDOAsm = nan(size(whale{wn}.TDOA));

                            % initialize interpolated data:
                            whale{wn}.TDOAi = nan([length(whale{wn}.TDeti), 18]);

                            

                            for ntdoa = 1:18
                        
                                InotNan = find(~isnan(whale{wn}.TDOA(:, ntdoa)));
                                if ntdoa>=13
                                    Irem = find(diff(whale{wn}.TDOA(InotNan, ntdoa))./diff(whale{wn}.TDet(InotNan))>=6/(c*spd));
                                    whale{wn}.TDOA(InotNan(Irem+1), ntdoa) = nan;
                                    InotNan = find(~isnan(whale{wn}.TDOA(:, ntdoa)));
                                end
                                if length(InotNan)>=5
                                    
                                    % break it up into segments if the time
                                    % between detections is too big or if
                                    % the TDOA changes too fast
                                    
                                    Ibreak = find(diff(whale{wn}.TDet(InotNan))>=5*60/spd | ...
                                        diff(whale{wn}.TDOA(InotNan, ntdoa))./diff(whale{wn}.TDet(InotNan))>=8/(c*spd));
                                    Ibreak = [0; Ibreak; length(InotNan)]; % add beginning and end
                                    
                                    for nbreak = 1:(length(Ibreak)-1)
                                        nstart = Ibreak(nbreak)+1;
                                        nend = Ibreak(nbreak+1);
                                        % find times that are within the period
                                        % of detections between first and last
                                        % detection not labeled as 'nan'
                                        Iwithin = find(whale{wn}.TDeti>=whale{wn}.TDet(InotNan(nstart)) ...
                                            & whale{wn}.TDeti<=whale{wn}.TDet(InotNan(nend)));

                                        % smooth and interpolate:
                                        whale{wn}.TDOAi(Iwithin, ntdoa) = pchip(whale{wn}.TDet(InotNan), whale{wn}.TDOA(InotNan, ntdoa), whale{wn}.TDeti(Iwithin));
                                        
                                        
                                        ok = 1;
                                    end
                                end

                            end
                            % LOCALIZE true detections:
                            whale{wn}.wloc = nan([length(whale{wn}.TDet), 3]);

                            sig2 = mean(whale{wn}.sigma.^2, 1, 'omitnan');
                            for idet = 1:length(whale{wn}.TDet)
                                [~, Idrift] = min((tdrift - whale{wn}.TDet(idet).^2));

                                Iuse = find(~isnan(whale{wn}.TDOA(idet, :)));
                                if length(Iuse)>=7
                                    TDOA = whale{wn}.TDOA(idet, :);
                                    TDOA(13:18) = TDOA(13:18) + driftTDOA(Idrift, :);

                                    L = (-sum(1./(2*sig2(Iuse)).*(M.TDOA(:, Iuse)-TDOA(Iuse)).^2, 2));

                                    [whale{wn}.L(idet), Ibest] = max(L);

                                    whale{wn}.wloc(idet, :) = M.wloc(Ibest, :);
                                end
                            end

                            % LOCALIZE interpolated detections:
                            whale{wn}.wloci = nan([length(whale{wn}.TDeti), 3]);

                            sig2 = mean(whale{wn}.sigma.^2, 'omitnan');
                            for idet = 1:length(whale{wn}.TDeti)
                                [~, Idrift] = min((tdrift - whale{wn}.TDeti(idet).^2));

                                Iuse = find(~isnan(whale{wn}.TDOAi(idet, :)));
                                if length(Iuse)>=7
                                    TDOA = whale{wn}.TDOAi(idet, :);
                                    TDOA(13:18) = TDOA(13:18) + driftTDOA(Idrift, :);

                                    L = (-sum(1./(2*sig2(Iuse)).*(M.TDOA(:, Iuse)-TDOA(Iuse)).^2, 2));

                                    [whale{wn}.Li(idet), Ibest] = max(L);

                                    whale{wn}.wloci(idet, :) = M.wloc(Ibest, :);
                                end
                            end
                        end
                    end
                end
                fig = figure(1);
                xlm = nan(1, 2);
                
                for wn = 1:numel(whale)
                    if ~isempty(whale{wn})
                        % get size of dots based on how many arrays they
                        % intersect:
                        sz = 20 + 60.*(sum(whale{wn}.IndUsed, 2)-7)./18;
                        sz(sz<=0) = nan;
                        
                        

                        % get color of whale:
                        wcol = brushing.params.colorMat(wn+2, :);

                        % change color brightness/darkness based on time:
                        if length(whale{wn}.TDet)>1
%                             tscale = (whale{wn}.TDet-(2*whale{wn}.TDeti(1)-whale{wn}.TDeti(end)))/(2*(whale{wn}.TDeti(end)-whale{wn}.TDeti(1)));
%                             tscalei = (whale{wn}.TDeti-(2*whale{wn}.TDeti(1)-whale{wn}.TDeti(end)))/(2*(whale{wn}.TDeti(end)-whale{wn}.TDeti(1)));

                            col = ones(size(whale{wn}.TDet))*wcol;
                            coli = ones(size(whale{wn}.TDeti))*wcol;

                            xlm(1) = min([xlm(1); whale{wn}.TDet]);
                            xlm(2) = max([xlm(2); whale{wn}.TDet]);

                            sub1 = subplot(6,3,[1,4]);
                            scatter(sub1, whale{wn}.TDet, whale{wn}.wloc(:, 1), sz, col)
                            hold on
                            scatter(sub1, whale{wn}.TDeti, whale{wn}.wloci(:, 1), 8, coli, 'filled')
                            xlim([xlm])
                            xticks(xlm(1):120/spd:xlm(end))
                            datetick('x', 'keeplimits', 'keepticks')
                            title('x (m)')
                            grid on

                            sub2 = subplot(6,3,[7,10]);
                            scatter(sub2, whale{wn}.TDet, whale{wn}.wloc(:, 2), sz, col)
                            hold on
                            scatter(sub2, whale{wn}.TDeti, whale{wn}.wloci(:, 2), 8, coli, 'filled')
                            xlim([xlm])
                            xticks(xlm(1):120/spd:xlm(end))
                            datetick('x', 'keeplimits', 'keepticks')
                            title('y (m)')
                            grid on

                            sub3 = subplot(6,3,[13, 16]);
                            scatter(sub3, whale{wn}.TDet, whale{wn}.wloc(:, 3), sz, col)
                            hold on
                            scatter(sub3, whale{wn}.TDeti, whale{wn}.wloci(:, 3), 8, coli, 'filled')
                            xlim([xlm])
                            xticks(xlm(1):120/spd:xlm(end))
                            datetick('x', 'keeplimits', 'keepticks')
                            title('z (m)')
                            grid on
                            hold on

                            for nt = 1:6
                                sub(nt) = subplot(6,3,3*nt-1);
                                scatter(sub(nt), whale{wn}.TDet, whale{wn}.TDOA(:, nt+12), ...
                                    sz, col)
                                hold on
                                scatter(sub(nt), whale{wn}.TDeti, whale{wn}.TDOAi(:, nt+12), ...
                                    8, coli, 'filled')
                                xlim([xlm])
                                xticks(xlm(1):120/spd:xlm(end))
                                datetick('x', 'keeplimits', 'keepticks')
                                ylabel('TDOA')
                                title(['large ap, pair', num2str(nt)])
                                grid on

                            end

                            %                             sub4 = subplot(3,2, [2,4,6]);
                            %                             scatter3(sub4, whale{wn}.wloc(:, 1), whale{wn}.wloc(:, 2), whale{wn}.wloc(:, 3), ...
                            %                                 sz, col, 'filled')
                            %                             hold on
                            %                             scatter3(sub4, whale{wn}.wloci(:, 1), whale{wn}.wloci(:, 2), whale{wn}.wloci(:, 3), ...
                            %                                 [], coli, 'filled')
                            %                             axis([-5000, 5000, -5000, 5000, -200, 1000])
                            %                             pbaspect([1,1,1])
                            %                             xlabel('x')
                            %                             ylabel('y')
                            %                             zlabel('z')
                            %                             scatter3(h(:, 1), h(:, 2), h(:, 3), 'sk')

                            for i = 1:length(whale{wn}.TDet)
                                doa1 = c*(whale{wn}.TDOA(i, 1:6).'\HEE);
                                doa2 = c*(whale{wn}.TDOA(i, 7:12).'\HEW);

                                % azimuths:
                                whale{wn}.Ang1(i, 1) = atan2d(doa1(2), doa1(1));
                                whale{wn}.Ang2(i, 1) = atan2d(doa2(2), doa2(1));

                                % elevations:
                                whale{wn}.Ang1(i, 2) = 180-acosd(doa1(3)/sqrt(sum(doa1.^2)));
                                whale{wn}.Ang2(i, 2) = 180-acosd(doa2(3)/sqrt(sum(doa2.^2)));
                            end

                            for i = 1:length(whale{wn}.TDeti)
                                doa1 = c*(whale{wn}.TDOAi(i, 1:6).'\HEE);
                                doa2 = c*(whale{wn}.TDOAi(i, 7:12).'\HEW);

                                % azimuths:
                                whale{wn}.Ang1i(i, 1) = atan2d(doa1(2), doa1(1));
                                whale{wn}.Ang2i(i, 1) = atan2d(doa2(2), doa2(1));

                                % elevations:
                                whale{wn}.Ang1i(i, 2) = 180-acosd(doa1(3)/sqrt(sum(doa1.^2)));
                                whale{wn}.Ang2i(i, 2) = 180-acosd(doa2(3)/sqrt(sum(doa2.^2)));
                            end

                            sub7 = subplot(6,3,3);
                            scatter(sub7, whale{wn}.TDet, whale{wn}.Ang1(:, 1), ...
                                sz, col)
                            hold on
                            scatter(sub7, whale{wn}.TDeti, whale{wn}.Ang1i(:, 1), ...
                                8, coli, 'filled')
                            xlim([xlm])
                            xticks(xlm(1):120/spd:xlm(end))
                            datetick('x', 'keeplimits', 'keepticks')
                            ylabel('angle')
                            title(['Azimuth, EE'])
                            grid on


                            sub8 = subplot(6,3,6);
                            scatter(sub8, whale{wn}.TDet, whale{wn}.Ang1(:, 2), ...
                                sz, col)
                            hold on
                            scatter(sub8, whale{wn}.TDeti, whale{wn}.Ang1i(:, 2), ...
                                8, coli, 'filled')
                            xlim([xlm])
                            xticks(xlm(1):120/spd:xlm(end))
                            datetick('x', 'keeplimits', 'keepticks')
                            ylabel('angle')
                            title(['Elevation, EE'])
                            grid on

                            sub9 = subplot(6,3,12);
                            scatter(sub9, whale{wn}.TDet, whale{wn}.Ang2(:, 1), ...
                                sz, col)
                            hold on
                            scatter(sub9, whale{wn}.TDeti, whale{wn}.Ang2i(:, 1), ...
                                8, coli, 'filled')
                            xlim([xlm])
                            xticks(xlm(1):120/spd:xlm(end))
                            datetick('x', 'keeplimits', 'keepticks')
                            ylabel('angle')
                            title('Azimuth, EW')
                            grid on

                            sub10 = subplot(6,3,15);
                            scatter(sub10, whale{wn}.TDet, whale{wn}.Ang2(:, 2), ...
                                sz, col)
                            hold on
                            scatter(sub10, whale{wn}.TDeti, whale{wn}.Ang2i(:, 2), ...
                                8, coli, 'filled')
                            xlim([xlm])
                            xticks(xlm(1):120/spd:xlm(end))
                            datetick('x', 'keeplimits', 'keepticks')
                            ylabel('angle')
                            title(['Elevation, EW'])
                            grid on

                        end
                    end
                end
                fig.WindowState='maximized';
                saveas(fig, fullfile(d(nd).folder, [newName(1:end-4), '_interp']), 'fig')
                saveas(fig, fullfile(d(nd).folder, [newName(1:end-4), '_interp']), 'jpg')
                saveas(fig, fullfile(plotDir, [newName(1:end-4), '_interp']), 'fig')
                saveas(fig, fullfile(plotDir, [newName(1:end-4), '_interp']), 'jpg')
                close(fig)

                save(fullfile(d(nd).folder, [newName, '_interp']), 'whale')

            catch ME
                fid = fopen(fullfile(fullfile(d(nd).folder, 'results.txt')), 'a');
                fprintf(fid, ['\nError in calcTracks, array ', num2str(nd), ': ', ME.message, '\n']);
                save(fullfile(d(nd).folder, ['calcTracksError_array', num2str(nd)]), 'ME')
                fclose(fid);
            end
        end

    end

end