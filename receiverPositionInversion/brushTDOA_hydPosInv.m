function [H, recPos, CI95] = brushTDOA_hydPosInv(varargin)
% Runs GUI to brush TDOA detections. Calculates the hydrophone positions
% and H matrix.
% H = brushDet_hydPosInv prompts user to select files for TDOA, ship
% positions, and parameter file.
%
% brushDet_hydPosInv('TDOA.mat', 'shipLoc.mat') loads data from TDOA.mat
% and shipLoc.mat files and prompts user to select parameter file.
%
% brushDet_hydPosInv(TDOAstruct, shipLocStruct) where TDOA and shipLoc are
% MATLAB structs assumes TDOAstruct.TDOA is NdetxNrec matrix of TDOAs, and
% TDOAstruct.T is the associated time vector.
% shipLocStruct.Lat, shipLocStruct.Lon, and shipLocStruct.T must each be
% Nx1 vectors of the Latitude, Longitude, and Time of the ship locations.
%
% brushDet_hydPosInv(..., paramFile) loads in the parameters in the file
% specified by paramFile.
%
% OUTPUTS: 
% H is the H matrix of vectors drawn between each receiver pair
% recPos are the receiver positions, where receiver 1 is (0,0,0)
% CI95 is a 3x1 vector with the 95% confidence invervals for x, y, and z
% coordinates of the receiver positions calculated by inverting for recPos.

%% Load in data
switch nargin
    case 0
        % select TDOA file
        [file, path] = uigetfile('.mat', 'Select TDOA file', 'Select TDOA file');
        TDOAstruct = load(fullfile(path, file));

        TDOA = TDOAstruct.TDOA; % TDOA of acoustic data
        tAc = TDOAstruct.T; % time of acoustic data

        % select ship position file
        [file, path] = uigetfile('.mat', 'Select ship positions file', 'Select ship positions file');

        shipLocStruct =  load(fullfile(path, file));
        Lat = shipLocStruct.Lat;
        Lon = shipLocStruct.Lon;
        tShip = shipLocStruct.t; % time of ship data

        % select parameter file
        [file, path] = uigetfile('.mat', 'Select ship positions file', 'Select ship positions file');
        loadParams(fullfile(path, file))

    case 1 % Time and TDOA included; no ship positions or parameter file

        if isa(varargin{1}, 'char') % user provided path to TDOA file
            TDOAstruct = load(varargin{1});

            TDOA = TDOAstruct.TDOA; % TDOA of acoustic data
            tAc = TDOAstruct.T; % time of acoustic data

        elseif isa(varargin{1}, 'struct')
            TDOA = varargin{1}.TDOA; % TDOA of acoustic data
            tAc = varargin{1}.T; % time of acoustic data

        else
            errordlg('Invalid input type for TDOA', 'Error')

        end

        % select ship position file
        [file, path] = uigetfile('.mat', 'Select ship positions file', 'Select ship positions file');

        shipLocStruct =  load(fullfile(path, file));
        Lat = shipLocStruct.Lat;
        Lon = shipLocStruct.Lon;
        tShip = shipLocStruct.t; % time of ship data

        % select parameter file
        [file, path] = uigetfile('.mat', 'Select ship positions file', 'Select ship positions file');
        loadParams(fullfile(path, file))

    case 2 % Time and TDOA included; ship positions included; no parameter file

        if isa(varargin{1}, 'char') % user provided path to TDOA file
            TDOAstruct = load(varargin{1});

            TDOA = TDOAstruct.TDOA; % TDOA of acoustic data
            tAc = TDOAstruct.T; % time of acoustic data

        elseif isa(varargin{1}, 'struct') % user provided TDOA struct
            TDOA = varargin{1}.TDOA; % TDOA of acoustic data
            tAc = varargin{1}.T; % time of acoustic data

        else
            errordlg('Invalid input type for TDOA', 'Error')

        end

        if isa(varargin{2}, 'char') % user provided path to ship lat/lon/t file
            shipLocStruct = load(varargin{2});

            Lat = shipLocStruct.Lat;
            Lon = shipLocStruct.Lon;
            tShip = shipLocStruct.T; % time of ship data

        elseif isa(varargin{2}, 'struct') % user provided  to ship lat/lon/t struct
            Lat = varargin{2}.Lat;
            Lon = varargin{2}.Lon;
            tShip = varargin{2}.T; % time of ship data

        else
            errordlg('Invalid input type for ship lat/lon/z', 'Error')

        end


        % select parameter file
        [file, path] = uigetfile('.params', 'Select parameter file');
        loadParams(fullfile(path, file))

    case 3 % all variables included
        if isa(varargin{1}, 'char') % user provided path to TDOA file
            TDOAstruct = load(varargin{1});

            TDOA = TDOAstruct.TDOA; % TDOA of acoustic data
            tAc = TDOAstruct.T; % time of acoustic data

        elseif isa(varargin{1}, 'struct') % user provided TDOA struct
            TDOA = varargin{1}.TDOA; % TDOA of acoustic data
            tAc = varargin{1}.T; % time of acoustic data

        else
            errordlg('Invalid input type for TDOA', 'Error')

        end

        if isa(varargin{2}, 'char') % user provided path to ship lat/lon/t file
            shipLocStruct = load(varargin{1});

            Lat = shipLocStruct.Lat;
            Lon = shipLocStruct.Lon;
            tShip = shipLocStruct.T; % time of ship data

        elseif isa(varargin{2}, 'struct') % user provided  to ship lat/lon/t struct
            Lat = varargin{2}.Lat;
            Lon = varargin{2}.Lon;
            tShip = varargin{2}.T; % time of ship data

        else
            errordlg('Invalid input type for ship lat/lon/z', 'Error')

        end

        loadParams(varargin{3})

