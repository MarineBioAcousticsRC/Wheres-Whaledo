load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track30_180324_205700\SOCAL_E_63_track30_180324_205700_ericMod_localized.mat')
load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track30_180324_205700\SOCAL_E_63_detections_track30_180324_205700_ericMod.mat')

% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track17_180323_045916\SOCAL_E_63_detections_track17_180323_045916_ericMod.mat')
% load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track17_180323_045916\SOCAL_E_63_track17_180323_045916_ericMod_localized.mat')


% load drift:
load('D:\SOCAL_E_63\xwavTables\drift');
dp{1} = coeffvalues(Dpoly{1}); % drift coefficients between inst 1 and 2
dp{2} = coeffvalues(Dpoly{2}); % drift coefficients between inst 1 and 3
dp{3} = coeffvalues(Dpoly{3}); % drift coefficients between inst 1 and 4
dp{4} = dp{2}-dp{1}; % drift coefficients between inst 2 and 3
dp{5} = dp{3}-dp{1}; % drift coefficients between inst 2 and 4
dp{6} = dp{3}-dp{2}; % drift coefficients between inst 3 and 4
% dp{1} = -dp{1};

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

c = 1488.4;

whaleLoc = loc3D_DOAintersect(DET, hydLoc, 'brushing.params');


for wn = 1:numel(whaleLoc)
    for ndet = 1:length(whale{wn}.TDet)
        [~, I] = min((whaleLoc{wn}.t - whale{wn}.TDet(ndet)).^2);

        for ntdoa = 1:6
            dr(ntdoa) = polyval(dp{ntdoa}, whale{wn}.TDet(ndet));
        end

        TDOAexp(1) = (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h1).^2)) - (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h2).^2))))/c;
        TDOAexp(2) = (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h1).^2)) - (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h3).^2))))/c;
        TDOAexp(3) = (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h1).^2)) - (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h4).^2))))/c;
        TDOAexp(4) = (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h2).^2)) - (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h3).^2))))/c;
        TDOAexp(5) = (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h2).^2)) - (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h4).^2))))/c;
        TDOAexp(6) = (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h3).^2)) - (sqrt(sum((whaleLoc{wn}.xyz(I, :) - h4).^2))))/c;

        DRIFT{wn}(ndet, :) = dr;

        eTDOA{wn}(ndet, :) = TDOAexp;

    end

    figure(10+wn)
    histogram(whale{wn}.TDOA(:, 13:18))
    hold on
    histogram(eTDOA{wn})
    hold off
    TDOAerr{wn} = whale{wn}.TDOA(:, 13:18) - eTDOA{wn};
    fig = figure(wn);
    for sp = 1:6
        subplot(6,1,sp)
        plot(whale{wn}.TDet, TDOAerr{wn}(:, sp), '.')
        histogram(TDOAerr{wn}(:,sp), 100)
        hold on
        stem(DRIFT{wn}(:, sp), 10.*ones(size(DRIFT{wn}(:, sp))))
        hold off
    end
end

%%
% Take whale locations from DOA intersect, calculate expected TDOA

for wn = 1:numel(whaleLoc)
    for ndet = 1:length(whaleLoc{wn}.t)
        x = whaleLoc{wn}.xyz(ndet, 1);
        y = whaleLoc{wn}.xyz(ndet, 2);
        z = whaleLoc{wn}.xyz(ndet, 3);
        [tdoa, wloc] = makeModel(x, y, z, hloc, H1, H2, c);

        [~, I] = min(abs(whale{wn}.TDet-whaleLoc{wn}.t(ndet)));
        %         drft{wn}(ndet, :) = DRIFT{wn}(I, :);
        terr{wn}(ndet, :) = whale{wn}.TDOA(I, :) - tdoa;

        smlTDOAexp{wn}(ndet, :) = whale{wn}.TDOA(I, 1:12);
        smlTDOAcalc{wn}(ndet, :) = tdoa(1:12);


    end
    figure(20+wn)
    for np = 1:6
        figure(20+wn)
        subplot(6,1,np)
        plot(smlTDOAexp{wn}(:, np), '.')
        hold on
        plot(smlTDOAcalc{wn}(:, np), '.')
        hold off
        ylim([-7e-4, 7e-4])

        figure(30+wn)
        subplot(6,1,np)
        plot(smlTDOAexp{wn}(:, np+6), '.')
        hold on
        plot(smlTDOAcalc{wn}(:, np+6), '.')
        hold off
        ylim([-7e-4, 7e-4])
        %         hold on
        %         stem(mean(drft{wn}(:, sp)), 10)
        %         hold off

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