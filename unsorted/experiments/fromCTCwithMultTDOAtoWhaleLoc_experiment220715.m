% Load detection data
trackName = 'track43_180327_084016'
% trackName = '180611_1030';

tdir = dir(['*det*', trackName, '*.mat']); 
load(tdir.name)

% load CTC TDOA:
tdir = dir(['*det*', trackName, '*.mat']); 
load(tdir.name)


% Load coarse model:
Mcoarse = load('D:\SOCAL_E_63\tracking\experiments\largeApertureTDOA\TDOAmodel_200m');

% folder containing fine-grid models
MfineFolder = 'D:\SOCAL_E_63\tracking\experiments\largeApertureTDOA\modelFiles_10mFrom200m\';

%% Set parameters for CTC

arrno = 2; % which array is primary array

% assign indices of other arrays
if arrno==1
    otherArrays = [2,3,4];
    hpair{1} = '1-2';
    hpair{2} = '1-3';
    hpair{3} = '1-4';
elseif arrno==2
    otherArrays = [1,3,4];
    hpair{1} = '1-2';
    hpair{2} = '2-3';
    hpair{3} = '2-4';
end