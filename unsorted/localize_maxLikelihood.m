function whaleOut = localize(whaleIn, hloc, H1, H2, driftPoly, varargin)
% whaleOut = localize(whaleIn, hloc, H1, H2, driftPoly)
% whaleOut = localize(whaleIn, hloc, H1, H2, driftPoly, paramFile)
% takes the TDOAs from a "whale" struct (output of calcTDOAfromCTC) and
% performs iterative model generation to determine the most likely whale location.
% INPUTS:
% -whaleIn = the "whale" struct
% -hloc = hydrophone locations (m).
% -H1 and H2 = H matrices for 4ch instruments (m).
% -driftPoly{i} contains the polynomials for the relative drift between
%  instruments. If drift is linear, driftPoly{i} will be two values
%  (y=mx+b).

global LOC

if nargin==6
    if isstring(varargin{1})
        loadParams(varargin{1})
    end
elseif nargin==5
    loadParams('localize.params')
else
    fprintf('Incorrect number of inputs')
end

% Overall process:
% 1) Iterate through each detection
%    a) Use LMSE to determine most likely whale location based on TDOA in
%    courseModel 

whaleOut = whaleIn;
Nlrg = numel(driftPoly); % number of large ap TDOAs

Ntop = round((LOC.topPercent/100)*LOC.Nx*LOC.Ny*LOC.Nz); % number of points to include to determine limits of next iteration

sig2sml = LOC.sig_sml^2; % variance of small ap
sig2lrg = LOC.sig_lrg^2; % variance of large ap

for wn = 1:numel(whaleOut)
    if ~isempty(whaleOut{wn})
        % initialize output loc files
        whaleOut{wn}.wlocCoarse = nan(length(whaleOut{wn}.TDet), 3);
        whaleOut{wn}.wloc = nan(length(whaleOut{wn}.TDet), 3);  
        whaleOut{wn}.CIx = nan(length(whaleOut{wn}.TDet), 2);  
        whaleOut{wn}.CIy = whaleOut{wn}.CIx;
        whaleOut{wn}.CIz = whaleOut{wn}.CIx;
        whaleOut{wn}.Lmax = nan(size(whaleOut{wn}.TDet));
        % want either both four-channels or one four-channel and two or
        % more large ap TDOAs
%         detUse = find(sum(~isnan(whaleOut{wn}.TDOA(:, 13:end)),2)>1 | sum(~isnan(whaleOut{wn}.TDOA(:, 1:12)),2)==12);
        
        % want either both four-channels or one four-channel and one or
        % more large ap TDOAs:
        detUse = find(sum(~isnan(whaleOut{wn}.TDOA),2)>=LOC.minNumTDOA);

        for ndet = 1:length(detUse)
            detInd = detUse(ndet); % index of detection currently being used

            % coarse localization with model:
            
            TDOA = whaleOut{wn}.TDOA(detInd, :);
            drift = zeros(1, Nlrg);
            for ntdoa = 1:Nlrg
                drift(ntdoa) = polyval(driftPoly{ntdoa}, whaleOut{wn}.TDet(detInd));
            end
            TDOA(13:end) = TDOA(13:end) + LOC.driftSign.*drift;

            Isml = find(~isnan(TDOA(1:12))); % indices of small ap used
            Ilrg = find(~isnan(TDOA(13:end)))+12; % indices of large ap used
            
            Asml = (2*pi*sig2sml)^(-length(Isml)/2); % coefficient of small ap
            Alrg = (2*pi*sig2lrg)^(-length(Ilrg)/2); % coefficient of large ap
            
            xv = linspace(LOC.wxlim(1), LOC.wxlim(2), LOC.Nx);
            yv = linspace(LOC.wylim(1), LOC.wylim(2), LOC.Ny);
            zv = linspace(LOC.wzlim(1), LOC.wzlim(2), LOC.Nz);
             
            for niter = 1:LOC.niter-1 
                % iteratively generate model and perform max likelihood
                [mTDOA, mwloc] = makeModel(xv, yv, zv, hloc, H1, H2, LOC.c);

                Lsml = Asml*exp(-1./(2.*sig2sml).*sum((mTDOA(:,1:12)-TDOA(1:12)).^2, 2, 'omitnan'));
                Llrg = Alrg*exp(-1./(2.*sig2lrg).*sum((mTDOA(:,13:end)-TDOA(13:end)).^2, 2, 'omitnan'));

                L = Lsml.*Llrg;
                [~, I] = maxk(L, Ntop);

                xv = linspace(min(mwloc(I, 1)), max(mwloc(I, 1)), LOC.Nx);
                yv = linspace(min(mwloc(I, 2)), max(mwloc(I, 2)), LOC.Ny);
                zv = linspace(min(mwloc(I, 3)), max(mwloc(I, 3)), LOC.Nz);

            end

            % final iteration (outside for-loop to avoid unecessary
            % calculations)

            [mTDOA, mwloc] = makeModel(xv, yv, zv, hloc, H1, H2, LOC.c);

            Lsml = Asml*exp(-1./(2.*sig2sml).*sum((mTDOA(:,1:12)-TDOA(1:12)).^2, 2, 'omitnan'));
            Llrg = Alrg*exp(-1./(2.*sig2lrg).*sum((mTDOA(:,13:end)-TDOA(13:end)).^2, 2, 'omitnan'));

            L = Lsml.*Llrg;
            [Lmax, Ibest] = max(L);
            whaleOut{wn}.wloc(detInd, :) = mwloc(Ibest, :);

            % calculate confidence intervals:
            [CIx, CIy, CIz] = calcCI(TDOA, whaleOut{wn}.wloc(detInd, :), hloc, H1, H2, Asml, Alrg, LOC);
            whaleOut{wn}.CIx(detInd, :) = CIx;
            whaleOut{wn}.CIy(detInd, :) = CIy;
            whaleOut{wn}.CIz(detInd, :) = CIz;
            whaleOut{wn}.Lmax(detInd) = Lmax;

        end
    end
end

end


