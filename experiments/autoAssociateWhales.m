function outDET = autoAssociateWhales(inDET, arrno, twin, fsct)
% DET = autoAssociateWhales(DET, twin, arrno)
% automatically associates whales from one labeled array to one unlabeled
% array using click-train-correlation.
% inDET is the input detection table
% twin is the window length used around each click in the click train
% correlation
% arrno is the array whose labels will be used. The other array will be
% matched to this one.

outDET = inDET;

wlabels = unique(outDET{arrno}.color);
spd = 60*60*24;

if arrno==1
    otherArray=2;
else
    otherArray=1;
end

for wn = 1:length(wlabels)
    Ind = find(outDET{arrno}.color==wlabels(wn)); % indices of detections with label wlabels(wn)
    for idet = 1:length(Ind)
        tdet = outDET{arrno}.TDet(Ind(idet)); % detection being examined
        
        tct = (-twin/2:1/fsct:twin/2)./spd + tdet;
        
        

        ok = 1;
    end
    
end