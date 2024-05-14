% global TDOAparam
% loadParams('calcTDOA.params')

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
figDir = 'D:\SOCAL_E_63\tracking\interns2022\allTracks_findTDOA_pics';

df = dir('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\*track*'); % directory of folders containing files
tn = zeros(numel(df), 1);

nstart = 1;
for ndf = nstart:numel(df)
    tic
    fprintf(['file ', num2str(ndf), '. ', num2str(100*ndf/numel(df)), '%% done\n'])
    clear CTC
    dc = dir(fullfile(df(ndf).folder, [df(ndf).name, '\*CTC*.mat']));
    if length(dc)==2
        drem = dir(fullfile(df(ndf).folder, [df(ndf).name, '\d_CTC.mat']));
        delete(fullfile(drem.folder, drem.name))
        dc = dir(fullfile(df(ndf).folder, [df(ndf).name, '\*CTC*.mat']));
    end
    
    dd = dir(fullfile(df(ndf).folder, [df(ndf).name, '\*det*.mat']));
   
    if ~isempty(dc) && ~isempty(dd)
        load(fullfile(dc.folder, dc.name))
        load(fullfile(dd.folder, dd.name))
        for wn = 1:numel(CTC)
            TDet = nan(length(CTC{wn}.TDet), 4);
            for ndet = 1:length(CTC{wn}.TDet)
                tdet = nan(1, 4);
                Iuse = find(~isnan(CTC{wn}.DETind(ndet, :)));
                for i = 1:length(Iuse)
                    tdet(Iuse(i)) = DET{Iuse(i)}.TDet(CTC{wn}.DETind(ndet, Iuse(i)));

                    ok = 1;
                end
                TDet(ndet, :) = tdet;
            end
            CTC{wn}.TDetAll = TDet;
        end
        save(fullfile(dc.folder, dc.name), 'CTC')
    end
    
end