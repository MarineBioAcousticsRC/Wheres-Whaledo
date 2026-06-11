function [whaleOut] = ww_kalman_smooth_whales(whaleIn,vel,win,maxtimegap)

% ww_kalman_smooth_whales
%
% Take localized points from Where's Whaledo loc3D_DOA_intersect and smooth
% them by applying a Kalman filter. Model covariance matrices using correlated random walk,
% and finish with moving average smoothing.
% LMB Oct 2024
% lbaggett@ucsd.edu
%
% Inputs:
% whaleIn: the whale struct that is outputted from your loc3D intersect step
% vel: the average velocity (meters / second) you assume the whale is moving, get from
%       literature
% win: the number of detections that you would like to consider in your
%       moving average. This step further smooths your detections. If you would
%       not like to calculate a moving average, set this value at 1.
% maxtimegap: the maximum time gap (seconds) allowed between points that you are
%       interpolating through. If you encounter a time gap larger than this
%       threshold, no smoothed position for that period will be generated.
%
% Example input:
% whale = kalman_filter_whale(whale,1,20,60);
%   ** these are the settings that I typically use for beaked whales (Zc).
%       Modify as necessary for your species of interest.

whaleOut = whaleIn; % save input whale for output

for wn = 1:numel(whaleIn) % for each whale in this encounter

    if height(whaleIn{wn}) > 10 % if we have more than 10 clicks for this whale

        measurements = whaleIn{1,wn}.wloc; % localized positions
        time = whaleIn{wn}.TDet; % time stamps
        error = [(whaleIn{wn}.CIx(:,2)-whaleIn{wn}.CIx(:,1))/2, ...
            (whaleIn{wn}.CIy(:,2)-whaleIn{wn}.CIy(:,1))/2, ...
            (whaleIn{wn}.CIz(:,2)-whaleIn{wn}.CIz(:,1))/2]; % position error

        N = size(measurements, 1); % total number of clicks for this whale
        
        % observation model
        % put 1s in here because we want the initial observation to be the
        % initial estimate
        H = [1 0 0 0 0 0;
            0 1 0 0 0 0;
            0 0 1 0 0 0;
            0 0 0 1 0 0;
            0 0 0 0 1 0;
            0 0 0 0 0 1];

        % process noise of the system
        % how much variability do we expect to have in the state due to
        % process noise?
        % luckily, we have a ton of measurements. let's explore the measurements
        % so we can match our model noise to the actual
        % dynamics of the measured data!

        % find correlations in real data
        var_x = var(diff(measurements(:,1)))+0.5;
        var_y = var(diff(measurements(:,2)))+0.5;
        var_z = var(diff(measurements(:,3)))+0.5;
        cov_xy = cov(diff(measurements(:,1))+0.5, diff(measurements(:,2)))+0.5;
        cov_xz = cov(diff(measurements(:,1))+0.5, diff(measurements(:,3)))+0.5;
        cov_yz = cov(diff(measurements(:,2))+0.5, diff(measurements(:,3)))+0.5;

        % use these parameters to construct the Q matrix
        Q = [var_x, cov_xy(1,2), cov_xz(1,2), 0, 0, 0;
            cov_xy(2,1), var_y, cov_yz(1,2), 0, 0, 0;
            cov_xz(2,1), cov_yz(2,1), var_z, 0, 0, 0;
            0, 0, 0, 1, 0, 0;
            0, 0, 0, 0, 1, 0;
            0, 0, 0, 0, 0, 1];

        x_interpolated = zeros(6, N); % store estimates

        for i = 1:N-1 % skip the first and last measurements

            dt = seconds(time(i+1)-time(i)); % time difference btwn measurements for this pair

            if dt < maxtimegap % if this time step is smaller than our max allowed

                % initial estimate is the measured position
                x_est = [measurements(i,1); measurements(i,2); measurements(i,3); vel; vel; vel];
                P_est = eye(6); 
                
                % state transition matrix
                F = [1 0 0 dt 0 0;
                    0 1 0 0 dt 0;
                    0 0 1 0 0 dt;
                    0 0 0 1 0 0;
                    0 0 0 0 1 0;
                    0 0 0 0 0 1];

                % predict the state based on transition matrix, model noise
                x_pred = F * x_est; % predicted state
                P_pred = F * P_est * F' + Q; % predicted covariance

                % measurement error
                % use the error calculated for this click in the earlier
                % jackknife approach
                R = diag([error(i,1), error(i,2), error(i,3), 0.05, 0.05, 0.05]);

                if ~isnan(measurements(i, 1)) % if we have a value here
                    % z = measurements(i, :)'; % make a vector with x,y,z position
                    y = x_est - H * x_pred; % residual (measurement)
                    S = H * P_pred * H' + R; % residual (covariance)
                    K = P_pred * H' / S; % calculate the Kalman gain

                    x_est = x_pred + K * y; % update the state estimate
                    P_est = (eye(size(K,1)) - K * H) * P_pred; % update the covariance

                    % store our estimated state
                    x_interpolated(:, i) = x_est;

                else
                    % in the case that we're missing a value, just store the
                    % predicted number (this should retain nans throughout)
                    x_est = x_pred;
                    P_est = P_pred;

                    x_interpolated(:, i) = x_est;
                end

            else % if our timestamp is greater than the max allowed
                x_interpolated(:,i) = nan; % just insert a nan
            end

        end

        % grab our estimated positions
        positions_estimated = x_interpolated(1:3, :); % x, y, z
        % azimuth_estimated = x_interpolated(7, :);
        % elevation_estimated = x_interpolated(8, :);

        window_size = win; % window size for the moving average

        % apply moving average smoothing
        positions_estimated = positions_estimated';
        % positions_estimated(isnan(positions_estimated)) = simulated_walk(isnan(positions_estimated));
        % if the window size is larger than the number of points we have
        % (happens around the endpoints), shrink to fit to the smaller
        % window
        smoothed_walk_x = movmean(positions_estimated(:, 1), window_size,'endpoints','shrink');
        smoothed_walk_y = movmean(positions_estimated(:, 2), window_size,'endpoints','shrink');
        smoothed_walk_z = movmean(positions_estimated(:, 3), window_size,'endpoints','shrink');

        % combine smoothed coordinates
        whaleOut{wn}.wlocSmooth = [smoothed_walk_x, smoothed_walk_y, smoothed_walk_z];

    end

end