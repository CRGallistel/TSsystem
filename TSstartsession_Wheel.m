function TSstartsession_Wheel
% Used to start new sessions, terminating previous session when necessary.
% Queries user, for each active subject, whether to continue with the
% session that subject is currently in or stop it. Also, whether to start a
% session; if so, whether the to-be-started session will use a new macro 
% (not previously used with that subject) or a macro previously used with
% that subject. If a new macro, it prompts user for necessary information:
% hfard drive letter, box number, & MedPC program file. Also prompts for the
% information: needed by the DailyAnalysis function and puts it in (or
% updates) the cell array ActiveExperiments, which contains the information
% that is passed by the Sequencer to DailyAnalysis.

if exist('TextForTSstartsession.txt','file')==2
    type TextForTSstartsession.txt
   
    while 1
       Str = input('Are you ready? [y] \nIf not, hit return & start again when you are. ','s');
       if length(Str)>1
           display('just the single letter "y"; no quotes')
       else
           break
       end
    end % while waiting for a proper answer to first question
  
   
   if ~strcmp('y',Str) % not ready
       return % stop
   end
end

Dr = cd; 

while ~strcmp(Dr(end-6:end),'Dropbox') % Dropbox is below current directory
    
    if exist('Dropbox','dir') % it's below current directory in search path
        
        cd Dropbox
        
    else % it's above current directory
        
        cd ..
        
    end
    Dr = cd;
end % Making sure current directory is the Dropbox

% 
% global t datatimer% structures in workspace when data-analysis timer and
% % datagrabber timer are running
% 
% if ~isempty(t)
%     stop(t) % so that Sequencer does not overload another Experiment
%     % structure while a session is being started. At conclusion, the timer 
%     % gets restarted
% end
% 
% if ~isempty(datatimer)
%     stop(datatimer)
% end
% % stop datatimer so that it does not generate confusing error messages
% % while TSstartsession is in progress. Timer restarted at end of function

if evalin('base','exist(''datatimer'')') % if the timer object called
    % datatimer, which calls NewDataGrabber periodically, is in the base
    % workspace
    evalin('base','stop(datatimer)') % stop it, so that it does not
    % interfere w this function (particulalry when this is being debugged!)
    % At end of this function, this is restarted
end

if evalin('base','exist(''analysistimer'')') % if the timer object called
    % analysistimer, which calls Sequencer periodically, is in the base
    % workspace
    evalin('base','stop(analysistimer)') % stop it
end

ExpIDnum = input('\n\nID number for this experiment? (e.g., 305) ');

% have the user navigate to the relevant experiment structure

L1 = 'Use the GUI to find the file of the Experiment structure.';
L2 = 'That structure will be loaded into workspace and declared global';
display(sprintf('\n\n%s\n   %s',L1,L2))

[StrucName,PathName] = uigetfile('Experiment*.mat','Find Experiment Structure');

i = length(num2str(ExpIDnum));

% compare the i letters following 'Experiment' in the file name to the
% user-specified experiment ID
if ~(str2double(StrucName(11:10+i))==ExpIDnum)
    
    display('Warning: user-specified ID and filename do not match')
    
end

TSloadexperiment([PathName StrucName]);

global Experiment;

if ~(ExpIDnum == Experiment.Id)
    
    display('Warning: user-specified ID and Experiment.Id do not match')
    
end

% if Experiment.Subject(i).MacroInfo doesn't exist, create it
if ~isfield(Experiment.Subject,'MacroInfo')
    for i=1:Experiment.NumSubjects

        Experiment.Subject(i).MacroInfo = struct('date',cell(1),...
        'progpath',cell(1),'program',cell(1),'box',[],'id',[],...
        'ExpId',[],'group',[],'macroname',[],'AnalysisFunction',cell(1));
    end % of for loop putting Marcro field in Experiment structure
end % Macro field not already in structure
%%
if strcmp(Experiment.Info.ActiveSubjects,'all')
    AS = 1:Experiment.NumSubjects;
else
    AS = Experiment.Info.ActiveSubjects;
end
%%
ASids = Experiment.Subjects(AS);

display(strvcat('These are id numbers of the currently active subjects:',...
    num2str(ASids),' '))

