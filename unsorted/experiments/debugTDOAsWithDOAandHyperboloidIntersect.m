% 1) take all detections found on both 4ch instruments
% 2) localize with DOA intersect
% 3) Determine expected TDOA from this position
% 4) wave expected TDOA, calculated TDOA, TDet, wloc, trackname
% 5) compare error between exp and calc TDOA across time (drift issue?)
% and space (sound speed error? Ray bending? Unresolvable geometry?)

%% pull in all the tracks & localize only with those that have detections on
% both 4chs. Save them in a separate folder.

% set up H matrices:
hyd1 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EE_Hmatrix_new.mat');
hyd2 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EW_Hmatrix_new.mat');

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

Nlrg = 6; % number of large ap TDOAs
global LOC
loadParams('localize.params')
sig2sml = LOC.sig_sml.^2;
sig2lrg = LOC.sig_lrg.^2;

global brushing
loadParams('D:\MATLAB_addons\gitHub\wheresWhaledo\brushing.params')

% xwav tables:
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EE_C4_xwavLookupTable');
XH{1} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EW_C4_xwavLookupTable');
XH{2} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EN_xwavLookupTable');
XH{3} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_ES_xwavLookupTable');
XH{4} = xwavTable;

fdir = dir('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\*track*');

w_doaInt = nan(1e5, 3);
w_12 = w_doaInt; % DOA 1, large ap TDOA 1-2
w_21 = w_doaInt; % DOA 2, large ap TDOA 1-2
w_13 = w_doaInt; % DOA 1, large ap TDOA 1-3
w_14 = w_doaInt; % DOA 1, large ap TDOA 1-4
w_23 = w_doaInt; % DOA 2, large ap TDOA 2-3
w_24 = w_doaInt; % DOA 2, large ap TDOA 2-4

werr = nan(1e5, 1);
tdet = werr;
tdoa_exp = nan(1e5, 6);
tdoa_meas = tdoa_exp;
tdoa_nodrift = tdoa_exp;
encNum = werr;
drft = tdoa_exp;

options = optimoptions('fsolve', 'Display', 'none');

