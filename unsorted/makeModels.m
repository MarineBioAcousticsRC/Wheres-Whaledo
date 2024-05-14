clear all
% build TDOA model with non-uniform grid sizes

load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m

hee = [0,0,0];
hew = h(1,:);
hen = h(2,:);
hes = h(3,:);

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

HEE = [hyd1.hydPos(2,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(3,:)];

HEE = hyd1.H;



c = 1488.4;


csml = 1488.4;

%% coarse resolution

dx = 50;
dy = 50;
dz = 20;

xvecCoarse = -5500:dx:5000;
yvecCoarse = -4000:dy:4000;
zvecCoarse = -100:dz:1300; % height above array

wloc = zeros(length(xvecCoarse)*length(yvecCoarse)*length(zvecCoarse), 3);
% make wloc vector:
% this method just iterates over each grid point and assigns the value to
% wloc. It's easier to understand, but about 2x slower than the method that
% isn't commented out.
% tic
% n = 0;
% for nx = 1:length(xvecCoarse)
%     for ny = 1:length(yvecCoarse)
%         for nz = 1:length(zvecCoarse)
%             n = n+1;
%             wloc(n, :) = [xvecCoarse(nx), yvecCoarse(ny), zvecCoarse(nz)];
%         end
%     end
% end
% toc

tic
% fill in x positions:
indShift = 0;
for nx = 1:length(xvecCoarse)
    Ind = 1:length(yvecCoarse)*length(zvecCoarse); % indices to be filled with xvecCoarse(nx)
    Ind = Ind + indShift;
    wloc(Ind, 1) = xvecCoarse(nx);

    indShift = indShift + length(Ind);


end

indShift = 0;
for ny = 1:length(yvecCoarse)
    Ind = 1:length(zvecCoarse); % indices of first occurance of yvecCoarse(ny)
    Ind = Ind + indShift;
    ypart(Ind) = yvecCoarse(ny); % vector of first occurance of yvecCoarse(ny), i.e. y vector associated with xvecCoarse(1)
    indShift = indShift + length(Ind);

end
wloc(:, 2) = repmat(ypart.', [length(xvecCoarse), 1]);
wloc(:, 3) = repmat(zvecCoarse.', [length(wloc)/length(zvecCoarse), 1]);
toc
TDOA = zeros(length(xvecCoarse)*length(yvecCoarse)*length(zvecCoarse), 18);


% find received time if source time is 0:
see = wloc - hee;
ree = sqrt(sum(see.^2, 2));
see = see./ree;

sew = wloc - hew;
rew = sqrt(sum(sew.^2, 2));
sew = sew./rew;

sen = wloc - hen;
ren = sqrt(sum(sen.^2, 2));

ses = wloc - hes;
res = sqrt(sum(ses.^2, 2));

TDOA(:, 1:6) = (-see*HEE.')./csml; % small aperture TDOA for EE
TDOA(:, 7:12) = (-sew*HEW.')./csml; % small aperture TDOA for EW

% large aperture TDOAs:
TDOA(:, 13) = (ree - rew)./c;
TDOA(:, 14) = (ree - ren)./c;
TDOA(:, 15) = (ree - res)./c;
TDOA(:, 16) = (rew - ren)./c;
TDOA(:, 17) = (rew - res)./c;
TDOA(:, 18) = (ren - res)./c;


indShift = 0;
for ny = 1:length(yvecCoarse)
    Ind = 1:length(zvecCoarse); % indices of first occurance of yvecCoarse(ny)
    Ind = Ind + indShift;
    ypart(Ind) = yvecCoarse(ny); % vector of first occurance of yvecCoarse(ny), i.e. y vector associated with xvecCoarse(1)
    indShift = indShift + length(Ind);
end
wloc(:, 2) = repmat(ypart.', [length(xvecCoarse), 1]);
wloc(:, 3) = repmat(zvecCoarse.', [length(wloc)/length(zvecCoarse), 1]);
toc
TDOA = zeros(length(xvecCoarse)*length(yvecCoarse)*length(zvecCoarse), 18);



save(['B:\TDOAmodel_', num2str(dx), 'dx', num2str(dy), 'dy', num2str(dz), 'dz'], 'TDOA', 'wloc')

toc


% find received time if source time is 0:
see = wloc - hee;
ree = sqrt(sum(see.^2, 2));
see = see./ree;


sew = wloc - hew;
rew = sqrt(sum(sew.^2, 2));
sew = sew./rew;

sen = wloc - hen;
ren = sqrt(sum(sen.^2, 2));

ses = wloc - hes;
res = sqrt(sum(ses.^2, 2));

TDOA(:, 1:6) = (see*HEE.')./csml; % small aperture TDOA for EE
TDOA(:, 7:12) = (sew*HEW.')./csml; % small aperture TDOA for EW

% large aperture TDOAs:
TDOA(:, 13) = (ree - rew)./c;
TDOA(:, 14) = (ree - ren)./c;
TDOA(:, 15) = (ree - res)./c;
TDOA(:, 16) = (rew - ren)./c;
TDOA(:, 17) = (rew - res)./c;
TDOA(:, 18) = (ren - res)./c;



% save(['B:\TDOAmodel_', num2str(dx), 'dx', num2str(dy), 'dy', num2str(dz), 'dz', '_hydDepthAdjusted'], 'TDOA', 'wloc')
save(['B:\TDOAmodel_', num2str(dx), 'dx', num2str(dy), 'dy', num2str(dz), 'dz'], 'TDOA', 'wloc')

toc
wlocCoarse = wloc;
fineRes = 10;

% create vectors for all points in grid
% ranges are 200 more than previous so that each file contains +/2 from
% 100m resolution whale loc


for nCoarse = 1:length(wlocCoarse) % iterate over each grid point in coarse wloc

    xvecFine = (wlocCoarse(nCoarse, 1)-2*dx):fineRes:(wlocCoarse(nCoarse, 1)+2*dx);
    yvecFine = (wlocCoarse(nCoarse, 2)-2*dy):fineRes:(wlocCoarse(nCoarse, 2)+2*dy);
    zvecFine = (wlocCoarse(nCoarse, 3)-2*dz):fineRes:(wlocCoarse(nCoarse, 3)+2*dz);

    wloc = zeros(length(xvecFine)*length(yvecFine)*length(zvecFine), 3);
    TDOA = zeros(length(xvecFine)*length(yvecFine)*length(zvecFine), 18);
    n = 0;

    indShift = 0;
    for nx = 1:length(xvecFine)
        Ind = 1:length(yvecFine)*length(zvecFine); % indices to be filled with xvecFine(nx)
        Ind = Ind + indShift;
        wloc(Ind, 1) = xvecFine(nx);

        indShift = indShift + length(Ind);

    end

    indShift = 0;
    for ny = 1:length(yvecFine)
        Ind = 1:length(zvecFine); % indices of first occurance of yvecFine(ny)
        Ind = Ind + indShift;
        ypart(Ind) = yvecFine(ny); % vector of first occurance of yvecFine(ny), i.e. y vector associated with xvecFine(1)
        indShift = indShift + length(Ind);
    end
    wloc(:, 2) = repmat(ypart.', [length(xvecFine), 1]);
    wloc(:, 3) = repmat(zvecFine.', [length(wloc)/length(zvecFine), 1]);
    toc
    TDOA = zeros(length(xvecFine)*length(yvecFine)*length(zvecFine), 18);

    % find received time if source time is 0:
    see = wloc - hee;
    ree = sqrt(sum(see.^2, 2));
    see = see./ree;

    sew = wloc - hew;
    rew = sqrt(sum(sew.^2, 2));
    sew = sew./rew;

    sen = wloc - hen;
    ren = sqrt(sum(sen.^2, 2));

    ses = wloc - hes;
    res = sqrt(sum(ses.^2, 2));

    TDOA(:, 1:6) = (see*HEE.')./c; % small aperture TDOA for EE
    TDOA(:, 7:12) = (sew*HEW.')./c; % small aperture TDOA for EW

    % large aperture TDOAs:
    TDOA(:, 13) = (ree - rew)./c;
    TDOA(:, 14) = (ree - ren)./c;
    TDOA(:, 15) = (ree - res)./c;
    TDOA(:, 16) = (rew - ren)./c;
    TDOA(:, 17) = (rew - res)./c;
    TDOA(:, 18) = (ren - res)./c;

    save(['B:\modelFiles_10mFromVariableGridSize\TDOAmodel_10m_n=', sprintf('%05d', nCoarse)], 'TDOA', 'wloc')
end


%% 10 m resolution

% wlocCoarse = wloc;
% fineRes = 10;
% 
% % create vectors for all points in grid
% % ranges are 200 more than previous so that each file contains +/2 from
% % 100m resolution whale loc
% 
% 
% for nCoarse = 1:length(wlocCoarse) % iterate over each grid point in coarse wloc
% 
%     xvecFine = (wlocCoarse(nCoarse, 1)-2*dx):fineRes:(wlocCoarse(nCoarse, 1)+2*dx);
%     yvecFine = (wlocCoarse(nCoarse, 2)-2*dy):fineRes:(wlocCoarse(nCoarse, 2)+2*dy);
%     zvecFine = (wlocCoarse(nCoarse, 3)-2*dz):fineRes:(wlocCoarse(nCoarse, 3)+2*dz);
% 
%     wloc = zeros(length(xvecFine)*length(yvecFine)*length(zvecFine), 3);
%     TDOA = zeros(length(xvecFine)*length(yvecFine)*length(zvecFine), 18);
%     n = 0;
% 
%     indShift = 0;
%     for nx = 1:length(xvecFine)
%         Ind = 1:length(yvecFine)*length(zvecFine); % indices to be filled with xvecFine(nx)
%         Ind = Ind + indShift;
%         wloc(Ind, 1) = xvecFine(nx);
% 
%         indShift = indShift + length(Ind);
% 
%     end
% 
%     indShift = 0;
%     for ny = 1:length(yvecFine)
%         Ind = 1:length(zvecFine); % indices of first occurance of yvecFine(ny)
%         Ind = Ind + indShift;
%         ypart(Ind) = yvecFine(ny); % vector of first occurance of yvecFine(ny), i.e. y vector associated with xvecFine(1)
%         indShift = indShift + length(Ind);
%     end
%     wloc(:, 2) = repmat(ypart.', [length(xvecFine), 1]);
%     wloc(:, 3) = repmat(zvecFine.', [length(wloc)/length(zvecFine), 1]);
%     toc
%     TDOA = zeros(length(xvecFine)*length(yvecFine)*length(zvecFine), 18);
% 
%     % find received time if source time is 0:
%     see = wloc - hee;
%     ree = sqrt(sum(see.^2, 2));
%     see = see./ree;
% 
%     sew = wloc - hew;
%     rew = sqrt(sum(sew.^2, 2));
%     sew = sew./rew;
% 
%     sen = wloc - hen;
%     ren = sqrt(sum(sen.^2, 2));
% 
%     ses = wloc - hes;
%     res = sqrt(sum(ses.^2, 2));
% 
%     TDOA(:, 1:6) = (see*HEE.')./c; % small aperture TDOA for EE
%     TDOA(:, 7:12) = (sew*HEW.')./c; % small aperture TDOA for EW
% 
%     % large aperture TDOAs:
%     TDOA(:, 13) = (ree - rew)./c;
%     TDOA(:, 14) = (ree - ren)./c;
%     TDOA(:, 15) = (ree - res)./c;
%     TDOA(:, 16) = (rew - ren)./c;
%     TDOA(:, 17) = (rew - res)./c;
%     TDOA(:, 18) = (ren - res)./c;
% 
%     save(['B:\modelFiles_10mFromVariableGridSize\TDOAmodel_10m_n=', sprintf('%05d', nCoarse)], 'TDOA', 'wloc')
% end
% 
% 

