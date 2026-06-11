function [specClickTf, peakFr, ppSignal, f] = ww_calculate_click_params(clickBuff, fs, inst, detParam)

% [specClickTf, peakFr, ppSignal] = ww_calculate_click_params(clickBuff, detParam)
%
% function to calculate click spectra, peak frequency, and peak-to-peak RL.
% math from this function comes from Triton SPICE detector function
% sp_dt_parameters()
%
% inputs:
%   - clickBuff: m x 1 vector, filtered click timeseries
%   - fs: scalar, sample rate
%   - inst: string, instrument name
%   - detParam: struct, user parameters as specified in detector
%       configuration gui
% outputs:
%   - specClickTf: 1 x n vector, click spectra
%   - peakFr: scalar, peak frequency (kHz)
%   - ppSignal: scalar, peak-to-peak RL (dB re 1 µPa^2)
%   - f: vector, frequency bins (kHz)

% ---- initialize FFT parameters ----
detParam.fftSize = ceil(fs * detParam.frameLengthUs / 1E6);
detParam.fftWindow = hann(detParam.fftSize)';
buff = (detParam.bufferLength_ms/1E3)*fs; % calculate the number of samples to buffer on either side of the peak
N = length(detParam.fftWindow);
lowSpecIdx = round(detParam.bpEdges(1)/fs*detParam.fftSize);
highSpecIdx = round(min(detParam.bpEdges(2),fs/2)/fs*detParam.fftSize);
detParam.specRange = lowSpecIdx:highSpecIdx;
detParam.tfFullFile = detParam.(inst).TFpath; % file path to transfer function
detParam = sp_fn_interp_tf(detParam);
f = 0:((fs/2)/1000)/((N/2)):((fs/2)/1000);
f = f(detParam.specRange);
sub = 10*log10(fs/N);

% ---- calculate click spectrum ----
winLength = length(clickBuff); % calculate window length
wind = hann(winLength); % calcualte window
wClick = zeros(1,N); % preallocate
wClick = clickBuff.*wind.'; % window click
spClick = 20*log10(abs(fft(wClick,N))); % calculate spectra
spClickSub = spClick-sub; % account for bin width
spClickSub = spClickSub(:,1:N/2); % reduce data to first half of spectra
specClickTf = spClickSub(detParam.specRange)+detParam.xfrOffset; % add tf offset

% ---- calculate peak frequency ----
[valMx, posMx] = max(specClickTf);
peakFr = f(posMx); %peak frequency in kHz

% ---- calculate ppRL ----
% find lowest and highest number in timeseries (counts) and add those
high = max(clickBuff);
low = min(clickBuff);
ppCount = high+abs(low);
% calculate dB value of counts and add transfer function value at peak
% frequency to get ppSignal (dB re 1uPa)
P = 20*log10(ppCount);
peakLow = floor(peakFr);
fLow=find(f>=peakLow);
% add PtfN transfer function at peak frequency to P
tfPeak = detParam.xfrOffset(fLow(1));
ppSignal = P+tfPeak;

% ---- helper functions (from Triton) ----
    function p = sp_fn_interp_tf(p)
        % p = sp_fn_interp_tf(p)
        %
        % function from TRITON, SPICE detector
        % nested helper function; if a transfer function is provided, interpolate to desired frequency bins

        % Determine the frequencies for which we need the transfer function
        p.xfr_f = (p.specRange(1)-1)*p.binWidth_hz:p.binWidth_hz:...
            (p.specRange(end)-1)*p.binWidth_hz;
        if ~isempty(p.tfFullFile)
            [p.xfr_f, p.xfrOffset] = sp_fn_tfMap(p.tfFullFile, p.xfr_f);
        else
            % if you didn't provide a tf function, then just create a
            % vector of zeros of the right size.
            p.xfrOffset = zeros(size(p.xfr_f));
        end
    end

    function [f, uppc] = sp_fn_tfMap(tf_fname,f_desired)
        % [f, uppc] = dtf_map(tf_fname, f_desired)
        % transfer function map

        % Given a path to a transfer function file open it and
        % interpollate to curve to match desired frequency vector.

        % Based tfmap.m in Triton, Version 1.64.20070709
        % function from TRITON SPICE DETECTOR

        fid = fopen(tf_fname,'r');
        if fid ~=-1
            % read in transfer function file
            [A,count] = fscanf(fid,'%f %f',[2,inf]);
            f = A(1,:);
            uppc = A(2,:);    % [dB re uPa(rms)^2/counts^2]
            fclose(fid);

            % If user wants response for different frequencies than those
            % in the transfer function, use linear interpolation.
            if nargin > 1 && ...
                    (length(f_desired) ~= length(f) || sum(f_desired ~= f))
                [~,uniqueIndex] = unique(f);
                if length(uniqueIndex)<length(f) % check for duplicate frequencies
                    % remove if there are duplicates, otherwise interpolation will
                    % fail
                    warning('Duplicate frequencies detected in transfer function.')
                    f = f(uniqueIndex);
                    uppc = uppc(uniqueIndex);
                end
                % interpolate for frequencies user wants

                uppc = interp1(f, uppc, f_desired, 'linear', 'extrap');
                f = f_desired;
            end
        else
            msg = sprintf('Unable to open transfer function %s',tf_fname);
            error(msg);
        end

    end

end