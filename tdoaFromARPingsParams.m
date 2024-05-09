% PARAMS file for tdoaFromARPings

global shipTDOA

shipTDOA.loadSegmentSize = 30; % size of the segment to load (seconds)
shipTDOA.xcovSegmentSize = 1;  % size of window used in xcov (seconds)

shipTDOA.fs = 100e3; % Sampling rate

shipTDOA.fc = [1000, 5000]; % cutoff frequencies of bandpass filter

shipTDOA.ixcov = [2, 3, 4, 7, 8, 12]; % columns of xcov to use for TDOA

shipTDOA.hydLoc = [33.53472  -120.25518  -1322.6153]; % localized position

shipTDOA.c = 1482.965459; % sound speed