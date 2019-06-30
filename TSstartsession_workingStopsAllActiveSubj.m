function TSstartsession
% Used to start new sessions, terminating previous session when necessary.
% Queries user, for each active subject, whether to continue with the
% session that subject is currently in or stop it. Also, whether to start a
% session; if so, whether the to-be-started session will use a new macro 
% (not previously used with that subject) or a macro previously used with
% that subject. If a new macro, it prompts user for necessary information:
% hard drive letter, box number, & MedPC program file. Also prompts for the
% information: needed by the DailyAnalysis function and puts it in (or
% updates) the cell array ActiveExperiments, which contains the information
% that is passed by the Sequencer to DailyAnalysis.

if exist('TextForTSstartsession.txt','file')==2
    type TextForTSstartsession.txt
    
   Str = input('Are you ready? (Respond y) \nIf not, hit return and start again when you are. ','s');
   
   if strcmp('y',Str) % continue
   else
       return % stop
   end
end

Dr = cd;

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

if strcmp(Experiment.Info.ActiveSubjects,'all')
    AS = 1:Experiment.NumSubjects;
else
    AS = Experiment.Info.ActiveSubjects;
end

ASids = Experiment.Subjects(AS);

display(strvcat('These are id numbers of the currently active subjects:',...
    num2str(ASids),' '))

progstring = [];

% added by HK to facilitate progInfo harvesting needed to stop these
% programs remotely --------- <
currProgPath = cell(size(AS,1), size(AS,2));
currProgCounter = 1;
% --------- >

ToBeStpd = [];
ToBeStrtd = [];

TSexperimentbrowser

i=1;

for S= AS % stepping through the active subjects, querying user
    
    if isfield(Experiment.Subject(S),'MacroInfo') &&...
            isfield(Experiment.Subject(S).MacroInfo(end),'program') &&...
            ~isempty(Experiment.Subject(S).MacroInfo(end).program)
    
        progstring = sprintf('%s\n%s',progstring, Experiment.Subject(S).MacroInfo(end).program);
        currProgPath{currProgCounter} = Experiment.Subject(S).MacroInfo(end).progpath; % added by HK
        % collecting program path info to be used later in closing programs
    end
    currProgCounter = currProgCounter + 1; % added by HK
    
    if Experiment.Subject(S).NumSessions == 0
        
        ToBeStrtd(i,:) = [S 1];
           
    elseif strcmp('y',input(sprintf('\nIs current session for S%d (ID#%d) to be stopped? [y/n] ',S,Experiment.Subjects(S)),'s'))
        ToBeStpd(end+1) = S;
    
        if strcmp('y',input(sprintf('\nStart new session for S%d (ID#%d)? [y/n] ',...
                S,Experiment.Subjects(S)),'s'));

            ToBeStrtd(end+1,:) = [S 0]; % vector of subject numbers for those
            % sessions that are to be terminated

            if strcmp('y',input('\nUsing new macro (vs one previously used w this subject)? [y/n] ','s'))

                ToBeStrtd(end,2) = 1; % flag indicating that a new macro must be
                % generated for this subject

            end % flagging those subjects requiring new macros

        end % querying for starting a new session and whether using new or old
        % macro
    end
    
    i = i+1;
    
end % When this loop is finished, the ToBeStpd vector gives the subjects
% whose sessions are to be closed and the ToBeStrtd array gives in first
% column the subjects that are to start a session with a flag in 2nd column
% if they require a new macro. Subjects with a 0 in 2nd column will
% use a macro previously used with that subject


