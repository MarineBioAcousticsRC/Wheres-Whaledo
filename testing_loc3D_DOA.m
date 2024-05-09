% testing:
global brushing
loadParams('brushing.params')
load('detections_brushDOA180611_1030.mat')
DET{1}.color = 4.*ones(size(DET{1}.color));

DET{1}.color = 4.*ones(size(DET{1}.color));
I = find(DET{1}.TDet<=datenum([18, 6, 11, 11, 05, 00]));
DET{1}.color(I) = 3.*ones(size(DET{1}.color(I)));

% When I made these DOAs I had the sign wrong in the detector, so don't do
% this if you ran the detector with the version after 15-June-2022
DET{1}.DOA = -DET{1}.DOA;
DET{2}.DOA = -DET{2}.DOA;

figure(914)
subplot(2,1,1)
scatter(DET{1}.TDet, DET{1}.Ang(:,2), 30, brushing.params.colorMat(DET{1}.color, :), 'filled');
datetick
subplot(2,1,2)
scatter(DET{2}.TDet, DET{2}.Ang(:,2), 30, brushing.params.colorMat(DET{2}.color, :), 'filled');
datetick

hyd1 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EE_Hmatrix_fromHydLocInversion_210702.mat');
hyd2 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EW_Hmatrix_fromHydLocInversion_210702.mat');

hydLoc{1} = hyd1.hydLoc;
hydLoc{2} = hyd2.hydLoc;

whaleLoc = loc3D_DOAintersect(DET, hydLoc, 'brushing.params')