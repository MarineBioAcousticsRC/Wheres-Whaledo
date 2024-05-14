
weights = [0.5 0.1 0.1 0.1 0.1 0.1]';
t = randi(1, 1);
weightedCounts = bootstrp(50,@(tdoa_sml)(loc(tdoa_sml, tdoa_lrg)),(1:6)','Weights',weights);

function numberofones = countfun(sample, t)
numberofones = sum(sample == 1) + t;
end