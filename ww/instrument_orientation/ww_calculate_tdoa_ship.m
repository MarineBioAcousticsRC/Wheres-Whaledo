function [T, TDOA, shipTDOA] = ww_calculate_tdoa_ship(tstart, tend, xwavPath)

% ww_calculate_tdoa_ship
%
% this function calculates the TDOA of ship sound from xwav files.

global PARAMS HANDLES

% grab params for the instrument we're currently working with
instrumentName = HANDLES.ui.calc.instrumentName.Value;
shipTDOA = PARAMS.project.InstrumentOrientationParams.(instrumentName);
tstart = datenum(tstart); tend = datenum(tend);

XH = ww_build_xwav_dir(xwavPath); % build directory of files
[XH, startSample, endSample, rfTimes, rfSamples, fs] = ww_subset_xwav_dir(XH, tstart, tend); % subset them based on times of interest

% set final params
shipTDOA.nxc = shipTDOA.XcovWindow_s * fs; % number of samples to use in xcov
shipTDOA.nTDOA = round((tend-tstart)*PARAMS.conversion.spd/shipTDOA.XcovWindow_s); % estimation for waitbar
[b, a] = ellip(4,0.1,40,[shipTDOA.bpLow_Hz shipTDOA.bpHigh_Hz].*2/fs); % filter coefficients
shipTDOA.ixcov = [2, 3, 4, 7, 8, 12]; % columns of xcov to use for TDOA

% initialize variables:
T = NaT(shipTDOA.nTDOA, 1);
TDOA = zeros(shipTDOA.nTDOA, length(shipTDOA.ixcov));

% show progress bar on ui
HANDLES.ui.calc.progressRow.Visible = 'on';
HANDLES.ui.calc.progressLabel.Text = "Calculating TDOAs...";
HANDLES.ui.calc.progressFill.Position = [0 0 0 ...
HANDLES.ui.calc.progressContainer.Position(4)];
drawnow; pg = 0;

for k = 1:numel(XH) % load each xwav

    for s = startSample(k) : shipTDOA.LoadSegment_s*fs : endSample(k) % define start

        e = s + shipTDOA.LoadSegment_s*fs - 1; % if we're at the last interval
        if e > endSample(k)
            e = endSample(k);
        end
        [x, t, fs] = ww_read_xwav(fullfile(XH(k).folder,XH(k).name), [round(s) round(e)], rfTimes{k}, rfSamples{k}); % read xwav data
        xf = filtfilt(b, a, x); % filter data

        % samples to use in xcov:
        nxc(1) = 1;
        nxc(2) = nxc(1) + shipTDOA.nxc;
        while nxc(2) <= length(xf)
            pg = pg+1; % update counter
            
            % display the progress bar
            frac = pg/shipTDOA.nTDOA;
            frac = max(0,min(1,frac));
            pos = HANDLES.ui.calc.progressContainer.Position;
            HANDLES.ui.calc.progressFill.Position = [0 0 pos(3)*frac pos(4)];
            drawnow limitrate

            T(pg) = t(nxc(1)) + (t(nxc(2)) - t(nxc(1)))/2; % time stamp is center of xcov segment
            xseg = xf(nxc(1):nxc(2), :);
            [xc, lags] = xcov(xseg);
            for npair = 1:length(shipTDOA.ixcov)
                [~, m] = max(xc(:, shipTDOA.ixcov(npair)));
                TDOA(pg, npair) = lags(m)/fs;
            end
            nxc(1) = nxc(2) + 1;
            nxc(2) = nxc(1) + shipTDOA.nxc;
        end
    end
end

% remove excess zeros from initialization
[T, rm] = rmmissing(T);
TDOA(rm,:) = [];

end
