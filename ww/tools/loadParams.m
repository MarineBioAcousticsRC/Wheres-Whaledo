function loadParams(filename)
% read in parameter file
% NOTE: parameter file must use a global variable defined within.

fid = fopen(filename, 'r');
while ~feof(fid)
    tline = fgets(fid);
    eval(tline)
end
fclose(fid);

end