for i = 1:size(ToBeStrtd,1) % stepping through the rows of ToBeStrtd
    
    S = ToBeStrtd(i,1);
    
    ID = Experiment.Subjects(S);
    
    if ToBeStrtd(i,2) == 0 % if old macro to be used again
        
        visualcheckr = 'n';
        
        while ~strcmp('y',visualcheckr)
            
            datecheck = 'n'; % checking that the compiled (.dll) file
                   % has a date and time >= date and time of code file (%
                   % to prevent cases where user has forgotten to
                   % recompile)
                   
           while ~strcmp(datecheck,'y')
                r = input(sprintf('\nFor S%d, choose previously used MacroInfo# to be run again. ',S));
                testrow = vertcat(strcat('LOAD BOX ', num2str(Experiment.Subject(S).MacroInfo(r).box),...
                           ' SUBJ ', num2str(Experiment.Subject(S).MacroInfo(r).id), ...
                           ' EXPT ', num2str(Experiment.Subject(S).MacroInfo(r).ExpId),...
                           ' GROUP ', num2str(Experiment.Subject(S).MacroInfo(r).group),...
                           ' PROGRAM ', num2str(Experiment.Subject(S).MacroInfo(r).program)));
                    % building the line they just specified

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
           end % while datecheck
           display(testrow)
           visualcheckr = input('is this info correct (y/n)? ');
        end
        
        NewDrives(i) = Experiment.Subject(S).MacroInfo(r).progpath(1);
        % the (upper case) letter that identifies a hard drive on the LAN
        NewBoxes(i) = Experiment.Subject(S).MacroInfo(r).box; % a number
        NewGroups(i) = Experiment.Subject(S).MacroInfo(r).group; % a number
        NewPrograms{i} =  Experiment.Subject(S).MacroInfo(r).program;
        % string giving name of a MedPC program
        NewProgramPath{i} = Experiment.Subject(S).MacroInfo(r).progpath;
        % the path to that program

    else % new macro to be created
        
        visualcheck = 'n';
        while ~strcmp(visualcheck,'y')
            NewDrives(i) = input(sprintf('Letter identifying hard drive for S%d (ID#%d): ',...
               S,ID),'s');
            NewBoxes(i) = input('Number of test box? (Be sure it''s not in use!) ');
            NewGroups(i) = input('Number of Experimental Group or Phase? ');
            [NewPrograms{i},NewProgramPath{i}] = uigetfile('.MPC',['Find program for S' num2str(S)]);
            % Opens file browser for user to find the MedPC program file on
            % the hard disk on which the subject is to be run. '.MPC' is a
            % filter spec that will gray out all files except those with
            % the extension '.MPC'; the string constructed in the 2nd
            % argument of uigetfile should appear at top of file browser
            
            
            % What follows is code that checks whether new program has been
            % compiled. I haven't vetted this code as of quitting time
            % 1/11/11 CRG

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

                if ~(NewDrives(i)==NewProgramPath{i}(1))
                    display('That is not the drive you specified for this subject earlier')
                end

            end % while datecheck (whether compiled date > program date)
                    sprintf('\nExperiment ID#: %d \nS#: %d (ID# %d)\nHard Drive: %s \nBox# %d \nGrp or Phase: %d \nProg: %s',...
            ExpIDnum,S,ID,NewDrives(i),NewBoxes(i),NewGroups(i),NewPrograms{i})
            visualcheck = input('Is this correct (y/n)? ', 's');
            
        end % while assemmbling & confirming new macro info for one subject
        
        cd(PathName) % back to directory that contains Experiment structure

%         sprintf('\nLOAD BOX %s SUBJ %s EXPT %s GROUP %s PROGRAM %s.MPC',...
%             testmac,num2str(NewBoxes(i)),num2str(ASids(i)),num2str(ExpIDnum),...
%             num2str(NewGroups(i)),num2str(NewPrograms{i}(1:end-4)));

    end % use old macro or else assemble infor for new
    
end % of stepping through ToBeStarted subjects assembling macro info

% Final confirmation of what is to be done
% Confirming sessions to be stopped
if ~isempty(ToBeStpd)
    sprintf('\nThe following sessions are to be stopped:')
    for i = size(ToBeStpd,1)
        S = ToBeStpd(i);
        ID = Experiment.Subjects(S);
        ses = Experiment.Subject(S).NumSessions;
        GorP = Experiment.Subject(S).Session(end).Phase;
        sprintf('S# %d (ID# %d): Session %d, Group/Phase %d',S,ID,ses,GorP)
    end
    AorD = input('\nAny deletions/additions? if not, \nhit return; \notherwise give subject number(s) to be added/deleted: ', 's');
    AorD = str2num(AorD);
    if ~isempty(AorD)
        AorD = reshape(length(AorD),1); % column vector
        ToBeStpd(ismember(ToBeStpd,AorD)) = []; % deletions
        ToBeStpd = [ToBeStpd;AorD(ismember(AorD,ToBeStpd))];
    end % if changes to be made to list of sessions to be stopped
end % of confirming sessions to be stopped
    
%  Confirming new macros
Str = char('','Following goes through the to-be-started sessions,',...
    'confirming the information about Subject, Hard Drive,',...
    'Box, Group or Phase, and Program. If info shown for a subject',...
    'is correct, just hit return in response to "Correct? "',...
    'If any item needs to be corrected, type ''n'' and you',...
    'will be prompted for each item in turn.');
