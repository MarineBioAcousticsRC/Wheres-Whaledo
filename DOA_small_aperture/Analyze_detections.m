%% run brushDOA
load('F:\Tracking\Erics_detector\SOCAL_E_63\detections\SOCAL_E_63_detections_track389_180611_104730')

[det1, det2] = brushDOA(DET{1}, DET{2},'brushing.params');

DET{1} = det1;
DET{2} = det2;
 
% save('F:\SOCAL_E_63_detections_track389_180611_104730_cleaned_brushDOA.mat', 'DET')