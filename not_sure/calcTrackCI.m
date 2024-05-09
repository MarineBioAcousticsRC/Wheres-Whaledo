function whaleOut = calcTrackCI(whaleIn, hloc, H, driftPoly, varargin)
% whaleOut = calcTrackCI(whaleIn, hloc, H, driftPoly) calculates confidence intervals on all
% localizations in whaleIn{wn}.wloc. Uses default parameter file.
% hloc are hydrophone locations, H{1} and H{2} are small ap H matrices.

% whaleOut = calcTrackCI(whaleIn, hloc, H, driftPoly, localizeParamFile) calculates confidence intervals on all
% localizations in whaleIn{wn}.wloc. Uses parameter file specified by
% localizeParamFile, which should be a string indicating the file path and
% name.

% whaleOut = calcTrackCI(whaleIn, hloc, H, driftPoly, smoothIndicator) 
% if smoothIndicator='smooth', calculates confidence intervals only on
% smoothed localizations in whaleIn{wn}.wlocSmooth. Uses default parameter
% file. If smoothIndicator = 'both', calculates on both smooth and
% unsmoothed localizations.


% whaleOut = calcTrackCI(whaleIn, hloc, H, driftPoly, smoothIndicator, localizeParamFile) 
% OR  
% whaleOut = calcTrackCI(whaleIn, hloc, H, driftPoly, localizeParamFile, smoothIndicator)

smoothFlag = 0; % =1 if running calcCI on wlocSmooth
locFlag = 1; % =1 if running calcCI on wloc

global LOC
if nargin == 4 % no parameter file specified, calcCI on wloc only
    loadParams('localize.params')
elseif nargin == 5 
    
    if strcmpi(varargin{1}, 'smooth')
        smoothFlag = 1; % run calcCI on wlocSmooth
        locFlag = 0;    % do not run calcCI on wloc (unsmoothed)
        loadParams('localize.params')
    elseif strcmpi(varargin{1}, 'both')
        smoothFlag = 1; % run calcCI on wlocSmooth
        locFlag = 1;    % run calcCI on wloc (unsmoothed)
        loadParams('localize.params')
    elseif isfile(varargin{1}) % if second argument is a file, load the params file
        loadParams(varargin{1})
    else
        fprintf('\nError: input 2 is invalid\n')
    end
elseif nargin == 6
    
    for iarg = 1:2
        if strcmpi(varargin{iarg}, 'smooth')
            smoothFlag = 1; % run calcCI on wlocSmooth
            locFlag = 0;    % do not run calcCI on wloc (unsmoothed)
        elseif strcmpi(varargin{iarg}, 'both')
            smoothFlag = 1; % run calcCI on wlocSmooth
            locFlag = 1;    % run calcCI on wloc (unsmoothed)
        elseif isfile(varargin{iarg}) % if second argument is a file, load the params file
            loadParams(varargin{iarg})
        else
            fprintf('\nError: input %d is invalid \n', iarg+1)
        end
    end
end

whaleOut = whaleIn;

