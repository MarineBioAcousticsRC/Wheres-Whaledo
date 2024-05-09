function [T, TDOA] = tdoaFromARPings(tstart, tend, xwavTable, varargin)
% [T, TDOA] = tdoaFromARPings(tstart, tend, xwavTable)
% [T, TDOA] = tdoaFromARPings(tstart, tend, xwavTable, paramsFile)
% calculates the Time Difference of Arrival by cross-covariating the ship
% sound.
% VARIABLES:
% - tstart: beginning of ship passage (in days since 01-Jan-2000 00:00:00)
% - tend: end of ship passage (in days since 01-Jan-2000 00:00:00)
% - xwavTable: the table of xwav start times and paths to files
%       can be generated using the readxwavSegment remora for Triton
% - OPTIONAL: paramsFile is the path and name of the .params file containing
%       all necessary parameters. Without this, user will be prompted to
%       select the .params file


if nargin==3 % No parameter file included: prompt user to select one
    [file, path] = uigetfile('*.params', 'Select a .params file for tdoaFromShipSound');

    loadParams(fullfile(path, file))


elseif nargin==4
    loadParams(varargin{1})
end

global shipTDOA % global variable that pulls in params

% determine filter coefficients
[b, a] = ellip(3,5,50, 2.*[10e3, 13e3]./shipTDOA.fs ,'bandpass');

% acoustic release specs:
% interrogate freq: 11 kHz
% response freq: 12 kHz
% turn-around time = 12.5 ms
nta = 12.5e-3*shipTDOA.fs;
% min interrogate pulse width = 5 ms
nw = 5e-3*shipTDOA.fs;
nij = [2, 3, 4, 7, 8, 12];
nprev = (nta + nw) + 300; % samples prior to response to start looking for interrogation ping
nwin = nw*3;

% Nxc = shipTDOA.xcovSegmentSize * shipTDOA.fs; % number of samples to use in xcov

spd = 60*60*24; % number of seconds per day
Ntdoa = round((tend-tstart)*spd/shipTDOA.xcovSegmentSize); % Estimate number of TDOAs that will be computed

% initialize variables:
T = zeros(Ntdoa, 1);
TDOA = zeros(Ntdoa, length(shipTDOA.ixcov));

% load time period:
tLoad(1) = tstart;
tLoad(2) = tstart + shipTDOA.loadSegmentSize/spd;

THresp = 2e4;
ndet = 0;

i = 0; % counter

while tLoad(2) <= tend
    fprintf('\nCalculating TDOA for segment %d of %d\n', i+1, Ntdoa)
    [x, t] = quickxwavRead(tLoad(1), tLoad(2), shipTDOA.fs, xwavTable); % read in xwav data
    xf = filtfilt(b, a, x); % filter data

    % % samples to use in xcov:
    % nxc(1) = 1;
    % nxc(2) = nxc(1) + Nxc;

    % while nxc(2) <= length(xf)
        i = i+1;

        % detect response pings:
        Ipk = find(xf(:,1) > THresp);

        if ~isempty(Ipk)

            Ipk2 = find(diff(Ipk)> 1000); % find individual response pings

            Iresp = zeros(length(Ipk2)+1, 1);
            Iresp(1) = Ipk(1);

            for nipk = 1:length(Ipk2)
                Iresp(nipk+1) = Ipk(Ipk2(nipk)+1);
            end

            Iresp(Iresp <= nprev) = []; % remove detections where interrogation occured prior to time frame

            % Now search ~12.5 ms prior for interrogation ping
            for ni = 1:length(Iresp)
                idet = (1:nwin) + (Iresp(ni) - nprev);
                x1 = xf(idet, :);
                t1 = t(idet);

                if max(max(x1))>100 % test to make sure ping is present
                    ndet = ndet+1;

                    T(ndet) = t1(1);

                    [xc, lags] = xcov(x1);
                    [~, imax] =  max(xc);

                    TDOA(ndet, :) = lags(imax(nij))./shipTDOA.fs;

                end
            end

        end

    %     nxc(1) = nxc(2) + 1;
    %     nxc(2) = nxc(1) + Nxc;
    % end

    tLoad(1) = tLoad(2);
    tLoad(2) = tLoad(1) + shipTDOA.loadSegmentSize/spd;
end


% remove excess zeros from initialization

Irem = find(T==0);

T(Irem) = [];
TDOA(Irem, :) = [];