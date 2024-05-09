function [CTC, DETout] = clickTrainCorr_old(DETin, whaleNum, kerInst, labeledInst, unlabeledInst, varargin)
% [CTC, DETout]  = clickTrainCorr(DETin, whaleNum, kerInst, labeledInst, unlabeledInst)
% [CTC, DETout]  = clickTrainCorr(DETin, whaleNum, kerInst, labeledInst, unlabeledInst, paramFile)
% Performs click train correlation (CTC) on DET tables.
%
% INPUTS:
% -DETin: struct of det tables, where DETin{1} is instrument 1's DET table,
% etc
% -colorNum: whale number being used in CTC
% -kerInst: instrument(s) being used as kernel of CTC. If it's a vector,
% code will iterate over all instruments listed and perform CTC then
% associate clicks. To use both instruments 1 and 2 as kernels, use
% kerInst=[1,2]
% -labeledInst: the instruments with detections already assigned whale
% labels. For instance, if instrument 1 and 2 have already been labeled
% using brushDOA, use labeledInst=[1,2]
% -unlabeledInst: the unlabled instruments to be used in CTC
% -paramFile (OPTIONAL): the parameter file with variables to be used in CTC
%
% Outputs:
% -'CTC': a table of only the detections/TDOAs associated with each labeled whale
% - DETout: same as DETin but with the labels updated to reflect output of CTC

global CTCparam

% load in params
if nargin == 6 % param file specified
    loadParams(varargin{1})
else % no param file specified, load default file
    loadParams('CTC.params')
end

% set variables:
spd = 60*60*24; % seconds per day, for converting between seconds and datenum

DETout = DETin; % assign output DET table to input one, labels will be changed as code performs CTC

% initialize CTC with approximate size:
numTDOA = max(CTCparam.indTDOA{3}); % number of TDOAs
Ninit = 4000; % number of table elements for initializing table (excess rows are removed later)
CTC = table(nan(Ninit, 1), nan(Ninit, CTCparam.numInst), nan(Ninit, CTCparam.numInst), ...
    nan(Ninit, numTDOA), nan(Ninit, CTCparam.numInst), nan(Ninit, CTCparam.numInst), ...
    'VariableNames', {'TDet', 'TDetAll', 'DAmp', 'TDOA', 'CTCpk', 'DETind'});

detnum = 0;

colorNum = whaleNum + 2;

