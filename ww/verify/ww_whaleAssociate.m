function DETout = ww_whaleAssociate(DETin, labeledInstNum, otherInstNum, whaleNum, varargin)

% ww_whaleAssociate
%
% DETout = whaleAss(DETin, labeledInstNum, otherInstNum, whaleNum)
% DETout = whaleAss(DETin, labeledInstNum, otherInstNum, whaleNum, paramFile)
% Takes Detections on DET{labeledInstnum} labeled as whaleNum and uses click-train
% correlation to find the detections on the other instrument(s)

global WAparam

% load in params
if nargin == 5 % param file specified
    loadParams(varargin{1})
else % no param file specified, load default file
    loadParams('whaleAssociate.params')
end

fwb = waitbar(0, ['Associating whale ', num2str(whaleNum), '...']);

DETout = DETin;
maxlag = ceil(WAparam.maxTDOA.*WAparam.fsct); % max lag used in xcorr

Iwn = find(DETout{labeledInstNum}.color==whaleNum+2); % Indices of detections labeled whaleNum
TDetL = DETout{labeledInstNum}.TDet(Iwn); % detection times on labeled array

TDetO = DETout{otherInstNum}.TDet; % all detection times on other array 

tstart = TDetL(1); % start time of segment in this window
tend = tstart + seconds(WAparam.twin); % end of time segment
tnext = seconds(WAparam.overlap*WAparam.twin);

niter = (TDetL(end)-TDetL(1))/seconds(WAparam.twin) + 1; % expected number of iterations
iter = 0; % current iteration
while tstart<=TDetL(end) % compute while tstart is less than last labeled detection
    
    iter = iter+1;
    waitbar(iter/niter, fwb, ['Associating whale ', num2str(whaleNum), '...']);

    % tct = tstart:1/(WAparam.fsct*spd):tend; % time vector of click train
    tct = tstart:seconds(1/WAparam.fsct):tend; % time vector of click train

    xL = zeros(1, length(tct)); % initialize click train signal of labeled clicks
    xO = xL; % initialize click train signal on other array
    
    IwinL = find(TDetL>=tstart & TDetL<=tend); % indices of detections on labeled array within this window
    IwinO = find(TDetO>=tstart & TDetO<=tend); % indices of detections on other array within this window 
    
    if (length(IwinL)<5)||(length(IwinO)<5) % insufficent detections on one or both arrays, skip this time period
        tstart = tend;
        tend = tstart + tnext;
        continue
    end

    % create click trains with delta functions for labeled array:
    for i = 1:length(IwinL)
        [~, I] = min(seconds(tct-TDetL(IwinL(i))).^2); % index of click train time vector closest to detection time
        xL(I) = 1; % replace index of detection with 1
    end

    % create click trains with delta functions for labeled array:
    for i = 1:length(IwinO)
        [~, I] = min(seconds(tct-TDetO(IwinO(i))).^2); % index of click train time vector closest to detection time
        xO(I) = 1; % replace index of detection with 1
    end

    % convolve with hanning window:
    xL = conv(xL, WAparam.Wk);
    xO = conv(xO, WAparam.Wk);

    % cross correlate click trains:
    [xc, lags] = xcorr(xL, xO, maxlag, 'coeff');

    % find peak of click train correlation:
    [pks, Ibest] = findpeaks(xc, 'Npeaks', 2, 'SortStr', 'descend');
    
    if length(pks)==2 % if two peaks were found
        if (WAparam.peakRatio*pks(1))>pks(2) % click trains correlated enough to assume they are the same whale
            bestLag = lags(Ibest(1)); % delay which best aligns click trains
            tdoa(iter) = bestLag/WAparam.fsct;
            PKS(iter, :) = pks;
        else % insufficient detections aligned in click trains
            tstart = tstart + tnext;
            tend = tstart + seconds(WAparam.twin);
            continue % skip to next time period
        end
    else % zero or 1 peak was found, continue to next time period
        tstart = tstart + tnext;
        tend = tstart + seconds(WAparam.twin);
        continue % skip to next time period
    end
    % iterate through labeled detections, find the ones that most closely
    % match on the other array, and assign that detection a label
    for i = 1:length(IwinL)
        % [tdif, I] = min(abs(TDetO - TDetL(IwinL(i)) + bestLag./(WAparam.fsct*spd))); % difference between this detection and closest detection on other array
        lagDur = seconds(bestLag / WAparam.fsct);
        [tdif, I] = min(abs(TDetO - (TDetL(IwinL(i)) - lagDur)));

        % if detection on other array fell within one hanning window if
        % expected detection time, label it as whaleNum
        if tdif<seconds(WAparam.tCloseEnough)
            DETout{otherInstNum}.Label(I) = num2str(whaleNum);
            DETout{otherInstNum}.color(I) = whaleNum + 2;
        end
    end

    tstart = tstart + tnext;
    tend = tstart + seconds(WAparam.twin);

end
close(fwb)

