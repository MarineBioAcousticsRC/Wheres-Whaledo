function whale = ww_loc3D_DOAintersect_includeCI(DET, brushing)
% whale = ww_loc3D_DOAintersect(DET, brushing)
%
% produces a 3-D track estimate from the period of time with
% overlapping detections on both four-channel arrays.
% whaleLoc is a struct with the 3-D tracks
% DET is a struct containing detection tables
% hydLoc is a struct with the hydrophone locations in lat, lon, z
% paramFile (optional) is the localize_DOAintersect.param file

% global LOC_DOA
% loadParams(paramFile)

global PARAMS HANDLES DET

alpha = 1-.95; % alpha for 95% CI
ts = tinv([alpha/2, 1-alpha/2], 12-1); % Student's T distribution

% w(:,3) is in the same h0-relative frame as h1(3)/h2(3); the sea
% surface (absolute depth 0) sits at w(:,3) == abs(brushing.h0(3)) in
% that frame. Estimates with w(:,3) above this are physically
% impossible (whale above the surface) and get reprojected below.
zSurface = abs(brushing.h0(3));

% Group/associate detections across the two arrays by whale-number
% identity (Label), never by color: color is a display-only field that
% ww_brushDOA_setColorMode.m overwrites to reflect species groupings
% when toggled to "Species label", which would otherwise make this
% cross-correlate every detection of a given species together as if it
% were one whale, regardless of which individual whale it came from.
wn1 = str2double(string(DET{1}.Label));
wn2 = str2double(string(DET{2}.Label));
whaleNums = unique([wn1; wn2]);
whaleNums(isnan(whaleNums) | whaleNums==0) = []; % remove unlabeled (0) and unparseable labels

