%% Ray bending error
clear all
M = load('D:\SOCAL_E_63\tracking\experiments\largeApertureTDOA\TDOAmodel_200m'); % load model
fp = 'D:\SOCAL_E_63\HARP_Deployment_Metadata\fromJenny\ctd'; % file containing full-profile SSPs
rootFileName = 'SSP_cast';

hyd1 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EE_Hmatrix_fromHydLocInversion_210702.mat');
hyd2 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EW_Hmatrix_fromHydLocInversion_210702.mat');

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
plot(sspSort, zSort, '.'); axis ij
hold on 
z = 1:10:round(zSort(end));
for iz = 1:length(z)
    ind = find(abs(zSort-z(iz))<=5);
    ssp(iz) = mean(sspSort(ind));
end

z(end+1) = 1321;
ssp(end+1) = c;
plot(ssp, z); axis ij

hz = 1320;
SD = hz;
RD = 200:50:1200;

Mrange = sqrt(M.wloc(:,1).^2+M.wloc(:,2).^2);
wRanges = 0:50:max(Mrange);
NR = length(wRanges);
RR = wRanges([1, end]);

makeEnv('D:\MATLAB_addons\gitHub\wheresWhaledo\experiments', 'rayBendingSSP', z, ssp, SD, RD, NR, RR, 'A')
% bellhop('rayBendingSSP')

[Arr, Pos] = read_arrivals_asc('rayBendingSSP.arr');

% plotray('rayBendingSSP')
% for i = 1:length(Pos)
% 
% end

for ir = 1:size(Arr, 1)
    for iz = 1:size(Arr, 2)
        arr = Arr(ir, iz);
        wr = Pos.r.r(ir); % whale range
        wz = Pos.r.z(iz); % whale depth

        Ind = find(abs(arr.A)>0 & arr.NumBotBnc==0 & arr.NumTopBnc==0);
        if ~isempty(Ind)
            [delay(ir, iz), ifirst] = min(arr.delay(Ind));
            inc_true(ir, iz) = atand((wz-hz)/wr);
            inc_ray(ir, iz) = arr.SrcDeclAngle(Ind(ifirst));
            
            ok = 1;
        end

        
    end
end

inc_err = (sqrt(inc_ray-inc_true).^2);
inc_err(inc_err>20) = [];

col = parula(size(Arr, 2));
figure(5)
for iz = 1:size(Arr, 2)
    p(2*iz-1) = plot(Pos.r.r(2:end), inc_ray(2:end, iz), '-x', 'MarkerFaceColor', col(iz, :), 'Color', col(iz, :)); 
    hold on; 
    p(2*iz)=plot(Pos.r.r(2:end), inc_true(2:end, iz), ':*', 'MarkerFaceColor', col(iz, :), 'MarkerEdgeColor', col(iz, :), 'Color', col(iz, :)); 
    leg{2*iz-1} = ['Ray trace, depth=', num2str(Pos.r.z(iz))];
    leg{2*iz} = ['True angle, depth=', num2str(Pos.r.z(iz))];
end
legend(leg, 'location', 'best')
ylabel('Angle^\circ')
xlabel('Range (m)')
title('Angle of Arrival')
hold off

