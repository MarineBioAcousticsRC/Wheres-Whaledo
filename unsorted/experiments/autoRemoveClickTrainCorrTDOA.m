load('track43_180327_084016_CTC_Array2.mat')
% load('180611_1030_CTC_Array2')
% load('clickTrain')
M = load('B:\TDOAmodel_200m.mat');
load('sigmaValues.mat')

% Parameters:
SNRthresh1 = .9;

spd = 24*60*60;
twin = 2*60;

for wn = 1:numel(whale)

    if ~isempty(whale{wn})
        figure(wn)
        for pn = 1:3
            I = find(whale{wn}.SNR(:, pn, 1)>SNRthresh1);

            if length(I)>5

                titer = whale{wn}.TDet(I(1))+twin/(2*spd);
                iter = 0;
                Ifit = 0;

                while titer<=whale{wn}.TDet(I(end))
                    iter = iter+1;

                    innerWindow = find(abs(whale{wn}.TDet(I)-titer)<=twin/(2*spd));
                    outerWindow = find(abs(whale{wn}.TDet(I)-titer)<=twin/(spd));
                    if ~isempty(innerWindow)
                        tdoa = whale{wn}.TDOA(I(innerWindow), pn, 1);
                        tdoaOuter = whale{wn}.TDOA(I(outerWindow), pn, 1);
                        wts = whale{wn}.SNR(I(innerWindow), pn, 1);
                        wtsOuter = whale{wn}.SNR(I(outerWindow), pn, 1);
                        tdet = whale{wn}.TDet(I(innerWindow));
                        tdetOuter = whale{wn}.TDet(I(outerWindow));

                        aveWhale{wn}.TDet(iter) = sum(wts.*tdet.')./sum(wts);

                        aveWhale{wn}.TDOA(iter, pn) = sum(wts.*tdoa)./sum(wts);
                        aveWhale{wn}.meansnr(iter, pn) = mean(wts);

                        W = diag(wtsOuter);
                        T = [(tdetOuter-tdetOuter(1)); ones(size(tdetOuter))].';
                        M = (W*T)\(wtsOuter.*tdoaOuter);
                        
                        Ifit = (1:length(tdet)) + max(Ifit);

                        tdoaFit = [(tdet-tdetOuter(1)); ones(size(tdet))].'*M;

                        linFit{wn}.TDOA(Ifit, pn) = tdoaFit;
                        linFit{wn}.TDet(Ifit) = tdet;
                        linFit{wn}.LMSE = (tdoa-tdoaFit).^2;
                    end
                    titer = titer+twin/(spd);

                end
                subplot(3,1,pn)
                scatter(whale{wn}.TDet(I), whale{wn}.TDOA(I, pn, 1), whale{wn}.SNR(I, pn, 1), 'filled')
                datetick
                hold on
%                 plot(aveWhale{wn}.TDet, aveWhale{wn}.TDOA(:, pn), 'r*')
%                 plot(linFit{wn}.TDet, linFit{wn}.TDOA(:,pn), 'x')
                hold off


                ok = 1;
            end
        end
    end
end