for wn = 1:numel(whaleOut)
    if isempty(whaleOut{wn})
        continue
    end

    Iuse = find(~isnan(whaleOut{wn}.wloc(:,1)));    % index of localized points
    if isempty(Iuse)
        continue
    end
    
    if locFlag==1 && smoothFlag==1 % run on both smooth and unsmoothed locs
        [Nrows, Ntdoa] = size(whaleOut{wn}.TDOA);
        
        % initialize confidence intervals:
        whaleOut{wn}.CIx = nan(Nrows, 2);
        whaleOut{wn}.CIxSmooth = whaleOut{wn}.CIx;
        whaleOut{wn}.CIySmooth = whaleOut{wn}.CIx;
        whaleOut{wn}.CIzSmooth = whaleOut{wn}.CIx;

        TDOA = whaleOut{wn}.TDOA(Iuse, :);
        TDet = whaleOut{wn}.TDet(Iuse);
        wloc = whaleOut{wn}.wloc(Iuse, :);
        wlocSmooth = whaleOut{wn}.wlocSmooth(Iuse, :);

        if Ntdoa==12 % only small apertures were used
            
            % calculate for non-smoothed localizations:
            [CIx, CIy, CIz] = run_calcCI_SmlOnly(TDOA, wloc, hloc, H, LOC);
            whaleOut{wn}.CIx(Iuse, :) = CIx;
            whaleOut{wn}.CIy(Iuse, :) = CIy;
            whaleOut{wn}.CIz(Iuse, :) = CIz;
            
            % calculate for smoothed localizations:
            [CIxSmooth, CIySmooth, CIzSmooth] = run_calcCI_SmlOnly(TDOA, wloc, hloc, H, LOC);
            whaleOut{wn}.CIxSmooth(Iuse, :) = CIxSmooth;
            whaleOut{wn}.CIySmooth(Iuse, :) = CIySmooth;
            whaleOut{wn}.CIzSmooth(Iuse, :) = CIzSmooth;

        else % large and small ap used
            TDOA = whaleOut{wn}.TDOA(Iuse, :);
            % calculate for smoothed localizations:
            wlocSmooth = whaleOut{wn}.wlocSmooth(Iuse, :);
            [CIxSmooth, CIySmooth, CIzSmooth] = run_calcCI_lrgAndSml(TDet, TDOA, wlocSmooth, hloc, H, driftPoly, LOC);
            whaleOut{wn}.CIxSmooth(Iuse, :) = CIxSmooth;
            whaleOut{wn}.CIySmooth(Iuse, :) = CIySmooth;
            whaleOut{wn}.CIzSmooth(Iuse, :) = CIzSmooth;
        end

    elseif locFlag==1 && smoothFlag==0 % run only on unsmoothed locs
        [Nrows, Ntdoa] = size(whaleOut{wn}.TDOA);
        
        % initialize confidence intervals:
        whaleOut{wn}.CIx = nan(Nrows, 2);
        whaleOut{wn}.CIxSmooth = whaleOut{wn}.CIx;
        whaleOut{wn}.CIy = whaleOut{wn}.CIx;
        whaleOut{wn}.CIySmooth = whaleOut{wn}.CIx;
        whaleOut{wn}.CIz = whaleOut{wn}.CIx;
        whaleOut{wn}.CIzSmooth = whaleOut{wn}.CIx;

        TDOA = whaleOut{wn}.TDOA(Iuse, :);
        TDet = whaleOut{wn}.TDet(Iuse);
        wloc = whaleOut{wn}.wloc(Iuse, :);
        wlocSmooth = whaleOut{wn}.wlocSmooth(Iuse, :);

        if Ntdoa==12 % only small apertures were used
            
            % calculate for non-smoothed localizations:
            [CIx, CIy, CIz] = run_calcCI_SmlOnly(TDOA, wloc, hloc, H, LOC);
            whaleOut{wn}.CIx(Iuse, :) = CIx;
            whaleOut{wn}.CIy(Iuse, :) = CIy;
            whaleOut{wn}.CIz(Iuse, :) = CIz;

            % calculate for smoothed localizations:
            [CIxSmooth, CIySmooth, CIzSmooth] = run_calcCI_SmlOnly(TDOA, wloc, hloc, H, LOC);
            whaleOut{wn}.CIxSmooth(Iuse, :) = CIxSmooth;
            whaleOut{wn}.CIySmooth(Iuse, :) = CIySmooth;
            whaleOut{wn}.CIzSmooth(Iuse, :) = CIzSmooth;

        else % large and small ap used
            TDOA = whaleOut{wn}.TDOA(Iuse, :);
            
            % calculate for non-smoothed localizations:
            wloc = whaleOut{wn}.wloc(Iuse, :);
            [CIx, CIy, CIz] = run_calcCI_lrgAndSml(TDet, TDOA, wloc, hloc, H, driftPoly, LOC);
            whaleOut{wn}.CIx(Iuse, :) = CIx;
            whaleOut{wn}.CIy(Iuse, :) = CIy;
            whaleOut{wn}.CIz(Iuse, :) = CIz;

            % calculate for smoothed localizations:
            wlocSmooth = whaleOut{wn}.wlocSmooth(Iuse, :);
            [CIxSmooth, CIySmooth, CIzSmooth] = run_calcCI_lrgAndSml(TDet, TDOA, wlocSmooth, hloc, H, driftPoly, LOC);
            whaleOut{wn}.CIxSmooth(Iuse, :) = CIxSmooth;
            whaleOut{wn}.CIySmooth(Iuse, :) = CIySmooth;
            whaleOut{wn}.CIzSmooth(Iuse, :) = CIzSmooth;
        end
    elseif locFlag==0 && smoothFlag==1 % run only on smoothed locs
        [Nrows, Ntdoa] = size(whaleOut{wn}.TDOA);
        
        % initialize confidence intervals:
        whaleOut{wn}.CIx = nan(Nrows, 2);
        whaleOut{wn}.CIxSmooth = whaleOut{wn}.CIx;
        whaleOut{wn}.CIy = whaleOut{wn}.CIx;
        whaleOut{wn}.CIySmooth = whaleOut{wn}.CIx;
        whaleOut{wn}.CIz = whaleOut{wn}.CIx;
        whaleOut{wn}.CIzSmooth = whaleOut{wn}.CIx;

        TDOA = whaleOut{wn}.TDOA(Iuse, :);
        TDet = whaleOut{wn}.TDet(Iuse);
        wloc = whaleOut{wn}.wloc(Iuse, :);
        wlocSmooth = whaleOut{wn}.wlocSmooth(Iuse, :);

        if Ntdoa==12 % only small apertures were used
            
            % calculate for non-smoothed localizations:
            [CIx, CIy, CIz] = run_calcCI_SmlOnly(TDOA, wloc, hloc, H, LOC);
            whaleOut{wn}.CIx(Iuse, :) = CIx;
            whaleOut{wn}.CIy(Iuse, :) = CIy;
            whaleOut{wn}.CIz(Iuse, :) = CIz;

            % calculate for smoothed localizations:
            [CIxSmooth, CIySmooth, CIzSmooth] = run_calcCI_SmlOnly(TDOA, wloc, hloc, H, LOC);
            whaleOut{wn}.CIxSmooth(Iuse, :) = CIxSmooth;
            whaleOut{wn}.CIySmooth(Iuse, :) = CIySmooth;
            whaleOut{wn}.CIzSmooth(Iuse, :) = CIzSmooth;

        else % large and small ap used
            TDOA = whaleOut{wn}.TDOA(Iuse, :);
            
            % calculate for non-smoothed localizations:
            wloc = whaleOut{wn}.wloc(Iuse, :);
            [CIx, CIy, CIz] = run_calcCI_lrgAndSml(TDet, TDOA, wloc, hloc, H, driftPoly, LOC);
            whaleOut{wn}.CIx(Iuse, :) = CIx;
            whaleOut{wn}.CIy(Iuse, :) = CIy;
            whaleOut{wn}.CIz(Iuse, :) = CIz;

            % calculate for smoothed localizations:
            wlocSmooth = whaleOut{wn}.wlocSmooth(Iuse, :);
            [CIxSmooth, CIySmooth, CIzSmooth] = run_calcCI_lrgAndSml(TDet, TDOA, wlocSmooth, hloc, H, driftPoly, LOC);
            whaleOut{wn}.CIxSmooth(Iuse, :) = CIxSmooth;
            whaleOut{wn}.CIySmooth(Iuse, :) = CIySmooth;
            whaleOut{wn}.CIzSmooth(Iuse, :) = CIzSmooth;
        end
    end

