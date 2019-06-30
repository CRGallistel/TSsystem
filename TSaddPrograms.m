%-----------------------help for TSaddPrograms.m------------------------------
%
%TSaddPrograms:
%This function places the MedPC program in the Experiment.Programs field and
%puts the index number for that program in the last loaded session's Program
%field (Experiment.Subject(end).Session(end).Program). Its arguments are
%the filename, the subject number(sub), and the session number(ses). The syntax is the following:
%
%  TSaddPrograms(filename,sub,ses);
%
%When the Experimental Structure is created (see TSinitExperiment) a
%Program field is created on the Experimental level that holds 
%the programs from the experiment. The fields are:
%
%               Name: Displays the filename of the program
%               Code: Displays the MedPC code
%
%TSinitexperiment defaults both these fields to 'No Programs Loaded'
%
% TSaddPrograms calls Matlab's readtextfile command, which will throw an
% error if the file being read contains any lines with only a line return.
% There are two remedies: 1) Open the program file in a word processor or
% text editor and do a find (^p) and replace (^p space); or 2) open Matlab's
% readtextfile command, which is editable, find all instances of the fgetl
% command and replace with fgets
%
%SEE ALSO: readtextfile.m, TSinitexperiment.m, TSLoadMEDPC.m

%% Compare Programs.

function [result, Err]=TSaddPrograms(Program_filename,sub,ses)

result = 0;
Err=[];

global Experiment;

isDuplicate = false;
numProgs = length(Experiment.Programs.Program);

if ~exist(Program_filename)
    
    'Cannot find program; change directory or provide proper path'
    
    return
    
end

try
   mainProg = readtextfile(Program_filename);
catch ME
    display(strvcat('The program file cannot be loaded because it',...
        'contains one or more lines with only a',...
        ' linefeed. See help TSaddPrograms for remedies.'));
    display(ME)
    return
end

stripFileName = find(Program_filename(1:end) == '\');  %strip away the path and leave only the file name
if stripFileName > 0
    Program_filename = Program_filename(stripFileName(end)+1:end); % file name alone is the text
    % after the last \
end


if isequal('No Programs Loaded',Experiment.Programs.Program(numProgs).Code) % if no program has been loaded
    Experiment.Programs.Program(numProgs) = struct('Name', Program_filename, 'Code',mainProg); % load filename
    Experiment.Subject(sub).Session(ses).Program = numProgs;
    disp (['Program ' Program_filename ' added to Experimental Structure.']);
    return;
end

disp 'Comparing programs...'
for i = 1:numProgs
    %disp (['Comparing programs: ' filename ' and ' Experiment.Programs.Program(i).Name])
    if isequal(mainProg,Experiment.Programs.Program(i).Code)
        isDuplicate = true;
        dupProgIndex = i;
        break;
    end % end if
end % end for

if isDuplicate
    Experiment.Subject(sub).Session(ses).Program = dupProgIndex; % putting program index number
    % for the session into the Program field of
    % Experiment.Subject(s).Session(ses)
    disp (['Duplicate found: Index number is ' num2str(dupProgIndex)]);
else % add new program
    numProgs = numProgs + 1;
    Experiment.Programs.Program(numProgs) = struct('Name', Program_filename, 'Code',mainProg);
    Experiment.Subject(sub).Session(ses).Program = numProgs; % index number of new program
    % goes into Program field
    disp (['No duplicate found: Program ' Program_filename ' added to Experimental Structure.']);
end 

%%
result=1;
%%