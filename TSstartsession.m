function TSstartsession
% Used to start new sessions by reading Excel spreadsheet. Older code,
% which is now more or less irrelevant [Sept 2015]
% terminates previous session when necessary.
% Queries user for each active subject, whether to continue with the
% session that subject is currently in or stop it. Also, whether to start a
% session; if so, whether the to-be-started session will use a new macro 
% (not previously used with that subject) or a macro previously used with
% that subject. If a new macro, it prompts user for necessary information:
% hard drive letter, box number, & MedPC program file. Also prompts for the
% information: needed by the DailyAnalysis function and puts it in (or
% updates) the cell array ActiveExperiments, which contains the information
% that is passed by the Sequencer to DailyAnalysis. Not even sure whether
% this older code still works, because has been superseded by code that
% reads required information from spreadsheet, which is much better
% approach--CRG Jan 2016

global DropboxPath

if isempty(DropboxPath)
    
    disp(char({'';'The variable ''DropboxPath'' is empty.';...
        'It must contain the path to the parent directory,';...
        'the directory that contains the Experiment folders.';...
        'Change current directory to the parent directory';...
        'and then type "Dropbox = cd" in command window.';...
        'Then type "return" and hit enter to continue.';...
        'Do not subsequently delete this global variable!';''}));    
    keyboard    
end

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
end % if the TextForTSstartsession.txt file exists

Dr = cd; 

while ~strcmp(Dr(end-6:end),'Dropbox') % Dropbox is below current directory
    
    if exist('Dropbox','dir') % it's below current directory in search path
        
        cd Dropbox
        
    else % it's above current directory
        
        cd ..
        
    end
    Dr = cd;
end % Making sure current directory is the Dropbox

evalin('base','if exist(''datatimer'');stop(datatimer);end')
    % stop datatimer so that it does not overload an Experiment structure
    % while this is running
    
if evalin('base','exist(''datatimer'')')==0
    fprintf('\nWarning: No timer object named ''datatimer''\nfound in base workspace. Hence, no data-grabbing\ntimer turned off. If one is running,\nit may cause TSsession to crash\n\n')
end

evalin('base','if exist(''analysistimer'');stop(analysistimer);end')
 % ditto for analysistimer
 
if evalin('base','exist(''analysistimer'')')==0
    fprintf('\nWarning: No timer object named ''analysistimer''\nfound in base workspace. Hence, no analysis\ntimer turned off. If one is running,\nit may cause TSsession to crash\n\n')
end

ExpIDnum = input('\n\nID number for this experiment? (e.g., 305) ');

% have the user navigate to the relevant experiment structure

L1 = 'Use the GUI to find the file of the Experiment structure.';
L2 = 'That structure will be loaded into workspace and declared global';
fprintf('\n\n%s\n   %s\n',L1,L2)

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
        'ExpId',[],'group',[],'macroname',[]);
    end % of for loop putting Marcro field in Experiment structure
end % Macro field not already in structure
%%
if strcmp(Experiment.Info.ActiveSubjects,'all')
    AS = 1:Experiment.NumSubjects;
else % active subjects specified by row vector
    Experiment.Info.ActiveSubjects = unique(Experiment.Info.ActiveSubjects);
    % in case subject indices have been duplicated, as sometimes happens
    AS = Experiment.Info.ActiveSubjects;
    
end

%%
[Tmplt,PathNm] = uigetfile ({'*.xls;*.xlsx;*.xlsm;*.xlsb'},...
    'Find ExperimentInformation Spreadsheet'); % code asking user to browse 
% for spreadsheet with all the experiment information, including the
% information needed for the to-be-started session

Template = [PathNm Tmplt]; % full name of template (including path)
%%
[~,HDs,Rw] = xlsread (Template,'H38:H200'); % read the HD column. HDs will
% contain only the letters of the drives for the to-be-started subjects; Rw
% will be a cell array with NaNs in every cell except those that contain
% the letter for a to-be-started subject

HDs = char(HDs); % converting cell array to column vector

HDs(HDs==' ')=[]; % getting rid of any blank characters

LV = ~cellfun(@isnan,Rw); % flags the rows for the subjects that are to be
% started, but starting at Row 38, i.e., first entry in this logical vector
% is for Row 38 of spreadsheet. Thus a find command that looks for the
% 'true' entries will return row #s referenced to a 0 at Row 37

