function [whaleOut] = ww_kalman_smooth_whales(whaleIn,vel,win,maxtimegap)

% ww_kalman_smooth_whales
%
% Take localized points from Where's Whaledo loc3D_DOA_intersect and smooth
% them with a constant-velocity Kalman filter + Rauch-Tung-Striebel (RTS)
% smoother, then finish with moving average smoothing.
% LMB Oct 2024, rewritten Oct 2026
% lbaggett@ucsd.edu
%
% Steps, for each whale:
%   1. split the track into segments wherever the time gap between
%      detections exceeds maxtimegap; each segment is smoothed on its own
%   2. forward Kalman filter through each segment (state = x,y,z position
%      and velocity), starting at the first detection with zero velocity.
%      Detections that are too far from the filter's prediction (given
%      their localization error) are treated as outliers and skipped
%   3. backward RTS pass, so each smoothed position uses detections both
%      before and after it
%   4. moving average within each segment
%   5. clamp smoothed positions so they can't go above the sea surface
%
% Inputs:
% whaleIn: the whale struct that is outputted from your loc3D intersect step
% vel: the average velocity (meters / second) you assume the whale is moving, get from
%       literature. Sets how quickly the filter lets the whale's velocity
%       change: velocity can drift by about vel over maxtimegap seconds.
% win: the number of detections that you would like to consider in your
%       moving average. This step further smooths your detections. If you would
%       not like to calculate a moving average, set this value at 1.
% maxtimegap: the maximum time gap (seconds) allowed between points that you are
%       interpolating through. If you encounter a time gap larger than this
%       threshold, the track is broken there (the last smoothed point before
%       the gap is set to NaN so plotted lines don't connect across it).
%
% Example input:
% whale = ww_kalman_smooth_whales(whale,1,20,60);
%   ** these are the settings that I typically use for beaked whales (Zc).
%       Modify as necessary for your species of interest.

% outlier gate: squared Mahalanobis distance of a detection from the
% filter's prediction, 99.9th percentile of chi-square with 3 dof
gateThresh = 16.27;
% after this many outliers in a row, assume the whale really did move
% and restart the filter at the current detection
maxConsecReject = 5;
% minimum localization error (m), so a detection with a near-zero CI
% can't pin the filter exactly to it
minErr = 1;

whaleOut = whaleIn; % save input whale for output

for wn = 1:numel(whaleIn) % for each whale in this encounter

    if height(whaleIn{wn}) > 10 % if we have more than 10 clicks for this whale

        measurements = whaleIn{1,wn}.wloc; % localized positions
        time = whaleIn{wn}.TDet; % time stamps
        error = [(whaleIn{wn}.CIx(:,2)-whaleIn{wn}.CIx(:,1))/2, ...
            (whaleIn{wn}.CIy(:,2)-whaleIn{wn}.CIy(:,1))/2, ...
            (whaleIn{wn}.CIz(:,2)-whaleIn{wn}.CIz(:,1))/2]; % position error

        % fill in missing/tiny errors with this whale's typical error
        for ax = 1:3
            typErr = median(error(:,ax),'omitnan');
            if isnan(typErr)
                typErr = minErr;
            end
            error(isnan(error(:,ax)),ax) = typErr;
        end
        error = max(error, minErr);

        N = size(measurements, 1); % total number of clicks for this whale

        if isdatetime(time)
            tsec = seconds(time - time(1));
        else
            tsec = (time - time(1))*24*60*60; % datenum days to seconds
        end

        % process noise: white-noise acceleration, scaled so velocity can
        % drift by about vel over maxtimegap
        q = vel^2/maxtimegap;

        positions_estimated = nan(N, 3);

        % segments of the track with no gaps larger than maxtimegap
        segEnds = [find(diff(tsec) > maxtimegap); N];
        segStarts = [1; segEnds(1:end-1)+1];

        for s = 1:numel(segStarts)

            idx = segStarts(s):segEnds(s);
            n = numel(idx);

            % storage for the forward pass, needed by the backward pass
            x_filt = nan(6, n); % filtered state
            P_filt = nan(6, 6, n); % filtered covariance
            x_pred = nan(6, n); % predicted state
            P_pred = nan(6, 6, n); % predicted covariance
            F_all = nan(6, 6, n); % state transition matrices
            restarted = false(1, n); % where the filter was restarted after outliers

            H = [eye(3) zeros(3)]; % we only measure position

            x_est = [];
            nReject = 0;

            for k = 1:n % forward Kalman filter

                i = idx(k);
                z = measurements(i,:)'; % this detection's position
                R = diag(error(i,:).^2); % measurement error for this detection

                if isempty(x_est) % start the filter at the first real detection
                    if any(isnan(z))
                        continue
                    end
                    x_est = [z; 0; 0; 0];
                    P_est = blkdiag(R, vel^2*eye(3));
                    F = eye(6);
                    x_pred(:,k) = x_est;
                    P_pred(:,:,k) = P_est;
                    F_all(:,:,k) = F;
                    x_filt(:,k) = x_est;
                    P_filt(:,:,k) = P_est;
                    continue
                end

                dt = tsec(i) - tsec(idx(k-1)); % time since previous detection

                % constant-velocity state transition
                F = [eye(3) dt*eye(3);
                    zeros(3) eye(3)];

                % process noise for this time step
                Qaxis = q*[dt^3/3 dt^2/2; dt^2/2 dt];
                Q = kron(Qaxis, eye(3));

                % predict
                xp = F*x_est;
                Pp = F*P_est*F' + Q;

                x_est = xp;
                P_est = Pp;

                if ~any(isnan(z)) % update with this detection, unless it's an outlier
                    y = z - H*xp; % residual
                    S = H*Pp*H' + R; % residual covariance
                    d2 = y'/S*y; % squared Mahalanobis distance

                    if d2 <= gateThresh || nReject >= maxConsecReject
                        if d2 > gateThresh
                            % too many outliers in a row: restart at this detection
                            x_est = [z; 0; 0; 0];
                            P_est = blkdiag(R, vel^2*eye(3));
                            Pp = P_est;
                            xp = x_est;
                            restarted(k) = true;
                        else
                            K = Pp*H'/S; % Kalman gain
                            x_est = xp + K*y;
                            P_est = (eye(6) - K*H)*Pp;
                        end
                        nReject = 0;
                    else
                        nReject = nReject + 1; % skip this detection
                    end
                end

                x_pred(:,k) = xp;
                P_pred(:,:,k) = Pp;
                F_all(:,:,k) = F;
                x_filt(:,k) = x_est;
                P_filt(:,:,k) = P_est;

            end

            % backward RTS smoother
            x_smooth = x_filt;
            for k = n-1:-1:1
                % don't smooth across a restart or before the filter started
                if restarted(k+1) || any(isnan(x_filt(:,k))) || any(isnan(x_filt(:,k+1)))
                    continue
                end
                C = P_filt(:,:,k)*F_all(:,:,k+1)'/P_pred(:,:,k+1);
                x_smooth(:,k) = x_filt(:,k) + C*(x_smooth(:,k+1) - x_pred(:,k+1));
            end

            % moving average within this segment
            % if the window size is larger than the number of points we have
            % (happens around the endpoints), shrink to fit to the smaller
            % window
            seg = x_smooth(1:3,:)';
            for ax = 1:3
                seg(:,ax) = movmean(seg(:,ax), win, 'omitnan', 'endpoints', 'shrink');
            end
            positions_estimated(idx,:) = seg;

            % break the track at the gap so plotted lines don't connect across it
            if s < numel(segStarts)
                positions_estimated(idx(end),:) = nan;
            end

        end

        % don't let smoothed positions go above the sea surface. wloc z
        % and LatLonDepth z (0 at the surface) differ by a constant
        % offset, which is the surface height in the wloc frame
        if ismember('LatLonDepth', whaleIn{wn}.Properties.VariableNames)
            zSurface = median(measurements(:,3) - whaleIn{wn}.LatLonDepth(:,3), 'omitnan');
            aboveSurface = positions_estimated(:,3) > zSurface; % (NaN gap breaks stay NaN)
            positions_estimated(aboveSurface,3) = zSurface;
        end

        % combine smoothed coordinates
        whaleOut{wn}.wlocSmooth = positions_estimated;

    end

end
