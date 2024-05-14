mainDir = 'D:\SOCAL_E_63\tracking\interns2022\processAsIs';
d = dir(fullfile(mainDir, '\*detections*'));

for nd = 65:numel(d)
    trackName = d(nd).name(23:end-4);
    foldername = fullfile(mainDir, trackName);
    mkdir(mainDir, trackName)
    copyfile(fullfile(d(nd).folder, d(nd).name), foldername)
    for arrno = 1:2
        fprintf(['Processing ', trackName, '; Array ', num2str(arrno), '; ', ...
            num2str(50*nd/numel(d)), '%% complete.\n'])
        fid = fopen(fullfile(foldername, 'results.txt'), 'wt' );
        try
            clickTrainCorr_multipleTDOA(trackName, foldername, arrno)
            try
                calcTDOA_fine(trackName, foldername, arrno)
            catch ME
                
                fprintf(fid, ['Error in calcTDOA_fine: ', ME.message, '\n']);
                save(fullfile(foldername, ['TDOAerror_array', num2str(arrno)]), 'ME')
                
            end

        catch ME
            
            fprintf(fid, ['Error in clickTrainCorr: ', ME.message, '\n']);
            
            save(fullfile(foldername, ['CTCerror_array', num2str(arrno)]), 'ME')
        end
        fclose(fid);
    end
end
