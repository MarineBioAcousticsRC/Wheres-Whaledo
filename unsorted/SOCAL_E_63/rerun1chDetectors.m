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

df = dir('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\*track*'); % directory of folders containing files

fwb = waitbar(0, 'running detectors');

h=findobj(fwb,'Type','figure');
ht = get(get(h,'currentaxes'),'title');
set(ht,'interpreter','none')

for ndf = 26:numel(df)
    tic

    d = dir(fullfile(df(ndf).folder, [df(ndf).name, '\*.mat']));
    if ~isempty(d)
        load(fullfile(d.folder, d.name))

        if ~isempty(DET{1}) && ~isempty(DET{2})
            tstart = min([DET{1}.TDet(1), DET{2}.TDet(1)]);
            tend = max([DET{1}.TDet(end), DET{2}.TDet(end)]);
        elseif ~isempty(DET{1}) && isempty(DET{2})
            tstart = DET{1}.TDet(1);
            tend = DET{1}.TDet(end);
        elseif isempty(DET{1}) && ~isempty(DET{2})
            tstart = DET{2}.TDet(1);
            tend = DET{2}.TDet(end);
        else
            continue
        end
        % rerun detector with better lockout time:
        waitbar(ndf/(2*numel(df)), fwb, ['Inst 3 on  ', df(ndf).name, '...']);
        try
            DET{3} = detectClicks_1ch(tstart, tend, XH{3}, 'D:\MATLAB_addons\gitHub\wheresWhaledo\detClicks_1ch.params');
        catch ME
            save(fullfile(d.folder, [d.name(1:end-4), '_ERROR_arr3']), 'ME')
        end
        
        waitbar((ndf+1)/(2*numel(df)), fwb, ['Inst 4 on  ', df(ndf).name, '...']);

        try
        DET{4} = detectClicks_1ch(tstart, tend, XH{4}, 'D:\MATLAB_addons\gitHub\wheresWhaledo\detClicks_1ch.params');
        catch ME
            save(fullfile(d.folder, [d.name(1:end-4), '_ERROR_arr4']), 'ME')
        end
        save(fullfile(d.folder, d.name), 'DET')
    end
    tn(ndf) = toc;
    tm = mean(tn);
    fprintf(['\nestimated time to completion = ' num2str((numel(df)-ndf)*tm/60), 'min'])
end