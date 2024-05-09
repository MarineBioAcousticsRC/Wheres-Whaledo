close all

d = dir('D:\SOCAL_E_63\tracking\interns2022\processAsIs\track*')

% load hydrophone locations:
load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m
h = [0,0,0; h];

ntrack = 0;

for nd = 1:numel(d)
    if d(nd).isdir
        for narr = 1:2
            df = dir(fullfile(fullfile(d(nd).folder, d(nd).name), ['*3Dloc_Array', num2str(narr), '*.mat']));

            if ~isempty(df)
                load(fullfile(df.folder, df.name))

                for wn = 1:numel(whale)
                    if ~isempty(whale{wn})
                        if ~isempty(whale{wn}.TDet)
                            Irem = find(abs(whale{wn}.wloc(:, 1))>5000);
                            whale{wn}.wloc(Irem, :) = nan;

                            Irem = find(abs(whale{wn}.wloc(:, 2))>5000);
                            whale{wn}.wloc(Irem, :) = nan;

                            Irem = find(whale{wn}.wloc(:, 3)>1000);
                            whale{wn}.wloc(Irem, :) = nan;

                            I = find(~isnan(whale{wn}.wloc(:, 1)));

                            t = whale{wn}.TDet(I);

                            x = whale{wn}.wloc(I, 1);
                            y = whale{wn}.wloc(I, 2);
                            z = whale{wn}.wloc(I, 3);

                            if ~isempty(x)
                                
                                [x, Irm] = rmoutliers(x, 'movmean', min([length(x), 50]));
                                y(Irm) = [];
                                z(Irm) = [];
                                t(Irm) = [];

                                [y, Irm] = rmoutliers(y, 'movmean', min([length(y), 50]));
                                x(Irm) = [];
                                z(Irm) = [];
                                t(Irm) = [];

                                [z, Irm] = rmoutliers(z, 'movmean', min([length(z), 50]));
                                x(Irm) = [];
                                y(Irm) = [];
                                t(Irm) = [];

                                %                             figure(10)
                                %                            plot3(x,y,z, '.-')

                                %                            txt = input('\nUse in plot? y/n: ', 's');
                                txt = 'y'

                                ok = 1;
                                if strcmp(txt, 'y')

                                    if length(t)>5
                                                                       I = find(~isnan(whale{wn}.wloc(:, 1)));
                                                                       px = polyfit(t, x-mean(x), 4);
                                                                       xf = polyval(px,t);
                                                                       xf = xf + mean(x);
%                                         xf = spline(t, x, t);

                                                                       py= polyfit(t, y-mean(y), 4);
                                                                       yf = polyval(py,t);
                                                                       yf = yf + mean(y);
%                                         yf = spline(t, y, t);


                                                                       pz= polyfit(t, z-mean(z), 4);
                                                                       zf = polyval(pz,t);
                                                                       zf = zf + mean(z);
%                                         zf = spline(t, z, t);


                                    

                                        figure(1)
                                        plot(xf, yf)
                                        hold on

                                        figure(2)
                                        plot((t-t(1)).*60*24,1330-zf)
                                        hold on

                                        % calculate azimuthal heading:
                                        px = polyfit(x, t, 1);
                                        py = polyfit(y, t, 1);

                                        %px(1) is the slope of the line
                                        ntrack = ntrack + 1;
                                        tstart(ntrack) = t(1);
                                        az(ntrack) = atan2d(py(1), px(1));
                                        
                                    end
                                end
                            end
                        end
                    end
                end

            end

        end
    end
end
%%
figure(1)
hold on
scatter(h(:, 1), h(:, 2), 'k^', 'filled')
hold off
xlabel('E-W (m)')
ylabel('N-S (m)')
grid on
saveas(gca, 'XYplot')
saveas(gca, 'XYplot', 'jpg')

figure(2)
axis ij
xlabel('Minutes after start of encounter')
ylabel('Depth (m)')
grid on
saveas(gca, 'ZTplot')
saveas(gca, 'ZTplot', 'jpg')
%%
figure(3)
Irem = find(tstart < 6000);
tstart(Irem) = [];
az(Irem) = [];
% az(az<0) = az(az<0) + 360;

plot(tstart+datenum([2000, 0, 0, 0, 0, 0]), az, '.', 'markersize', 15)
datetick('x', 'yyyy-mmm-dd')
xlabel('Date (UTC)')
grid on
% yticks({''})
% ylabel('')
%%
figure(4)
edges = (0:45:360) + 22.5;
edges = deg2rad(edges);
polarhistogram(az, edges);
title('Histogram of average horizontal direction of travel')
thetaticks(0:45:360)
thetaticklabels({'E', 'NE', 'N', 'NW', 'W', 'SW', 'S', 'SE'})
rticks(20:5:55);
rlim([0, 55])
saveas(gca, 'dirHist')
saveas(gca, 'dirHist', 'jpg')