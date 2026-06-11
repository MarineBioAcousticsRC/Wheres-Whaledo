function whereswhaledo

% whereswhaledo.m
%
% Where'sWhaledo is a TDOA/DOA localization software package created by the
% Marine Bioacoustics Research Collaborative (MBARC; https://mbarc.ucsd.edu)
% at Scripps Institution of Oceanography to track echolocating marine mammals, 
% optimized for use with small-aperture tetrahedral hydrophone arrays.
% 
% Where'sWhaledo v2.0 was created by Lauren Baggett (GitHub @laurenbaggett)
% and is the most updated version. Version 1.0 of this software was initially 
% created by Dr. Eric Snyder (GitHub @ericSnyderSIO).
% 
% This repository is currently maintained by Lauren Baggett. Any feedback
% or questions should be directed to lbaggett@ucsd.edu.
%
% New and archived versions of Where'sWhaledo are available at
% https://github.com/MarineBioAcousticsRC/Wheres-Whaledo
%
% If you use this software in published work, please cite:
% - Baggett et al., 2025 (https://doi.org/10.1038/s41598-025-24490-x)
% - Snyder et al., 2024 (https://doi.org/10.1371/journal.pcbi.1011456)

clear global; % clear any preloaded global variables
clc; % clear command window
close all force;  % close all windows

global PARAMS HANDLES % declare global variables


PARAMS.MATLAB_ver = version; % MATLAB version
PARAMS.software_name = 'Where''sWhaledo'; % Where's Whaledo software
PARAMS.software_ver = '2.0'; % version release 2.0
PARAMS.wiki = 'https://github.com/MarineBioAcousticsRC/Wheres-Whaledo/wiki'; % link to the wiki for assistance
PARAMS.help = 'lbaggett@ucsd.edu'; % email for assistance
PARAMS.conversion.spd = 60*60*24; % number of seconds per day, for datenum conversions
PARAMS.path.repo = fullfile(fileparts(which('whereswhaledo'))); % path to the repo on the user's machine
PARAMS.path.images = fullfile(fileparts(which('whereswhaledo')), 'images'); % finds the folder where the logo lives
PARAMS.path.precalcEnsembles =  [fullfile(fileparts(which('whereswhaledo')), 'ww'), '\instrument_orientation\precalculated_ensembles']; % finds folder where precalculated orientations live
PARAMS.ui.anchor = "top-left"; % anchor windows in the top left
PARAMS.ui.wFrac = 0.8; % fraction of screen width to popup window
PARAMS.ui.hFrac = 0.8; % fraction of screen height to popup window
PARAMS.ui.marginFrac = 0.02; % define margin fraction of screen

% print information to the command window
fprintf('\n');
fprintf(' Starting %s v%.1f\n', char(PARAMS.software_name), str2double(PARAMS.software_ver));
fprintf(' Marine Bioacoustics Research Collaborative (MBARC)\n\n')
fprintf(' You are using MATLAB version: %s\n', PARAMS.MATLAB_ver);
fprintf(' Support can be found at: %s\n', PARAMS.wiki)

init_ww_gui(); % launch GUI
