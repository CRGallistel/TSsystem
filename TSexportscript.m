function TSexportscript(NameOfScriptFile)
% reads Experiment-building script out of the Experiment.Script field into
% a Matlab .m newly created script file in the current directory. If there
% is already a file with the specified name, its contents will be
% overwritten
%
% Syntax: TSexportscript(NameOfScriptFile)
%
% NameOfScriptFile must be a string specifying the name to be given to the
% file into which the script will be exported--without any extension,
% because a .m extension will be added, The resulting script will look like
% the original but without blank lines

global Experiment

if isempty(Experiment)
    fprintf('\n\nThere is no Experiment structure in the workspace\n')
    return
elseif ~isfield(Experiment,'Script')
    fprintf('\n\nThere is no Script field at the Experiment level\n')
    return
end

if exist([NameOfScriptFile '.m'],'file')
    if strcmp('n',input('\n\nThere is a .m file with that name in the current directory.\nOverwrite it? [y/n] ','s'))
        return
    end
end
        

CellArray = cellstr(Experiment.Script); % makes each row of the character
% array into a cell containing the characters in that row--with trailing
% white spaces suppressed (hence, also blank lines)

fid = fopen(sprintf('%s.m',NameOfScriptFile),'w'); %  creating a file with
% the specified name and opening it for writing

for r=1:size(CellArray,1) % stepping through the rows of the script
    if isempty(CellArray{r})
        fprintf(fid,'\n'); % blank line
    else
        fprintf(fid,'%s\n',CellArray{r,:}); % writing each row
    end
end
fclose(fid); % closing the file

fprintf('\n\nThe code in the Experiment.Script field\nhas been written to the file %s\n',[NameOfScriptFile '.m'])