%% Iterate through different azimuths and determine TDOA error at these ranges
az = 0:5:350;
i = 0;
for iaz = 1:length(az)
    for iz = 1:length(Pos.r.z)
        for ir = 2:length(Pos.r.r)
            % True location of whale:
            wx = Pos.r.r(ir)*cosd(az(iaz));
            wy = Pos.r.r(ir)*sind(az(iaz));
            sTrue = [wx, wy, Pos.r.z(iz)];
            sTrue = sTrue./sqrt(sum(sTrue.^2)); % true direction vector

            smx = cosd(az(iaz)); % x component of direction vector
            smy = sind(az(iaz)); % y component of direction vector
            smz = -sind(inc_ray(ir, iz));
            sMeas = [smx, smy, smz];
            sMeas = sMeas./sqrt(sum(sMeas.^2));

            tdoa1True = (sTrue*hyd1.H.')./c;
            tdoa1Meas = (sMeas*hyd1.H.')./c;
           
            tdoa2True = (sTrue*hyd2.H.')./c;
            tdoa2Meas = (sMeas*hyd2.H.')./c;

            i = i+1;

            HARP{1}.TDOAtrue(i, :) = tdoa1True;
            HARP{1}.TDOAmeas(i, :) = tdoa1Meas;
            HARP{1}.TDOAerr(i, :) = sqrt(mean(tdoa1Meas-tdoa1True).^2);
            HARP{1}.wloc(i, :) = [wx, wy, Pos.r.z(iz)]; % whale location in relation to this HARP
            HARP{1}.travelTimeISO(i) = sqrt(Pos.r.r(ir)^2 + (hz-Pos.r.z(iz))^2)./c;
            HARP{1}.travelTimeRay(i) = real(delay(ir, iz));
            HARP{1}.travelTimeError(i) = abs(HARP{1}.travelTimeISO(i)-HARP{1}.travelTimeRay(i));

            HARP{2}.TDOAtrue(i, :) = tdoa2True;
            HARP{2}.TDOAmeas(i, :) = tdoa2Meas;
            HARP{2}.TDOAerr(i, :) = sqrt(mean(tdoa2Meas-tdoa2True).^2);
            HARP{2}.wloc(i, :) = [wx, wy, Pos.r.z(iz)]; % whale location in relation to this HARP
            HARP{2}.travelTimeISO(i) = sqrt(Pos.r.r(ir)^2 + (hz-Pos.r.z(iz))^2)./c;
            HARP{2}.travelTimeRay(i) = real(delay(ir, iz));
            HARP{2}.travelTimeError(i) = abs(HARP{2}.travelTimeISO(i)-HARP{2}.travelTimeRay(i));
            ok = 1;
        end
    end
end

figure(6)
histogram(HARP{1}.TDOAerr)
title('Array 1 TDOA error')

figure(7)
histogram(HARP{2}.TDOAerr)
title('Array 2 TDOA error')



%%
HARP{1}.TDOAstd = std(std(sqrt((HARP{1}.TDOAtrue-HARP{1}.TDOAmeas).^2)));
HARP{2}.TDOAstd = std(std(sqrt((HARP{2}.TDOAtrue-HARP{2}.TDOAmeas).^2)));

Itt = find(HARP{1}.travelTimeRay~=0);
HARP{1}.travelTimestd = sqrt(mean(HARP{1}.travelTimeError(Itt).^2));
HARP{2}.travelTimestd = sqrt(mean(HARP{2}.travelTimeError(Itt).^2));


figure(8)
z = unique(HARP{1}.wloc(:, 3));
for iz = 1:length(z)
    Iz = find(HARP{1}.wloc(:,3)==z(iz));
    scatter(sqrt(HARP{1}.wloc(Iz, 1).^2+HARP{1}.wloc(Iz, 2).^2), HARP{1}.travelTimeRay(Iz), ...
        [], col(iz, :), 'filled');
    hold on
    scatter(sqrt(HARP{1}.wloc(Iz, 1).^2+HARP{1}.wloc(Iz, 2).^2), HARP{1}.travelTimeISO(Iz), ...
        60, col(iz, :), 'x');
end
hold off

figure(9); histogram(HARP{1}.travelTimeError(Itt))
title('Travel Time Error')
xlabel('Error (s)')

figure(10); 
% plot(sqrt(sum(HARP{1}.wloc(Itt, :).^2, 2)), HARP{1}.travelTimeError(Itt), '.')
plot(HARP{1}.wloc(Itt, 3), HARP{1}.travelTimeError(Itt), '.')
title('Travel Time Error')
xlabel('range (m)')
ylabel('error')

travelTimeErr_all = [HARP{1}.travelTimeError, HARP{2}.travelTimeError];
Irem =find (travelTimeErr_all>=1);
travelTimeErr_all(Irem) = [];
sig_travelTime = mean([HARP{1}.travelTimeError, HARP{2}.travelTimeError])

%% Make environtment file

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