ijk = 0;
for nd = 1:numel(fdir)
    if ~isfolder(fullfile(fdir(nd).folder, fdir(nd).name)) % if this isn't a directory, skip to next iteration
        continue
    end
    currentDirectory = fullfile(fdir(nd).folder, fdir(nd).name);
    if contains(currentDirectory, 'track600')
        ok =1 ;
    end

    locFile = dir(fullfile(currentDirectory, '*loc*.mat'));

    % if there are multiple localization files, select the most recently
    % edited one:
    if numel(locFile)==1

    elseif isempty(locFile)
        continue
    else % more than one localization file exists
        dnum = datenum(vertcat(locFile(:).date)); % datenum format of last edited date
        [~, IndLastEdited] = max(dnum); % find most recently edited loc file
        locFile = locFile(IndLastEdited); % reassign locFile to only most recently edited

    end
    load(fullfile(locFile.folder, locFile.name))

    for wn = 1:numel(whale)
        try
            Iuse = find(~isnan(whale{wn}.Ang1(:, 1)) & ~isnan(whale{wn}.Ang2(:, 1)));
        catch
            continue
        end
        for i = 1:length(Iuse)
            ijk = ijk+1;
            ang1 = whale{wn}.Ang1(Iuse(i), :);
            ang2 = whale{wn}.Ang2(Iuse(i), :);

            doa1(1) = sind(180-ang1(2))*cosd(ang1(1));
            doa1(2) = sind(180-ang1(2))*sind(ang1(1));
            doa1(3) = cosd(180-ang1(2));
            doa1 = doa1./sqrt(sum(doa1.^2));

            doa2(1) = sind(180-ang2(2))*cosd(ang2(1));
            doa2(2) = sind(180-ang2(2))*sind(ang2(1));
            doa2(3) = cosd(180-ang2(2));
            doa2 = doa2./sqrt(sum(doa2.^2));

            D = [doa1; -doa2];

            R = D.'\(h2-h1).';

            w1 = R(1).*doa1 + h1;
            w2 = R(2).*doa2 + h2;

            w_doaInt(ijk, :) = mean([w1; w2]);
            werr(ijk, :) = sqrt(sum((w1-w2).^2));

            drift = zeros(1, 6);
            for ntdoa = 1:6
                drift(ntdoa) = polyval(dp{ntdoa}, whale{wn}.TDet(Iuse(i)));
            end

            drft(ijk, :) = drift;

            tdoa_nodrift(ijk, :) = whale{wn}.TDOA(Iuse(i), 13:end);
            tdoa_meas(ijk, :) = whale{wn}.TDOA(Iuse(i), 13:end) + LOC.driftSign.*drift;

            r1 = sqrt(sum((w_doaInt(ijk, :) - hloc(1, :)).^2));
            r2 = sqrt(sum((w_doaInt(ijk, :) - hloc(2, :)).^2));
            r3 = sqrt(sum((w_doaInt(ijk, :) - hloc(3, :)).^2));
            r4 = sqrt(sum((w_doaInt(ijk, :) - hloc(4, :)).^2));

            tdoa_exp(ijk, 1) = (r1-r2)/LOC.c;
            tdoa_exp(ijk, 2) = (r1-r3)/LOC.c;
            tdoa_exp(ijk, 3) = (r1-r4)/LOC.c;
            tdoa_exp(ijk, 4) = (r2-r3)/LOC.c;
            tdoa_exp(ijk, 5) = (r2-r4)/LOC.c;
            tdoa_exp(ijk, 6) = (r3-r4)/LOC.c;

            tdet(ijk) = whale{wn}.TDet(Iuse(i));
            encNum(ijk) = nd;

            % localize with hyperboloid/DOA intersect:

            % DOA 1, large ap TDOA 1-2
            if ~isnan(tdoa_meas(ijk, 1))
                fun = @(r)searchOneDOA(r, doa1, tdoa_meas(ijk, 1), LOC.c, hloc([1,2], :));
                [r, ~, ~, ~]  = fsolve(fun, 0, options);
                w_12(ijk, :) = doa1.*r + hloc(1, :);

                % DOA 2, large ap TDOA 1-2
                fun = @(r)searchOneDOA(r, doa2, -tdoa_meas(ijk, 1), LOC.c, hloc([2,1], :));
                [r, ~, ~, ~]  = fsolve(fun, 0, options);
                w_21(ijk, :) = doa2.*r + hloc(2, :);
            end

            % DOA 1, large ap TDOA 1-3
            if ~isnan(tdoa_meas(ijk, 2))
                fun = @(r)searchOneDOA(r, doa1, tdoa_meas(ijk, 2), LOC.c, hloc([1,3], :));
                [r, ~, ~, ~]  = fsolve(fun, 0, options);
                w_13(ijk, :) = doa1.*r + hloc(1, :);
            end

            % DOA 1, large ap TDOA 1-4
            if ~isnan(tdoa_meas(ijk, 3))
                fun = @(r)searchOneDOA(r, doa1, tdoa_meas(ijk, 3), LOC.c, hloc([1,4], :));
                [r, ~, ~, ~]  = fsolve(fun, 0, options);
                w_14(ijk, :) = doa1.*r1 + hloc(1, :);
            end

            % DOA 2, large ap TDOA 2-3
            if ~isnan(tdoa_meas(ijk, 4))
                fun = @(r)searchOneDOA(r, doa2, tdoa_meas(ijk, 4), LOC.c, hloc([2,3], :));
                [r, ~, ~, ~]  = fsolve(fun, 0, options);
                w_23(ijk, :) = doa2.*r + hloc(2, :);
            end

            % DOA 2, large ap TDOA 2-4
            if ~isnan(tdoa_meas(ijk, 5))
                fun = @(r)searchOneDOA(r, doa2, tdoa_meas(ijk, 5), LOC.c, hloc([2,4], :));
                [r, ~, ~, ~]  = fsolve(fun, 0, options);
                w_24(ijk, :) = doa2.*r + hloc(2, :);
            end
        end
    end
end

Irem = find(isnan(tdet));