display(Str)

for i = size(ToBeStrtd,1):-1:1
    S = ToBeStrtd(i,1);
    ID = Experiment.Subjects(S);
    HD = NewDrives(i);
    B = NewBoxes(i);
    G = NewGroups(i);
    P = [NewProgramPath{i} NewPrograms{i}];

    sprintf('S# %d (ID# %d) \nDrive: %s \nBox#: %d \nGroup: %d \nProgram: %s',...
        S,ID,HD,B,G,P)
    Correct = input('Correct? [y/n or d for delete subject] ','s');

    switch  Correct % if response to "Correct?" was no
        case 'd'
            ToBeStrtd(i,:) = [];
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
end % of loop confirming info on to-be-started sessions
            
%% create macros based on user responses
MACRO='';
%Print=[];
for i=1:length(AS)
    MACRO{i} = ['LOAD BOX ' num2str(NewBoxes(i)) ' SUBJ ' num2str(ASids(i)) ' EXPT ' num2str(ExpIDnum) ' GROUP ' num2str(NewGroups(i)) ' PROGRAM ' NewPrograms{i}(1:end-4)];
end

%% Print Macro to Appropriate Drive
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


%% add the information of the successfully completed macro to the exp struc
i=1;
for j=AS;
        
%         if exist(['Experiment.Subject(', num2str(j), ').MacroInfo.date'])
       if isfield(Experiment.Subject(j),'MacroInfo') &&...
                ~isempty(Experiment.Subject(j).MacroInfo) &&...
                ~isempty(Experiment.Subject(j).MacroInfo(1).date)
            
                Experiment.Subject(j).MacroInfo(end+1).date = date; 
                Experiment.Subject(j).MacroInfo(end).progpath = NewProgramPath{i};
                Experiment.Subject(j).MacroInfo(end).program = NewPrograms{i};
                Experiment.Subject(j).MacroInfo(end).box = NewBoxes(i);
                Experiment.Subject(j).MacroInfo(end).id = ASids(i);
                Experiment.Subject(j).MacroInfo(end).ExpId = ExpIDnum;
                Experiment.Subject(j).MacroInfo(end).group = NewGroups(i);
                Experiment.Subject(j).MacroInfo(end).macroname = sprintf('Exp%d.MAC',ExpIDnum);%['Exp' num2str(ExpIDnum) '.MAC'];
%                 Experiment.Subject(j).MacroInfo.macrodate{end+1} = MacroDate;
       else % MacroInof field doesn't exist or is empty or its fields are empty
                Experiment.Subject(j).MacroInfo.date = date; 
                Experiment.Subject(j).MacroInfo.progpath = NewProgramPath{i};
                Experiment.Subject(j).MacroInfo.program = NewPrograms{i};
                Experiment.Subject(j).MacroInfo.box = NewBoxes(i);
                Experiment.Subject(j).MacroInfo.id = ASids(i);
                Experiment.Subject(j).MacroInfo.ExpId = ExpIDnum;
                Experiment.Subject(j).MacroInfo.group = NewGroups(i);
                Experiment.Subject(j).MacroInfo.macroname = sprintf('Exp%d.MAC',ExpIDnum);
        end
    i=i+1;
end
    
%% Close the Boxes In Case Already Open

