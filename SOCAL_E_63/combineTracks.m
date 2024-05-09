global CTCparam
loadParams('CTC.params')

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
figDir = 'D:\SOCAL_E_63\tracking\interns2022\allTracks_CTC_pics';

df = dir('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\*track*'); % directory of folders containing files
tn = zeros(numel(df), 1);

nstart =61;
for ndf = nstart:numel(df)
    tic
    fprintf(['file ', num2str(ndf), '. ', num2str(100*ndf/numel(df)), '%% done\n'])
    clear CTC
    d = dir(fullfile(df(ndf).folder, [df(ndf).name, '\*det*.mat']));
    if ~isempty(d)
        load(fullfile(d.folder, d.name))

        newName = [d.name([1:11, 23:end-4]), '_CTC'];
        if ~isempty(DET{1}) && ~isempty(DET{2})
            whaleNums = unique([DET{1}.color; DET{2}.color]); % all whale num labels in this encounter
            whaleNums(whaleNums<3) = []; % remove labels '2' and '1' for unlabeled detections
            kerInst = [1,2];
            labeledInst = [1,2];
            tmin = min([DET{1}.TDet(1), DET{2}.TDet(1)]);
            tmax = max([DET{1}.TDet(end), DET{2}.TDet(end)]);

        elseif ~isempty(DET{1}) && isempty(DET{2})
            whaleNums = unique(DET{1}.color);   % all whale num labels in this encounter
            whaleNums(whaleNums<3) = []; % remove labels '2' and '1' for unlabeled detections
            kerInst = 1;
            labeledInst = 1;
            tmin = DET{1}.TDet(1);
            tmax = DET{1}.TDet(end);
        elseif isempty(DET{1}) && ~isempty(DET{2})
            whaleNums = unique(DET{2}.color);   % all whale num labels in this encounter
            whaleNums(whaleNums<3) = []; % remove labels '2' and '1' for unlabeled detections
            kerInst = 2;
            labeledInst = 2;
            tmin = DET{2}.TDet(1);
            tmax = DET{2}.TDet(end);
        else % no labels
            continue
        end
       
        fig = figure(1);
        fig.WindowState = 'maximized';
        for wn = 1:length(whaleNums)
            [CTC{wn}, DET] = clickTrainCorr(DET, whaleNums(wn), kerInst, labeledInst, [3,4], 'D:\MATLAB_addons\gitHub\wheresWhaledo\CTC.params');

            for ntdoa = 1:18

                subplot(6,3,sporder(ntdoa))
                plot(CTC{wn}.TDet, CTC{wn}.TDOA(:, ntdoa), '.')
                xlim([tmin, tmax])
                hold on
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

        sgtitle(datestr(CTC{wn}.TDet(1), 'yy-mmm-dd'))

        save(fullfile(d.folder, d.name), 'DET')
        save(fullfile(d.folder, newName), 'CTC')

        saveas(fig, fullfile(d.folder, newName), 'jpg')
        saveas(fig, fullfile(d.folder, newName), 'fig')
        saveas(fig, fullfile(figDir, newName), 'jpg')
        saveas(fig, fullfile(figDir, newName), 'fig')

        close
        tn(ndf) = toc;
        tm = mean(tn(nstart:ndf));
        fprintf(['Estimated time to completion = ', num2str((numel(df)-ndf)*tm/60), ' min\n']);
    end


end


