function ww_auto_label_whales(dets)

% ww_auto_label_whales()
%
% function to assign whale numbers to detections to minimize manual
% labeling:
% first, DBSCAN estimates the number and rough locations of targets
% (potential whales) from the encounter, then Kalman filters maintain 
% smooth per-target trajectories between batch steps, using 
% nearest-neighbor gating to accept consistent observations and reject 
% noise; tracks are created when new clusters appear and deleted when 
% they stop being supported.
%
% approach adapted from Walker et al., (in review, JASA)

% run DBSCAN
[labels, clusterCenters] = ww_DBSCAN_for_DOA(dets,eps,10);

unqLab = unique(labels);
figure
hold on
for u = 1:length(unqLab)
    thislab = find(labels==unqLab(u));
    scatter(dets.TDet(thislab),dets.Ang(thislab,1))
end

fprintf('Pausing here :)')





end