end
end
%%
function [CIx, CIy, CIz] = run_calcCI_lrgAndSml(TDet, TDOA, wloc, hloc, H, driftPoly, LOC)
sig2sml = LOC.sig_sml.^2;
sig2lrg = LOC.sig_lrg.^2;

Nlrg = size(TDOA, 2) - 12;


CIx = nan(size(wloc, 1), 2);
CIy = CIx;
CIz = CIx;
for i = 1:size(wloc, 1)
    tdoa = TDOA(i, :);
    w = wloc(i, :);
    Isml = find(~isnan(tdoa(1:12)));
    Ilrg = find(~isnan(tdoa(13:end)));

    Asml = (2*pi*sig2sml)^(-length(Isml)/2); % coefficient of small ap
    Alrg = (2*pi*sig2lrg)^(-length(Ilrg)/2); % coefficient of large ap
    for ntdoa = 1:Nlrg
        drift(ntdoa) = polyval(driftPoly{ntdoa}, TDet(i));
    end
    tdoa(13:end) = tdoa(13:end) + LOC.driftSign.*drift;
    [CIx(i, :), CIy(i, :), CIz(i, :)] = calcCI(tdoa, w, hloc, H{1}, H{2}, Asml, Alrg, LOC);
end

end


function [CIx, CIy, CIz] = run_calcCI_SmlOnly(TDOA, wloc, hloc, H, LOC)
sig2sml = LOC.sig_sml.^2;

CIx = nan(size(wloc, 1), 2);
CIy = CIx;
CIz = CIx;
for i = 1:size(wloc, 1)
    tdoa = TDOA(i, :);
    w = wloc(i, :);
    Isml = find(~isnan(tdoa(1:12)));

    Asml = (2*pi*sig2sml)^(-length(Isml)/2); % coefficient of small ap
        
    [CIx(i, :), CIy(i, :), CIz(i, :)] = calcCI_smallAp(tdoa, w, hloc, H{1}, H{2}, Asml, LOC);
end


end
