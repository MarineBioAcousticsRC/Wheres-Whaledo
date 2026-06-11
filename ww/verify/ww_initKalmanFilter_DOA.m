function kf = ww_initKalmanFilter_DOA(centerXYZ)
% kf = ww_initKalmanFilter_DOA(centerXYZ)
%
% Initialize a simple constant-velocity Kalman filter in 3D, matching the
% original Python code.
%
% INPUT
%   centerXYZ : 1x3 (or 3x1) initial position [x y z]
%
% OUTPUT
%   kf : struct with fields F,H,Q,R,x,P and predicted x_prior,P_prior
%
% Notes:
%   - dt is assumed to be 1 (like the Python transition matrix).
%   - You observe only position (not velocity).

    centerXYZ = centerXYZ(:);

    % State transition (constant velocity, dt = 1)
    F = [1 0 0 1 0 0;
         0 1 0 0 1 0;
         0 0 1 0 0 1;
         0 0 0 1 0 0;
         0 0 0 0 1 0;
         0 0 0 0 0 1];

    % Observation model (position only)
    H = [1 0 0 0 0 0;
         0 1 0 0 0 0;
         0 0 1 0 0 0];

    % Covariances (kept the same scaling as the Python)
    P = eye(6) * 1000;          % initial state covariance
    Q = eye(6) * (0.01 * 100);  % process covariance
    R = eye(3) * (10 * 100);    % observation covariance

    % Initial state [x y z vx vy vz]
    x = [centerXYZ; 0; 0; 0];

    % Pack struct
    kf = struct();
    kf.F = F;
    kf.H = H;
    kf.Q = Q;
    kf.R = R;
    kf.x = x;
    kf.P = P;

    % Predicted placeholders
    kf.x_prior = x;
    kf.P_prior = P;
end

% -------------------------------------------------------------------------
% kf = ww_kfPredict_DOA(kf)
% Predict step: x_prior, P_prior
% -------------------------------------------------------------------------
function kf = ww_kfPredict_DOA(kf)
    kf.x_prior = kf.F * kf.x;
    kf.P_prior = kf.F * kf.P * kf.F.' + kf.Q;
end

% -------------------------------------------------------------------------
% kf = ww_kfUpdate_DOA(kf, z)
% Update step with observation z = [x y z]
% -------------------------------------------------------------------------
function kf = ww_kfUpdate_DOA(kf, z)
    z = z(:);
    % innovation
    y = z - kf.H * kf.x_prior;
    % innovation covariance
    S = kf.H * kf.P_prior * kf.H.' + kf.R;
    % Kalman gain
    K = kf.P_prior * kf.H.' / S;

    % state + covariance update
    kf.x = kf.x_prior + K * y;
    kf.P = (eye(6) - K * kf.H) * kf.P_prior;
end

% -------------------------------------------------------------------------
% [kf, x, P] = ww_kfStep_DOA(kf, observation)
% One-step wrapper like the Python filter_update():
%   - predict
%   - if observation provided: update
%   - else: accept prediction
% -------------------------------------------------------------------------
function [kf, x, P] = ww_kfStep_DOA(kf, observation)
    kf = ww_kfPredict_DOA(kf);

    if nargin >= 2 && ~isempty(observation)
        kf = ww_kfUpdate_DOA(kf, observation);
    else
        kf.x = kf.x_prior;
        kf.P = kf.P_prior;
    end

    x = kf.x;
    P = kf.P;
end