w_doaInt(Irem, :) = [];
w_12(Irem, :) = []; % DOA 1, large ap TDOA 1-2
w_21(Irem, :) = []; % DOA 2, large ap TDOA 1-2
w_13(Irem, :) = []; % DOA 1, large ap TDOA 1-3
w_14(Irem, :) = []; % DOA 1, large ap TDOA 1-4
w_23(Irem, :) = []; % DOA 2, large ap TDOA 2-3
w_24(Irem, :) = []; % DOA 2, large ap TDOA 2-4
werr(Irem) = [];
tdet(Irem) = [];
tdoa_exp(Irem, :) = [];
tdoa_meas(Irem, :) = [];
tdoa_nodrift(Irem, :) = [];
encNum(Irem) = [];
drft(Irem, :) = [];
%%
pairstr{1} = '1-2';
pairstr{2} = '1-3';
pairstr{3} = '1-4';
pairstr{4} = '2-3';
pairstr{5} = '2-4';
pairstr{6} = '3-4';

figure(1)
for sp = 1:6
    subplot(6,1,sp)
    plot(tdet, tdoa_exp(:, sp) - tdoa_meas(:, sp), '.')
    grid on
    title(pairstr{sp})
    datetick
    ylabel('difference [s]')
    %     ylim([-.1, .1])
end
sgtitle('exp-meas')

figure(2)
for sp=1:6
    subplot(6,1,sp)
    histogram(tdoa_exp(:, sp) - tdoa_meas(:, sp))
    title(pairstr{sp})
end
xlabel('exp-meas [s]')
sgtitle('histograms of exp-meas')
r = sqrt(sum(w_doaInt.^2, 2));

figure(3)
for sp = 1:6
    subplot(6,1,sp)
    plot(r, tdoa_exp(:, sp) - tdoa_meas(:, sp), '.')
    grid on
    %     ylim([-.1, .1])
    xlim([0, 4000])
    title(pairstr{sp})
    ylabel('exp-meas [s]')
end
xlabel('range to center of instruments [m]')

%%

edges = -.05:.001:.05;
encNum_unique = unique(encNum);
tdet_hist = zeros(size(encNum_unique));
HC = zeros(length(encNum_unique), length(edges)-1);

figure(4)
for sp = 1:6
    for nd = 1:length(encNum_unique)
        I = find(encNum==encNum_unique(nd));

        [N,~] = histcounts(tdoa_exp(I, sp)-tdoa_meas(I, sp), edges);

        tdet_hist(nd) = mean(tdet(I));
        HC(nd, :) = N./max(N);
