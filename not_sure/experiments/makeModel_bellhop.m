clear all
% load hydrophone locations:
load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m
hydLoc = [0,0,0; h];
hyd1 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EE_Hmatrix_fromHydLocInversion_210702.mat');
hyd2 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EW_Hmatrix_fromHydLocInversion_210702.mat');

% Reorder hydrophones to fit new TDOA order
HEE = [hyd1.hydPos(2,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(3,:)];

HEW = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];



fp = 'D:\SOCAL_E_63\HARP_Deployment_Metadata\fromJenny\ctd'; % file containing full-profile SSPs
rootFileName = 'SSP_cast';


c = 1488.4;

castNumber = [1, 2, 4]; % which casts were full-depth

figure(3)
sspAll = [];
zAll = [];
for i = 1:length(castNumber)
    fn = [rootFileName, num2str(castNumber(i))];
    SSP{i} = load(fullfile(fp, fn));
    plot(SSP{i}.SSP, SSP{i}.depth, '.')
    hold on
    axis ij

    sspAll = [sspAll; mean(SSP{i}.SSP, 2)];
    zAll = [zAll; SSP{i}.depth];

end
hold off
[zSort, Isort] = sort(zAll);
sspSort = sspAll(Isort);

Irem = find(zSort<=2 & sspSort<1506);
zSort(Irem) = [];
sspSort(Irem) = [];
figure(2)
plot(sspSort, zSort, '.'); axis ij
% hold on
z = 1:10:round(zSort(end));
for iz = 1:length(z)
    ind = find(abs(zSort-z(iz))<=5);
    ssp(iz) = mean(sspSort(ind));
end

z(end+1) = 1351;
ssp(end+1) = c;
plot(ssp, z); axis ij

