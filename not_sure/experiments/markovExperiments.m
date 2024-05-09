load('D:\SOCAL_E_63\tracking\interns2022\AMS_Datasets\track43_180327_084016\track43_180327_084016_fineTDOA_Array2.mat')

%% model stuff
Mcoarse = load('B:\TDOAmodel_100m.mat');
% Mcoarse.TDOA()
% MfineFolder = 'B:\modelFiles_10mFrom200m'; % folder containing fine grid model
% calculate TDOA for each possible location posLoc
load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m
hydLoc = [0,0,0; h];

hyd1 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EE_Hmatrix_fromHydLocInversion_210702.mat');
hyd2 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EW_Hmatrix_fromHydLocInversion_210702.mat');


% Reorder hydrophones to fit new TDOA order
HEE = [hyd1.hydPos(2,:)-hyd1.hydPos(1,:);
         hyd1.hydPos(3,:)-hyd1.hydPos(1,:);
         hyd1.hydPos(4,:)-hyd1.hydPos(1,:);
         hyd1.hydPos(3,:)-hyd1.hydPos(2,:);
         hyd1.hydPos(4,:)-hyd1.hydPos(2,:);
         hyd1.hydPos(4,:)-hyd1.hydPos(3,:)];
     
HEW = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
         hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
         hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
         hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
         hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
         hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];

c = 1488.4;

%%
wn = 6;

% extract best detection to begin with:
[maxSNR, Imax] = max(sqrt(sum(whale{wn}.SNR.^2, 2)));

tdoa = whale{wn}.TDOA(Imax, :);
tdet = whale{wn}.TDet(Imax);
sigma = whale{wn}.sigma(Imax, :);

% determine most likely locations:
L = exp(-sum(1./(sigma.^2).*(Mcoarse.TDOA - tdoa).^2, 2));
Lsml =  exp(-sum(1./(sigma(1:12).^2).*(Mcoarse.TDOA(:, 1:12) - tdoa(1:12)).^2, 2));
Llrg =  exp(-sum(1./(sigma(13:18).^2).*(Mcoarse.TDOA(:, 13:18) - tdoa(13:18)).^2, 2));

[~, Isml] = max(Lsml);
[~, Ilrg] = max(Llrg);


wlocSml = Mcoarse.wloc(Isml, :);
wlocLrg = Mcoarse.wloc(Ilrg, :);

[Lcoarse, Iloc] = max(L);

coarseLoc = Mcoarse.wloc(Iloc, :);

% randomly generate whale positions around coarseLoc:
posLoc = coarseLoc + 400.*rand(1000, 3)-200;

scatter3(coarseLoc(1), coarseLoc(2), coarseLoc(3))
hold on
scatter3(posLoc(:,1), posLoc(:,2), posLoc(:,3), '.')
hold off

posTDOA = calcTDOAfromWloc(posLoc, hydLoc, HEE, HEW, c);


function TDOA = calcTDOAfromWloc(wloc, hydLoc, HEE, HEW, c)
N = size(wloc, 1); % number of whale locations  
% initialize TDOA     
TDOA = zeros([N, 18]);

% small aperture:
    
    % EE:
    see = wloc - hydLoc(1, :); % vector from hydrophone to whale
    ree = sqrt(sum(see.^2, 2)); % range between hydrophone and whale
    TDOA(:, 1:6) = -((see./ree)*HEE.')./c;

    % EW:
    sew = wloc - hydLoc(2, :); % vector from hydrophone to whale
    rew = sqrt(sum(sew.^2, 2)); % range between hydrophone and whale
    TDOA(:, 7:12) = -((sew./rew)*HEW.')./c;

    % EN:
    sen = wloc - hydLoc(3, :);
    ren = sqrt(sum(sen.^2, 2));

    % ES:
    ses = wloc - hydLoc(4, :);
    res = sqrt(sum(ses.^2, 2));

    % large aperture:
    TDOA(:, 13) = (ree-rew)./c;
    TDOA(:, 14) = (ree-ren)./c;
    TDOA(:, 15) = (ree-res)./c;
    TDOA(:, 16) = (rew-ren)./c;
    TDOA(:, 17) = (rew-res)./c;
    TDOA(:, 18) = (ren-res)./c;
end