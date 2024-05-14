function whale = calcTDOAfromCTC(CTC, XH, varargin)
% whale = calcTDOAfromCTC(CTC, XH)
% whale = calcTDOAfromCTC(CTC, XH, TDOAparamFile)
% calculates TDOA from CTC by cross-correlating the acoustic data.


global TDOAparam

% load in params
if nargin == 3 % param file specified
    loadParams(varargin{1})
elseif nargin == 2 % no param file specified, load default file
    loadParams('calcTDOA.params')
else
    fprintf('\nIncorrect number of inputs into function calcTDOAfromCTC')
end

for n = 1:TDOAparam.Ninst
    [b{n}, a{n}] = ellip(4,0.1,40,TDOAparam.fc*2/TDOAparam.fs(n),'high');
end
spd = 60*60*24; % seconds per day
whale = CTC;

for wn = 1:numel(CTC) % iterate through each whale
    
    if ~isempty(CTC{wn})
        whale{wn}.TDOA(:, 13:12+TDOAparam.NTDOA) = nan;
        whale{wn}.XAmp = nan(length(whale{wn}.TDet), TDOAparam.NTDOA); % initialize XAmp
        whale{wn}.Iuse = zeros(size(whale{wn}.TDetAll));
        
        for ndet = 1:length(CTC{wn}.TDet)
            clear X T
            Iuse = find(~isnan(CTC{wn}.TDetAll(ndet, :)));

            for i = Iuse
                % define window of data to load in:
                tstart = CTC{wn}.TDetAll(ndet, i)-TDOAparam.twin/(2*spd);
                tend = tstart + TDOAparam.twin/spd;

                % read in acoustic data:
                [x, t] = quickxwavRead(tstart, tend, TDOAparam.fs(i), XH{i});
                xf = filtfilt(b{i}, a{i}, x(:, 1));

                if TDOAparam.upsample(i)==1
                    xfi = interpft(xf, length(xf)*2);
                    dt = 1/(2*TDOAparam.fs(i));
                    ti = t(1):dt/spd:t(end);
                    xfi = xfi(1:length(ti));

                    X{i} = xfi;
                    T{i} = ti;
                else
                    X{i} = xf;
                    T{i} = t;
                end
                

            end

            [TDOA, XAmp] = calcTDOA(X, T, Iuse, TDOAparam);

            tdoaErr = TDOA-CTC{wn}.TDOA(ndet, 13:end);

            % make whale=CTC, then update whale.TDOA to include new TDOA
            % and XAmp.
            whale{wn}.TDOA(ndet, 13:12+TDOAparam.NTDOA) = TDOA;
            whale{wn}.XAmp(ndet, :) = XAmp;
            whale{wn}.Iuse(ndet, :) = zeros(1, 4);
            whale{wn}.Iuse(ndet, Iuse) = 1; 
        end
    end
end

end

%%
function [TDOA, XAmp] = calcTDOA(X, T, Iuse, TDOAparam)

spd = 60*60*24;

% find which TDOA pairs can be calculated with the instruments that had
% detections
ITDOA = find(sum(ismember(TDOAparam.hpair, Iuse), 2)==2); 

% initialize outputs
TDOA = nan(TDOAparam.NTDOA, 1);
XAmp = TDOA; 

for i = ITDOA.'
    i1 = TDOAparam.hpair(i, 1);
    i2 = TDOAparam.hpair(i, 2);
    [xc, lags] = xcov(X{i1}, X{i2});

    [XAmp(i), I] = max(xc);

    TDOA(i) = lags(I)/TDOAparam.fsxc + (T{i1}(1)-T{i2}(1))*spd;
end


end
