% clock sync with DOA intersect
c = 1488.4;


% load drift:
load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift.mat');
dp{1} = coeffvalues(Dpoly{1}); % drift coefficients between inst 1 and 2
dp{2} = coeffvalues(Dpoly{2}); % drift coefficients between inst 1 and 3
dp{3} = coeffvalues(Dpoly{3}); % drift coefficients between inst 1 and 4
dp{4} = coeffvalues(Dpoly{4}); % drift coefficients between inst 2 and 3
dp{5} = coeffvalues(Dpoly{5}); % drift coefficients between inst 2 and 4
dp{6} = coeffvalues(Dpoly{6}); % drift coefficients between inst 3 and 4

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

df = dir('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\*track*'); % directory of folders containing files

TDet = []
TDOAmeas = [];
TDOAexp = [];
TDOAerrMean = [];
TDOAerrMode = [];
TDetM = [];
W = [];

nstart = 1;
for ndf = nstart:numel(df) % iterate through all folders containing localized tracks
%     fprintf(['file ', num2str(ndf), '. ', num2str(100*ndf/numel(df)), '%% done\n'])
    clear whale
    d = dir(fullfile(df(ndf).folder, [df(ndf).name, '\*fineTDOA*.mat']));
    if ~isempty(d)
        load(fullfile(d.folder, d.name))

        [tdoaexp, tdoameas, tdet] = calcTDOAerr_allDet(whale, hloc, H1, H2, c);

        TDOAmeas = [TDOAmeas; tdoameas];
        TDOAexp = [TDOAexp; tdoaexp];
        TDet = [TDet, tdet];
        if size(tdoameas, 1)>5
            TDOAerrMean = [TDOAerrMean; mean(tdoameas-tdoaexp, 'omitnan')];
            TDOAerrMode = [TDOAerrMode; mode(tdoameas-tdoaexp)];
            TDetM = [TDetM, mean(tdet)];
            W = [W, size(tdoameas, 1)];
        end
    end

end
%%
figure(1)
for sp = 1:6
    subplot(6,1,sp)
    plot(TDet, TDOAmeas(:, sp)-TDOAexp(:, sp), '.')
end

figure(2)
for sp = 1:6
    subplot(6,1,sp)
%     scatter(TDetM, TDOAerrMode(:, sp), W./10, W, '+')
%     hold on
    scatter(TDetM, TDOAerrMean(:, sp), W./10, 10.*ones(size(W)), 'x')
    
    plf = polyfit(TDetM, TDOAerrMean(:,sp), 1);
    lf = polyval(plf, TDetM);

    drft(:, sp) = (polyval(dp{sp}, TDetM)).';
    hold on
    
    plot(TDetM, drft(:, sp))
    plot(TDetM, lf)
    hold off
end
legend('Mean TDOA error', 'clock drift', 'line fit to mean error')


%%
function [TDOAexp, TDOAmeas, TDet] = calcTDOAerr_allDet(whale, hloc, H1, H2, c)

TDOAexp = [];
TDOAmeas = [];
TDet = [];
i = 0;

for wn = 1:numel(whale)
    if ~isempty(whale{wn})
        % find all the detections which were found on both 4ch:
        Iuse = find(sum(~isnan(whale{wn}.TDOA), 2)>=12);

        for ndet = 1:length(Iuse)
            i = i+1;
            TDet(i) = whale{wn}.TDet(Iuse(ndet));
            tdoameas = whale{wn}.TDOA(Iuse(ndet),:);

            DOA1 = (tdoameas(1:6).'\H1);
            DOA1 = DOA1./sqrt(sum(DOA1.^2));

            DOA2 = (tdoameas(7:12).'\H1);
            DOA2 = DOA2./sqrt(sum(DOA2.^2));

            [tdoaexp, ~, ~] = calcTDOAerr_1det(DOA1, DOA2, hloc, H1, H2, c);
            TDOAexp(i, :) = tdoaexp;
            TDOAmeas(i, :) = tdoameas(13:end);
        end

    end
end

end

function [TDOAexp, w, werr] = calcTDOAerr_1det(DOA1, DOA2, hloc, H1, H2, c)

% find whale location based on DOA intersect:

D = [DOA1; -DOA2];
R = D.'\(hloc(2, :)-hloc(1, :)).';

w1 = R(1).*DOA1 + hloc(1, :);
w2 = R(2).*DOA2 + hloc(2, :);

w = mean([w1; w2]);
werr = sqrt(sum((w1-w2).^2));

% use that whale location to estimate TDOA
R = sqrt(sum((w - hloc).^2, 2));

TDOAexp(1) = (R(1)-R(2))/c;
TDOAexp(2) = (R(1)-R(3))/c;
TDOAexp(3) = (R(1)-R(4))/c;
TDOAexp(4) = (R(2)-R(3))/c;
TDOAexp(5) = (R(2)-R(4))/c;
TDOAexp(6) = (R(3)-R(4))/c;

end