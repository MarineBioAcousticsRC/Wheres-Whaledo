fpath = 'D:\SOCAL_E_63\tracking\interns2022\processAsIs\track147_180416_160254_mod_AMS4_corrAngle';
fname = 'track147_180416_160254_mod_AMS4_corrAngle_3Dloc_Array1.mat';

load(fullfile(fpath, fname))

wn = 2;

load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m

h = [0,0,0; h];
h(3:4, 3) = h(3:4, 3) + 10;


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
spd = 24*60*60;

M = load('B:\TDOAmodel_100dx100dy20dz.mat'); % load model

t = (whale{wn}.TDet-whale{wn}.TDet(1)).*spd;
TDOA = whale{wn}.TDOA;

% Build the forward-looking weight matrix:
A = zeros(length(t), length(t));

ix = 1:length(t)-2;
iy = 2:length(t)-1;
I = sub2ind(size(A), ix, iy);
A(I) = 1 + (t(3:end) - t(2:end-1))./(t(2:end-1)-t(1:end-2));

B = zeros(size(A));
T = (t(2:end-1) - t(3:end))./(t(2:end-1) - t(1:end-2));
T(end + 1) = 0;
T(end+1) = 0;
B = diag(T);

C = -eye(length(t));
C(1,1) = 0;
C(2,2) = 0;

D = A + B + C;

