function whale = loc3D_DOAintersect_includeCI(DET, hydLoc, H1, H2, paramFile)
% whale = loc3D_DOAintersect(DET, hydLoc, H1, H2, paramFile)
% produces a 3-D track estimate from the period of time with
% overlapping detections on both four-channel arrays.
% whaleLoc is a struct with the 3-D tracks
% DET is a struct containing detection tables
% hydLoc is a struct with the hydrophone locations in lat, lon, z
% paramFile (optional) is the localize_DOAintersect.param file

global LOC_DOA
loadParams(paramFile)
spd = 60*60*24;
alpha = 1-.95; % alpha for 95% CI
ts = tinv([alpha/2, 1-alpha/2], 12-1); % Student's T distribution

colorNums = unique([DET{1}.color; DET{2}.color]); % find all unique labels
colorNums(colorNums==2) = []; % remove unlabeled points

h0 = mean([hydLoc{1}; hydLoc{2}]);

% convert hydrophone locations to meters:
[h1(1), h1(2)] = latlon2xy_wgs84(hydLoc{1}(1), hydLoc{1}(2), h0(1), h0(2));
h1(3) = abs(h0(3))-abs(hydLoc{1}(3));

[h2(1), h2(2)] = latlon2xy_wgs84(hydLoc{2}(1), hydLoc{2}(2), h0(1), h0(2));
h2(3) = abs(h0(3))-abs(hydLoc{2}(3));

if LOC_DOA.plotFlag
    figure(31)
    scatter3(h1(1), h1(2), h1(3), 24, 'k^', 'filled')
    hold on
    scatter3(h2(1), h2(2), h2(3), 24, 'k^', 'filled')
end

for wn = 1:length(colorNums) % iterate through each whale number
    whale{wn} = table;
    I1 = find(DET{1}.color==colorNums(wn)); % indices on array 1 labeled as whale wn
    I2 = find(DET{2}.color==colorNums(wn)); % indices on array 2 labeled as whale wn

    if ~isempty(I1) && ~isempty(I2) % make sure there are detections on both arrays with this label

        t1 = DET{1}.TDet(I1); % times of detections on array 1
        t2 = DET{2}.TDet(I2); % times of detections on array 2

        doa1 = DET{1}.DOA(I1, :); %% times of DOA on array 1
        doa2 = DET{2}.DOA(I2, :); %% times of DOA on array 2

        tdoa1 = DET{1}.TDOA(I1, :);
        tdoa2 = DET{2}.TDOA(I2, :);

        % initialize variables as nan:
        w = nan(length(t1), 3);
        werr = nan(length(t1), 1);
        t1_used = werr;
        t1_used_idx = werr;
        t2_used = werr;
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

            if tdiff<3/spd
                i = i+1; % iterate counter of localized detections
                D = [doa1(i1, :); -doa2(i2, :)];
                R = D.'\(h2-h1).'; % range of whale to each instrument

                w1 = R(1).*doa1(i1, :) + h1;
                w2 = R(2).*doa2(i2, :) + h2;

                w(i, :) = mean([w1; w2]);

                % jackknife:
                wjk = nan(12, 3);
                ijk = 0;
                % remove datapoints on H1:
                for irem = 1:6
                    ijk = ijk+1;

                    H1temp = H1;
                    
                    td1 = tdoa1(i1, :);
                    td2 = tdoa2(i2, :);

                    % remove one measurement:
                    td1(irem) = [];
                    H1temp(irem, :) = [];
                    s1 = H1temp\(td1.'.*LOC_DOA.c);
                    s1 = s1.'./sqrt(sum(s1.^2));

                    s2 = H2\(td2.'.*LOC_DOA.c);
                    s2 = s2.'./sqrt(sum(s2.^2));

                    D = [s1; -s2];
                    
                    R = D.'\(h2-h1).';
                    w1 = R(1).*s1 + h1;
                    w2 = R(2).*s2 + h2;

                    wjk(ijk, :) = mean([w1; w2]);
                end

                % remove datapoints on H2:
                for irem = 1:6
                    ijk = ijk+1;

                    H2temp = H2;
                    
                    td1 = tdoa1(i1, :);
                    td2 = tdoa2(i2, :);

                    % remove one measurement:
                    td2(irem) = [];
                    H2temp(irem, :) = [];
                    s1 = H1\(td1.'.*LOC_DOA.c);
                    s1 = s1.'./sqrt(sum(s1.^2));

                    s2 = H2temp\(td2.'.*LOC_DOA.c);
                    s2 = s2.'./sqrt(sum(s2.^2));

                    D = [s1; -s2];
                    
                    R = D.'\(h2-h1).';
                    w1 = R(1).*s1 + h1;
                    w2 = R(2).*s2 + h2;

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
        [lat, lon] = xy2latlon_wgs84(w(:, 1), w(:, 2), h0(1), h0(2));
        z = w(:, 3) - abs(h0(3));
        whale{wn}.LatLonDepth = [lat, lon, z];
        whale{wn}.werr = werr;
        whale{wn}.TDOA(:, 1:6) = DET{1}.TDOA(t1_used_idx, :); % only simultaneous TDOAs array 1
        whale{wn}.TDOA(:, 7:12) = DET{2}.TDOA(t2_used_idx, :); % only simultaneous TDOAs array 2
        whale{wn}.DAmp(:, 1) = DET{1}.DAmp(t1_used_idx); % only simultaneous TDOAs array 1
        whale{wn}.DAmp(:, 2) = DET{2}.DAmp(t2_used_idx, :); % only simultaneous TDOAs array 2
        whale{wn}.I1 = I1_used;
        whale{wn}.I2 = I2_used;
        whale{wn}.sig_w = sig_w;
        whale{wn}.CIx = CIx;
        whale{wn}.CIy = CIy;
        whale{wn}.CIz = CIz;

        if LOC_DOA.plotFlag
            scatter3(whale{wn}.wloc(:, 1), whale{wn}.wloc(:, 2), whale{wn}.wloc(:, 3), ...
                24, brushing.params.colorMat(wn+2, :), 'filled')
        end
    end
end
hold off

