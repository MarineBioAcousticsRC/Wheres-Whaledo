function whale = ww_locDOA_bearings_includeCI(DET, brushing)
% whale = ww_locDOA_bearings_includeCI(DET, brushing)
%
% single-array counterpart to ww_loc3D_DOAintersect_includeCI. With only
% one four-channel array there is no second DOA ray to cross, so there is
% no range and no x/y/z position; instead, this produces a bearing-only
% track (azimuth and elevation over time) for each labeled whale.
% DET is a 1 x 1 cell containing the detection table for the array
% brushing holds the array's hydrophone geometry (brushing.H{1}) and
% sound speed (brushing.c{1}), set by ww_generate3DPlot('init', ...)
%
% Angles follow ww_calculate_TDOA_DOA: azimuth in degrees (0 = east),
% elevation in degrees (0 = into the seafloor).
% Confidence intervals come from a jackknife over the 6 TDOAs: each TDOA
% is removed in turn, the DOA is re-solved from the remaining 5, and the
% spread of the resulting angles gives the 95% CI. CIaz is not wrapped,
% so it can extend past +/-180 degrees.

alpha = 1-.95; % alpha for 95% CI
ts = tinv([alpha/2, 1-alpha/2], 6-1); % Student's T distribution

H = brushing.H{1};
c = brushing.c{1};

% group detections by whale-number identity (Label), never by color:
% color is a display-only field that ww_brushDOA_setColorMode.m
% overwrites to reflect species groupings
wn1 = str2double(string(DET{1}.Label));
whaleNums = unique(wn1);
whaleNums(isnan(whaleNums) | whaleNums==0) = []; % remove unlabeled (0) and unparseable labels

whale = {};
for wn = 1:length(whaleNums) % iterate through each whale number
    whale{wn} = table;
    I1 = find(wn1==whaleNums(wn)); % indices on array 1 labeled as whale wn
    n = length(I1);

    doa = DET{1}.DOA(I1, :);
    tdoa = DET{1}.TDOA(I1, :);
    az = atan2d(doa(:,2), doa(:,1));
    el = 180 - acosd(doa(:,3));

    sig_ang = nan(n, 2);
    CIaz = nan(n, 2);
    CIel = nan(n, 2);
    for i = 1:n
        % jackknife: remove one TDOA at a time
        azjk = nan(6, 1);
        eljk = nan(6, 1);
        for irem = 1:6
            Htemp = H;
            td = tdoa(i, :);

            % remove one measurement:
            td(irem) = [];
            Htemp(irem, :) = [];
            s = Htemp\(td.'.*c);
            s = s.'./sqrt(sum(s.^2));

            azjk(irem) = atan2d(s(2), s(1));
            eljk(irem) = 180 - acosd(s(3));
        end

        dAz = mod(azjk - az(i) + 180, 360) - 180; % wrap azimuth differences to +/-180
        sig_ang(i, :) = [std(dAz), std(eljk - el(i))];

        CIaz(i, :) = az(i) + sig_ang(i, 1)*ts;
        CIel(i, :) = el(i) + sig_ang(i, 2)*ts;
    end

    whale{wn}.TDet = DET{1}.TDet(I1);
    whale{wn}.Ang = [az, el];
    whale{wn}.DOA = doa;
    whale{wn}.sig_ang = sig_ang;
    whale{wn}.CIaz = CIaz;
    whale{wn}.CIel = CIel;
    whale{wn}.TDOA = tdoa;
    whale{wn}.DAmp = DET{1}.DAmp(I1, :);
    whale{wn}.I1 = I1;
    % use the modal non-"NaN" species across this whale's detections
    % (same approach as ww_loc3D_DOAintersect_includeCI)
    spCandidates = DET{1}.Species(I1);
    spCandidates = spCandidates(~ismissing(spCandidates) & spCandidates ~= "NaN");
    if isempty(spCandidates)
        wSpecies = "NaN";
    else
        cat = categorical(spCandidates);
        [cats, ~, ic] = unique(cat);
        counts = accumarray(ic, 1);
        [~, ord] = max(counts);
        wSpecies = string(cats(ord));
    end
    whale{wn}.Species = repmat(wSpecies, n, 1);
    whale{wn}.color = repmat(whaleNums(wn)+2, n, 1); % whale-number colorMat row (ww_get_whale_colorMat.m)
end

end
