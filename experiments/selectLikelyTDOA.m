% trackName = 'track43_180327_084016'
trackName = '180611_1030';
tdir = dir(['*clickByClick_roughTDOA*', trackName, '*.mat']);
load(tdir.name)

spd = 60*60*24;
vwhale = 3; % maximum speed of source, m/s
c = 1488.4;
terr = .8e-3; % max error in TDOA (2x approx signal duration, seconds)
maxTDOAslope = 2*vwhale/c + terr; % maximum change in TDOA per second

for nw =  3%unique(label)
    Ilab = find(label==nw);     % whales with label nw

    for np = 1:3 % iterate through each TDOA pair
        for nlike = 1:size(TDOA, 3) % all possible TDOAs for this detection
            Ind = find(TDOA(Ilab, np, nlike)>-10);
            

            tdoa = TDOA(Ilab(Ind), np, nlike);
            tdet = TDet(Ilab(Ind));

            
            
           
        end
    end
end