% % TSendsession(ExpIDnum, AS)
% % assuming all old active subjects need to be terminated, do this:
% 
% % get drive letter for each subject
% closeDriveList = cell(1,length(currProgPath));
% for y = 1:length(currProgPath)
%     tmpPath = currProgPath{y};
%     closeDriveList{1,y} = tmpPath(1,1);
% end
% 
% % get rid of drive letter duplicates
% closeDriveList = cell2mat(unique(closeDriveList)); 
% 
% % issue closing command for each subject
% for D=closeDriveList
% 
% [s, w] = dos(['net use | find /i "', D, ':"']);
% b = strfind(w,'\\');
% e = strfind(w,'\');
% e = e(end);
% server = w(b:e);
% server = server(3:end-1);
% 
% curTime = clock; 
%     StartTime = sprintf('%02d:%02d:00', curTime(4), curTime(5)+2);
%     if (strcmp(server,'gallanalysis') || strcmp(server,'nel-gallistel03') || strcmp(server,'gallistallab3'))
%         % if windows xp computer
%         KillCmd = ['winrs -r:', server, ' -u:LIFE_SCIENCES\Gallistellab -p:McCogGen1 schtasks /create /sc ONCE /tn StopMedPCMacro /tr "taskkill /IM MEDPC_IV.exe" /st ', StartTime, ' /ru LIFE_SCIENCES\Gallistellab /rp McCogGen1'];
%     elseif (strcmp(server,'nel7-glab3') || strcmp(server,'nel7-glab1'))
%         % else if windows 7 computer
%         KillCmd = ['winrs -r:', server, ' -u:LIFE_SCIENCES\Gallistellab -p:McCogGen1 schtasks /create /sc ONCE /tn StopMedPCMacro /tr "taskkill /IM MEDPC_IV.exe" /st ', StartTime, ' /f'];
%     end
% 
%     dos(KillCmd);
%     display(['stopped ', D, ' drive'])
% end


%% Launch New Session in MedPC on Appropriate Computer
%MacMedPath = which('MacroMed.exe');
% NOTE: this needs to be changed to get the server name from the drive letter.
for D=DriveSet
    
    [s, w] = dos(['net use | find /i "', D, ':"']);
    b = strfind(w,'\\');
    e = strfind(w,'\');
    e = e(end);
    server = w(b:e);
    server = server(3:end-1);
    
    global DosCmd;
    curTime = clock; 
    StartTime = sprintf('%02d:%02d:00', curTime(4), curTime(5)+3);
    
    %DosCmd = sprintf('psexec %s -c -f -i -d -h "%s" Exp%d.MAC',server,MacMedPath,ExpIDnum);
    if (strcmp(server,'gallanalysis') || strcmp(server,'nel-gallistel03') || strcmp(server,'gallistallab3'))
        % if windows xp computer
        DosCmd = ['winrs -r:', server, ' -u:LIFE_SCIENCES\Gallistellab -p:McCogGen1 schtasks /create /sc ONCE /tn RunMedPCMacro /tr "C:\MED-PC~1\MacroMed.exe Exp', num2str(ExpIDnum), '.MAC" /st ', StartTime, ' /ru LIFE_SCIENCES\Gallistellab /rp McCogGen1'];
    elseif (strcmp(server,'nel7-glab3') || strcmp(server,'nel7-glab1'))
        % else if windows 7 computer
        DosCmd = ['winrs -r:', server, ' -u:LIFE_SCIENCES\Gallistellab -p:McCogGen1 schtasks /create /sc ONCE /tn RunMedPCMacro /tr "''C:\MED-PC IV\MEDPC_IV.exe'' ''C:\MED-PC IV\Macro\Exp', num2str(ExpIDnum), '.MAC''" /st ', StartTime, ' /f'];
    end

    %dos(sprintf('psexec %s -c -f -i -d -h "%s" Exp%d.MAC',server,MacMedPath,ExpIDnum));
    dos(DosCmd);
    display(['executed ', D, ' drive'])
end

display('hit r-e-t-u-r-n if everything executed properly');
keyboard

% set the field that keeps track of which subjects are active in the
% Experiment structure to be the set of Active Subjects (AS) we have been
% working with.

Experiment.Info.ActiveSubjects = AS;  


%% save experiment

TSsaveexperiment([PathName StrucName])


%% Create or alter ActiveExperiments
% (the variable that Sequencer steps through)

if exist('ActiveExperiments.mat','file') > 1
    
    cd(Dr)

    load('ActiveExperiments.mat') % This is the cell array that the Sequencer
    % uses to call the analysis of the active experiments. There is one row per
    % active experiment. There are 7 columns in a row. First column contains
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
    % The 6th col of a row of ActiveExperiments cells contains the names of the
    % plots that are to be emailed and the 7th column contains the email
    % addresses
    
    display(ActiveExperiments)
    
else
    ActiveExperiments=[];
    display('There are no active experiments')
end
%%    
if ~isempty(ActiveExperiments)
    
    L1 = 'Above is the ActiveExperiments cell array with one row per active experiment.';
    L2 = 'Are all of these experiments still active? If yes, hit return. ';
    L3 = 'If not, which number(s) should be deleted?: ';

    NoLongerActive = input(sprintf('\n%s\n%s\n%s',L1,L2,L3));
    
    if ~isempty(NoLongerActive)
    
        for r = size(ActiveExperiments,1):-1:1 % stepping through the rows

            if ismember(ActiveExperiments{r,1},NoLongerActive) % if the
                % experiment in this row is no longer active

                ActiveExperiments(r,:) = []; % delete it            
            end        
        end
    end
    
    try 
        
        if isempty([ActiveExperiments{:}]) % if they have all been deleted
            ActiveExperiments = [];
        end
        
    catch % if the cells are not all empty and contain cells whose contents
        % are cell arrays that will not concatenate, then the isempty call
        % will crash and the ActiveExperiments=[] will not execute. If all
        % the cells are in fact empty, then it won't crash and the
        % ActiveExperiments = [] will execute
    end
    
end

if ~isempty(ActiveExperiments) % if ActiveExperiments was not just created,
    
    LV = ismember([ActiveExperiments{:,1}],Experiment.Id);
    % If this experiment is already running, its location in
    % ActiveExperiments will be flagged by a 1 in this logical vector
    
    
    if sum(LV)>0 % This experiment is already running
        
        L1 = 'This experiment is already running.';
        L2 = 'Do you want to change the restricted feeding phase event code vectors?';
        L3 = 'Answer y or n (default is n, just hit Rtn): ';
        
        if strcmp(input(sprintf('\n%s\n%s\n%s',L1,L2,L3),'s'),'y')
            % if event codes for restricted feeding phases are to be
            % changed
            
            ActiveExperiments{LV,4} = FdgPhases_local;
            
        end % 
        
        L4 = 'Does this session constitute a new phase (condition, group),';
        L5 = 'with a new protocol and a new protocol-specific analysis function?';
        L6 = 'If so, respond y; if not, hit Rtn: ';
                
        if strcmp(input(sprintf('\n%s\n%s\n%s',L4,L5,L6),'s'),'y')
            % if a new protocol-specific data-analyzing function is to be
            % added
            
            ActiveExperiments{LV,5} = ProtSpecFuns_local;
            
            
            sprintf('\nPlots currently slated to be emailed:')
            
            for plt = 1:length(ActiveExperiments{LV,6})
                % stepping through currently scheduled plots, listing them
                
                sprintf('\n  %s',ActiveExperiments{LV,6}{plt})
                
            end % of listing plots currently emailed
            
            if strcmp('y',input('\nDo you want to alter this list? (y/n) ','s'))
                % if list of plots to be emailed is to be altered
                
                L1 = 'Names of plots to be emailed, enclosed in single quotes and separated by spaces';
                L2 = '(e.g., ''CmPksFds'' ''CmImbalances''): ';

                PlotNames = input(sprintf('\n%s\n  %s',L1,L2),'s');

                PlotNames = sprintf('{%s}',PlotNames);

                eval(sprintf('PN = %s;',PlotNames))

                ActiveExperiments{LV,6} = PN;
            end % of altering list of plots to be emailed
        end % of if this is a new protocol
        
        
    else % ActiveExperiments exists but this experiment is not in it yet  

        ActiveExperiments{end+1,1} = Experiment.Id;

        ActiveExperiments{end,2} = input('Format in which figures to be saved? ','s');

        ActiveExperiments{end,3} = input('Number of rows wanted in subplots? ','s');
    
        ActiveExperiments{end,4} = FdgPhases_local;
        
        ActiveExperiments{end,5} = ProtSpecFuns_local;
        
        L1 = 'Names of plots to be emailed, enclosed in single quotes and separated by spaces';
        L2 = '(e.g., ''CmPksFds'' ''CmImbalances''): ';
        
        PlotNames = input(sprintf('\n%s\n  %s',L1,L2),'s');
        
        PlotNames = sprintf('{%s}',PlotNames);
        
        eval(sprintf('PN = %s;',PlotNames))
        
        ActiveExperiments{end,6} = PN;
        
        L1 = 'Email addresses, enclosed in single quotes and separated by spaces';
        L2 = '(e.g., ''galliste@ruccs.rutgers.edu'' ''s1prash@yahoo.com''): ';
        
        Addresses = input(sprintf('\n%s\n  %s',L1,L2),'s');
        
        Addresses = sprintf('{%s}',Addresses);
        
        eval(sprintf('Ad = %s;',Addresses))
        
        ActiveExperiments{end,7} = Ad;
        
    end
    
else % ActiveExperiments does not exist
    
    
    ActiveExperiments{1,1} = Experiment.Id;
%%    
    while 1 % waiting for an acceptable graphic format
        
        Frmt = input('Format in which figures to be saved? ','s');
        
        if logical(sum(strcmp({'.pdf' '.fig' '.eps' '.tif' '.png' '.ai' '.ppm'},Frmt)))
            
            ActiveExperiments{1,2} = Frmt;
            
            break
        else
            L1 = 'Not a supported graphics format.';
            L2 = 'Supported formats are:';
            L3 = '.pdf, .fig, .eps, .tif, .png, .ai & .ppm';
            sprintf('\n%s\n%s\n%s\n',L1,L2,L3)
        end
    end % of while waiting for acceptable graphic format
%%
    ActiveExperiments{1,3} = input('Number of rows wanted in subplots? [not in quotes!] ');
    if ischar(ActiveExperiments{1,3})
        display('Do not enclose the number of rows in quotes!')
        ActiveExperiments{1,3} = input('Number of rows wanted in subplots? [not in quotes!] ');
    end
    
    ActiveExperiments{1,4} = FdgPhases_local;

    ActiveExperiments{1,5} = ProtSpecFuns_local;
%%    
    L1 = 'Names of plots to be emailed, enclosed in single quotes and separated by spaces';
    L2 = '(e.g., ''CmPksFds'' ''CmImbalances''): ';
    
    PlotNames = input(sprintf('\n%s\n  %s: ',L1,L2),'s');

    PlotNames = sprintf('{%s}',PlotNames);

    eval(sprintf('PN = %s;',PlotNames))
%%
    ActiveExperiments{1,6} = PN;

    L1 = 'Email addresses, enclosed in single quotes and separated by spaces';
    L2 = '(e.g., ''galliste@ruccs.rutgers.edu'' ''s1prash@yahoo.com''): ';

    Addresses = input(sprintf('\n%s\n  %s',L1,L2),'s');

    Addresses = sprintf('{%s}',Addresses);

    eval(sprintf('Ad = %s;',Addresses))

    ActiveExperiments{1,7} = Ad;
    
end
        
save(sprintf('%s/ActiveExperiments',Dr),'ActiveExperiments')

cd(Dr) % restoring current directory

display(sprintf('\nThe ActiveExperiments are:\n'))

TSdisplayactiveexperiments
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
% This cell array has one row for each protocol-specific function that is
% to be called by the DailyAnalysis function. The first cell in each row is
% a scalar or vector of scalars specifying the phases (conditions, groups)
% for which this analysis is to be done; the 2nd gives the function that is
% to be called; the 3rd is a string giving the arguments of this function.

PSF=cell(1,3);

Fun = 1; % initializing row index
while 1
    
    NewFun = input(...
        sprintf(...
        '\n\nProtocol-specific analysis function %d (e.g., MatchingAnalysis)? \nIf none or no further, hit return. ',Fun),'s');
    
    if isempty(NewFun)
        break
    end
      
    PSF{Fun,1} = input('\n\nPhase(s) to which this analysis applies? ');
    
    PSF{Fun,2} = NewFun;
    
    sprintf('\n\n Documentation for that function: \n\n')
    help(NewFun)
    
    
    L1 = 'Input arguments to be passed to this function';
    L1a = 'The documentation for this function is displayed above so you can see its input arguments.';
    L2 = '  [Sample Answer 1: TdyPlts,Rows,Format';
    L3 = '    These arguments are variables created by DailyAnalysis (TdyPlts)';
    L4 = '    or passed to it by the Sequencer (Rows, Format).';
    L5 = '  Sample Answer 2: TdyPlts,Rows,''''.fig'''' ';
    L6 = '    In this example, a different format is specified for the saved figures.';
    L7 = '    Note the necessary double single quotes before and after a string argument.';
    L8 = '  If no arguments are to be passed, hit return]: ';
   
    Str = sprintf('\n\n%s\n%s\n\n%s\n%s\n%s\n\n%s\n%s\n%s\n\n%s',...
        L1,L1a,L2,L3,L4,L5,L6,L7,L8);
    
    Arg = input(Str,'s');
    
    if isempty(Arg)
        Arg='TdyPlts,Rows,Format';
    end
    
    PSF{Fun,3} = sprintf('%s',Arg); % arguments of the function
    % When the string is constructed, these arguments will be encased in
    % open and close parentheses
    
    Fun = Fun+1; % incrementing row index
    
end