progstring = []; % initializing (so that these variables exist, whether used
% or not
ToBeStpd = [];
ToBeStrtd = [];
NewPrograms = cell(1);
NewProgramPath = cell(1);
NewBoxes = [];
NewDrives=char([]);
NewGroups = [];
StpDrvLet = char([]);
StrtDrvLet = char([]);
StpID = [];
StpPrgrm = cell(1);
StpBox = [];

TSexperimentbrowser

display(sprintf('\nSubjects now in Experiment structure: \n%s',num2str(Experiment.Subjects)))

if strcmp('y',input('\nAdd subjects to structure? [y] \n In no, hit Return (Enter)','s'))
    
    TSaddsubjects
    
end
%%
disp('Index #s of currently active subjects')
disp(AS')
%% 

if strcmp('y',input('\nStop current session for some or all subjects? [y] If no, hit Return (Enter) ','s'))
    
    ToBeStpd = input('Subjects for which session to be stopped: [vector of index numbers] ');
    
end

ToBeStrtd = input('Subjects for which new session to be started: [row vector of index numbers] ');

for i = 1:length(ToBeStrtd) % stepping through ToBeStrtd
    
    S = ToBeStrtd(i);    
    ID = Experiment.Subjects(S);
    
    if ~isfield(Experiment.Subject(S),'MacroInfo') ...
        || isempty(Experiment.Subject(S).MacroInfo) ...
        || isempty(Experiment.Subject(S).MacroInfo(1).date) % no sessions for this subject
        %%Need to fix this: If one has added subjects, then they will not
        % yet have a MacroInfo
        
        visualcheck = 'n';
        while ~strcmp(visualcheck,'y')
            ND = input(sprintf('\n\nLetter identifying hard drive for S%d (ID#%d): ',...
               S,ID),'s');
            NewBoxes(i) = input('Number of test box? (Be sure it''s not in use!) ');
            NG = input('Number of Experimental Group or Phase? ');
            
            if ~isempty(NewDrives) && ~isempty(NewGroups) && strcmp(ND,NewDrives(end)) && NG==NewGroups(end)
             % if this S on same drive & in same Group as preceding S, so
             % likely uses same MedPC program
             
                if strcmp('y',input('Use same MedPC file as for preceding S? [y/n]','s'))
                    NewDrives(i) = ND;
                    NewGroups(i) = NG;
                    NewPrograms{i} = NewPrograms{end};
                    NewProgramPath{i} = NewProgramPath{end};
                else
                    NewDrives(i) = ND;
                    NewGroups(i) = NG;
                    display(sprintf('Browse Drive %s for MedPC file for S%d, ID%d\n',...
                        NewDrives(i),S,ID))
                    [NewPrograms{i},NewProgramPath{i}] = ...
                        uigetfile('.MPC',['Find program for S' num2str(S)]);
                end % if using same file as previous else using different file
                
                    
            else % not same drive and group as previous S, so user must
                % browse for MedPC program
                NewDrives(i) = ND;
                NewGroups(i) = NG;
                display(sprintf('\nBrowse Drive %s for MedPC file for S%d, ID%d\n',NewDrives(i),S,ID))
                [NewPrograms{i},NewProgramPath{i}] = uigetfile('.MPC',['Find MedPC program for S' num2str(S)]);
                % Opens file browser for user to find the MedPC program file on
                % the hard disk on which the subject is to be run. '.MPC' is a
                % filter spec that will gray out all files except those with
                % the extension '.MPC'; the string constructed in the 2nd
                % argument of uigetfile should appear at top of file browser 
                
            end % if this S on same drive & in same group as previous S
                        
            
            if ~strcmp(NewProgramPath{i}(1),NewDrives(i)) % if drive on
                % which they found MedPC file not the same as the drive of
                % the computer controlling this subject's box
                
                display(char({'';'Chosen MedPC must be on same drive as S';'Choose again';''}))
                [NewPrograms{i},NewProgramPath{i}] = uigetfile('.MPC',['Find program for S' num2str(S)]);
            end % checking that MedPC file chosen is on same drive as computer
            % controlling experiment for S
            

            datecheck = 'n'; 
            while ~strcmp(datecheck,'y') % || ~(NewDrives(i)==NewProgramPath{i}(1))
                cd(NewProgramPath{i}) % changing to directory in which MedPC
                % program for this subject is found

                ProgInfo = dir([NewProgramPath{i} NewPrograms{i}]); % returns
                % a structure with name, date, bytes, isdir & datenam
                % fields for the file the user has chosen

            %   CompiledInfo = ProgInfo;
                CompiledPath = [NewProgramPath{i}(1) ':/MED-PC IV/DLL/' NewPrograms{i}(1:end-3) 'dll'];

                if exist(CompiledPath,'file')
                    CompiledInfo = dir(CompiledPath);
                    if CompiledInfo.datenum < ProgInfo.datenum
                        display(strvcat(['Selected program has been modified    ' ProgInfo.date],...
                            ['but was last compiled on              ' CompiledInfo.date ';'],...
                            'changes made after being compiled will have no effect'))
                        datecheck = input('proceed anyway (y/n)? ','s');
                    else
                        datecheck = 'y';
                    end
                else
                    display('Program not yet compiled on this drive. Please translate and compile before continuing')
                    display('when this is done, please type the word return to continue')
                    keyboard
                end

                if ~strcmp(NewDrives(i),NewProgramPath{i}(1))
                    display('That is not the drive you specified for this subject earlier')
                end

            end % while datecheck (whether compiled date > program date)
            
            display(sprintf('\nExperiment ID#: %d \nS#: %d (ID# %d)\nHard Drive: %s \nBox# %d \nGrp or Phase: %d \nProg: %s',...
            ExpIDnum,S,ID,NewDrives(i),NewBoxes(i),NewGroups(i),NewPrograms{i}))
            visualcheck = input('is this correct (y/n)? ', 's');
            
        end % while ~strcmp(visualcheck,'y') -- stepping through never run Ss
        
        cd(PathName) % back to directory that contains Experiment structure
        % This is end of code for creating new macro for subjects never run
        % before
        
    else % subject has been run already in this experiment
%%        
        display(char({'Macros previously run with this subject: ';''}))
                
        for m = 1:length(Experiment.Subject(S).MacroInfo) % displaying
            % previous macros for this subject
            
            display(['S: ' num2str(S)])
            
            display(['Index #: ' num2str(m)])
            
            display(Experiment.Subject(S).MacroInfo(m))            
            
        end % displaying previous macros
        
        OldMacroNum = input('Use old macro? \nIf yes, input index number; else hit Return (Enter)');
        
        if isempty(OldMacroNum) % new macro for this subject
            
            visualcheck = 'n';
            while ~strcmp(visualcheck,'y')
                ND = input(sprintf('Letter identifying hard drive for S%d (ID#%d): ',...
                   S,ID),'s');
                NewBoxes(i) = input('Number of test box? (Be sure it''s not in use!) ');
                NG = input('Number of Experimental Group or Phase? ');
                
                if ~isempty(NewDrives) && strcmp(ND,NewDrives(end)) && NG==NewGroups(end)
                    % if this S on same drive & in same Group as preceding
                    % S,in which case, probably uses same MedPC program
                    
                    if strcmp('y',input('Use same MedPC file as for preceding S? [y/n]','s'))
                        NewDrives(i) = ND;
                        NewGroups(i) = NG;
                        NewPrograms{i} = NewPrograms{end};
                        NewProgramPath{i} = NewProgramPath{end};
                    else
                        NewDrives(i) = ND;
                        NewGroups(i) = NG;
                        display(sprintf('\nBrowse Drive %s for MedPC file for S%d, ID%d\n',...
                            NewDrives(i),S,ID))
                        [NewPrograms{i},NewProgramPath{i}] = ...
                            uigetfile('.MPC',['Find program for S' num2str(S)]);
                    end % if using same file as previous else using different file
                    
                else % not on same drive & in same group as previous S, so
                    % user must browse
                    NewDrives(i) = ND;
                    NewGroups(i) = NG;
                    display(sprintf('\nBrowse Drive %s for MedPC file for S%d, ID%d\n',NewDrives(i),S,ID))
                    [NewPrograms{i},NewProgramPath{i}] = uigetfile('.MPC',['Find program for S' num2str(S)]);
                    % Opens file browser for user to find the MedPC program file on
                    % the hard disk on which the subject is to be run. '.MPC' is a
                    % filter spec that will gray out all files except those with
                    % the extension '.MPC'; the string constructed in the 2nd
                    % argument of uigetfile should appear at top of file browser

                    
                end % if this S on same drive & in same group as previous S
                

                datecheck = 'n'; 
                while ~strcmp(datecheck,'y') % || ~(NewDrives(i)==NewProgramPath{i}(1))
                    cd(NewProgramPath{i}) % changing to directory in which MedPC
                    % program for this subject is found

                    ProgInfo = dir([NewProgramPath{i} NewPrograms{i}]); % returns
                    % a structure with name, date, bytes, isdir & datenam
                    % fields for the file the user has chosen

                %   CompiledInfo = ProgInfo;
                    CompiledPath = [NewProgramPath{i}(1) ':/MED-PC IV/DLL/' NewPrograms{i}(1:end-3) 'dll'];

                    if exist(CompiledPath,'file')
                        CompiledInfo = dir(CompiledPath);
                        if CompiledInfo.datenum < ProgInfo.datenum
                            display(strvcat(['Selected program has been modified    ' ProgInfo.date],...
                                ['but was last compiled on              ' CompiledInfo.date ';'],...
                                'changes made after being compiled will have no effect'))
                            datecheck = input('proceed anyway (y/n)? ','s');
                        else
                            datecheck = 'y';
                        end
                    else
                        display('Program not yet compiled on this drive. Please translate and compile before continuing')
                        display('when this is done, please type the word return to continue')
                        keyboard
                    end

                    if ~strcmp(NewDrives(i),NewProgramPath{i}(1))
                        display('That is not the drive you specified for this subject earlier')
                    end

                end % while datecheck (whether compiled date > program date)

                display(sprintf('\nExperiment ID#: %d \nS#: %d (ID# %d)\nHard Drive: %s \nBox# %d \nGrp or Phase: %d \nProg: %s%s',...
                ExpIDnum,S,ID,NewDrives(i),NewBoxes(i),NewGroups(i),NewProgramPath{i},NewPrograms{i}))
                visualcheck = input('is this correct (y/n)? ', 's');
            end % stepping through AS, checking date

            cd(PathName) % back to directory that contains Experiment structure
            % end of code for creating new macro for subjects previously
            % run in this experiment
            
        else % use older macro    
          
            visualcheckr = 'n';        

            while ~strcmp('y',visualcheckr)            
                datecheck = 'n'; % checking that the compiled (.dll) file
                       % has a date and time >= date and time of code file (%
                       % to prevent cases where user has forgotten to
                       % recompile)

               r = OldMacroNum; % this is used repeatedly in while loop that follows

               while ~strcmp(datecheck,'y')
                        
                    testrow = ...
                        sprintf('\n\nLoad Box: %d\nSubjectID: %d\nExperimentID#: %d\nGroup/Cond/Phase: %d\nMedPCprog: %s',...
                        Experiment.Subject(S).MacroInfo(r).box,...
                        Experiment.Subject(S).MacroInfo(r).id,...
                        Experiment.Subject(S).MacroInfo(r).ExpId,...
                        Experiment.Subject(S).MacroInfo(r).group,...
                        Experiment.Subject(S).MacroInfo(r).program);

                   ProgInfo = dir([Experiment.Subject(S).MacroInfo(r).progpath Experiment.Subject(S).MacroInfo(r).program]);

            %      CompiledInfo=ProgInfo;
                   CompiledInfo = dir([Experiment.Subject(S).MacroInfo(r).progpath(1) ':/MED-PC IV/DLL/' Experiment.Subject(S).MacroInfo(r).program(1:end-3) 'dll']);
                    % looking at date and time of compiled file

                   if CompiledInfo.datenum<ProgInfo.datenum % compiled file date and time
                       % earlier than date and time on code file

                       display(strvcat(['Selected program has been modified ' ProgInfo.date],...
                           ['but was last compiled on ' CompiledInfo.date], ...
                           'changes made after being compiled will have no effect'))
                       datecheck = input(strvcat('proceed anyway? (y)',...
                           'or choose again (perhaps after recompiling)? (n)'),'s');
                   end % of if compiled file date earlier than code file date
                   datecheck = 'y';
               end % while datecheck
               disp(testrow)
               visualcheckr = input('is this info correct (y/n)? ','s');
            end
                  
            NewDrives(i) = Experiment.Subject(S).MacroInfo(r).progpath(1);
            % the (upper case) letter that identifies a hard drive on the LAN
            NewBoxes(i) = Experiment.Subject(S).MacroInfo(r).box; % a number
            NewGroups(i) = Experiment.Subject(S).MacroInfo(r).group; % a number
            NewPrograms{i} =  Experiment.Subject(S).MacroInfo(r).program;
            % string giving name of a MedPC program
            NewProgramPath{i} = Experiment.Subject(S).MacroInfo(r).progpath;
            % the path to that program
            
        end % if new macro for this previously run subject else old macro
        
    end % if no sessions for this subject else there are previous sessions
    
    display(char({'' '____________________________' ''})) % draw line at
    % conclusion of each subject
    
end % of stepping through ToBeStarted subjects assembling macro info

%%
% Final confirmation of what is to be done
% Confirming sessions to be stopped. Also contains code that builds string
% to tell user which drives to access and what to stop and start

if ~isempty(ToBeStpd)
    display(sprintf('\n\nThe following sessions are to be stopped:'))
    for i = 1:length(ToBeStpd)
        S = ToBeStpd(i);
        ID = Experiment.Subjects(S);
        if isempty(Experiment.Subject(S).NumSessions)
            display(sprintf('Cannot stop session for  S %d, \nbecause no session has previously been started.',S))
            continue
        end
        ses = Experiment.Subject(S).NumSessions;
        GorP = Experiment.Subject(S).Session(end).Phase;
        display(sprintf('S# %d (ID# %d): Session %d, Group/Phase %d',S,ID,ses,GorP))
        
        % getting drive, program, ID and Box 3 to be stopped (for later
        % use)
        if isfield(Experiment.Subject(S),'MacroInfo') ...
                && ~isempty(Experiment.Subject(S).MacroInfo)...
                && isfield(Experiment.Subject(S).MacroInfo(end),'progpath')...
                && ~isempty(Experiment.Subject(S).MacroInfo(end).progpath)
            StpDrvLet(i) = Experiment.Subject(S).MacroInfo(end).progpath(1);
            StpPrgrm{i} = Experiment.Subject(S).MacroInfo(end).program;
            StpID(i) = ID; % ID # of S to be stopped
            StpBox(i) = Experiment.Subject(S).MacroInfo(end).box;            
        end % if for getting letter of drive of an S to be stopped
    end

end % of confirming sessions to be stopped
%%    
%  Confirming new macros
Str = char({'','Following goes through the to-be-started sessions,' ...
    '(in reverse order), confirming the information about' ...
    ' Subject, Hard Drive,Box, Group or Phase, and Program.' ...
    ' If info shown for a subject is correct,' ...
    ' just hit return in response to "Correct? "' ...
    'If any item needs to be corrected, type ''n'' and you' ...
    'will be prompted for each item in turn.'});
disp(Str)

StrtID = []; % initializing
for i = length(ToBeStrtd):-1:1
    S = ToBeStrtd(i);
    ID = Experiment.Subjects(S);
    HD = NewDrives(i);
    B = NewBoxes(i);
    G = NewGroups(i);
    P = [NewProgramPath{i} NewPrograms{i}];

    display(sprintf('\n\nS# %d (ID# %d) \nDrive: %s \nBox#: %d \nGroup: %d \nProgram: %s',...
        S,ID,HD,B,G,P))
    Correct = input('\nCorrect? [y/n or d for delete subject] ','s');

    switch  Correct % if response to "Correct?" was no
        case 'd'
            ToBeStrtd(i) = [];
            NewDrives(i) = [];
            NewBoxes(i) = [];
            NewGroups(i) = [];
            NewPrograms(i) = [];
            NewProgramPath(i) = [];
        case 'n'
            sprintf('Hard Drive: %s',HD)
            C = input('Change? [if no, hit return; otherwise, enter new letter]: ','s');
            if ~isempty(C)
                NewDrives(i) = C; % Chris to write checking code
            end
            
            sprintf('Box#: %d',B)
            C = input('Change? [if no, hit return; otherwise, enter new number]: ');
            if ~isempty(C)
                NewBoxes(i) = C;
            end
            
            sprintf('Group or Phase: %d',G)
            C = input('Change? [if no, hit return; otherwise, enter new number]: ');
            if ~isempty(C)
                NewGroups(i) = C;
            end
            
            sprintf('Program: %s',P)
            C = input('Change? [If y, file browser will open] ');
            if strcmp('y',C)
                [NewPrograms{i},NewProgramPath{i}] = uigetfile('.MPC',['Find program for S' num2str(S)]);
            end
            
    end % switch
    
    StrtDrvLet(i) = HD;
    StrtID(i) = ID;
    % the program to be started is NewPrograms{i}
    
end % of loop confirming info on to-be-started sessions
            
%% create macros based on user responses
MACRO='';
%Print=[];

for i=1:length(ToBeStrtd) % building macro for each subject
    MACRO{i} = ['LOAD BOX ' num2str(NewBoxes(i)) ...
        ' SUBJ ' num2str(Experiment.Subjects(ToBeStrtd(i))) ...
        ' EXPT ' num2str(ExpIDnum) ' GROUP ' num2str(NewGroups(i)) ...
        ' PROGRAM ' NewPrograms{i}(1:end-4)];
end

%% Print Macro to Appropriate Drive
if exist('NewDrives', 'var')
    DriveSet = unique(NewDrives);

    for i = 1:length(DriveSet) % for each unique drive letter
        D = DriveSet(i);
        r = find(NewDrives==D); % find the macro rows that have that as the drive letter
        fid = fopen([D ':/MED-PC IV/MACRO/' 'Exp' num2str(ExpIDnum) '.MAC'], 'wt'); %create or modify the relevant MAC file on that drive
        fprintf(fid, '%s\n', ['                           Exp' num2str(ExpIDnum) '.MAC']); %make the first row the title
        fprintf(fid, '%s\n', MACRO{r}); % make the following rows, the rows of the macro that are for drive D
        fclose(fid); 
        type([D ':/MED-PC IV/MACRO/' 'Exp' num2str(ExpIDnum) '.MAC'])

    end
end

%% add the information of the successfully completed macro to the exp struc
if ~isempty(ToBeStrtd) 
    i=1;
    for j=ToBeStrtd;
        
        if ~isfield(Experiment.Subject(j),'MacroInfo')
            Experiment.Subject(j).MacroInfo=struct('date',date,...
                'progpath',NewProgramPath{i},'program',NewPrograms{i},...
                'box',NewBoxes(i),'id',Experiment.Subjects(j),...
                'ExpId',ExpIDnum,'group',NewGroups(i),...
                'macroname',sprintf('Exp%d.MAC',ExpIDnum));
            
        elseif isempty(Experiment.Subject(j).MacroInfo) ...
                || isempty(Experiment.Subject(j).MacroInfo(1).date)
            % if MacroInfo field exists but has no subfields or if it has
            % subfields but they are empty
            Experiment.Subject(j).MacroInfo(1).date = date; 
            Experiment.Subject(j).MacroInfo(1).progpath = NewProgramPath{i};
            Experiment.Subject(j).MacroInfo(1).program = NewPrograms{i};
            Experiment.Subject(j).MacroInfo(1).box = NewBoxes(i);
            Experiment.Subject(j).MacroInfo(1).id = Experiment.Subjects(j);
            Experiment.Subject(j).MacroInfo(1).ExpId = ExpIDnum;
            Experiment.Subject(j).MacroInfo(1).group = NewGroups(i);
            Experiment.Subject(j).MacroInfo(1).macroname = sprintf('Exp%d.MAC',ExpIDnum);
            
        else
            Experiment.Subject(j).MacroInfo(end+1).date = date; 
            Experiment.Subject(j).MacroInfo(end).progpath = NewProgramPath{i};
            Experiment.Subject(j).MacroInfo(end).program = NewPrograms{i};
            Experiment.Subject(j).MacroInfo(end).box = NewBoxes(i);
            Experiment.Subject(j).MacroInfo(end).id = Experiment.Subjects(j);
            Experiment.Subject(j).MacroInfo(end).ExpId = ExpIDnum;
            Experiment.Subject(j).MacroInfo(end).group = NewGroups(i);
            Experiment.Subject(j).MacroInfo(end).macroname = sprintf('Exp%d.MAC',ExpIDnum);
        end
        i=i+1;
    end
end

if ~isempty(ToBeStpd); AS(ismember(AS, ToBeStpd)) = []; end % remove subjects that we are stopping
if ~isempty(ToBeStrtd); AS = sort([AS, ToBeStrtd]); end % add subjects that are starting
Experiment.Info.ActiveSubjects = AS;  


%% save Experiment structure

TSsaveexperiment([PathName StrucName])


%% Create or alter ActiveExperiments_Wheel
% (the variable that Sequencer steps through)

cd(Dr) % set current directory to Dropbox

if exist('ActiveExperiments_Wheel.mat','file')

    load('ActiveExperiments_Wheel.mat') % This is the cell array that the Sequencer
    % uses to call the analysis of the active experiments. There is one row per
    % active experiment. There are 6 columns in a row. First column contains
    % the experiment's ID number, taken from the Experiment.Id field in the
    % Experiment structure. The 2nd column contains the string specifying the
    % format in which figures are to be saved (usually, '.pdf' or '.fig'). The
    % 3rd col contains the desired number of rows of subplots in one figure.
    % The 4th col contains a cell array, each cell of of which contains the
    % pair of event codes that define start and end of a feeding phase. The 5th
    % col contains a cell array that specifies the protocol-specific
    % data-analysis functions that are to be called by the DailyAnalysis
    % function and the arguments that are to be passed to them. In this cell
    % array, there is one row per function to be called and 3 cells in that
    % row. First cell is scalar or vector specifying phases (groups,
    % conditions, protocols) on which that analysis is to be run, 2nd col gives
    % name of the function, 3rd col gives the arguments to be passed to it).
    % The 6th col of a row contains the email addresses to which alerts are
    % sent when there is a suspicious lack of data
    
    display(ActiveExperiments_Wheel)
    
else
    ActiveExperiments_Wheel=[];
    display('There are no currently active experiments')
end
%%    
if ~isempty(ActiveExperiments_Wheel)
    
    L1 = 'Above is the ActiveExperiments cell array with one row per active experiment.';
    L2 = 'Are all of these experiments still active? If yes, hit return. ';
    L3 = 'If not, answer with vector of ID numbers of to-be-deleted experiments: ';

    NoLongerActive = input(sprintf('\n\n%s\n%s\n%s',L1,L2,L3));
    
    if ~isempty(NoLongerActive)
    
        for r = size(ActiveExperiments_Wheel,1):-1:1 % stepping through the rows

            if ismember(ActiveExperiments_Wheel{r,1},NoLongerActive) % if the
                % experiment in this row is no longer active

                ActiveExperiments_Wheel(r,:) = []; % delete it            
            end        
        end
    end
    
    try 
        
        if isempty([ActiveExperiments_Wheel{:}]) % if they have all been deleted
            ActiveExperiments_Wheel = [];
        end
        
    catch % if the cells are not all empty and contain cells whose contents
        % are cell arrays that will not concatenate, then the isempty call
        % will crash and the ActiveExperiments=[] will not execute. If all
        % the cells are in fact empty, then it won't crash and the
        % ActiveExperiments = [] will execute
    end
    
end

if ~isempty(ActiveExperiments_Wheel) % if ActiveExperiments was not just created,
    
    LV = ismember([ActiveExperiments_Wheel{:,1}],Experiment.Id);
    % If this experiment is already running, its location in
    % ActiveExperiments will be flagged by a 1 in this logical vector
    
    
    if sum(LV)>0 % This experiment is already running
        
        L1 = 'This experiment is already running.';
        L2 = 'Do you want to change the restricted feeding phase event code vectors?';
        L3 = 'Answer y or n (default is n, just hit Rtn): ';
        
        if strcmp(input(sprintf('\n%s\n%s\n%s',L1,L2,L3),'s'),'y')
            % if event codes for restricted feeding phases are to be
            % changed
            
            ActiveExperiments_Wheel{LV,4} = FdgPhases_local;
            
        end % 
        
        L4 = 'Does this session constitute a new "phase" (aka "condition" or "group"),';
        L5 = 'with a new protocol-specific analysis function?';
        L6 = 'If so, respond "y" [just the letter, no quotes]; if not, hit Rtn: ';
                
        if strcmp(input(sprintf('\n%s\n%s\n%s',L4,L5,L6),'s'),'y')
      
            if ~isempty(ActiveExperiments_Wheel{LV,5})              
                display(ActiveExperiments_Wheel{LV,5})
                L7 = 'Above is the current list of analysis functions for this experiment.';
                L8 ='Each row is a different analysis function';
                L9 = 'Respond with row numbers for those (if any) that should';
                L10 = 'no longer be run. If they should all continue to be run, hit Rtn '; 
               
                ToBeStopped = input(sprintf('\n%s\n%s\n%s\n%s',L7,L8,L9,L10));
                
                if ~isempty(ToBeStopped)
                    
                    for r = sort(ToBeStopped,'descend') % stepping through
                        % those to be stopped, in reverse order
                        
                        ActiveExperiments_Wheel{LV,5}(r,:) = [];
                        
                    end % deleting analyses that are no longer to be run
                    
                end % checking if there are analyses that are no longer to be run
            end % of if there are analysis functions already running
                
            
            ActiveExperiments_Wheel{LV,5}(end+1,:) = ProtSpecFuns_local; % adding
            % new analysis functions
            
        end % of if this is a new protocol
        
        
    else % ActiveExperiments exists but this experiment is not in it yet  

        ActiveExperiments_Wheel{end+1,1} = Experiment.Id;

        ActiveExperiments_Wheel{end,2} = input('Format in which figures to be saved? ','s');

        ActiveExperiments_Wheel{end,3} = input('Number of rows wanted in subplots? [not in quotes] ');
    
        ActiveExperiments_Wheel{end,4} = FdgPhases_local;
        
        ActiveExperiments_Wheel{end,5} = ProtSpecFuns_local;
        
        L1 = 'Email addresses for alerts, in single quotes & separated by spaces';
        L2 = '(e.g., ''galliste@ruccs.rutgers.edu'' ''s1prash@yahoo.com''): ';
        
        Addresses = input(sprintf('\n%s\n  %s',L1,L2),'s');
        
        Addresses = sprintf('{%s}',Addresses);
        
        eval(sprintf('Ad = %s;',Addresses))
        
        ActiveExperiments_Wheel{end,6} = Ad;
        
    end
    
else % ActiveExperiments does not exist
    
    
    ActiveExperiments_Wheel{1,1} = Experiment.Id;
%%    
    while 1 % waiting for an acceptable graphic format
        
        Frmt = input('Format in which figures to be saved? ','s');
        
        if logical(sum(strcmp({'.pdf' '.fig' '.eps' '.tif' '.png' '.ai' '.ppm'},Frmt)))
            
            ActiveExperiments_Wheel{1,2} = Frmt;
            
            break
        else
            L1 = 'Not a supported graphics format.';
            L2 = 'Supported formats are:';
            L3 = '.pdf, .fig, .eps, .tif, .png, .ai & .ppm';
            sprintf('\n%s\n%s\n%s\n',L1,L2,L3)
        end
    end % of while waiting for acceptable graphic format
%%
    ActiveExperiments_Wheel{1,3} = input('Number of rows wanted in subplots? [not in quotes!] ');
    if ischar(ActiveExperiments_Wheel{1,3})
        display('Do not enclose the number of rows in quotes!')
        ActiveExperiments_Wheel{1,3} = input('Number of rows wanted in subplots? [not in quotes!] ');
    end
    
    ActiveExperiments_Wheel{1,4} = FdgPhases_local;

    ActiveExperiments_Wheel{1,5} = ProtSpecFuns_local;

%%

    L1 = 'Email addresses for alerts, in single quotes & separated by spaces';
    L2 = '(e.g., ''galliste@ruccs.rutgers.edu'' ''s1prash@yahoo.com''): ';

    Addresses = input(sprintf('\n%s\n  %s',L1,L2),'s');

    Addresses = sprintf('{%s}',Addresses);

    eval(sprintf('Ad = %s;',Addresses))

    ActiveExperiments_Wheel{1,6} = Ad;
    
end

cd(Dr) % restoring current directory

save(sprintf('%s/ActiveExperiments_Wheel',Dr),'ActiveExperiments_Wheel')

display(sprintf('\nThe ActiveExperiments_Wheel are:\n'))

% try
%     TSdisplayactiveexperiments
% catch ME
%     display(ME)
% end

% try
%     DataGrabberTimer
% catch ME
%     display(ME)
% end
% 
% try
%     StartAnalysisTimer
% catch ME
%     display(ME)
% end

%% Listing by drive letter & IP the sessions to be stopped and started
StpDrvLet = StpDrvLet';
StrtDrvLet = StrtDrvLet';

if isempty(StpDrvLet) && isempty(StrtDrvLet)
    display('Nothing to be started or stopped');
    return
elseif ~isempty(StpDrvLet) && ~isempty(StrtDrvLet)
    StpDrvLet(:,2) = 'e'; % flagging stops
    StrtDrvLet(:,2) = 'b'; % flagging starts
elseif ~isempty(StpDrvLet)
    StpDrvLet(:,2) = 'e'; % flagging stops
else
    StrtDrvLet(:,2) = 'b'; % flagging starts
end

[DrvLet,Indx] = sortrows([StpDrvLet;StrtDrvLet],[1 -2]); % sorting on the 
% basis  first of ascending drive letter, then on basis of descending b e

% if exist('IPaddresses.mat','file')
%     
%     load('IPaddresses') % dictionary giving for each drive letter (now made a 
%     % variable in the function's workspace) its ip address
%     
% else
%     display(char({' ' 'Can''t find IPaddresses file' ' '}))
%     
%     for drv = unique(DrvLet(:,1))' % prompting for IP addresses
%         
%         eval([drv '=' ...
%             input(sprintf('IP address for Drive %s (enclose in single quotes) ',drv),'s') ...
%             ';'])
%     end
%     
% end

IDs = [StpID';StrtID'];
IDs = IDs(Indx); % sorting to line up with corresponding drive letters
 

Prgrms = [StpPrgrm';NewPrograms']; % cell array of programs to be stopped & started
Prgrms = Prgrms(Indx); % sorting to line up w corresponding drive letters and IDs


Boxes = [StpBox';NewBoxes'];
Boxes = Boxes(Indx);
%
display(char({' ' 'SESSIONS ALMOST STARTED!' 'Access hard drives from server:' ...
    'Start->Remote Desktop Connection' 'and enter IP address of each hard drive' ...
    'After accessing each drive, call up MedPC' ...
    'and close (stop) and open (start) sessions.' ...
    'Drives w their IPs and stops & starts listed below:'}))

LVe = DrvLet(:,2)=='e'; % flags rows that specify sessions to be ended
for drv = unique(DrvLet(:,1))'
     
    LVd = DrvLet(:,1)==drv; % flags all entries w same drive
    % letter as drvR
    
%     if ~exist(drv,'var') % in case IP for this drive not in loaded file
%         
%         eval([drv '=' ...
%             input(sprintf('IP address for Drive %s (enclose in single quotes) ',drv),'s') ...
%             ';'])
%     end
    
%     display(sprintf('\nDrive: %s IP:%s\n   Stop\n      ID   Box  Program',drv,eval(drv)))
    
    IDsTmp = IDs(LVe&LVd);
    BoxesTmp = Boxes(LVe&LVd);
    PrgrmsTmp = Prgrms(LVe&LVd);
    
    for i = 1:length(IDsTmp)
        display(sprintf('     %d   %d   %s',...
            IDsTmp(i),BoxesTmp(i),PrgrmsTmp{i}))
    end
    
    if isempty(IDsTmp); display('        None');end
%        
    display(sprintf('\n   Start\n      ID   Box  Program'))
    
    IDsTmp = IDs(~LVe&LVd);
    BoxesTmp = Boxes(~LVe&LVd);
    PrgrmsTmp = Prgrms(~LVe&LVd);
%    
    for i = 1:length(IDsTmp)
        display(sprintf('     %d   %d   %s',IDsTmp(i),BoxesTmp(i),PrgrmsTmp{i}))
    end
    
    if isempty(IDsTmp); display('        None');end
    
end
        

%%
TSsaveexperiment([PathName StrucName])

%% 4th cell column (FdgPhases)

function FdgPhases = FdgPhases_local
% constructs the cell array of 2D event-code vectors that delimit feeding
% phases
global Experiment
TSdeclareeventcodes

FP = '{';
Phase =1;
while 1 % building the cell array of start and stop event codes
    
    while 1 % waiting for an event code (or an empty return)
        
        NwStrStr =input(sprintf(...
            '\nEvent code for start of restricted feeding phase %d \n(e.g. StartEarly)? \nIf none or no further, hit return. ',...
            Phase),'s');
        
        if isfield(Experiment.EventCodes,NwStrStr)
            
            FP = [FP '[' NwStrStr];
            
            break %stop waiting for an event code
            
        elseif isempty(NwStrStr) % user returned an empty
            
            break % stop waiting for event code
            
        else
            sprintf('\n%s is not an event code',NwStrStr)
        end % of displaying error message
        
    end % of waiting for either an event code or an empty
    
    if isempty(NwStrStr) && (length(FP)==1)
        
        FP = '[]';
        
        break % building FdgPhases concludes w empty FdgPhases
        
    elseif isempty(NwStrStr)
        
        FP = [FP(1:end-1) '}']; % complete the cell array
        
        break % end of building FdgPhases cell array
        
    end % of either entering new start event code or terminating
    
    while 1 % waiting for an acceptable stop event code
    
        NwStpStr = input(sprintf(...
            '\nEvent code for end of restricted feeding phase %d \n(e.g. StopEarly)? \nIf none or no further, hit return. ',...
            Phase),'s');
        
        if isfield(Experiment.EventCodes,NwStpStr)

            FP = [FP ' ' NwStpStr '] '];
            
            break % stop waiting for new end event code
            
        else
            sprintf('\n%s is not an event code',NwStpStr)
        end % of displaying error message
            
    end % of waiting for an acceptable stop event code
    
    Phase = Phase+1;
    
end

eval(['FdgPhases = ' FP])


        
%% 5th column: the ProtSpecFuns cell array

function PSF = ProtSpecFuns_local
%
% Returns a cell array with one one row for each protocol-specific function
% to be called by the DailyAnalysis function. The first cell in a row is
% a scalar or vector of scalars specifying the phases (conditions, groups)
% for which this analysis is to be done; the 2nd gives the function that is
% to be called; the 3rd is a string giving the arguments of this function.

PSF=cell(1,3);

Fun = 1; % initializing row index
while 1
    
    NewFun = input(...
        sprintf(...
        '\n\nProtocol-specific analysis function %d (e.g., MatchingAnalysis) [without quotes]? \nIf none or no further, hit return. ',Fun),'s');
    
    if isempty(NewFun)
        break
    end
      
    PSF{Fun,1} = input('\n\nPhase(s) to which this analysis applies? ');
    
    PSF{Fun,2} = NewFun;
    
    sprintf('\n\n Documentation for that function: \n\n')
    help(NewFun)
    
    
    L1 = 'Input arguments to be passed to this function';
    L1a = 'The documentation for this function is displayed above so you can see its input arguments.';
    L2 = '  [Sample Answer 1: "PlotPath,Rows,Format"';
    L3 = '    These arguments are variables created by DailyAnalysis (PlotPath)';
    L4 = '    or passed to it by the Sequencer (Rows, Format).';
    L5 = '  Sample Answer 2: "PlotPath,Rows,''.pdf''" ';
    L6 = '    In this example, a different format is specified for the saved figures.';
    L7 = '    Note the necessary doubling of the single quotes before and after a string argument.';
    L8 = '  Hit Rtn to pass the default arguments, "PlotPath,Rows,Format"]: ';
   
    Str = sprintf('\n\n%s\n%s\n\n%s\n%s\n%s\n\n%s\n%s\n%s\n\n%s',...
        L1,L1a,L2,L3,L4,L5,L6,L7,L8);
    
    Arg = input(Str,'s');
    
    if isempty(Arg)
        Arg='PlotPath,Rows,Format';
    end
    
    NoNo = ''''''; % No is a string of 2 single quotes, which may occur if
    % user is confused about how to use single quotes in above answer
    
    dblsngl = strfind(Arg,NoNo); % if the 2 single quotes in succession
    % appear at one or more places in the user-input string argument,
    % dblsngl gives the position at which each of these forbidden sequences
    % begins
    
    if ~isempty(dblsngl) % if there are No-Nos
        
        L1 = 'One or more of the strings that you entered to be passed';
        L2 = 'as an argument contained one or more occurrences of 2';
        L3 = 'single quotes in succession. This usually causes a crash.';
        L4 = 'Unless you type veto, one single quote will be deleted';
        L5 = 'from each occurrence of 2 single quotes in succession.';
        
        Str = sprintf('\n\n%s\n%s\n%s\n%s\n%s)',L1,L2,L3,L4,L5);
        
        if ~strcmp('veto',input(Str,'s'))
            
            Arg(dblsngl)=[];
            
        end % if no veto, delete excess single quotes
        
    end % if there are Noo-Nos
    
    PSF{Fun,3} = sprintf('%s',Arg); % arguments of the function
    % When the string is constructed, these arguments will be encased in
    % open and close parentheses
    
    Fun = Fun+1; % incrementing row index
    
end