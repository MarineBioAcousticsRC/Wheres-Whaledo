function hdr = ww_read_xwav_header(xwavPath)

% ww_read_xwav_header
%
% function to read in header information from an xwav
% outputs: hdr (struct with header information)
% inputs: xwavPath (path to one xwav file
%
% adapted from Triton function rxwavhd (Sean Wiggins)

hdr = []; % preallocate
fid =  fopen(xwavPath,'r'); % oepn the file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RIFF chunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hdr.ChunkID = char(fread(fid,4,'uchar'))';       % "RIFF"
hdr.ChunkSize = fread(fid,1,'uint32');           % File size - 8 bytes
filesize = getfield(dir(xwavPath),'bytes');
if hdr.ChunkSize ~= filesize - 8
    disp_msg('Error - incorrect Chunk Size')
end
hdr.Format = char(fread(fid,4,'uchar'))';        % "WAVE"

if ~strcmp(hdr.ChunkID,'RIFF') || ~strcmp(hdr.Format,'WAVE')
    disp_msg('not wav file - exit')
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Format Subchunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hdr.fSubchunkID = char(fread(fid,4,'uchar'))';    % "fmt "
hdr.fSubchunkSize = fread(fid,1,'uint32');        % (Size of Subchunk - 8) = 16 bytes (PCM)
hdr.AudioFormat = fread(fid,1,'uint16');         % Compression code (PCM = 1)
hdr.NumChannels = fread(fid,1,'uint16');         % Number of Channels
hdr.SampleRate = fread(fid,1,'uint32');          % Sampling Rate (samples/second)
hdr.ByteRate = fread(fid,1,'uint32');            % Byte Rate = SampleRate * NumChannels * BitsPerSample / 8
hdr.BlockAlign = fread(fid,1,'uint16');          % # of Bytes per Sample Slice = NumChannels * BitsPerSample / 8
hdr.BitsPerSample = fread(fid,1,'uint16');       % # of Bits per Sample : 8bit = 8, 16bit = 16, etc

if ~strcmp(hdr.fSubchunkID,'fmt ') || hdr.fSubchunkSize ~= 16
    disp_msg('unknown wav format - exit')
    return
end

% copy to another name, and get number of bytes per sample
PARAMS.nBits = hdr.BitsPerSample;       % # of Bits per Sample : 8bit = 8, 16bit = 16, etc
PARAMS.samp.byte = floor(PARAMS.nBits/8);       % # of Bytes per Sample

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HARP Subchunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hdr.hSubchunkID = char(fread(fid,4,'uchar'))';    % "harp"
if strcmp(hdr.hSubchunkID,'data')
    PARAMS.fs = hdr.SampleRate;
    disp_msg('normal wav file - read data now')
    return
elseif ~strcmp(hdr.hSubchunkID,'harp')
    disp_msg('unsupported wav format')
    disp_msg(['SubchunkID = ',hdr.hSubchunkID])
    return
end
hdr.hSubchunkSize = fread(fid,1,'uint32');        % (Size of Subchunk - 8) includes write subchunk
hdr.WavVersionNumber = fread(fid,1,'uchar');     % Version number of the "harp" header (0-255)
hdr.FirmwareVersionNumber = char(fread(fid,10,'uchar'))';  % HARP Firmware Vesion
hdr.InstrumentID = char(fread(fid,4,'uchar'))';         % Instrument ID Number (0-255)
hdr.SiteName = char(fread(fid,4,'uchar'))';             % Site Name, 4 alpha-numeric characters
hdr.ExperimentName = char(fread(fid,8,'uchar'))';       % Experiment Name
hdr.DiskSequenceNumber = fread(fid,1,'uchar');   % Disk Sequence Number (1-16)
hdr.DiskSerialNumber = char(fread(fid,8,'uchar'))';     % Disk Serial Number
hdr.NumOfRawFiles = fread(fid,1,'uint16');         % Number of RawFiles in XWAV file
hdr.Longitude = fread(fid,1,'int32');           % Longitude (+/- 180 degrees) * 100,000
hdr.Latitude = fread(fid,1,'int32');            % Latitude (+/- 90 degrees) * 100,000
hdr.Depth = fread(fid,1,'int16');               % Depth, positive == down
if hdr.WavVersionNumber == 2
    hdr.drate = fread(fid,hdr.NumChannels,'single');
end
hdr.Reserved = fread(fid,8,'uchar')';            % Padding to extend subchunk to 64 bytes

if hdr.WavVersionNumber == 2
    hscs = (64 + 4*hdr.NumChannels) - 8 + hdr.NumOfRawFiles * (32 + 4*hdr.NumChannels);
else
    hscs = 64 - 8 + hdr.NumOfRawFiles * 32;
end
if hdr.hSubchunkSize ~= hscs
    disp_msg('Error - HARP SubchunkSize and NumOfRawFiles discrepancy?')
    disp_msg(['hSubchunkSize = ',num2str(hdr.hSubchunkSize)])
    disp_msg(['NumOfRawFiles = ',num2str(hdr.NumOfRawFiles)])
    %   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write sub-sub chunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:hdr.NumOfRawFiles
    % Start of Raw file :
    hdr.year(i) = fread(fid,1,'uchar');          % Year
    hdr.month(i) = fread(fid,1,'uchar');         % Month
    hdr.day(i) = fread(fid,1,'uchar');           % Day
    hdr.hour(i) = fread(fid,1,'uchar');          % Hour
    hdr.minute(i) = fread(fid,1,'uchar');        % Minute
    hdr.secs(i) = fread(fid,1,'uchar');          % Seconds
    hdr.ticks(i) = fread(fid,1,'uint16');        % Milliseconds
    hdr.byte_loc(i) = fread(fid,1,'uint32');     % Byte location in xwav file of RawFile start
    hdr.byte_length(i) = fread(fid,1,'uint32');    % Byte length of RawFile in xwav file
    hdr.write_length(i) = fread(fid,1,'uint32'); % # of blocks in RawFile length (default = 60000)
    hdr.sample_rate(i) = fread(fid,1,'uint32');  % sample rate of this RawFile
    hdr.gain(i) = fread(fid,1,'uint8');          % gain (1 = no change)
    hdr.padding = fread(fid,7,'uchar');    % Padding to make it 32 bytes...misc info can be added here
    if hdr.WavVersionNumber == 2
        hdr.dt = fread(fid,hdr.NumChannels,'single');     % time diff to channel 1
    end

    % should only be needed for special case bad data
    % remove after debugging
    %     if hdr.sample_rate(i) == 100000
    %         %   disp('Warning, changing sample rate from 100,000 to 200,000 Hz')
    % %         hdr.sample_rate(i) = 200000;
    %          hdr.sample_rate(i) = 500000;
    %
    %     end

    % calculate starting time [dnum => datenum in days] for each raw
    % write/buffer flush
    hdr.raw.dnumStart(i) = datenum([hdr.year(i) hdr.month(i)...
        hdr.day(i) hdr.hour(i) hdr.minute(i) ...
        hdr.secs(i)+(hdr.ticks(i)/1000)]);
    hdr.raw.dvecStart(i,:) = [hdr.year(i) hdr.month(i)...
        hdr.day(i) hdr.hour(i) hdr.minute(i) ...
        hdr.secs(i)+(hdr.ticks(i)/1000)];

    % end of RawFile:
    hdr.raw.dnumEnd(i) = hdr.raw.dnumStart(i) ...
        + datenum([0 0 0 0 0 (hdr.byte_length(i) - 2)  ./  hdr.ByteRate]);
    hdr.raw.dvecEnd(i,:) = hdr.raw.dvecStart(i,:) ...
        + [0 0 0 0 0 (hdr.byte_length(i) - 2)  ./  hdr.ByteRate];
    %     hdr.raw.dnumEnd(i) = hdr.raw.dnumStart(i) ...
    %         + datenum([0 0 0 0 0 ceil((hdr.byte_length(i))  ./  (hdr.ByteRate * hdr.NumChannels))]);
    %     hdr.raw.dvecEnd(i,:) = hdr.raw.dvecStart(i,:) ...
    %         + [0 0 0 0 0 (hdr.byte_length(i))  ./  (hdr.ByteRate * hdr.NumChannels)];
end

% calculate number of samples in each raw file
% LMB addition, adapted from Marie's python script
% AudioStreamDescriptor.py
bytes_per_sample = hdr.NumChannels * hdr.BitsPerSample / 8;
hdr.raw.rawSamples = hdr.byte_length ./ bytes_per_sample;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATA Subchunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hdr.dSubchunkID = char(fread(fid,4,'uchar'))';    % "data"
if ~strcmp(hdr.dSubchunkID,'data')
    disp_msg('hummm, should be "data" here?')
    disp_msg(['SubchunkID = ',hdr.dSubchunkID])
    return
end
hdr.dSubchunkSize = fread(fid,1,'uint32');        % (Size of Subchunk - 8) includes write subchunk

% read some data and check
%data = fread(fid,[4,100],'int16');

fclose(fid);

end