for nh = 1:length(kerInst) % iterate through each instrument being used as a kernel in click train
    thisInst = kerInst(nh); % instrument currently being used as kernel in click train
    otherInsts = [labeledInst, unlabeledInst]; % all instruments
    otherInsts(otherInsts==thisInst) = []; % all instruments besides thisInst

    Iwhale = find(DETout{thisInst}.color==colorNum); % indices of all detections labeled colorNum
    
    for idet = 1:length(Iwhale)
        detnum = detnum+1;
        CTC.TDet(detnum) = DETout{thisInst}.TDet(Iwhale(idet));
        CTC.TDetAll(detnum, thisInst) = DETout{thisInst}.TDet(Iwhale(idet));
        CTC.DAmp(detnum, thisInst) = DETout{thisInst}.DAmp(Iwhale(idet));
        CTC.DETind(detnum, thisInst) = Iwhale(idet);
        CTC.TDOA(detnum, CTCparam.indTDOA{thisInst}) = DETout{thisInst}.TDOA(Iwhale(idet), :);
        
        tdet = DETout{thisInst}.TDet(Iwhale(idet)); % time of current detection
        
        % start and end times of click train:
        tstart = tdet - CTCparam.twin/(2*spd);
        tend = tstart + CTCparam.twin/spd;
        
        % time vector for click train:
        tct = (tstart:1/(CTCparam.fsct*spd):tend).';

        % make click trains for labeled instruments:
        for ninst = 1:length(labeledInst)
            % find indices of detections within time window and labeled colorNum
            I = find(DETout{labeledInst(ninst)}.TDet>=tstart & DETout{labeledInst(ninst)}.TDet<=tend ...
                & DETout{labeledInst(ninst)}.color==colorNum);
            DETind{labeledInst(ninst)} = I;
            % make click train for this instrument:
            X(:, labeledInst(ninst)) = makeCT(DETout{labeledInst(ninst)}.TDet(I), tct, CTCparam);
        end

        % make click trains for unlabeled instruments:
        for ninst = 1:length(unlabeledInst)
            % find indices of detections within time window and labeled colorNum
            I = find(DETout{unlabeledInst(ninst)}.TDet>=tstart & DETout{unlabeledInst(ninst)}.TDet<=tend);
            DETind{unlabeledInst(ninst)} = I;
            % make click train for this instrument:
            X(:, unlabeledInst(ninst)) = makeCT(DETout{unlabeledInst(ninst)}.TDet(I), tct, CTCparam);
        end
        
        % cross-correlate click trains, determine TDOA, and associate clicks:
        for ninst = 1:length(otherInsts) 
            [xc, lags] = xcorr(X(:, thisInst), X(:, otherInsts(ninst)), CTCparam.maxLag);
            [pks, locs] = findpeaks(xc, "NPeaks", 2, "SortStr", 'descend');
            
            if length(pks)<2 % not enough clicks
                CTC.CTCpk(detnum, otherInsts(ninst)) = 0;
                continue
            end
            if pks(1)*CTCparam.peakRatio>pks(2) % sufficiently unique peak in xcorr
                bestLag = lags(locs(1));
                
                CTC.CTCpk(detnum, otherInsts(ninst)) = pks(1)/pks(2);
                
                % determine detection on otherInst which is closest to
                % current detection after delayed by TDOA:
                [tdif, Imatch] = min(abs(DETout{otherInsts(ninst)}.TDet(DETind{otherInsts(ninst)}) - ...
                    DETout{thisInst}.TDet(Iwhale(idet)) + bestLag/(CTCparam.fsct*spd)));

                if tdif<=(CTCparam.tCloseEnough/spd) % detections are close enough to likely be the same click

                    DETout{otherInsts(ninst)}.color(DETind{otherInsts(ninst)}(Imatch)) = colorNum;
                    DETout{otherInsts(ninst)}.Label(DETind{otherInsts(ninst)}(Imatch)) = num2str(colorNum-2);
                    

                    % find which large aperture TDOA index we are
                    % calculating:
                    TDOAind = find(ismember(CTCparam.hpair, [thisInst, otherInsts(ninst)],'rows')); 
                    
                    % transfer data to CTC table
                    CTC.TDOA(detnum, CTCparam.indTDOA{3}(TDOAind)) = bestLag/CTCparam.fsct;
                    CTC.DAmp(detnum, otherInsts(ninst)) = DETout{otherInsts(ninst)}.DAmp(DETind{otherInsts(ninst)}(Imatch));
                    CTC.DETind(detnum, otherInsts(ninst)) = DETind{otherInsts(ninst)}(Imatch);
                    CTC.TDetAll(detnum, otherInsts(ninst)) = DETout{otherInsts(ninst)}.TDet(DETind{otherInsts(ninst)}(Imatch));
                    
                    
                    % if this is small ap TDOA, tranfer small ap TDOA data:
                    if otherInsts(ninst)==1
                        % transfer small ap TDOA of inst 1:
                        CTC.TDOA(detnum, CTCparam.indTDOA{1}) = DETout{1}.TDOA(DETind{1}(Imatch), :);
                        
                        % also must flip sign on large ap TDOA, because I
                        % calculted inst2-inst1 instead of inst1-inst2:
                        CTC.TDOA(detnum, CTCparam.indTDOA{3}(TDOAind)) = -bestLag/CTCparam.fsct;
                    elseif otherInsts(ninst)==2
                        % transfer small ap TDOA of inst 2:
                        CTC.TDOA(detnum, CTCparam.indTDOA{2}) = DETout{2}.TDOA(DETind{2}(Imatch), :);                     
                    end
                end
            else
                CTC.CTCpk(detnum, otherInsts(ninst)) = 0;
            end
        end
    end
end

% REMOVE extra initialized Nan values (CTC.TDet =nan)
Irem = find(isnan(CTC.TDet));
CTC(Irem, :) = [];

% sort
[~, Isort] = sort(CTC.TDet);
CTC = CTC(Isort, :);

end
%%
function Xct = makeCT(TDet, tct, CTCparam)
% Xct = makeCT(TDet, tct, CTCparam)
% makes click train Xct using time vector tct with detection times TDet
Xct = zeros(size(tct));

for i = 1:length(TDet)
    [~, I] = min((tct-TDet(i)).^2); % find which time sample is closest to current detection time
    Xct(I) = 1;
end

Xct = conv(Xct, CTCparam.Wk, 'same'); % convolve with hanning window

end