function [ result ] = TSwriteoutfunctions(ScriptName)
% Reads the script (.m) or text (.txt) file SCRIPTNAME containing TSlib 
% functions, reads each function, and writes it into a file with the name 
% of that function. The file name passed in (ScriptName) must have either
% the .m or the .txt extension included.
result = 0;
raw = fileread(ScriptName);
c = strfind('.',ScriptName);
if strcmp('m',ScriptName(c+1)) % script filed
    r = strfind(raw,'TSlib functions called by this script');
    raw(1:r) = []; % deleting script itself, leaving only the TSlib and helper
    % functions
end
mkdir('TSlib')
cd TSlib
rb = strfind(raw,'startfunction')+13; % first lines of functions
re = strfind(raw,'endfunction')-1; % last lines of functions
for i = 1:length(rb) % stepping through the functions
    str = raw(rb(i):re(i));
    BfName = strfind(str,'funName:')+9;
    EfName = strfind(str,'EndOfFunName')-1;
    Bfun = strfind(str,'EndOfFunName')+13;
    fName = str(BfName:EfName);
    fid = fopen(fName,'w');
    fprintf(fid,'%s',str(Bfun:end));
    fclose(fid);    
end
addpath(cd)
fprintf('\nThe TS Toolbox functions have been written into the newly created\nTSlib folder, and it has been added to Matlab''s search path\n')
result = 1;