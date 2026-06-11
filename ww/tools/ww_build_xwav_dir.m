function XH = ww_build_xwav_dir(xwavPath);

% ww_build_xwav_dir()
%
% function that builds a list of all xwav files in a directory
% input: xwav file path
% output: directory of xwav files within that path (checks subfolders)

XH = dir(xwavPath + "\**\*.x.wav");





end