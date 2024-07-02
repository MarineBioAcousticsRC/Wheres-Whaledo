function [whaleOut, varargout] = weightedSplineFit(whaleIn, smoothingParam)

% note - make sure you have the Curve Fitting Toolbox from MATLAB
% installed!

whaleOut = whaleIn;
spd = 24*60*60; % seconds per day

for wn = 1:numel(whaleOut)
    if isempty(whaleOut{wn})
        continue
    end
    whaleOut{wn}.wlocSmooth = nan(size(whaleOut{wn}.wloc));

    Iuse = find(~isnan(whaleOut{wn}.wloc(:,1))); % indices of localized detections
    if length(Iuse)<3
        continue
    end
    wts = sum(~isnan(whaleOut{wn}.TDOA(Iuse, :)), 2); % define weights as number of TDOAs used to localize
%     if length(unique(wts))>1 % if there is more than one 
%         % scales weights to be between 0 and 1:
%         wts = wts-min(wts);
%         wts = wts./max(wts);
%     end
    t = (whaleOut{wn}.TDet(Iuse) - whaleOut{wn}.TDet(Iuse(1))).*spd; % time in seconds
    wfit{wn}.t = t;
    wfit{wn}.t1 = whaleOut{wn}.TDet(Iuse(1));
    for ndim = 1:3 % iterate through each dimension (x, y, z)
        pos = whaleOut{wn}.wloc(Iuse, ndim); % whale position in dimension ndim

        splineFit = fit(t, pos, 'smoothingspline', 'SmoothingParam', smoothingParam, 'Weights', wts); % fit spline

        posSpline = feval(splineFit, t); % evaluate spline at times t

        wfit{wn}.dim{ndim} = splineFit;
        whaleOut{wn}.wlocSmooth(Iuse, ndim) = posSpline;
    end
end

if nargout==2
    if exist('wfit')
        varargout{1} = wfit;
    else
        varargout{1} = 'ERROR: no fit generated'
    end
end