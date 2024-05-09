% run_detector_per_array
% 
% detects clicks from all instruments, 4ch and 1ch arrays
% requires:
% encFile - timetable with encounter times to run the detector
% saveDetPath - path to save the detections per track
% xwavLookupTable File - mat file with xwav paths and corresponding raw
% files start times
% hydLocInversionFile - mat file with hydrophone positions 
%
% adapted from newOrderExperiment220430
% asb,2022
clear all

% TO DEFINE: Set up data and paths
site = 'SOCAL_W_05'; % fileprefix 
encFile = 'F:\GDrive_Backup\Lauren Baggett MS\AI_Classification\Time_Tables\Zc\SOCAL_W_05_WW\SOCAL_W_05_WW_encounterTimes.mat';
saveDetPath = 'F:\Tracking\Erics_detector\SOCAL_W_05\new\detections'; % set path to save tracking detections
xwavLookupTableFile_HW = 'F:\Tracking\Instrument_Orientation\SOCAL_W_05\new_4ch_matrices\SOCAL_W_05_WE\SOCAL_W_05_WE_C4_xwavLookupTable.mat';
xwavLookupTableFile_HS = 'F:\Tracking\Instrument_Orientation\SOCAL_W_05\new_4ch_matrices\SOCAL_W_05_WS\SOCAL_W_05_WS_C4_xwavLookupTable.mat';
hydLocInversionsFile_HW = 'F:\Tracking\Instrument_Orientation\SOCAL_W_05\new_4ch_matrices\SOCAL_W_05_WE\SOCAL_W_05_WE_harp4chParams.mat';
hydLocInversionsFile_HS = 'F:\Tracking\Instrument_Orientation\SOCAL_W_05\new_4ch_matrices\SOCAL_W_05_WS\SOCAL_W_05_WS_harp4chPar.mat';

% % for dolphin removal steps only
% % transfer function path for the hydrophone you're using
% tf1 = 'G:\Shared drives\MBARC_TF\900-999\968\968_210226_A_HARP.tf';
% tf2 = 'G:\Shared drives\MBARC_TF\900-999\915\915_180502_A_HARP.tf';
% % channel # of your hydrophone
% channel = 1;

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% constants
c = 1482.965459;
fs1 = 200e3;
fs4 = 100e3;

% filter parameters
fc = 20e3;
[b4, a4] = ellip(4,0.1,40,fc*2/fs4,'high'); % 4ch filter coeff's
[b1, a1] = ellip(4,0.1,40,fc*2/fs1,'high'); % 1ch filter coeff's

% load in xwav tables
XH{1} = load(xwavLookupTableFile_HW);
XH{2} = load(xwavLookupTableFile_HS);
% XH{3} = load('F:\Instrument_Orientation\SOCAL_H_75\SOCAL_H_75_HE\dep\SOCAL_H_75_HE_xwavLookupTable.mat');
%XH{4} = load('D:\SOCAL_E_63\xwavTables\SOCAL_E_63_ES_xwavLookupTable.mat');

% load hydrophone loc inversions matrices
hyd1 = load(hydLocInversionsFile_HW);
hyd2 = load(hydLocInversionsFile_HS);

% Reorder hydrophones to fit new TDOA order
H{1} = [hyd1.recPos(2,:)-hyd1.recPos(1,:);
    hyd1.recPos(3,:)-hyd1.recPos(1,:);
    hyd1.recPos(4,:)-hyd1.recPos(1,:);
    hyd1.recPos(3,:)-hyd1.recPos(2,:);
    hyd1.recPos(4,:)-hyd1.recPos(2,:);
    hyd1.recPos(4,:)-hyd1.recPos(3,:)];

H{2} = [hyd2.recPos(2,:)-hyd2.recPos(1,:);
    hyd2.recPos(3,:)-hyd2.recPos(1,:);
    hyd2.recPos(4,:)-hyd2.recPos(1,:);
    hyd2.recPos(3,:)-hyd2.recPos(2,:);
    hyd2.recPos(4,:)-hyd2.recPos(2,:);
    hyd2.recPos(4,:)-hyd2.recPos(3,:)];


% Run Detector on all instruments

% load encounter times
load(encFile)
% bwEnc = ddEnc;

for encNum = 420:height(bwEnc)
    encounterStart = datenum(bwEnc.startSnipped(encNum))-datenum([2000 0 0 0 0 0]);
    encounterEnd = datenum(bwEnc.endSnipped(encNum))-datenum([2000 0 0 0 0 0]);
    
    if encounterEnd > XH{1}.xwavTable.startTime(end)
        fprintf('Encounter %d outside of file range; proceeding with the next encounter\n',encNum)
    else
    detFileName = [site,'_detections_track',num2str(bwEnc.encN(encNum)),'_',datestr(bwEnc.startEnc(encNum),'yymmdd_HHMMSS'),'.mat'];

    if isfile(fullfile(saveDetPath,detFileName))
        fprintf('File %d/%d already exists: %s\n',encNum,height(bwEnc),detFileName)
    else
    % SOCAL_E_63_EE
    [DET{1}] = detectClicks_4ch(encounterStart, encounterEnd, XH{1}.xwavTable, H{1}, c, 'detClicks_4ch.params');
    % [DET{1}] = detectClicks_4ch_dolphin(encounterStart, encounterEnd, XH{1}.xwavTable, H{1}, c, 'detClicks_4ch.params',tf1,channel,fs4);
    
    % SOCAL_E_63_EW
    [DET{2}] = detectClicks_4ch(encounterStart, encounterEnd, XH{2}.xwavTable, H{2}, c, 'detClicks_4ch.params');
    % [DET{2}] = detectClicks_4ch_dolphin(encounterStart, encounterEnd, XH{2}.xwavTable, H{2}, c, 'detClicks_4ch.params',tf2,channel,fs4);

    save(fullfile(saveDetPath,detFileName),'DET')
    fprintf('File %d/%d saved: %s\n',encNum,height(bwEnc),detFileName)
        
    end
    end
end

% for encNum = 1:height(bwEnc)
% 
%     encounterStart = datenum(bwEnc.startSnipped(encNum))-datenum([2000 0 0 0 0 0]);
%     encounterEnd = datenum(bwEnc.endSnipped(encNum))-datenum([2000 0 0 0 0 0]);
% % SOCAL_E_63_EN
%     [DET{3}] = detectClicks_1ch(encounterStart, encounterEnd, XH{3}.xwavTable, 'detClicks_1ch.params');
% end
% SOCAL_E_63_ES
% [DET{4}] = detectClicks_1ch(encounterStart, encounterEnd, XH{4}.xwavTable, 'detClicks_1ch.params');



