function whale = loc3D_DOAintersect(DET, hydLoc, paramFile)
% produces a rough 3-D track estimate from the period of time with
% overlapping detections on both four-channel arrays.
% whaleLoc is a struct with the 3-D tracks
% DET is a struct containing detection tables
% hydLoc is a struct with the hydrophone locations in lat, lon, z
% paramFile is the same brushing.params file used for brushDOA

global brushing
loadParams(paramFile)
spd = 60*60*24;

colorNums = unique([DET{1}.color; DET{2}.color]); % find all unique labels
colorNums(colorNums==2) = []; % remove unlabeled points

h0 = mean([hydLoc{1}; hydLoc{2}]);

% convert hydrophone locations to meters:
[h1(1), h1(2)] = latlon2xy_wgs84(hydLoc{1}(1), hydLoc{1}(2), h0(1), h0(2));
h1(3) = abs(h0(3))-abs(hydLoc{1}(3));

[h2(1), h2(2)] = latlon2xy_wgs84(hydLoc{2}(1), hydLoc{2}(2), h0(1), h0(2));
h2(3) = abs(h0(3))-abs(hydLoc{2}(3));

figure(31)
scatter3(h1(1), h1(2), h1(3), 24, 'k^', 'filled')
hold on
scatter3(h2(1), h2(2), h2(3), 24, 'k^', 'filled')


for wn = 1:length(colorNums) % iterate through each whale number
    whale{wn} = table;
    I1 = find(DET{1}.color==colorNums(wn)); % indices on array 1 labeled as whale wn
    I2 = find(DET{2}.color==colorNums(wn)); % indices on array 2 labeled as whale wn

    if ~isempty(I1) && ~isempty(I2) % make sure there are detections on both arrays with this label

        t1 = DET{1}.TDet(I1); % times of detections on array 1
        t2 = DET{2}.TDet(I2); % times of detections on array 2

        doa1 = DET{1}.DOA(I1, :); %% times of DOA on array 1
        doa2 = DET{2}.DOA(I2, :); %% times of DOA on array 2
        
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
        
        

        scatter3(whale{wn}.wloc(:, 1), whale{wn}.wloc(:, 2), whale{wn}.wloc(:, 3), ...
            24, brushing.params.colorMat(wn+2, :), 'filled')

    end
end
hold off

