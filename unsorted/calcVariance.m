function whaleOut = calcVariance(whaleIn, XH, sig2_H1, sig2_H2, sig2_lrg, c, calcTDOA_paramFile, detClicks_4ch_paramFile)

global TDOAparam detParam

whale = whaleIn;
spd = 60*60*24;

% load in params
loadParams(calcTDOA_paramFile)
loadParams(detClicks_4ch_paramFile)

% design small ap filters:
if length(detParam.fc)==1
    [bsm, asm] = ellip(4,0.1,40,detParam.fc*2/detParam.fs,'high');
else
    [bsm, asm] = ellip(4,0.1,40,detParam.fc.*2/detParam.fs);
end

% design large ap filters:
for n = 1:TDOAparam.Ninst
    [b{n}, a{n}] = ellip(4,0.1,40,TDOAparam.fc*2/TDOAparam.fs(n),'high');
end

sig2_sml{1} = sig2_H1;
sig2_sml{2} = sig2_H2;

itdoa{1} = 1:6; % indices of TDOA associated with AR1 small ap
itdoa{2} = 7:12; % indices of TDOA associated with AR2 small ap
itdoa{3} = 12 + (1:TDOAparam.NTDOA); % indices of TDOA associated with large ap

% calculate bandwidth:
BW = detParam.fs/2-detParam.fc; % bandwidth of click

for wn = 1:numel(whale)
    if ~isempty(whale{wn})
        % initialize variables:
        whale{wn}.SNR = nan(size(whale{wn}.TDOA));
        whale{wn}.sigma = whale{wn}.SNR;
        
        % iterate through all detections and calculate SNR and sigma
        for ndet = 1:length(whale{wn}.TDet)
            clear X

            SNR = nan(1, 12 + TDOAparam.NTDOA);
            sigma = SNR;

            % calculate small aperture variance:
            for i = 1:2
                if whale{wn}.Iuse(ndet, i)==1
                    tstart = whale{wn}.TDetAll(ndet, i) - TDOAparam.twin/(2*spd);
                    tend = tstart + TDOAparam.twin/spd;
                    [x, t] = quickxwavRead(tstart, tend, detParam.fs, XH{i});
                    xf = filtfilt(b{i}, a{i}, x);

                    if TDOAparam.upsample(i)==1
                        xfi = interpft(xf, length(xf)*2);
                        X{i} = xfi(:, 1);
                    else
                        X{i} = xf(:, 1);
                    end

                    [xc, lags] = xcov(xf, detParam.maxdn);

                    for nx = 1:length(detParam.xcRow)
                        [~, loc] = max(xc(:, detParam.xcRow(nx)));

                        Isig = max([1, loc-detParam.sigDuration/2]):min([length(lags), loc+detParam.sigDuration/2]);
                        Inoise = 1:length(lags);
                        Inoise(Isig) = [];

                        sigPow = mean(xc(Isig, detParam.xcRow(nx)).^2);
                        noisePow = mean(xc(Inoise, detParam.xcRow(nx)).^2);
                        
                        SNR(itdoa{i}(nx)) = sigPow/noisePow;
                        sig2_xcov = 1/(BW^2*SNR(itdoa{i}(nx)));
                        tdoa = whale{wn}.TDOA(ndet, itdoa{i}(nx));
                        sigma(itdoa{i}(nx)) = sqrt(sig2_sml{i}*[1; tdoa^2; 1; sig2_xcov]).';

                    end

                end
            end

            % load in single-channel data:
            for i = 3:TDOAparam.Ninst
                if whale{wn}.Iuse(ndet, i)==1
                    [x, t] = quickxwavRead(tstart, tend, detParam.fs, XH{i});
                    xf = filtfilt(b{i}, a{i}, x);
                    X{i} = xf;
                end
            end

            % find which TDOA pairs can be calculated with the instruments
            % that had detections:
            Iuse = find(whale{wn}.Iuse(ndet, :)==1);
            ITDOA = find(sum(ismember(TDOAparam.hpair, Iuse), 2)==2);

            for i = ITDOA.'
                i1 = TDOAparam.hpair(i, 1);
                i2 = TDOAparam.hpair(i, 2);

                [xc, lags] = xcov(X{i1}, X{i2});

                [~, loc] = max(xc);
                Irem = find(xc==0); % remove zero values that artificially inflate SNR
                xc(Irem) = [];
                lags(Irem) = [];

                Isig = max([1, loc-TDOAparam.sigDuration/2]):min([length(lags), loc+TDOAparam.sigDuration/2]); % indices of signal
                Inoise = 1:length(lags); % all indices
                Inoise(Isig) = []; % remove indices of signal, other indices are noise

                sigPow = mean(xc(Isig).^2);
                noisePow = mean(xc(Inoise).^2);

                SNR(itdoa{3}(i)) = sigPow/noisePow;
                sig2_xcov = 1/(BW^2*SNR(itdoa{3}(i)));
                tdoa = whale{wn}.TDOA(ndet, itdoa{3}(i));

                sigma(itdoa{3}(i)) = sqrt(sig2_lrg(:, i).'*[1; (abs(tdoa)+TDOAparam.maxDrift)^2; 1; sig2_xcov]).'; 
            end

            whale{wn}.SNR(ndet, :) = SNR;
            whale{wn}.sigma(ndet, :) = sigma;

        end
    end
end

whaleOut = whale;