function [idxAmatch, idxBmatch] = ww_match_dets_with_ID_files(A,B,tol)

% [idxAmatch, idxBmatch] = ww_match_dets_with_ID_files(A,B,tol)
%
% function to match detections from Where'sWhaledo detector with inputted
% ID files from a user
% inputs:
%   - A: n x 1 vector of sorted datenums from ID files
%   - B: m x 1 vector of datenums from Where'sWhaledo
%   - tol: tolerance for matching detection times (in seconds)
% outputs:
%   - idxAmatch: indices of rows in A (ID detections) that match values in
%       B (ww detections)
%   - idxBmatch: indices in B (ww detections) which have a matching
%       timestamp

global PARAMS

% first, check ID timestamps to see if they're in millenium format or not
if datetime(A(1),'convertfrom','datenum') > datetime('01-Jan-2000');
    A = A - datenum([2000 0 0 0 0 0]);
end

% convert tolerance to datenum value
tolerance = tol / PARAMS.conversion.spd;

% discretize ID detections into bins
edges = [-inf; (A(1:end-1) + A(2:end))/2; inf];
idxAnear = discretize(B,edges); % match ww detections to these bins

% since we just did nearest-neighbor matching, see if any of these
% detections are close enough for us to count
err = abs(B - A(idxAnear)); 
keep = find(err<=tol);

% grab indices
idxBmatch = find(keep); % indices in B
idxAmatch = idxAnear(keep); % corresponding indices in A

end