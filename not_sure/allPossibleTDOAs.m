function T = allPossibleTDOAs(CTC, DET, hloc, varargin)
% determines all possible TDOA associations.

global allTDOA

if nargin==4
    loadParams(varargin{1})
elseif nargin==3
    loadParams('allTDOA.params')
end


for itdoa = 1:allTDOA.NTDOA
    h1 = hloc(allTDOA.hpair(itdoa, 1), :); % location of 1st instrument in tdoa pair
    h2 = hloc(allTDOA.hpair(itdoa, 2), :); % location of 2nd instrument in tdoa pair
    maxTDOA(itdoa) = sqrt(sum((h1-h2).^2))/allTDOA.c + allTDOA.maxDrift;
end

spd = 60*60*24; % seconds per day
maxTDOA = maxTDOA/spd; % convert to days (for easier comparison)

for wn = 1:numel(CTC)
    i = 0; % counter for total number of possible TDOAs for this whale
    if ~isempty(CTC{wn})

        for ninst = 1:allTDOA.Ninst
            % find all detections that are either unlabeled or labeled as whale wn:
            IndPos{ninst} = find(DET{ninst}.color==2 | DET{ninst}.color==wn+2);
        end
        Ninit = length(CTC{wn}.TDet)*5; % number of indices used for initializing the tables.

        % itialize output table for this whale
        T{wn} = table(nan(Ninit, 1), nan(Ninit, allTDOA.Ninst), nan(Ninit, allTDOA.NTDOA), nan(Ninit, allTDOA.Ninst), ...
            'VariableNames', {'TDet', 'TDetAll', 'TDOA', 'DETind'});

        for ndet = 1:length(CTC{wn}.TDet)


            % which 4ch instruments received this detection?
            I4ch = find(~isnan(CTC{wn}.DETind(ndet, 1:2)));

            if length(I4ch)==1 % only one 4ch instrument received this detection

                [TDOArows, ~] = find(allTDOA.hpair==I4ch); % which TDOA pairs used this instrument

                for itdoa = 1:length(TDOArows) % iterate through all TDOA pairs
                    hpair = allTDOA.hpair(TDOArows(itdoa), :);
                    otherInst = hpair(hpair~=I4ch); % other instrument number

                    % indices of detections that are within maxTDOA:
                    Iclose = find(abs(DET{otherInst}.TDet(IndPos{otherInst}) - CTC{wn}.TDet(ndet))<=maxTDOA(TDOArows(itdoa)));

                    if ~isempty(Iclose)
                        for ic = 1:length(Iclose) 
                            % fill in a new row of T{wn} for each possible
                            % TDOA association

                            i = i+1; % iterate possible TDOA counter

                            % get each detection time:
                            tdet1 = CTC{wn}.TDetAll(ndet, I4ch);
                            tdet2 = DET{otherInst}.TDet(IndPos{otherInst}(Iclose(ic)));

                            T{wn}.TDet(i) = CTC{wn}.TDet(ndet);
                            T{wn}.TDetAll(i, I4ch) = tdet1;
                            T{wn}.DETind(i, I4ch) = CTC{wn}.DETind(ndet, I4ch);

                            T{wn}.TDetAll(i, otherInst) = tdet2;
                            T{wn}.DETind(i, otherInst) = IndPos{otherInst}(Iclose(ic));
                            
                            T{wn}.TDOA(i, TDOArows(itdoa)) = (T{wn}.TDetAll(i, hpair(1)) -  T{wn}.TDetAll(i, hpair(2)))*spd; % calculate TDOA
                            if abs(T{wn}.TDOA(i, TDOArows(itdoa)))>2
    ok = 1;
end
       
                        end

                    end
                end

            elseif length(I4ch)==2 % both 4ch instruments received this detection

                for i4ch = 1:2
                    thisInst = I4ch(i4ch);
                    [TDOArows, ~] = find(allTDOA.hpair==thisInst); % which TDOA pairs used this instrument

                    for itdoa = 1:length(TDOArows) % iterate through all TDOA pairs
                        hpair = allTDOA.hpair(TDOArows(itdoa), :);
                        otherInst = hpair(hpair~=thisInst); % other instrument number

                        Iclose = find(abs(DET{otherInst}.TDet(IndPos{otherInst}) - CTC{wn}.TDet(ndet))<=maxTDOA(TDOArows(itdoa)));

                        if ~isempty(Iclose)
                            for ic = 1:length(Iclose) % add a new row to T for each detection
                                i = i+1; % iterate possible TDOA counter

                                % get each detection time:
                                tdet1 = CTC{wn}.TDetAll(ndet, thisInst);
                                tdet2 = DET{otherInst}.TDet(IndPos{otherInst}(Iclose(ic)));

                                T{wn}.TDet(i) = CTC{wn}.TDet(ndet);
                                T{wn}.TDetAll(i, thisInst) = tdet1;
                                T{wn}.DETind(i, thisInst) = CTC{wn}.DETind(ndet, thisInst);

                                T{wn}.TDetAll(i, otherInst) = tdet2;
                                T{wn}.DETind(i, otherInst) = IndPos{otherInst}(Iclose(ic));
                            
                                T{wn}.TDOA(i, TDOArows(itdoa)) = (T{wn}.TDetAll(i, hpair(1)) -  T{wn}.TDetAll(i, hpair(2)))*spd; % calculate TDOA
if abs(T{wn}.TDOA(i, TDOArows(itdoa)))>2
    ok = 1;
end
                            end

                        end
                    end

                end
            end

        end

        T{wn}((i+1):end, :) = []; % remove excess table entries
    end
end

