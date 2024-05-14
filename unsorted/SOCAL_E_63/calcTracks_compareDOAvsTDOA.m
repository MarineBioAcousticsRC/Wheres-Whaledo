% directory of folders containing detections:
dfolder = dir('D:\SOCAL_E_63\tracking\interns2022\processAsIs\*track*');

%% set parameters:
c = 1488.4;

%% load other necessary files:
% M = load('B:\TDOAmodel_100dx100dy20dz.mat'); % load model

load('D:\SOCAL_E_63\xwavTables\drift')
driftTDOA(:, 1) = drift(1, :).';
driftTDOA(:, 2) = drift(2, :).';
driftTDOA(:, 3) = drift(3, :).';
driftTDOA(:, 4) = drift(2, :).' - drift(1, :).';
driftTDOA(:, 5) = drift(3, :).' - drift(1, :).';
driftTDOA(:, 6) = drift(3, :).' - drift(2, :).';


% load hydrophone locations:
load('D:\SOCAL_E_63\xwavTables\instrumentLocs.mat')  % calculated in D:\MATLAB_addons\gitHub\wheresWhaledo\experiments\calcSigma.m
h = [0,0,0; h];

% h([3,4], 3) = h([3,4], 3) + 15;

hyd1 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EE_Hmatrix_new.mat');
hyd2 = load('D:\MATLAB_addons\gitHub\wheresWhaledo\receiverPositionInversion\SOCAL_E_63_EW_Hmatrix_new.mat');

% Reorder hydrophones to fit new TDOA order
HEE = [hyd1.recPos(2,:)-hyd1.recPos(1,:);
    hyd1.recPos(3,:)-hyd1.recPos(1,:);
    hyd1.recPos(4,:)-hyd1.recPos(1,:);
    hyd1.recPos(3,:)-hyd1.recPos(2,:);
    hyd1.recPos(4,:)-hyd1.recPos(2,:);
    hyd1.recPos(4,:)-hyd1.recPos(3,:)];

HEW = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];

%%

ndetALL = 0;
TDOA_ALL = zeros(10000, 6);
TDOAexp_ALL = TDOA_ALL;
TDetALL = zeros(10000, 1);

for ndf = 1:numel(dfolder)
    if dfolder(ndf).isdir
        fpn = fullfile(dfolder(ndf).folder, dfolder(ndf).name);
        d = dir(fullfile(fpn, '*fineTDOA*.mat'));

        for nd = 1:numel(d)
            load(fullfile(d(nd).folder, d(nd).name))

            newName = replace(d(1).name, 'fineTDOA', '3Dloc');

            % iterate through each whale and localize
            for wn = 1:numel(whale)
                if ~isempty(whale{wn})
                    whale{wn}.wloc = nan([length(whale{wn}.TDet), 3]);
                    whale{wn}.L = nan([length(whale{wn}.TDet), 1]);
                    
                    % find detections that occured on at least 1 4ch and
                    % one other instrument:
                    Iuse = find(sum(whale{wn}.IndUsed, 2)==18);
                    if ~isempty(Iuse)
                          
                        for ndet = 1:length(Iuse)
                            ndetALL = ndetALL + 1; % iterate the counter of all detections
                            [~, Idrift] = min((tdrift - whale{wn}.TDet(Iuse(ndet)) ).^2);

                            TDOA = whale{wn}.TDOA(Iuse(ndet), :);

                            TDOA(13:18) = TDOA(13:18) + driftTDOA(Idrift, :);
%                             sig2 = whale{wn}.sigma(Iuse(ndet), :).^2;
                            % indices of TDOA pairs which had detections:
%                             Itdoa = find(whale{wn}.IndUsed(Iuse(ndet), :)==1);
%                             L = (-sum(1./(2*sig2(Itdoa)).*(M.TDOA(:, Itdoa)-TDOA(Itdoa)).^2, 2));

%                             [whale{wn}.Lbest, Ibest] = max(L);

%                             whale{wn}.wloc = M.wloc(Ibest, :);

                            % calculate DOA intersect:
                            tdoa1 = whale{wn}.TDOA(Iuse(ndet), 1:6);
                            tdoa2 = whale{wn}.TDOA(Iuse(ndet), 7:12);

                            doa1 = (tdoa1.'.*c)\HEE;
                            doa2 = (tdoa2.'.*c)\HEW;

                            D = [doa1; -doa2];
                            R = D.'\(h(2, :) - h(1, :)).';

                            w1 = R(1).*doa1 + h(1, :);
                            w2 = R(2).*doa2 + h(2, :);

                            wloc = (w1+w2)./2;
                            
                            rngs = sqrt(sum((h-wloc).^2, 2));
                            
                            TDOAexp_ALL(ndetALL, 1) = (rngs(1) - rngs(2))/c;
                            TDOAexp_ALL(ndetALL, 2) = (rngs(1) - rngs(3))/c;
                            TDOAexp_ALL(ndetALL, 3) = (rngs(1) - rngs(4))/c;
                            TDOAexp_ALL(ndetALL, 4) = (rngs(2) - rngs(3))/c;
                            TDOAexp_ALL(ndetALL, 5) = (rngs(2) - rngs(4))/c;
                            TDOAexp_ALL(ndetALL, 6) = (rngs(3) - rngs(4))/c;

                            TDOA_ALL(ndetALL, :) = TDOA(13:18);
                            TDetALL(ndetALL) = whale{wn}.TDet(Iuse(ndet));
                        end
                    end
                end
            end

        end

    end

end


Irem = find(TDetALL==0);
TDetALL(Irem) = [];
TDOA_ALL(Irem, :) = [];
TDOAexp_ALL(Irem, :) = [];
%%
% load('D:\SOCAL_E_63\xwavTables\drift') % drift (sec) and tdrift (datenum) for EW, EN, ES relative to EE
% driftTDOA(:, 1) = drift(1, :).';
% driftTDOA(:, 2) = drift(2, :).';
% driftTDOA(:, 3) = drift(3, :).';
% driftTDOA(:, 4) = drift(2, :).' - drift(1, :).';
% driftTDOA(:, 5) = drift(3, :).' - drift(1, :).';
% driftTDOA(:, 6) = drift(3, :).' - drift(2, :).';


altDrift = load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift_ADCPonly.mat');

figure(1)
for np = 1:6
    subplot(6,1,np)
    tdoaErr(:, np) = TDOA_ALL(:, np)-TDOAexp_ALL(:, np);
    tep = polyfit(TDetALL, tdoaErr(:, np), 1);
    tdoaErrLine = polyval(tep, tdrift);
    plot(TDetALL, tdoaErr(:, np), 'x')
    

    hold on
%     plot(tdrift, tdoaErrLine, ':')
    plot(tdrift, -driftTDOA(:, np))
    plot(altDrift.tdrift, altDrift.drift(:, np))
%     plot(TDetALL, TDOAexp_ALL(:, np), 'x')
    hold off
%     ylim([-.3, .3])
    datetick
    grid on
end


%%
figure(2)
histogram(tdoaErr)