Rws = 37+find(LV>0); % row #s in spreadsheet that need to be read; the find
% command will return #s referenced to a 0 at 37

% str = sprintf('A%d:A%d',Rws(1),Rws(end));
S = 1;
for r = Rws'
    SubIds(S,1) = xlsread(Template,sprintf('A%d:A%d',r,r));
    Bxs(S,1) = xlsread(Template,sprintf('I%d:I%d',r,r));
    Grps(S,1) = xlsread(Template,sprintf('J%d:J%d',r,r));
    [~,MPCs(S,1)] = xlsread(Template,sprintf('K%d:K%d',r,r));
    S=S+1;
end
    % read ID # column--only the rows for
    % the subjects to be started in this new session

LV1 = ismember(SubIds,Experiment.Subjects); % LV1 is same length as LV. It
% flags those subjects that are already in Experiment structure; ~LV1 flags those
% who are not yet in it


if any(~LV1) % there are subjects that are to be started but that are 
    % new subjects, not yet entered into experiment structure. This has
    % never been tested (9/15/2015) and probably needs fixing
    
    fprintf('\nThese subjects are not in Experiment structure:\n%s\n',num2str(SubIDs(~LV1)))
    if strcmp('a',input('Add them [a] or ignore them [Rtn]? ','s')) % add new subjects
        OldAS = Experiment.Info.ActiveSubjects;
        
        str = sprintf('B%d:B%d',Rws(1),Rws(end));
        [~,Species] = xlsread(Template,str);
        str = sprintf('C%d:C%d',Rws(1),Rws(end));
        [~,Strain] = xlsread(Template,str);
        str = sprintf('D%d:D%d',Rws(1),Rws(end));
        [~,Sex] = xlsread(Template,str);
        str = sprintf('E%d:E%d',Rws(1),Rws(end));
        ArWt = xlsread(Template,str);
        str = sprintf('F%d:F%d',Rws(1),Rws(end));
        [~,ArDate] = xlsread(Template,str);
        str = sprintf('G%d:G%d',Rws(1),Rws(end));
        [~,Source] = xlsread(Template,str);
        
        TSaddsubjects(SubIds(~LV1),Species(~LV1),Strain(~LV1),...
            Sex(~LV1),ArWt(~LV1),ArDate(~LV1),Source(LV1))
        % LV flags subjects to be started; ~LV1 flags subjects not in
        % Experiment structure
        
        % There should be some more code that reads a protocol template to add
        % protocols to the newly added subjects (if it's fully automated)
        
        if ~strcmp('all',OldAS)
            NwSubs = SubIds(~LV1);
            NwIndx = find(Experiment.Subjects==NwSubs); % the index #s for the
            % newly added subjects
            Experiment.Info.ActiveSubjects = unique(sort([OldAS NwIndx]));
        end
        
    end % add or ignore subjects not in structure    
end % there are subjects not in Experiment structure

SbIds = SubIds; % vector of ID #s for subjects to be started
i = 1;
Ss = nan(1,length(SbIds)); % row vector of subject index #s
for id = SubIds'
    Ss(i) = find(Experiment.Subjects==id); % index number is position
    % # in row vector Experiment.Subjects
    i=i+1;
end % getting index #s for the ID #s

%%
Pths = cell(length(MPCs),1);
Prgrms = cell(length(MPCs),1);
for p = 1:length(MPCs) % extracting path & file name
    in = strfind(MPCs{p},'\'); % in is a vector of the backslash positions
    % in the complete name of the MedPC program code file
    Pths{p} = MPCs{p}(1:in(end)); % path; in(end) is position of last backslash
    Prgrms{p} = MPCs{p}(in(end)+1:end); % MedPC program file name, including
    % the extension
end
%%
Exp = Experiment.Id;

MACRO = createMACRO_local(SbIds,Bxs,Exp,Grps,Prgrms); % create
% macros
disp('')
disp(char(MACRO))

str = char({'\nAbove is the macro constructed from the information on the spreadsheet.';...
    '\nIf it is correct, it will be written to the Macro folder on the';...
    '\nhard disk of the experiment-control computer. If you see a mistake,';...
    '\nanswer ''n'' to this prompt. That will abort this start, allowing';...
    '\nyou to correct the mistake on the spreadsheet and rerun TSstartsession';...
    '\n                 Is the macro correct? [y/n] '});

if strcmp('n',input(str','s'))
    fprintf('\nCorrect mistake on spreadsheet and call TSstartsession again\n')
    return
end

writemacros_local(HDs,MACRO,Exp); % write macros to the hard disk(s) of
% the control computers

addmacros_local(Ss,SbIds,Bxs,Exp,Grps,Pths,Prgrms); % add info in
% macro to Experiment.Subject(S).MacroInfo

CreateActiveExperiment_local(Exp,Template)

if ~isempty(Ss); AS = unique(sort([AS, Ss])); end % add subjects that are starting

Experiment.Info.ActiveSubjects = AS;

if strcmp('y',input('\n\nIs this experiment fully automated? [y/n] ','s'))
    if ~isfield(Experiment.Subject,'Protocols')
        char('','There is no "Protocols" field in Experiment.Subject',...
            'You will need to add a non-empty Protocols structure',...
            'to each Experiment.Subject before starting the session','')
    else % there is already a Protocols field
        S=1;
        for r = Rws'
            PrtNums(S,1) = xlsread(Template,sprintf('L%d:L%d',r,r));
            S=S+1;
        end
%         str = sprintf('L%d:L%d',Rws(1),Rws(end));
%         PrtNums = xlsread(Template,str); % read Column L of the non-blank
        % row #s 38 and below

        if isempty(PrtNums)
            fprintf('No protocol #s in Col C of %s\nYou will need to fill in Experiment.Subject.Protocols.Current\nwith the number of the protocol with which this session is to start\n',Tmplt)
        else % PrtNums not empty
            disp(char('','The current sessions for those subjects who are to start',...
                'this new session MUST(!) be stopped BEFORE proceeding'))
            if strcmp('y',input('\nHave you stopped those current sessions? [y] ','s'))
            end
            iii = 1;
            for SS = Ss % stepping through subjects being started

                if size(Experiment.Subject(SS).Protocols.Parameters,2)>=PrtNums(iii)
                    Experiment.Subject(SS).Protocols.Current=PrtNums(iii);

                    C = Experiment.Subject(SS).Protocols.Current; % current protocol number

                    DL = Experiment.Subject(SS).MacroInfo(end).progpath(1); % path to the file

                    BN = Experiment.Subject(SS).MacroInfo(end).box; % box number

                    FN =sprintf('%s:/Med-PC IV/Data/Box%dCurrentParameters.txt',DL,BN);
                    % complete name of remote file to be written to

                    dlmwrite(FN, Experiment.Subject(SS).Protocols.Parameters(:,C), 'newline', 'pc')
                    % Writing to the parameter file read by MedPC

                    OP = zeros(size(Experiment.Subject(SS).Protocols.Parameters(:,C)));

                    OFN = sprintf('%s:/Med-PC IV/Data/Box%dOldParameters.txt',DL,BN);
                    % name of the corresponding old parameters file

                    dlmwrite(OFN,OP, 'newline', 'pc')
                    % writes all 0's into the corresponding OldParameters
                    % file so as to guarantee that the old parameter file
                    % differs from the new one. (Otherwise, the new one
                    % would not be read into MedPC's internal array.)

                    iii=iii+1;

                else % protocol # > than # of protocols
                    fprintf('\nProtocol number you have specified > number of\nprotocols in Experiment.Subject(%d).Protocols.Parameters\n',SS)
                    fprintf('Therefore, nothing written for this subject to text files read by MedPC program!\n')
                    iii=iii+1;
                    continue
                end % of if protocol # > # protocols      
            end % of for
        end % of if PrtNums empty or not
    end % if Protocols field isn't/is present


end % if fully automated

TSsaveexperiment([PathName StrucName])

DT = input('Enter time in seconds to first data grab (e.g., 900 = 15 minutes): ');
AT = input('Enter time in seconds to first data analysis (e.g., 28800 = 8 hrs): ');
try
    evalin('base','if exist(''datatimer''); set(datatimer,''StartDelay'',DT),start(datatimer);else;DataGrabberTimer;end')
    % start the datatimer if it already exists in the base workspace; if it
    % does not, then call the function that creates it
    
    evalin('base','if exist(''analysistimer'',''var'') set(analysistimer,''StartDelay'',AT);start(analysistimer);else CreateAnalysisTimer;end')
    % start the analysistimer if it already exists in the base workspace;
    % if not, then call the function that creates it
catch ME
    display(ME)
end

disp(char('','TSstartsession is done!',...
    'Now start the macro(s), either via remote desktop',...
    'access to the indicated hard drive(s) or working directly',...
    'on the desktops of the experiment-control computers.',...
    '   To verify that data grabbing timer is on type "datatimer".',...
    'If there is no such object, type "DataGrabberTimer".',...
    'and answer the prompts.',...
    '   To check that analysis timer is on, type "analysistimer".',...
    'If there is no such object, type "CreateAnalysisTimer".',...
    'and answer the prompts.',''))

%% child functions

function MAC = createMACRO_local(IDs,Bxs,Exp,Grps,Prgrms)
MAC='';
for mm=1:length(IDs) % building macro for each subject
    MAC{mm} = ['LOAD BOX ' num2str(Bxs(mm)) ...
        ' SUBJ ' num2str(IDs(mm)) ...
        ' EXPT ' num2str(Exp) ' GROUP ' num2str(Grps(mm)) ...
        ' PROGRAM ' Prgrms{mm}(1:end-4)]; % deleting .MPC extension
    % from the macro written to the hard disk
end

%% -----------------------------------------------------------

function Mes = writemacros_local(HDs,MAC,Exp)
Mes = [];
try
    DriveSet = HDs;
    DriveSet = unique(HDs); % the unique non-blank characters

    for d = 1:length(DriveSet) % for each unique drive letter  
        D = DriveSet(d);
        r = find(HDs==D); % find the macro rows that have that as the drive letter
        fid = fopen([D ':/MED-PC IV/MACRO/' 'Exp' num2str(Exp) '.MAC'], 'wt');
        %create or modify the relevant MAC file on that drive
        fprintf(fid, '%s\n', ['                           Exp' num2str(Exp) '.MAC']); %make the first row the title
        fprintf(fid, '%s\n', MAC{r}); % make the following rows, the rows
        % of the macro that are for drive D
        fclose(fid); 
        type([D ':/MED-PC IV/MACRO/' 'Exp' num2str(Exp) '.MAC'])
        % This displays the macro that has just been written

    end

    disp(char({'';'The macros have been written to the MedPCIV->Macro';...
        'folders of the utilized computers. You will be able';...
        'to start the boxes controlled by a given computer';...
        'by pressing the F5 key on that computer to bring up';...
        'the browser window showing the MedPC Macros and';...
        'selecting the macro for the current experiment #.';...
        'BE SURE TO FIRST STOP THOSE SUBJECTS ALREADY RUNNING;';...
        'BEFORE CALLING A MACRO THAT STARTS THEM ON A NEW SESSION!';''}))


catch ME

    Mes = getReport(ME);

    fprintf('\nWriting the macros to the MedPCIV->Macro folders failed\nfor reasons indicated in  following message:\n%s\n\n',Mes)

    disp(char({'';'You will need to start the Subjects one by one';''}))

end
%%------------------------------------------------------ 
function addmacros_local(Ss,IDs,Bxs,Exp,Grps,Pths,Prgrms)
global Experiment
ii=1;
for jj=Ss;

    if ~isfield(Experiment.Subject(jj),'MacroInfo')
        Experiment.Subject(jj).MacroInfo=struct('date',date,...
            'progpath',Pths{ii},'program',Prgrms{ii},...
            'box',Bxs(ii),'id',IDs(ii),...
            'ExpId',Exp,'group',Grps(ii),...
            'macroname',sprintf('Exp%d.MAC',Exp));
        % Notice that the entry in the program field includes the extension,
        % that is, it gives the complete file name

    elseif isempty(Experiment.Subject(jj).MacroInfo) ...
            || isempty(Experiment.Subject(jj).MacroInfo(1).date)
        % if MacroInfo field exists but has no subfields or if it has
        % subfields but they are empty
        Experiment.Subject(jj).MacroInfo(1).date = date; 
        Experiment.Subject(jj).MacroInfo(1).progpath = Pths{ii};
        Experiment.Subject(jj).MacroInfo(1).program = Prgrms{ii};
        Experiment.Subject(jj).MacroInfo(1).box = Bxs(ii);
        Experiment.Subject(jj).MacroInfo(1).id = IDs(ii);
        Experiment.Subject(jj).MacroInfo(1).ExpId = Exp;
        Experiment.Subject(jj).MacroInfo(1).group = Grps(ii);
        Experiment.Subject(jj).MacroInfo(1).macroname = sprintf('Exp%d.MAC',Exp);
        % Notice that the entry in the program field includes the extension,
        % that is, it gives the complete file name

    else % MacroInfo field exists and has subfields
        Experiment.Subject(jj).MacroInfo(end+1).date = date; 
        Experiment.Subject(jj).MacroInfo(end).progpath = Pths{ii};
        Experiment.Subject(jj).MacroInfo(end).program = Prgrms{ii};
        Experiment.Subject(jj).MacroInfo(end).box = Bxs(ii);
        Experiment.Subject(jj).MacroInfo(end).id = IDs(ii);
        Experiment.Subject(jj).MacroInfo(end).ExpId = Exp;
        Experiment.Subject(jj).MacroInfo(end).group = Grps(ii);
        Experiment.Subject(jj).MacroInfo(end).macroname = sprintf('Exp%d.MAC',Exp);
    end
    ii=ii+1;
end
%%--------------------------------------------------------------------------
function CreateActiveExperiment_local(Exp,Temp)
% Modifies or creates the ActiveExperiments file, which contains the
% ActiveExperiments variable, which is an n x 5 cell array, where n is the
% number of active experiments. The cells in Col 1 contain the Experiment
% ID #s; the cells in Col 2 contain the figure format text (e.g., '.fig');
% the cells in Col 3 contain the number of rows of panels in the figures
% that contain multiple panels; the cells in Col 4 contain the ProtSpecFuns
%  cell array, which gives the information necessary to call a protocol-specific
% analysis function; the cells in Col 5 contain the email addresses to which
% alerts and specified figures are to be sent.

%{
 ActiveExperiments used to
 have 6 columns, with the 4th column containing a cell array that gave the
 event codes for the starts and stops of the feeding phases (FdgPhases),
 but this was eliminated 04/22/2015, when it was realized that that
 information belonged in the arguments passed in to the protocol-specific
 analysis functions. The old code for this has been commented out below; it
 should be removed when we are sure this change works--CRG
%}
global DropboxPath
global Experiment % need to access this to get event codes
% in the workspace of this function
TSdeclareeventcodes
%
if isempty(DropboxPath)
    char('','The global variable DropboxPath is empty. Set the',...
        'current directory to the parent Dropbox directory',...
        '(the directory in which the experiment folders are kept),',...
        'then type "DropboxPath=cd" -Enter. Then "return" -Enter','')
    keyboard
end
%%    
if exist([DropboxPath filesep 'ActiveExperiments.mat'],'file')
    load([DropboxPath filesep 'ActiveExperiments.mat']) % This file contains
    % the variable ActiveExperiments, which is a n x 5 cell array, where n
    % is the number of active experiments
    LV = ismember([ActiveExperiments{:,1}],Exp); % flags current
    % experiment if it is already in ActiveExperiments. (The variable
    % ActiveExperiments is in the file ActiveExperiments.)
    
    if any(LV) % current experiment is already in ActiveExperiments
        
        if ~strcmp('y',input('\nThis experiment is already in ActiveExperiments.\nDo you want to replace the data analysis information already there? [y/n] ','s'))
            return
        else % yes, replace
            
            [~,Frmt] = xlsread(Temp,'A31:A31'); % read figure format
            ActiveExperiments{LV,2} = Frmt{1}; % fig format in 2nd cell of row
            ActiveExperiments{LV,3} = xlsread(Temp,'A33:A33'); % # rows in plots
%             [~,EC] = xlsread(Temp,'A23:J23'); % read event names
%             EC2 = cell(1,length(EC)/2);
%             for cc = 1:length(EC2)
%                 EC2{cc} = [eval(EC{2*cc-1}) eval(EC{2*cc})]; % convert event
%                 % names in row vectors of start and stop event codes
%             end
%             ActiveExperiments{LV,4} = EC2; % cell array of event code row
%             % vectors for the start and stop of feeding phases
            [~,PrtSpcFuns] = xlsread(Temp,'A25:J25'); % protocol-specific data-
            % analysis functions
            [~,Args] = xlsread(Temp,'A27:J27'); % input arguments
            PhaseNums = xlsread(Temp,'A29:J29');% phases to which they apply
            PN = cellstr(int2str(PhaseNums')); % converting to 1-col cell array
            for ccc = 1:length(PN)
                PN{ccc} = str2double(PN{ccc}); % converting string#s to #s
            end
            ActiveExperiments{LV,4} = [PN PrtSpcFuns' Args']; % ProtSpecFuns
            % cell array in col-4 cell
            [~,ActiveExperiments{LV,5}] = xlsread(Temp,'A35:J35'); % email addresses
        end % replace/don't replace entry in existing ActiveExperiments
        
    else % current experiment not in existing ActiveExperiments
        ActiveExperiments{end+1,1} = Exp; % Experiment ID in 1st cell of new row
        [~,Frmt] = xlsread(Temp,'A31:A31'); % read figure format
        ActiveExperiments{end,2} = Frmt{1}; % fig format in 2nd cell of row
        ActiveExperiments{end,3} = xlsread(Temp,'A33:A33'); % # rows in plots
%         [~,EC] = xlsread(Temp,'A23:J23'); % read event names for start and
%         % stops of feeding phases
%         EC2 = cell(1,length(EC)/2);
%         for cc = 1:length(EC2)
%             EC2{cc} = [eval(EC{2*cc-1}) eval(EC{2*cc})]; % convert event
%             % names to event code row vectors
%         end
%         ActiveExperiments{end,4} = EC2; % event codes in col-4 cell
%         % for the start and stop of feeding phases
        [~,PrtSpcFuns] = xlsread(Temp,'A25:J25'); % protocol-specific data-
        % analysis functions
        [~,Args] = xlsread(Temp,'A27:J27'); % input arguments for them
        PhaseNums = xlsread(Temp,'A29:J29');% phases to which they apply
        PN = cellstr(int2str(PhaseNums')); % converting to 1-col cell array
        for ccc = 1:length(PN)
            PN{ccc} = str2double(PN{ccc}); % converting string#s to #s
        end
        ActiveExperiments{end,4} = [PN PrtSpcFuns' Args']; % ProtSpecFuns
        % cell array in col-5 cell
        [~,ActiveExperiments{end,5}] = xlsread(Temp,'A35:J35'); % email addresses
        % in col-6 cell
    end % current experiment already in ActiveExperiments or else not
               
else % No ActiveExperiments file: create active experiments cell array

    ActiveExperiments=cell(1,5);
    ActiveExperiments{1,1} = Exp; % Experiment ID
    [~,ActiveExperiments{1,2}] = xlsread(Temp,'A31:A31'); % figure format
    % in col-2 cell
    ActiveExperiments{1,3} = xlsread(Temp,'A33:A33'); % # rows in plots
    [~,EC] = xlsread(Temp,'A23:J23'); % read event names for start and
    % stops of feeding phases
%         EC2 = cell(1,length(EC)/2);
%         for cc = 1:length(EC2)
%             EC2{cc} = [eval(EC{2*cc-1}) eval(EC{2*cc})]; % convert event
%             % names to event code row vectors
%         end
%         ActiveExperiments{1,4} = EC2; % event codes in col-4 cell
%         % for the start and stop of feeding phases
    [~,PrtSpcFuns] = xlsread(Temp,'A25:J25'); % protocol-specific data-
    % analysis functions
    [~,Args] = xlsread(Temp,'A27:J27'); % input arguments for them
    PhaseNums = xlsread(Temp,'A29:J29');% phases to which they apply
    PN = cellstr(int2str(PhaseNums')); % converting to 1-col cell array
    for ccc = 1:length(PN)
        PN{ccc} = str2double(PN{ccc}); % converting string#s to #s
    end
    ActiveExperiments{1,4} = [PN PrtSpcFuns' Args']; % ProtSpecFuns
    % cell array in col-5 cell
    [~,ActiveExperiments{1,5}] = xlsread(Temp,'A35:J35'); % email addresses
    % in col-6 cell
end
save([DropboxPath filesep 'ActiveExperiments'],'ActiveExperiments')