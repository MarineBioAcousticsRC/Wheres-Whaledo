function [TDOA, wloc] = makeModel(xv, yv, zv, h, H1, H2, c, varargin)
% [TDOA, wloc] = makeModel(xv, yv, zv, h, H1, H2, c) - generates TDOA
% models for all grid points defined by xv, yv, and zv using hydrphone
% positions h. H1 and H2 are small aperture array H matrices. c is sound
% speed.
% [TDOA, wloc] = makeModel(xv, yv, zv, h, H1, H2, c, 'DOA') - 'DOA'
% specifies that only the DOA intersect was used between two four-channel
% arrays. In this case, no large-aperture TDOAs are calculated.

% make wloc (matrix of whale positions)
[cx, cy, cz] = ndgrid(xv, yv, zv);
wloc = [cx(:), cy(:), cz(:)];

s{1} = wloc-h(1, :);
r1 = sqrt(sum(s{1}.^2, 2)); % range to instrument 1
s{1} = s{1}./r1; % direction vector to instrument 1

s{2} = wloc-h(2, :);
r2 = sqrt(sum(s{2}.^2, 2)); % range to instrument 2
s{2} = s{2}./r2; % direction vector to instrument 2

% small aperture TDOAs
TDOA(:, 1:6) = (s{1}*H1.')./c;
TDOA(:, 7:12) = (s{2}*H2.')./c;

if nargin==7 % need to calculate large ap. TDOAs

    % large aperture TDOAs
    numh = size(h, 1); % number of hydrophones
    switch numh
        case 2 % only two arrays, calculate one large-aperture TDOA
            TDOA(:, 13) = (r1-r2)./c;

        case 3 % two arrays and one single channel, calculate three large-aperture TDOAs

            s{3} = wloc-h(3, :);
            r3 = sqrt(sum(s{3}.^2, 2)); % range to instrument 3

            TDOA(:, 13) = (r1-r2)./c;
            TDOA(:, 14) = (r1-r3)./c;
            TDOA(:, 15) = (r2-r3)./c;
        case 4 % 2 arrays and 2 single channels, calculate 6 large ap TDOAs

            s{3} = wloc-h(3, :);
            r3 = sqrt(sum(s{3}.^2, 2)); % range to instrument 3

            s{4} = wloc-h(4, :);
            r4 = sqrt(sum(s{4}.^2, 2)); % range to instrument 4

            TDOA(:, 13) = (r1-r2)./c;
            TDOA(:, 14) = (r1-r3)./c;
            TDOA(:, 15) = (r1-r4)./c;
            TDOA(:, 16) = (r2-r3)./c;
            TDOA(:, 17) = (r2-r4)./c;
            TDOA(:, 18) = (r3-r4)./c;

    end
end
end