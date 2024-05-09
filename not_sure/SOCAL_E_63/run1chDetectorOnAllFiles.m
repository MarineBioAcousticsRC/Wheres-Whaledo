% load xwav tables
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EE_C4_xwavLookupTable');
XH{1} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EW_C4_xwavLookupTable');
XH{2} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_EN_xwavLookupTable');
XH{3} = xwavTable;
load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_ES_xwavLookupTable');
XH{4} = xwavTable;

% dirOfFolders = dir('D:\SOCAL_E_63\tracking\interns2022\ericEdits');
% for nd = 72:numel(dirOfFolders)
%     fpath = fullfile(dirOfFolders(nd).folder, dirOfFolders(nd).name);
%     if dirOfFolders(nd).isdir==1 % this is a directory containing a DET file
%         detfile = dir(fullfile(fpath, ['*det*.mat']));
%         try
%             run_detector(fullfile(detfile.folder, detfile.name), XH);
%         catch
%             fprintf(['\nError on ', detfile.name, '. Possible xwav table error.\n'])
%             ok = 1;
%         end
%     end
% end
%
% function run_detector(filename, XH)
%
% load(filename)
%
% tstart = min([DET{1}.TDet(1), DET{2}.TDet(1)]);
% tend = max([DET{1}.TDet(end), DET{2}.TDet(end)]);
%
% paramFile = 'D:\MATLAB_addons\gitHub\wheresWhaledo\detClicks_1ch.params';
%
% [DET{3}] = detectClicks_1ch(tstart, tend, XH{3}, paramFile)
% [DET{4}] = detectClicks_1ch(tstart, tend, XH{4}, paramFile)
%
% save(filename, 'DET')
%
% end
%

%%

d = dir('D:\SOCAL_E_63\tracking\interns2022\processAsIs\*detections*');
for nd = 22:numel(d)
    fprintf([d(nd).name, '; ', num2str(100*nd/numel(d)), '%% complete\n'])    

    try
        run_detector(fullfile(d(nd).folder, d(nd).name), XH);
    catch
        fprintf(['\nError on ', d(nd).name, '. Possible xwav table error.\n'])
        fid = fopen(fullfile(d(nd).folder, [d(nd).name, 'error.txt']), 'wt' );
        fprintf(fid, 'Error in detector\n')
        fclose(fid)
    end
end

function run_detector(filename, XH)

load(filename)

tstart = min([DET{1}.TDet(1), DET{2}.TDet(1)]);
tend = max([DET{1}.TDet(end), DET{2}.TDet(end)]);

paramFile = 'D:\MATLAB_addons\gitHub\wheresWhaledo\detClicks_1ch.params';

[DET{3}] = detectClicks_1ch(tstart, tend, XH{3}, paramFile)
[DET{4}] = detectClicks_1ch(tstart, tend, XH{4}, paramFile)

save(filename, 'DET')

end

