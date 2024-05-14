function [tOut] = clockDriftCorrection(tIn, tDrift, drift, varargin)
% [tout] = clockDriftCorrection(tIn, tDrift, drift) takes the time value or
% vector tIn and corrects for clock drift based on tDrift and drift.
% -tIn is the time scaler or vector prior to clock drift correction
% -tDrift is the vector of time stamps for each clock drift measurement
% -drift is the value of the drift at each corresponding time stamp in tDrift
% OPTIONAL: [tout] = clockDriftCorrection(tIn, tDrift, drift, interpMethod)
% -interpMethod is the string indicating which method should be used in
% interp1() to estimate drift

if length(tDrift)==2
    % Assume linear drift based on two drift measurements
    % tOut = slope*tIn + yIntercept linear drift equation
    slope = (drift(2)-drift(1))/(tDrift(2)-tDrift(1));
    yIntercept = drift(1)-slope*tDrift(1);
    driftOut = slope.*tIn + yIntercept;
    tOut = tIn + driftOut;
elseif length(tDrift)>2
    % Multiple measurements of drift. Use interpolation.
    if nargin==4 % if user specified an interpolation type
        driftOut = interp1(tDrift, drift, tIn, varargin{1});
        tOut = tIn + driftOut;
    else % user did no specify interpolation type, use linear interpolation
        driftOut = interp1(tDrift, drift, tIn);
        tOut = tIn + driftOut;

    end
else 
    fprintf('\nError in clockDriftCorrection: Incorrect vector sizes\n')
end

