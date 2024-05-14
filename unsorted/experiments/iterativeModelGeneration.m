% iterative localization method

clear all
% build TDOA model with non-uniform grid sizes

load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m

h = [0,0,0; h];

% hen(3) = hen(3) + 6;
% hes(3) = hes(3) + 6;

hyd1 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EE_Hmatrix_new.mat');
hyd2 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EW_Hmatrix_new.mat');

% HEW = H;

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

% load('D:\SOCAL_E_63\tracking\interns2022\processAsIs\track19_180323_104620_mod_AMS5_corrAngle\track19_180323_104620_mod_AMS5_corrAngle_3Dloc_Array2.mat')
load('D:\SOCAL_E_63\tracking\interns2022\processAsIs\track30_180324_205700_mod_AMS2_corrAngle\track30_180324_205700_mod_AMS2_corrAngle_3Dloc_Array1.mat')
% load coarse model:
M = load('B:\TDOAmodel_100dx100dy20dz.mat'); % load model

load('D:\SOCAL_E_63\xwavTables\drift')
driftTDOA(:, 1) = drift(1, :).';
driftTDOA(:, 2) = drift(2, :).';
driftTDOA(:, 3) = drift(3, :).';
driftTDOA(:, 4) = drift(2, :).' - drift(1, :).';
driftTDOA(:, 5) = drift(3, :).' - drift(1, :).';
driftTDOA(:, 6) = drift(3, :).' - drift(2, :).';

%% Localize
% steps:
% 1. coarse localize
% 2. get range of detections based on top
for wn = 1:numel(whale)
    if ~isempty(whale{wn})
        whale{wn}.wcoarse = nan([length(whale{wn}.TDet), 3]);
        whale{wn}.Lcoarse = nan([length(whale{wn}.TDet), 1]);

        whale{wn}.wfine = nan([length(whale{wn}.TDet), 3]);
        whale{wn}.Lfine = nan([length(whale{wn}.TDet), 1]);

        Iuse = find(sum(whale{wn}.IndUsed, 2)>=7);

        for ndet = 1:length(Iuse)
            [~, Idrift] = min((tdrift - whale{wn}.TDet(Iuse(ndet)) ).^2); % index of drift

            TDOA = whale{wn}.TDOA(Iuse(ndet), :); % calculated TDOA
            TDOA(13:18) = TDOA(13:18) + driftTDOA(Idrift, :); % correct large ap TDOA for drift

            sig2 = whale{wn}.sigma(Iuse(ndet), :).^2;

            % indices of TDOA pairs which had detections:
            Itdoa = find(whale{wn}.IndUsed(Iuse(ndet), :)==1);

            M.wloc = [-6000, -6000, -200; 6000, 6000 1350];
            I = [1,2];
            for niter = 1:4

                xvec = linspace(min(M.wloc(I, 1)), max(M.wloc(I, 1)), 70);
                yvec = linspace(min(M.wloc(I, 2)), max(M.wloc(I, 2)), 70);
                zvec = linspace(min(M.wloc(I, 3)), max(M.wloc(I, 3)), 70);

                [M.TDOA, M.wloc] = makeModel(xvec, yvec, zvec, h, HEE, HEW, c); % fine grid

                L = (-sum(1./(2*sig2(Itdoa)).*(M.TDOA(:, Itdoa)-TDOA(Itdoa)).^2, 2));

                [~, I] = maxk(L, 1000);
                Lnorm = L(I); Lnorm = Lnorm-min(Lnorm); Lnorm = Lnorm./max(Lnorm);

                        subplot(2,2,niter)
                        scatter3(M.wloc(I, 1), M.wloc(I, 2), M.wloc(I, 3), [], Lnorm, 'filled')
                        title(['iteration ', num2str(niter)])
                        xlabel('x')
                        ylabel('y')
                        zlabel('z')
                        hold on
            end
                hold off
            bestwhaleloc(ndet, :) = M.wloc(I(1), :);
            bestTDet(ndet) = whale{wn}.TDet(Iuse(ndet));

        end
        figure(wn+6)
        subplot(3,2,[2,4,6])
        scatter3(bestwhaleloc(:, 1), bestwhaleloc(:, 2), bestwhaleloc(:, 3), 'filled')
        hold on
        scatter3(whale{wn}.wloc(:, 1), whale{wn}.wloc(:, 2), whale{wn}.wloc(:, 3), 'x')
        hold off
        xlabel('x')
        ylabel('y')
        zlabel('z')

        subplot(3,2,1)
        plot(bestTDet, bestwhaleloc(:, 1), '.')
        hold on
        plot(whale{wn}.TDet, whale{wn}.wloc(:, 1), 'x')
        hold off
        datetick
        ylabel('x (m)')

        subplot(3,2,3)
        plot(bestTDet, bestwhaleloc(:, 2), '.')
        hold on
        plot(whale{wn}.TDet, whale{wn}.wloc(:, 2), 'x')
        hold off
        datetick
        ylabel('y (m)')

        subplot(3,2,5)
        plot(bestTDet, bestwhaleloc(:, 3), '.')
        hold on
        plot(whale{wn}.TDet, whale{wn}.wloc(:, 3), 'x')
        hold off
        datetick
        ylabel('z (m)')
    end
end
%%
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