% fp{1} = 'D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track369_180520_120810\SOCAL_E_63_track369_180520_120810_ericMod_localized.mat';
fp{2} = 'D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track30_180324_205700\SOCAL_E_63_track30_180324_205700_ericMod_localized.mat';
% fp{3} = 'D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track15_180320_060600\SOCAL_E_63_track15_180320_060600_ericMod_localized.mat';
fp{4} = 'D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track179_180422_091708\SOCAL_E_63_track179_180422_091708_ericMod_localized.mat';
fp{5} = 'D:\SOCAL_E_63\tracking\interns2022\ericEdits_allTracks\track600_180611_110414\SOCAL_E_63_track600_180611_110414_ericMod_localized.mat';

hyd1 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EE_Hmatrix_fromHydLocInversion_210702.mat');
hyd2 = load('D:\SOCAL_E_63\tracking\experiments\inverseProblem\matfiles\SOCAL_E_63_EW_Hmatrix_fromHydLocInversion_210702.mat');

% HEW = H;

% Reorder hydrophones to fit new TDOA order
H{1} = [hyd1.hydPos(2,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(1,:);
    hyd1.hydPos(3,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(2,:);
    hyd1.hydPos(4,:)-hyd1.hydPos(3,:)];

H{2} = [hyd2.hydPos(2,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(1,:);
    hyd2.hydPos(3,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(2,:);
    hyd2.hydPos(4,:)-hyd2.hydPos(3,:)];

load('D:\Writing\wheresWhaledo\figures\tracks\hydLoc.mat')

% load drift:
load('D:\SOCAL_E_63\tracking\experiments\clockSync\drift.mat');
dp{1} = coeffvalues(Dpoly{1}); % drift coefficients between inst 1 and 2
dp{2} = coeffvalues(Dpoly{2}); % drift coefficients between inst 1 and 3
dp{3} = coeffvalues(Dpoly{3}); % drift coefficients between inst 1 and 4
dp{4} = coeffvalues(Dpoly{4}); % drift coefficients between inst 2 and 3
dp{5} = coeffvalues(Dpoly{5}); % drift coefficients between inst 2 and 4
dp{6} = coeffvalues(Dpoly{6}); % drift coefficients between inst 3 and 4

for ifp = numel(fp)
    load(fp{ifp})
    whale = brushTDOA(whale, H);
    whale = localize(whale, h, H{1}, H{2}, dp);
    save([fp{ifp}(1:end-4), '_cleaned.mat'], 'whale')
    clear whale
end