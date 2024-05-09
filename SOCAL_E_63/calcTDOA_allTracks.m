% global TDOAparam
% loadParams('calcTDOA.params')
colorMat(1, :) = [0.600000, 0.600000, 0.600000]; % acoustic data 
colorMat(2, :) = [0.000000, 0.000000, 0.000000]; % Unlabeled detections 
colorMat(3, :) = [0.984314, 0.603922, 0.600000]; % Whale 1 
colorMat(4, :) = [0.756863, 0.874510, 0.541176]; % Whale 2 
colorMat(5, :) = [0.650980, 0.807843, 0.890196]; % Whale 3 
colorMat(6, :) = [0.992157, 0.749020, 0.435294]; % Whale 4 
colorMat(7, :) = [0.121569, 0.470588, 0.705882]; % Whale 5 
colorMat(8, :) = [0.415686, 0.239216, 0.603922]; % Whale 6 
colorMat(9, :) = [0.219608, 0.725490, 0.027451]; % Whale 7 
colorMat(10, :) = [0.890196, 0.101961, 0.109804]; % Whale 8 
colorMat(11, :) = [0.792157, 0.698039, 0.839216]; % Buzzes 

% xwav tables:
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EE_C4_xwavLookupTable');
XH{1} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EW_C4_xwavLookupTable');
XH{2} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EN_xwavLookupTable');
XH{3} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_ES_xwavLookupTable');
XH{4} = xwavTable;

spd = 60*60*24; % seconds per day (converting from datenum)
numInst = 4; % number of instruments
sporder = [1:3:18, 2:3:18, 3:3:18];
figDir = 'D:\SOCAL_E_63\tracking\interns2022\allTracks_TDOA_pics';

df = dir('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\*track*'); % directory of folders containing files
tn = zeros(numel(df), 1);

nstart = 5;
for ndf = nstart:numel(df)
    tic
    fprintf(['file ', num2str(ndf), '. ', num2str(100*ndf/numel(df)), '%% done\n'])
    clear whale
    d = dir(fullfile(df(ndf).folder, [df(ndf).name, '\*CTC*.mat']));
    if ~isempty(d)
        load(fullfile(d.folder, d.name))
        newName = [d.name(1:end-7), 'fineTDOA'];

        whale = calcTDOAfromCTC(CTC, XH);


        fig = figure(1);
        fig.WindowState = 'maximized';
        
        tmin = nan;
        tmax = nan;
        for wn = 1:numel(whale)
            tmin = min([tmin, min(min(whale{wn}.TDet))]);
            tmax = max([tmax, max(max(whale{wn}.TDet))]);
            for ntdoa = 1:18
                
                subplot(6,3,sporder(ntdoa))
                plot(min(whale{wn}.TDetAll.'), whale{wn}.TDOA(:, ntdoa), '.', 'color', colorMat(wn+2, :))
                hold on
                scatter(min(CTC{wn}.TDetAll.'), CTC{wn}.TDOA(:, ntdoa), 20, colorMat(wn+2, :).*ones(size(CTC{wn}.TDOA, 1), 1), 'MarkerEdgeAlpha', .25)
                xlim([tmin, tmax])
                
                grid on
                datetick('x', 'HH:MM','keeplimits')

                if sporder(ntdoa)==1
                    title('Small-ap TDOA EE')
                elseif sporder(ntdoa)==2
                    title('Small-ap TDOA EW')
                elseif sporder(ntdoa)==3
                    title('Large-ap TDOA')
                end

            end
        end

        sgtitle(datestr(min(min(whale{wn}.TDet)), 'yy-mmm-dd'))

        save(fullfile(d.folder, newName), 'whale')

        saveas(fig, fullfile(d.folder, newName), 'jpg')
        saveas(fig, fullfile(d.folder, newName), 'fig')
        saveas(fig, fullfile(figDir, newName), 'jpg')
        saveas(fig, fullfile(figDir, newName), 'fig')

        close(fig)
    end
end