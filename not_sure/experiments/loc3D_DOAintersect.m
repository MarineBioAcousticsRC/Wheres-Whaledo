function whaleLoc = loc3D_DOAintersect(DET, hydLoc, paramFile, varargin)
% whaleLoc = loc3D_DOAintersect(DET, hydLoc, paramFile)
% whaleLoc = loc3D_DOAintersect(DET, hydLoc, paramFile, interpFlag)
% produces a rough 3-D track estimate from the period of time with
% overlapping detections on both four-channel arrays.
% whaleLoc is a struct with the 3-D tracks
% DET is a struct containing detection tables
% hydLoc is a struct with the hydrophone locations in lat, lon, z
% optional: interpFlag, determines whether data will be interpolated prior
% to localization. Possible inputs include:
% -'interp', 'interpOn', or 1 = interpolation will be used
% -'noInterp', 'interpOff', or 0 = interpolation will not be used

global brushing
if nargin==3

    interpFlag = 0;
elseif nargin==4
    if isstr(varargin{1})
        if strcmp(varargin{1}, 'interp')||strcmp(varargin{1}, 'interpOn')
            interpFlag=1; % interpolate DOA data
        elseif strcmp(varargin{1}, 'noInterp')||strcmp(varargin{1}, 'interpOff')
            interpFlag = 0;
        else
            fprintf('\ninvalid datatype, using default settings (no interpolation)\n')
            interpFlag = 0;
        end
    end
elseif isnumeric(varargin{1})
    interpFlag = varargin{1};
else
    fprintf('\ninvalid datatype, using default settings (no interpolation)\n')
    interpFlag = 0;
end
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
    I1 = find(DET{1}.color==colorNums(wn)); % indices on array 1 labeled as whale wn
    I2 = find(DET{2}.color==colorNums(wn)); % indices on array 2 labeled as whale wn

    if ~isempty(I1) && ~isempty(I2) % make sure there are detections on both arrays with this label

        t1 = DET{1}.TDet(I1); % times of detections on array 1
        t2 = DET{2}.TDet(I2); % times of detections on array 2

        % period of overlapping detections
        tstart = max([min(DET{1}.TDet(I1)), min(DET{2}.TDet(I2))]);
        tend = min([max(DET{1}.TDet(I1)), max(DET{2}.TDet(I2))]);

        tdet = tstart:1/spd:tend;

        if ~isempty(tdet) % will be empty if there aren't overlapping detections
            doa1 = DET{1}.DOA(I1, :);
            doa2 = DET{2}.DOA(I2, :);

            if interpFlag==1
                doa1i = interp1(t1, doa1, tdet);
                doa2i = interp1(t2, doa2, tdet);

                w = zeros(length(tdet), 3);
                werr = zeros(size(tdet));
                wdiff = w;

                for i = 1:length(tdet)
                    D = [doa1i(i, :); -doa2i(i, :)];
                    R = D.'\(h2-h1).';

                    w1 = R(1).*doa1i(i,:) + h1;
                    w2 = R(2).*doa2i(i,:) + h2;

                    w(i, :) = mean([w1; w2]);
                    werr(i) = sqrt(sum((w1-w2).^2));
                    wdiff(i, :) = (w1-w2).';
                end
            else
                ndet = 0;

                w = nan([length(t1)+length(t2), 3]);
                wdiff = w;
                werr = nan([length(t1)+length(t2), 1]);
                tdet = werr;

                for i = 1:length(doa1)
                    [terr, Iclosest] = min(abs(t2-t1(i))); % find closest detection on other array with the same label
                    
                    if terr <= 5*spd % detection must be within 5 seconds of other detection
                        ndet = ndet+1;
                        D = [doa1(i, :); -doa2(Iclosest, :)];
                        R = D.'\(h2-h1).';

                        w1 = R(1).*doa1(i,:) + h1;
                        w2 = R(2).*doa2(Iclosest,:) + h2;
                        tdet(ndet) = t1(i);
                        w(ndet, :) = mean([w1; w2]);
                        werr(ndet) = sqrt(sum((w1-w2).^2));
                        wdiff(ndet, :) = (w1-w2).';
                    end
                end

                for i = 1:length(doa2)
                    [terr, Iclosest] = min(abs(t1-t2(i))); % find closest detection on other array with the same label
                    
                    if terr <= 30*spd % detection must be within 30 seconds of other detection
                        ndet = ndet+1;
                        D = [doa1(Iclosest, :); -doa2(i, :)];
                        R = D.'\(h2-h1).';

                        w1 = R(1).*doa1(Iclosest,:) + h1;
                        w2 = R(2).*doa2(i,:) + h2;
                        tdet(ndet) = t2(i);
                        w(ndet, :) = mean([w1; w2]);
                        werr(ndet) = sqrt(sum((w1-w2).^2));
                        wdiff(ndet, :) = (w1-w2).';
                    end
                end
                Irem = find(isnan(tdet));
                tdet(Irem) = [];
                w(Irem, :) = [];
                werr(Irem) = [];
                wdiff(Irem, :) = [];
                
                [tdet, Isort] = sort(tdet);
                w = w(Isort, :);
                werr = werr(Isort);
                wdiff = wdiff(Isort, :);
                
            end
            whaleLoc{wn}.xyz = w;
            whaleLoc{wn}.t = tdet;
            whaleLoc{wn}.werr = werr;
            whaleLoc{wn}.wdiff = wdiff;
            whaleLoc{wn}.color = colorNums(wn);
            [lat, lon] = xy2latlon_wgs84(w(1, :), w(2, :), h0(1), h0(2));
            z = w(3,:) - abs(h0(3));
            whaleLoc{wn}.LatLonDepthz = [lat; lon; z];

            scatter3(whaleLoc{wn}.xyz(:, 1), whaleLoc{wn}.xyz(:, 2), whaleLoc{wn}.xyz(:, 3), ...
                24, brushing.params.colorMat(wn+2, :), 'filled')
        end
    end
end
hold off