end

% Set up necessary variables
global TDOAbrush

c = TDOAbrush.c; % sound speed
TDOAbrush.TDOA = TDOA;

TDOAbrush.Nrec = size(TDOAbrush.TDOA, 2); % number of receivers
spd = 60*60*24; % seconds per day

% get cartesian position of ship in relation to receiver:
[x, y] = latlon2xy_wgs84(Lat, Lon, TDOAbrush.recLoc(1), TDOAbrush.recLoc(2));

% adjust ship time stamp for travel time
R = sqrt(x.^2 + y.^2 + TDOAbrush.recLoc(3).^2); % distance between ship and hydrophone
travelTime = R/c; % estimate of travel time between ship and hydrophone
tShip = tShip + travelTime./spd;

% time frame for analysis
t1 = max([tShip(1), tAc(1)]);
t2 = min([tShip(end), tAc(end)]);

I = find(tAc>=t1 & tAc<=t2); % Find indices where there are overlapping ship and acoustic time stamps
TDOAbrush.t = tAc(I); % time vector used for interpolation and inversions
TDOAbrush.TDOA = TDOAbrush.TDOA(I, :);

% Get interpolated ship positions (interpolated to match acoustic time
% stamps)
xi = interp1(tShip, x, TDOAbrush.t);
yi = interp1(tShip, y, TDOAbrush.t);
zi = ones(size(xi)).*abs(TDOAbrush.recLoc(3)); % positive zi since ship is about hydrophone
Ri = sqrt(xi.^2 + yi.^2 + zi.^2); % distance between ship and hydrophone

% Set up matrices for inversion:
% NOTE: a simpler inversion is used for the brushing GUI portion, where the
% H matrix is solved for using H = S\D. For the final hydrophone positions
% and H matrix, a more precise inversion is used which solves only for the
% hydrophone positions.


