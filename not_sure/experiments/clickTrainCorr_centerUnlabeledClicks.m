function [CTC, DETout] = clickTrainCorr(DETin, whaleNum, labeledInst, unlabeledInst, varargin)
% [CTC, DETout]  = clickTrainCorr(DETin, whaleNum, kerInst, labeledInst, unlabeledInst)
% [CTC, DETout]  = clickTrainCorr(DETin, whaleNum, kerInst, labeledInst, unlabeledInst, paramFile)
% Performs click train correlation (CTC) on DET tables.
%
% INPUTS:
% -DETin: struct of det tables, where DETin{1} is instrument 1's DET table,
% etc
% -whaleNum: whale number being used in CTC
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

% Perform CTC on labeled instruments
if length(labeledInst)==2 % both 4ch are labeled, perform CTC with only labeled detections
    Ind{1} = find(DETin{1}.color==colorNum); % indices of detections with label whaleNum, instrument 1
    Ind{2} = find(DETin{2}.color==colorNum); % indices of detections with label whaleNum, instrument 2
    
    % find period where there are overlapping detections:
    TSTART = max([DETin{1}.TDet(Ind{1}(1)), DETin{2}.TDet(Ind{2}(1))]); % beginning of period with detections on both arrays
    TEND = min([DETin{1}.TDet(Ind{1}(end)), DETin{2}.TDet(Ind{2}(end))]); % end of period with detections on both arrays
    
    % remove detections outside the window where detections overlap (+/- the window used to make click trains):
    I1remove = find(DETin{1}.TDet(Ind{1})<(TSTART - CTCparam.twin/(2*spd)) | DETin{1}.TDet(Ind{1})>(TEND + CTCparam.twin/(2*spd)));
    I2remove = find(DETin{2}.TDet(Ind{2})<(TSTART - CTCparam.twin/(2*spd)) | DETin{2}.TDet(Ind{2})>(TEND + CTCparam.twin/(2*spd)));
    Ind{1}(I1remove) = [];
    Ind{2}(I2remove) = [];

    % iterate over each detection:
    for i = 1:length(Ind{1})
        tcenter = DETin{1}.TDet(Ind{1}(i));
        tct = tcenter + (-CTCparam.twin/2:1/CTCparam.fsct:CTCparam.twin/2)./spd;
        
        for ninst = 1:2
            Iwin = find(abs(DETin{ninst}.TDet(Ind{ninst}) - tcenter)<=CTCparam.twin/2); % indices of detections within the window
            X(:,ninst) = makeCT(DETin{ninst}.TDet(Ind{ninst}(Iwin)), tct, CTCparam);
        end

        [XC, lags] = xcorr(X);
        [pks, locs] = findpeaks(XC, 'NPeaks', 2, 'SortStr', 'descend');

        if length(pks)<2
            CTC.CTCpk
        end

        ok  =1;
    end

    ok = 1;
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