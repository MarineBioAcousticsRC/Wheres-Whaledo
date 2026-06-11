function [labels, clusterCenters] = ww_DBSCAN_for_DOA(dets,rad,min_samples)

% [labels, clusterCenters] = ww_DBSCAN_for_DOA(dets,eps,min_samples)
%
% function to run DBSCAN on DOA unit vectors and compute cluster centers
% inputs:
%   - dets: DET field from array with more detections
%   - rad: DBSCAN neighborhood radius
%   - min_samples: minimum number of points to form a cluster
% outputs:
%   - labels: cluster labels (noise is -1)
%   - clusterCenters: array of cluster "centers" (mean of last 3 points,
%       to estimate current position which is useful for the Kalman filter
%       step coming after this :)

% grab point cloud (DOA values, N x 3)
X = [dets.DOA(:,1), dets.DOA(:,2), dets.DOA(:,3)];

% run DBSCAN (statistics + machine learning toolbox!)
labels = dbscan(X,rad,min_samples);

% find the cluster "centers" (more recent location)
unq = unique(labels); unq(unq==-1) = []; % find unique labels but remove noise

for j = 1:length(unq)
    idx = find(labels==unq(j));
    n = numel(idx);
    if n >=3
        useIdx = idx(end-2:end);
    else
        useIdx = idx;
    end
    clusterCenters(j,:) = mean(X(useIdx,:),1);
end
