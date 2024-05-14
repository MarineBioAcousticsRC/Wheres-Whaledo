load('D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track369_180520_120810\SOCAL_E_63_track369_180520_120810_ericMod_localized_v2.mat')

% xwav tables:
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EE_C4_xwavLookupTable');
XH{1} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EW_C4_xwavLookupTable');
XH{2} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EN_xwavLookupTable');
XH{3} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_ES_xwavLookupTable');
XH{4} = xwavTable;

fs(1:2) = 100e3;
fs(3:4) = 200e3;

isig = -58:58;
spd = 60*60*24;
twin = 1e-3/spd;


for wn = 1:numel(whale)
    I1 = find(~isnan(whale{wn}.DETind(:,1)));
    for ndet = 1:length(I1)
        Iuse = find(~isnan(whale{wn}.DETind(I1(ndet), :)));
        if length(Iuse)<=2
            continue
        end

        tdet = whale{wn}.TDet(I1(ndet)); 
            
        [x, t] = quickxwavRead(tdet - twin, tdet + twin, fs(1), XH{1});

        ok = 1;

        for ih = 1:length(Iuse)
            
        end
    end
end