if size(xi, 1) == 1
    TDOAbrush.S = ([xi.', yi.', zi.'])./Ri.'; % unit vector pointing from hydrophone to ship
elseif size(xi, 1)>1
    TDOAbrush.S = ([xi, yi, zi])./Ri; % unit vector pointing from hydrophone to ship
end
TDOAbrush.H = (-TDOAbrush.S\(TDOAbrush.TDOA.*TDOAbrush.c)).'; % initial H matrix estimate

% Calculate expected TDOA based on ship locations and assumed H Matrix
TDOAbrush.TDOAexp = -(TDOAbrush.S*TDOAbrush.H.')./c;

run_brushTDOA

qselect = input('\nEnter ''q'' to quit: ', 's');

calcFinalH

H = TDOAbrush.H;
recPos = TDOAbrush.recPos;
CI95 = TDOAbrush.CI95;
recLoc = TDOAbrush.recLoc;
stdev = TDOAbrush.stdev;

[file,path] = uiputfile('harp4chParams')

save(fullfile(path, file(1:end-7)), 'H', 'recLoc', 'recPos', 'CI95', 'c', 'stdev')

end

%% Run brushTDOA GUI
function run_brushTDOA
global TDOAbrush

fig = findall(0, 'Type', 'figure', 'name', 'Brush TDOA');
if isempty(fig)
    fig = figure('Name', 'Brush TDOA');
end

% make TDOA plots
for np = 1:TDOAbrush.Nrec
    subplot(TDOAbrush.Nrec, 1, np)
    plot(TDOAbrush.t, TDOAbrush.TDOA(:, np), '.')
    hold on
    plot(TDOAbrush.t, TDOAbrush.TDOAexp(:, np), '.')
    hold off
    ylabel(['pair', num2str(np)])
    datetick
    grid on
end
legend('Measured', 'Expected')
title('TDOA')
xlabel('Time')
brush on



hManager = uigetmodemanager(fig);
[hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2 (on 2014b or later)
set(fig, 'KeyPressFcn', @keyPressCallback);

end


function keyPressCallback(source,eventdata)

global TDOAbrush

key = eventdata.Key;

switch key
    case 'd' % d for delete
        % Get indices for highlighted points

        % iterate through each subplot
        % (note: source.Children(1) is likely the legend, so iteration is
        % through 2:Npair+1

        Irem = [];
        for np = 2:numel(source.Children)
            for nlines = 1:2
                I = find(source.Children(np).Children(nlines).BrushData~=0);

                Irem = [Irem, I];


            end
        end

        
        TDOAbrush.TDOA(Irem, :) = [];
        TDOAbrush.t(Irem) = [];
        TDOAbrush.S(Irem, :) = [];
        
        % recalculate H matrix and expected TDOA:
        TDOAbrush.H = (-TDOAbrush.S\(TDOAbrush.TDOA.*TDOAbrush.c)).'; 
        TDOAbrush.TDOAexp = -(TDOAbrush.S*TDOAbrush.H.')./TDOAbrush.c;

        % update plots
        for np = 2:numel(source.Children)
            tdoaNum = str2double(source.Children(np).YLabel.String(5));

            set(source.Children(np).Children(1), 'xdata', TDOAbrush.t, 'ydata', TDOAbrush.TDOAexp(:, tdoaNum));
            set(source.Children(np).Children(2), 'xdata', TDOAbrush.t, 'ydata', TDOAbrush.TDOA(:, tdoaNum));

            source.Children(np).Children(1).BrushData = []; % unbrush all points
            source.Children(np).Children(2).BrushData = []; % unbrush all points
        end

    case 'a' % automatically remove points
        autoRemove
end

end

%%
function autoRemove

global TDOAbrush
    
maxIter = length(TDOAbrush.t)/4; % don't remove more than 25% of the data

err = abs(TDOAbrush.TDOA - TDOAbrush.TDOAexp);

errstd = std(err); 

i = 0; 
while max(errstd)>0.01e-3 && i<maxIter
    i = i+1;

    % remove worst datapoint from each TDOA 
    [~, Ind] = max(err); % find datapoints of max error in each TDOA

    TDOAbrush.TDOA(Ind, :) = [];
    TDOAbrush.t(Ind) = [];
    TDOAbrush.S(Ind, :) = [];

    % recalculate H matrix and expected TDOA:
    TDOAbrush.H = (-TDOAbrush.S\(TDOAbrush.TDOA.*TDOAbrush.c)).';
    TDOAbrush.TDOAexp = -(TDOAbrush.S*TDOAbrush.H.')./TDOAbrush.c;
    
    err = abs(TDOAbrush.TDOA - TDOAbrush.TDOAexp);
    errstd = std(err);
    
end


% update plots
fig = findall(0, 'Type', 'figure', 'name', 'Brush TDOA');
for np = 2:numel(fig.Children)
    tdoaNum = str2double(fig.Children(np).YLabel.String(5));

    set(fig.Children(np).Children(1), 'xdata', TDOAbrush.t, 'ydata', TDOAbrush.TDOAexp(:, tdoaNum));
    set(fig.Children(np).Children(2), 'xdata', TDOAbrush.t, 'ydata', TDOAbrush.TDOA(:, tdoaNum));

    fig.Children(np).Children(1).BrushData = []; % unbrush all points
    fig.Children(np).Children(2).BrushData = []; % unbrush all points
end


end

function calcFinalH
% This inverts for the optimal position of each hydrophone, rather than the
% H matrix. It's a little more involved and I'm not sure how to explain
% the process in code comments. 

% The goal is to solve the equation:
% hpos = inv(G'*Rinv*G)*G'*Riv*D
% hpos are the hydrophone positions of h2, h3, and h4 (h1=<0,0,0>)
% stacked in a 9x1 vector; 
% D = TDOA*c, or the distance traveled by the wave between receivers
% G are the vectors pointing towards the ship
%
% Example of the math:
% the forward problem for hydrophone pair h2-h3 is:
% d = -s*h
% where d = TDOA*c for that pair, h = h2-h3, and s=unit vector pointing
% towards ship. This breaks out into: 
% d = -(h2x-h3x)*sx - (h2y-h3y)*sy - (h2z-h3z)*sz
%   = -h2x*sx + h3x*sx - h2y*sy + h3y*sy - h2z*sz + h3z*sz
% This can be rewritten as a vector g containing the s vector, and a vector
% hpos containing the hydrophone coordinates (where h1=<0,0,0>).
% hpos = [h2x, h2y, h2z, h3x, h3y, h3z, h4x, h4y, h4z];
% g = [-sx, -sy, -sz, sx, sy, sz, 0, 0, 0];
% d = hpos*g will solve the same algebraic problem as d=-s*h
%
% So, the TDOAs are reshaped from an Nx6 matrix into an N*6x1 matrix, where
% the 1st, 7th, 13th, etc elements are for pair h1-h2, the 2nd, 8th, and
% 14th are for h1-h3, and so on. 
% G becomes a N*6 x 9 matrix of s as shown with g.  

global TDOAbrush

G = zeros(length(TDOAbrush.t)*6, 9);

Ni = 1:6:(length(TDOAbrush.t)*6); % rows corresponding to h1-h2

% pair 1 (h1-h2), where h1=<0,0,0>
G(Ni, [1,2,3]) = TDOAbrush.S;
D(Ni) = TDOAbrush.TDOA(:, 1).*TDOAbrush.c;

% pair 2 (h1-h3), where h1=<0,0,0>
G(Ni+1, [4,5,6]) = TDOAbrush.S;
D(Ni+1) = TDOAbrush.TDOA(:, 2).*TDOAbrush.c;

% pair 3 (h1-h4), where h1=<0,0,0>
G(Ni+2, [7,8,9]) = TDOAbrush.S;
D(Ni+2) = TDOAbrush.TDOA(:, 3).*TDOAbrush.c;

% pair 4 (h2-h3), where h1=<0,0,0>
G(Ni+3, [1,2,3]) = -TDOAbrush.S;
G(Ni+3, [4,5,6]) = TDOAbrush.S;
D(Ni+3) = TDOAbrush.TDOA(:, 4).*TDOAbrush.c;

% pair 5 (h2-h3), where h1=<0,0,0>
G(Ni+4, [1,2,3]) = -TDOAbrush.S;
G(Ni+4, [7,8,9]) = TDOAbrush.S;
D(Ni+4) = TDOAbrush.TDOA(:, 5).*TDOAbrush.c;

% pair 6 (h3-h4), where h1=<0,0,0>
G(Ni+5, [4,5,6]) = -TDOAbrush.S;
G(Ni+5, [7,8,9]) = TDOAbrush.S;
D(Ni+5) = TDOAbrush.TDOA(:, 6).*TDOAbrush.c;

% start doing the inverse
rinv = 1/(TDOAbrush.c*2e-2); % one element in the matrix R^-1
Rinv = rinv.*eye(length(G));

hpos = inv(G'*Rinv*G)*G'*Rinv*D.';

% calculate the 95% confidence intervals
Cxx = inv(G'*Rinv*G); 
Cxxdiag = diag(Cxx); % autocorrelation
stdev = sqrt(Cxxdiag); % standard deviation

SEM = stdev./sqrt(length(G)); 

alpha = 1-.95;
ts = tinv([alpha/2, 1-alpha/2], length(G)-1);

CIxyz = hpos + SEM*ts; 

h_moves = abs(hpos - CIxyz); % the 95% CI for each hydrophone coordinate. 
% It should be the same for every hydrophone, and for above and below each.

CI95 = h_moves(1:3, 1);

% calculate H matrix
H(1, :) = hpos(1:3);                % vector from h1->h2, (i.e. h2-h1 where h1=<0,0,0>)
H(2, :) = hpos(4:6);                % h1->h3
H(3, :) = hpos(7:9);                % h1->h4
H(4, :) = -hpos(1:3) + hpos(4:6);   % h2->h3
H(5, :) = -hpos(1:3) + hpos(7:9);   % h2->h4
H(6, :) = -hpos(4:6) + hpos(7:9);   % h3->h4

% set all array values to be stored
TDOAbrush.H = H;
TDOAbrush.recPos(1, :) = [0,0,0]; 
TDOAbrush.recPos(2, :) = hpos(1:3);
TDOAbrush.recPos(3, :) = hpos(4:6);
TDOAbrush.recPos(4, :) = hpos(7:9);
TDOAbrush.CI95 = CI95;
TDOAbrush.stdev = stdev;

% plot 3D array elements
figure('Name', 'Receiver Locations')
for np = 1:4
    plot3(TDOAbrush.recPos(np,1), TDOAbrush.recPos(np,2), TDOAbrush.recPos(np,3), '.', 'markersize', 25)
    hold on
end
legend('Rec 1', 'Rec 2', 'Rec3', 'Rec4')
title('Receiver Locations in relation to receiver 1')
xlabel('E-W (m)')
ylabel('N-S (m)')
zlabel('Depth (m)')
grid on

% Plot H matrix
dh = sqrt(sum(H.^2, 2));
dhCI95 = sqrt(sum(CI95.^2)); % confidence interval for distance between hydrophones
figure('Name', 'Distance Between Hydrophones')
plot(dh, '.', 'markersize', 25)
hold on
errorbar(1:6, dh, dhCI95.*ones(size(dh)), dhCI95.*ones(size(dh)), 'linewidth', 1.5)
hold off
title('Distance between hydrophones')
ylabel('Distance (m)')
xticks(1:6)
xticklabels({'1-2', '1-3', '1-4', '2-3', '2-4', '3-4'})
xlabel('pair')

end

