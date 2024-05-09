%% run brushDOA
load('detections.mat')

[det1, det2] = brushDOA(DET{1}, DET{2});

DET{1} = det1;
DET{2} = det2;
 
save('detections_brushDOA.mat', 'DET')