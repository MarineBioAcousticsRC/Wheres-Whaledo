load('track_180611_1030.mat')
% load('track43_180327_084016.mat')

global brushing
loadParams('brushing.params')

twin = 20; % window size
spd = 60*60*24;
vwhale = 3; % maximum speed of source, m/s
c = 1488.4;
terr = .8e-3; % max error in TDOA (2x approx signal duration, seconds)
driftErr = .002; % error due to uncertainty in drift
maxdTDOA = 2*vwhale/c + terr + driftErr; % maximum change in TDOA per second

for wn = 1:numel(whale)

    % for wn = 2

    whale{wn}.TDOAcleaned = whale{wn}.TDOA;
    whale{wn}.dTDOA = zeros(size(whale{wn}.TDOA));
%     whale{wn}.TDOAsm = whale{wn}.TDOA;
    for ntdoa = 1:6

        Ind = find(whale{wn}.TDOA(:, ntdoa)>-10); % find points not flagged for removal
        if ~isempty(Ind)
            tdet = whale{wn}.TDet(Ind);
            tdoa = whale{wn}.TDOA(Ind, ntdoa);

            mtdoa = mean(tdoa);

            [~, Istart] = min(abs(tdoa-mtdoa));

            dtdoa = abs(tdoa - tdoa(Istart)./((tdet-tdet(Istart))*spd));
            whale{wn}.dTDOA(Ind, ntdoa) = dtdoa;
%             Nprior = Istart-1;
%             Nafter = length(tdoa)-Istart;
            

%             Iprev = Istart;
%             % Run through detections prior to Istart
%             for n = 1:length(Nprior)
%                 Ihere = Istart - n;
%                 dtdoa = abs(tdoa(Iprev) - tdoa(Ihere)/((tdet(Iprev)-tdet(Ihere))*spd));
%                 whale{wn}.dTDOA(Ind(Ihere), ntdoa) = dtdoa;
% 
%                 if dtdoa > maxdTDOA
%                     whale{wn}.TDOAcleaned(Ind(Ihere), ntdoa) = -99;
%                     
%                 else
% 
%                     Iprev = Ihere;
%                 end
% 
%             end
% 
%             Iprev = Istart;
%             % Run through detections after Istart
%             for n = 1:length(Nafter)
%                 Ihere = Istart + n;
%                 dtdoa = abs(tdoa(Iprev) - tdoa(Ihere)/((tdet(Iprev)-tdet(Ihere))*spd));
%                 whale{wn}.dTDOA(Ind(Ihere), ntdoa) = dtdoa;
% 
%                 if dtdoa > maxdTDOA
%                     whale{wn}.TDOAcleaned(Ind(Ihere), ntdoa) = -99;
%                 else
% 
%                     Iprev = Ihere;
%                 end
% 
%             end

            ok = 1;

        end
    end
end
%%
figure(7)
for np = 1:6
    subplot(6,1,np)
    yyaxis left
    for wn = 1:numel(whale)

        Ic = find(whale{wn}.TDOAcleaned(:, np) > -10);
        scatter(whale{wn}.TDet(Ic), whale{wn}.TDOAcleaned(Ic, np), 40, brushing.params.colorMat(wn+1, :).*.5, 'x')
        hold on
        
%         Is = find(whale{wn}.TDOAsm(:, np) > -10);
%         scatter(whale{wn}.TDet(Is), whale{wn}.TDOAsm(Is, np), 44, brushing.params.colorMat(wn+1, :), 'x')

        Io = find(whale{wn}.TDOA(:, np) > -10);
        scatter(whale{wn}.TDet(Io), whale{wn}.TDOA(Io, np), 12, brushing.params.colorMat(wn+1, :), 'filled')
    end
    hold off

    yyaxis right
    for wn = 1:numel(whale)

        Ic = find(whale{wn}.TDOAcleaned(:, np) > -10);
        scatter(whale{wn}.TDet(Ic), whale{wn}.dTDOA(Ic, np), 12, '*')
        
    end
end