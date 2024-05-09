% localize_grace

hloc =  [519.0111,  130.8736,   2.1721;
        -519.0247, -130.8466,  -2.1721;
        -153.1411,  513.4609,  -2.4135;
        -177.5483, -453.0182,  -5.4382];

H1 = [0.4936   -0.1133   -0.8183;
   -0.4437   -0.3424   -0.7987;
   -0.1294    0.5832   -0.7729;
   -0.9374   -0.2291    0.0196;
   -0.6230    0.6965    0.0455;
    0.3144    0.9256    0.0259];

H2 = [0.6385    0.0851   -0.7919;
   -0.1502   -0.5297   -0.7824;
   -0.3141    0.3986   -0.8015;
   -0.7887   -0.6148    0.0094;
   -0.9526    0.3135   -0.0096;
   -0.1638    0.9284   -0.0190];

c = 1488.4

xv = -2000:20:2000;
yv= -2000:20:2000;
zv = -10:10:1000;

[M.TDOA, M.wloc] = makeModel(xv, yv, zv, hloc, H1, H2, c);

save('model_20x20y10z', 'M')

function [TDOA, wloc] = makeModel(xv, yv, zv, h, H1, H2, c)

% make wloc (matrix of whale positions)
[cx, cy, cz] = ndgrid(xv, yv, zv);
wloc = [cx(:), cy(:), cz(:)];

s1 = wloc-h(1, :);
r1 = sqrt(sum(s1.^2, 2)); % range to instrument 1
s1 = s1./r1; % direction vector to instrument 1

s2 = wloc-h(2, :);
r2 = sqrt(sum(s2.^2, 2)); % range to instrument 2
s2 = s2./r2; % direction vector to instrument 2

s3 = wloc-h(3, :);
r3 = sqrt(sum(s3.^2, 2)); % range to instrument 3

s4 = wloc-h(4, :);
r4 = sqrt(sum(s4.^2, 2)); % range to instrument 4

% small aperture TDOAs
TDOA(:, 1:6) = (s1*H1.')./c;
TDOA(:, 7:12) = (s2*H2.')./c;

% large aperture TDOAs
TDOA(:, 13) = (r1-r2)./c;
TDOA(:, 14) = (r1-r3)./c;
TDOA(:, 15) = (r1-r4)./c;
TDOA(:, 16) = (r2-r3)./c;
TDOA(:, 17) = (r2-r4)./c;
TDOA(:, 18) = (r3-r4)./c;

end