% hz = 1351;
for nHarp = 1:4
    SD = abs(hLatLonZ(nHarp, 3));
    RD = 200:50:1350;

    wRanges = 100:100:6000;
    NR = length(wRanges);
    RR = wRanges([1, end]);

    fileName = ['rayBendingModelTDOA_H', num2str(nHarp)];
    makeEnv('D:\MATLAB_addons\gitHub\wheresWhaledo\experiments', fileName, z, ssp, SD, RD, NR, RR, 'A')
    bellhop(['D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\', fileName])


    [Arr, Pos] = read_arrivals_asc(['D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\', fileName, '.arr']);

    n = 0; % counter
    for nr = 0:length(Pos.r.r) % iterate through whale ranges
        % (starts at zero because I need to calculate travel times from whales
        % directly above the instrument via integration/harmonic sound
        % speed because Bellhop returns nothing for these locations.
        for nz = 1:length(Pos.r.z) % iterate through whale depths
            n = n+1; % increment counter
            
            if nr==0 % if range is 0, calculate harmonic sound speed
                H{nHarp}.wloc(n, :) = [0, Pos.r.z(nz)];
                H{nHarp}.wz(nz) = Pos.r.z(nz);
                H{nHarp}.wr(nr+1) = 0;
                H{nHarp}.Ang(nr+1, nz) = -90;
                iz = find(z>=Pos.r.z(nz) & z<=SD); % indices of sound speed depths between source and receiver

                if isempty(iz) % iz is empty if source depth is at bottom
                    d = abs(Pos.s.z - Pos.r.z(nz));      % distance traveled
                    H{nHarp}.ttVec(n) = d/c;   % use c at depth for travel time

                    H{nHarp}.ttMat(nr+1, nz) = d/c; % matrix form;
                else
                    cHarmonic = length(iz)./sum(1./ssp(iz)); % harmonic sound speed

                    d = abs(Pos.r.z(nz) - Pos.s.z);      % distance traveled

                    H{nHarp}.ttVec(n) = d/cHarmonic;   % travel time
                    H{nHarp}.ttMat(nr+1, nz) = d/cHarmonic;
                end

            else

                H{nHarp}.wloc(n, :) = [Pos.r.r(nr), Pos.r.z(nz)];
                H{nHarp}.wz(nz) = Pos.r.z(nz);
                H{nHarp}.wr(nr+1) =  Pos.r.r(nr);

                % find first arrival with no top or bottom bounces
                Idir = find(Arr(nr, nz).NumTopBnc==0 & Arr(nr, nz).NumBotBnc==0); % indices of direct arrivals (no bounces)

                if ~isempty(Idir)
                    [tt, Ifirst] = min(Arr(nr, nz).delay(Idir)); % travel time of first arrival w/ no bounces
                    
                    H{nHarp}.ttVec(n) = tt;
                    H{nHarp}.ttMat(nr+1, nz) = tt;
                    H{nHarp}.Ang(nr+1, nz) = Arr(nr, nz).SrcDeclAngle(Idir(Ifirst)); % AoA of first arrival

                else % no direct arrivals (usually along sea floor)
                    H{nHarp}.ttVec(n) = nan;
                    H{nHarp}.ttMat(nr+1, nz) = nan;
                    H{nHarp}.Ang(nr+1, nz) = nan;
                end
            end
            H{nHarp}.expAng(nr+1, nz) = atand(H{nHarp}.wr(nr+1)/(H{nHarp}.wz(nz) + hLatLonZ(nHarp, 3)));
        end
        if sum(isnan(H{nHarp}.ttMat(nr+1, :)))>0 % if profile at this range has any nan values

            Ifit = find(~isnan(H{nHarp}.ttMat(nr+1, :)));
            Inan = find(isnan(H{nHarp}.ttMat(nr+1, :)));

            % fit line to travel time profile at this range:
            pf = polyfit(H{nHarp}.wz(Ifit), H{nHarp}.ttMat(nr+1, Ifit), 4);
            ttz = polyval(pf, H{nHarp}.wz);
            
            H{nHarp}.ttMat(nr+1, Inan) = ttz(Inan);

            % fit line to travel time profile at this range:
            pf = polyfit(H{nHarp}.wz(Ifit), H{nHarp}.Ang(nr+1, Ifit), 2);
            angz = polyval(pf, H{nHarp}.wz);
            
            H{nHarp}.Ang(nr+1, Inan) = angz(Inan);
            
        end

    end

    fig = figure(4+2*nHarp);
    % contour(repmat(H{1}.wr, [length(H{1}.wz), 1]).', repmat(H{1}.wz, [length(H{1}.wr), 1]), H{1}.ttMat)
    imagesc(H{nHarp}.wr, H{nHarp}.wz, H{nHarp}.ttMat.')
    set(gca, 'YDir', 'reverse')
    colormap('jet')
    colorbar
    title(['Travel Time for HARP ', num2str(nHarp)])
    xlabel('range (m)')
    ylabel('depth (m)')

    fig = figure(5+2*nHarp);
    % contour(repmat(H{1}.wr, [length(H{1}.wz), 1]).', repmat(H{1}.wz, [length(H{1}.wr), 1]), H{1}.ttMat)
    imagesc(H{nHarp}.wr, H{nHarp}.wz, (H{nHarp}.Ang-H{nHarp}.expAng).')
    set(gca, 'YDir', 'reverse')
    colormap('jet')
    colorbar
    title(['AoA error for HARP ', num2str(nHarp)])
    xlabel('range (m)')
    ylabel('depth (m)')

end


%% Use travel time maps to determine TDOA

% define grid:
xvec = -4000:100:4000;
yvec = -4000:100:4000;
zvec = 0:50:1100; % height above EE
n = 0;
for ix = 1:length(xvec)
    for iy = 1:length(yvec)
        for iz = 1:length(zvec)
            % Steps:
            % 1. For each whale position in grid, get r and z to all instruments
            % 2. interpolate w/ interp2 to get best estimate of travel time to each
            % instrument
            % 3. Take difference
            for nh = 1:4 % iterate over each instrument
                % step 1: get r and z to instrument:
                r = sqrt((xvec(ix)-hydLoc(nh, 1))^2 + (yvec(ix)-hydLoc(nh, 2))^2);
                depth = abs(zvec(iz) + hLatLonZ(nh, 3)); % this needs to be depth, not height above instrument!!!! Fix this
                
                % find range and depth values surrounding the grid point
                [zi, Iz] = sort([H{nh}.wz, depth]);
                [ri, Ir] = sort([H{nh}.wr, r]);
                [~, Iz] = max(Iz);
                [~, Ir] = max(Ir);

                tti = interp2(H{nh}.wz.', H{nh}.wr, H{nh}.ttMat, zi.', ri);

                tt(nh) = tti(Ir, Iz);
                
            end
            n = n+1;
            wloc(n, :) = [xvec(ix), yvec(iy), zvec(iz)];

            see = (wloc(n, :) - hydLoc(1, :));
            see = see./sqrt(sum(see.^2));
            TDOA(n, 1:6) = (-see*HEE.')./c;

            sew = (wloc(n, :) - hydLoc(2, :));
            sew = sew./sqrt(sum(sew.^2));
            TDOA(n, 7:12) = (-sew*HEW.')./c;


            TDOA(n, 13) = tt(1)-tt(2);
            TDOA(n, 14) = tt(1)-tt(3);
            TDOA(n, 15) = tt(1)-tt(4);
            TDOA(n, 16) = tt(2)-tt(3);
            TDOA(n, 17) = tt(2)-tt(4);
            TDOA(n, 18) = tt(3)-tt(4);

        end
    end
end

save('B:/model_bellhop', 'wloc', 'TDOA')
%%
function makeEnv(filepath, filename, z, ssp, SD, RD, NR, RR, modelType)

fpn = fullfile(filepath, [filename, '.env']);

% make file or erase current contents of file:
fid = fopen(fpn, 'w');
fclose(fid);

% open file to append contents
fid = fopen(fpn, 'at');

% line 1: title
fprintf(fid, ['''', filename, '''']);
fprintf(fid, '\n');

% line 2: freq
fprintf(fid, '300\t!Freq (Hz)\n');

% line 3: No. of media
fprintf(fid, '1\t! NMEDIA\n');

% line 4: interpolation type
fprintf(fid, '''PVF''\t! SSPOPT (Analytic or C-linear interpolation)\n');

% line 5: Bottom depth, number of depth values
fprintf(fid, '%d  0.0  %.3f\t! Depth of bottom (m)\n', length(z), max(z));

% lines 6 to 6 + N: depth and ssp
fprintf(fid, '%d\t%.6f\t/ \n', z(1), ssp(1));
for nz = 2:length(z)
    fprintf(fid, '%.3f\t%.6f\t/ \n', z(nz), ssp(nz));
end

% Bottom half-space properties
fprintf(fid, '''A'' 0.0\n');
fprintf(fid, ' 5000.0  %.3f  0.0 1.5 0.5  /\n', max(ssp)*1.01);

% Number of source depths (hydrophone location)
fprintf(fid, '%d\t! No. of SD\n', length(SD));

% Source depths
fprintf(fid, '%.4f  ', SD);
fprintf(fid, '/\t! SD\n');

% Number of receiver depths (ship locations)
fprintf(fid, '%d\t! No. of RD\n', length(RD));

% receiver depths
fprintf(fid, '%.4f  ', RD);
fprintf(fid, '/\t! RD\n');

% Number of receiver ranges (ship locations)
fprintf(fid, '%d\t! No. of RR\n', NR);

% Source depths
fprintf(fid, '%.4f  ', RR./1000);
fprintf(fid, '/\t! RR\n');

% model type
fprintf(fid, ['''', modelType, '''\n']);

% No. of beams
switch modelType
    case 'A'
        fprintf(fid, '0\n');
    case 'E'
        fprintf(fid, '2001\n');
end

% Beam angles
fprintf(fid, '-90.0  90.0 /\n');

% Step, ZBOX, RBOX
fprintf(fid, '0.0  1500 101.0');

fclose(fid);
end