for wn = 1:length(whaleNums) % iterate through each whale number
    whale{wn} = table;
    I1 = find(wn1==whaleNums(wn)); % indices on array 1 labeled as whale wn
    I2 = find(wn2==whaleNums(wn)); % indices on array 2 labeled as whale wn
    
    if ~isempty(I1) && ~isempty(I2) % make sure there are detections on both arrays with this label
        t1 = DET{1}.TDet(I1); % times of detections on array 1
        t2 = DET{2}.TDet(I2); % times of detections on array 2

        doa1 = DET{1}.DOA(I1, :); %% times of DOA on array 1
        doa2 = DET{2}.DOA(I2, :); %% times of DOA on array 2

        tdoa1 = DET{1}.TDOA(I1, :);
        tdoa2 = DET{2}.TDOA(I2, :);

        sp = unique(string(DET{1}.Species(I1,:)));

        % initialize variables as nan:
        w = nan(length(t1), 3);
        werr = nan(length(t1), 1);
        t1_used = NaT(length(t1), 1);
        t1_used_idx = werr;
        t2_used = NaT(length(t1), 1);
        t2_used_idx = werr;
        I1_used = werr;
        I2_used = werr;
        damp = nan(length(t1), 2);
        sig_w = w;
        CIx = damp;
        CIy = damp;
        CIz = damp;
        i = 0;
        for i1 = 1:length(t1) % iterate through all detections on array 1
            [tdiff, i2] = min(abs(t2 - t1(i1))); % find nearest detection on array 2

            if tdiff<seconds(3)
                i = i+1; % iterate counter of localized detections

                [w1, w2] = closest_point_underwater(doa1(i1,:), doa2(i2,:), brushing.h1, brushing.h2, zSurface);

                w(i, :) = mean([w1; w2]);

                % jackknife:
                wjk = nan(12, 3);
                ijk = 0;
                % remove datapoints on H1:
                for irem = 1:6
                    ijk = ijk+1;

                    H1temp = brushing.H{1};
                    
                    td1 = tdoa1(i1, :);
                    td2 = tdoa2(i2, :);

                    % remove one measurement:
                    td1(irem) = [];
                    H1temp(irem, :) = [];
                    s1 = H1temp\(td1.'.*brushing.c{1});
                    s1 = s1.'./sqrt(sum(s1.^2));

                    s2 = brushing.H{2}\(td2.'.*brushing.c{1});
                    s2 = s2.'./sqrt(sum(s2.^2));

                    [w1, w2] = closest_point_underwater(s1, s2, brushing.h1, brushing.h2, zSurface);

                    wjk(ijk, :) = mean([w1; w2]);
                end

                % remove datapoints on H2:
                for irem = 1:6
                    ijk = ijk+1;

                    H2temp = brushing.H{2};
                    
                    td1 = tdoa1(i1, :);
                    td2 = tdoa2(i2, :);

                    % remove one measurement:
                    td2(irem) = [];
                    H2temp(irem, :) = [];
                    s1 = brushing.H{1}\(td1.'.*brushing.c{2});
                    s1 = s1.'./sqrt(sum(s1.^2));

                    s2 = H2temp\(td2.'.*brushing.c{2});
                    s2 = s2.'./sqrt(sum(s2.^2));

                    [w1, w2] = closest_point_underwater(s1, s2, brushing.h1, brushing.h2, zSurface);

                    wjk(ijk, :) = mean([w1; w2]);
                end

                sig_w(i, :) = std(wjk-w(i, :));

                CIx(i, :) = w(i, 1) + sig_w(i, 1)*ts;
                CIy(i, :) = w(i, 2) + sig_w(i, 2)*ts;
                CIz(i, :) = w(i, 3) + sig_w(i, 3)*ts;
                
                werr(i) = sqrt(sum((w1-w2).^2));
                t1_used(i) = t1(i1);
                t1_used_idx(i) = i1; % save for TDOA indexing later
                t2_used(i) = t2(i2);
                t2_used_idx(i) = i2; % save for TDOA indexing later
                I1_used(i) = I1(i1);
                I2_used(i) = I2(i2);
                
            end
        end

        if i<1
            continue
        end

        % remove excess nans
        Irem = find(isnan(w(:,1)));
        w(Irem, :) = [];
        werr(Irem) = [];
        t1_used(Irem) = [];
        t1_used_idx(Irem) = [];
        t2_used(Irem) = [];
        t2_used_idx(Irem) = [];
        I1_used(Irem) = [];
        I2_used(Irem) = [];
        sig_w(Irem, :) = [];
        CIx(Irem, :) = [];
        CIy(Irem, :) = [];
        CIz(Irem, :) = [];

        whale{wn}.wloc = w;
        whale{wn}.TDet = t1_used;
        whale{wn}.t1 = t1_used;
        whale{wn}.t2 = t2_used;
        [lat, lon] = ww_convert_latlon2xy_wgs84(w(:, 1), w(:, 2), brushing.h0(1), brushing.h0(2));
        z = w(:, 3) - abs(brushing.h0(3));
        whale{wn}.LatLonDepth = [lat, lon, z];
        whale{wn}.werr = werr;
        whale{wn}.TDOA(:, 1:6) = DET{1}.TDOA(I1_used, :); % only simultaneous TDOAs array 1
        whale{wn}.TDOA(:, 7:12) = DET{2}.TDOA(I2_used, :); % only simultaneous TDOAs array 2
        whale{wn}.DAmp(:, 1) = DET{1}.DAmp(I1_used); % only simultaneous TDOAs array 1
        whale{wn}.DAmp(:, 2) = DET{2}.DAmp(I2_used, :); % only simultaneous TDOAs array 2
        whale{wn}.I1 = I1_used;
        whale{wn}.I2 = I2_used;
        whale{wn}.sig_w = sig_w;
        whale{wn}.CIx = CIx;
        whale{wn}.CIy = CIy;
        whale{wn}.CIz = CIz;
        % use the modal non-"NaN" species across this whale's used
        % detections on both arrays, rather than just the first row on
        % array 1 -- more robust to any one row having a stale/mismatched
        % Species value (Label/color can desync; color is ground truth,
        % Species assignment keys off Label text, so a handful of rows
        % can end up without a species even though the whale as a whole
        % clearly has one)
        spCandidates = [DET{1}.Species(I1_used); DET{2}.Species(I2_used)];
        spCandidates = spCandidates(~ismissing(spCandidates) & spCandidates ~= "NaN");
        if isempty(spCandidates)
            wSpecies = "NaN";
        else
            c = categorical(spCandidates);
            [cats, ~, ic] = unique(c);
            counts = accumarray(ic, 1);
            [~, ord] = max(counts);
            wSpecies = string(cats(ord));
        end
        whale{wn}.Species = repmat(wSpecies, length(CIz),1);
        whale{wn}.color = repmat(whaleNums(wn)+2, length(CIz),1); % whale-number colorMat row (ww_get_whale_colorMat.m), independent of DET{}.color's current display mode

    end
end
hold off

end

% ======================================================================
function [w1, w2] = closest_point_underwater(s1, s2, h1, h2, zSurface)
% closest_point_underwater
%
% Finds the closest point of approach between two DOA rays (ray 1: from
% h1 in direction s1; ray 2: from h2 in direction s2), ruling out either
% ray's own point going above the surface.
%
% w1(3) depends only on R1 (ray 1's range), and w2(3) only on R2, so
% this is a simple box constraint per ray, not a joint one: R1max/R2max
% is the range along each ray at which it crosses the surface (only
% relevant if the ray points toward the surface, i.e. a positive
% z-direction cosine in this h0-relative frame).
%
% If neither ray's own unconstrained point exceeds its bound, the plain
% closest point of approach is returned unchanged. If only one does,
% that ray is clamped to the surface and the other ray's range is
% re-solved to minimize the remaining gap (so the result does not, in
% general, end up exactly at the surface -- only the clamped ray's
% point does). Only when both rays independently would go above the
% surface are both clamped.

D = [s1; -s2];
A = D.';
b = (h2-h1).';
R = A\b; % closest point of approach between the two rays, unconstrained

R1max = inf;
if s1(3) > 0
    R1max = (zSurface - h1(3)) / s1(3);
end
R2max = inf;
if s2(3) > 0
    R2max = (zSurface - h2(3)) / s2(3);
end

viol1 = R(1) > R1max;
viol2 = R(2) > R2max;

if viol1 && viol2
    R = [R1max; R2max];
elseif viol1
    R(1) = R1max;
    R(2) = A(:,2)\(b - A(:,1)*R(1));
elseif viol2
    R(2) = R2max;
    R(1) = A(:,1)\(b - A(:,2)*R(2));
end

w1 = R(1).*s1 + h1;
w2 = R(2).*s2 + h2;

end