%         HC(nd, :) = N;

    end
    subplot(3,2,sp)
    [~, Isort] = sort(tdet_hist);
    imagesc(tdet_hist(Isort) - min(tdet), edges, HC(Isort, :).')
    set(gca, 'YDir', 'normal')
    title(pairstr{sp})
    c = colorbar;
    c.Label.String = 'normalized counts';
    xlabel('days since deployment')
    ylabel('error')
    
%             hold on
%         plot(tdet - min(tdet), drft(:, sp), 'r-')
%         hold off
    
end


%%
edges = -.05:.002:.05;
r_round = round(r/10)*10;
r_unique = unique(r_round);
tdet_hist = zeros(size(encNum_unique));
HC = zeros(length(r_unique), length(edges)-1);

figure(14)
for sp = 1:6
    for nd = 1:length(r_unique)
        I = find(r_round==r_unique(nd));

        [N,~] = histcounts(tdoa_exp(I, sp)-tdoa_meas(I, sp), edges);

        tdet_hist(nd) = mean(tdet(I));
%         HC(nd, :) = N./max(N);
        HC(nd, :) = N;

    end
    subplot(3,2,sp)
    [~, Isort] = sort(r_unique);
    imagesc(r_unique(Isort), edges, HC(Isort, :).')
    set(gca, 'YDir', 'normal')
    title(pairstr{sp})
    c = colorbar;
    c.Label.String = 'normalized counts';
    xlabel('range to center [m]')
    ylabel('error')
    
%             hold on
%         plot(tdet - min(tdet), drft(:, sp), 'r-')
%         hold off
    
end

%%
figure(5)
for sp = 1:6
    subplot(3,2,sp)
    histogram2(r, tdoa_exp(:, sp) - tdoa_meas(:, sp))
    xlabel('range [m]')
    ylabel('tdoa error')
    title(pairstr{sp})
end


%%
figure(6)

ystr{1} = 'x [m]';
ystr{2} = 'y [m]';
ystr{3} = 'z [m]';

for sp = 1:3
    subplot(3,1, sp)
%     hold on
    plot(w_12(:, sp)-w_doaInt(:, sp), '<')
    hold on
    plot(w_13(:, sp)-w_doaInt(:, sp), '<')
    plot(w_14(:, sp)-w_doaInt(:, sp), '<')
    plot(w_21(:, sp)-w_doaInt(:, sp), 'o')
    plot(w_23(:, sp)-w_doaInt(:, sp), 'o')
    plot(w_24(:, sp)-w_doaInt(:, sp), 'o')
    hold off
    ylim([-4000, 4000])
    ylabel(ystr{sp})
    title('error in whale position estimates')
end

w_edges = -2000:50:2000;
figure(7)
for sp = 1:3
    if sp==3
        w_edges = -500:10:500;
    end
    subplot(3,6, (sp-1)*6 +1)
    histogram(w_12(:, sp)-w_doaInt(:, sp), w_edges)
    ylabel(ystr{sp})
    title('DOA1, TDOA 1-2')
%     ylim([0, 6e4])

    subplot(3,6, (sp-1)*6 +2)
    histogram(w_13(:, sp)-w_doaInt(:, sp), w_edges)
    title('DOA1, TDOA 1-3')
%     ylim([0, 6e4])

    subplot(3,6, (sp-1)*6 +3)
    histogram(w_14(:, sp)-w_doaInt(:, sp), w_edges)
    title('DOA1, TDOA 1-4')
%     ylim([0, 6e4])

    subplot(3,6, (sp-1)*6 +4)
    histogram(w_21(:, sp)-w_doaInt(:, sp), w_edges)
    title('DOA2, TDOA 2-1')
%     ylim([0, 6e4])

    subplot(3,6, (sp-1)*6 +5)
    histogram(w_23(:, sp)-w_doaInt(:, sp), w_edges)
    title('DOA2, TDOA 2-3')
%     ylim([0, 6e4])

    subplot(3,6, (sp-1)*6 +6)
    histogram(w_24(:, sp)-w_doaInt(:, sp), w_edges)
    title('DOA2, TDOA 2-4')
%     ylim([0, 6e4])
end
sgtitle('histogram of errors in whale position estimates')
%%
wmean = (w_12 + w_21 + w_13 + w_14 + w_23 + w_24)./6;

figure(8)
w_edges = -2000:50:2000;
for sp = 1:3
    if sp==3
        w_edges = -500:10:500;
    end
    subplot(3,6, (sp-1)*6 +1)
    histogram(w_12(:, sp)-wmean(:, sp), w_edges)
    title(pairstr{1})
%     ylim([0, 6e4])

    subplot(3,6, (sp-1)*6 +2)
    histogram(w_13(:, sp)-wmean(:, sp), w_edges)
    title(pairstr{2})
%     ylim([0, 6e4])

    subplot(3,6, (sp-1)*6 +3)
    histogram(w_14(:, sp)-wmean(:, sp), w_edges)
    title(pairstr{3})
%     ylim([0, 6e4])

    subplot(3,6, (sp-1)*6 +4)
    histogram(w_21(:, sp)-wmean(:, sp), w_edges)
    title(pairstr{4})
%     ylim([0, 6e4])

    subplot(3,6, (sp-1)*6 +5)
    histogram(w_23(:, sp)-wmean(:, sp), w_edges)
    title(pairstr{5})
%     ylim([0, 6e4])

    subplot(3,6, (sp-1)*6 +6)
    histogram(w_24(:, sp)-wmean(:, sp), w_edges)
    title(pairstr{6})
%     ylim([0, 6e4])
end


%%

function L = searchOneDOA(r1, doa, tdoa, c, hloc)
w = r1*doa + hloc(1, :);

r2 = sqrt(sum((w - hloc(2, :)).^2));

L = (tdoa - (r1-r2)./c)^2;

end

