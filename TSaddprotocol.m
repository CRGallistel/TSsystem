function [Params,ProtocolStructure] = TSaddprotocol(Exp,Subjects,varargin)
% TSaddprotocol adds a new column of protocol parameters, specifying a new 
% protocol in the Protocol structure in the Protocols field at the Subject 
% level of an Experiment structure. To be called once for each new protocol
% that is to be added to a given set of subjects. Also adds corresponding
% DecisionField, DecisionCode and DecisionCriteria
%
% Syntax: [Params ProtocolStructure] = TSaddprotocol(Exp,Subjects,Variable-Value pairs),
%
% where Exp is the ID# of the experiment and Subjects is a row(!) vector of
% Subject indices specifying the subjects to whose sequence of protocols
% the new protocol is to be added. THESE TWO ARGUMENTS ARE OBLIGATORY
%
% ProtocolStructure is the 1-column structure showing the
% column that was added to the structure in the Protocols field of each
% subject specified in Subjects. It has 4 fields: .Parameters;
% .DecisionFields; .DecisionCode; & .DecisionCriteria. Params is the column
% vector of new parameter values; it also appears in the Parameters field
% of ProtocolStructure. The structure in the Protocols field of Experiment
% has 2 more fields: .Current and .Info. This function does not alter the
% contents (if any) of those fields. As in other Matlab commands, enter
% only those variable-value pairs for which you want to change the value
% of the variable from its default value.
%
% The variable-value pairs are:
%   'Protocol', ['M' 'A' or 'S'];
%   'Dawn' [time of lights on in HH:MM format];
%   'Dusk'[time of lights off];
%   'ErlStrt' [time when early feeding phase starts in HH:MM format];
%   'ErlStp' [time when it stops];
%   'LtStrt'[time when late feeding phase starts];
%   'LtStp'[time when it stops];
%   'ITI' [expected intertrial interval in autoshape & switch protocols in
%       seconds];
%   'p(S)' [probability of a short trial: specify as chances out of 10000;
%       for example: p(S) = .5 is specified by the value 5000];
%   'p(O)' [probability of an operant trial, in chances out of 10000];
%   'FdLat1' [feeding latency for Hopper 1 in seconds];
%   'FdLat2' [feeding latency for Hopper 2];
%   'VI1 [variable interval for Hopper 1 in seconds]';
%   'VI2' [variable interval for Hopper 2];
%   'Flag' [false for matching protocol, true for autoshape and switch]

global Experiment

if nargin<1
    Exp = input('\n\nID # of Experiment to which protocol is to be added? ');
end

if ~isnumeric(Exp)
   fprintf('\n1st argument must be the ID # of the Experiment\n')
   return
end

if nargin<2
    Subjects = input('Row vector of subjects to which protocol to be added: ');
end

if ~isnumeric(Subjects) || size(Subjects,1)>1
    fprintf('\nSecond argument (Subjects) must be\nscalar or ROW VECTOR(!) whose elements\nare subject index number(s)\n')
    return
end

while any(~ismember(Subjects,1:Experiment.NumSubjects))
    fprintf('\nAt least one entry in the Subjects row vector\is not within the range of Subject index numbers\n')
    Subjects = input(sprintf('Row vector of index numbers for subjects\nwho will run with the to-be-specified protocol parameters:'));
end
    
ProtocolStructure = struct('Parameters',[],'DecisionFields',[],'DecisionCode',[],...
    'DecisionCriteria',[],'Current',[],'Info',[]); % initializing
%  Added the 'info' field 2/21/13

if strcmp('n',input('Is this Matching, Autoshape2H or Switch protocol? [y/n] ','s'))
    
    if strcmp('y',input('Parameters stored in available text file? [y/n] ','s'))
        
        [FN,PN] = uigetfile('*.txt','Find file w Parameters','ProtocolParameters.txt');
        
        if ~FN % could not find file with parameter values
            fprintf('\nCreate text file(s)\nwith parameter values for your protocol;\nthen try again.\n')
        else
            ProtStruc = struct('Parameters',[],'ParameterNames',[]);
            fid = fopen([PN '/' FN],'rt'); % open file to read the text
            
            s = fgets(fid); % get first line
            r = 1; % initializing row counter
            while (ischar(s)) % end of file not yet reached
               ProtStruc.Parameters(r,1) = str2num(s);
               r = r+1;
               s = fgets(fid);
            end;
            
            fclose(fid)
            
        end
        
    else % parameters not stored in text file
        ProtStruc = struct('Parameters',[],'ParameterNames',[]);
        fprintf('\nAdding parameter values 1 by 1:\n')
        for r = 1:input('Number of parameters in your protocol? ');
            ProtStruc.Parameters(r,1) = input(sprintf('Value for Parameter %d? ',r));
        end
        
    end % if parameters input from text file or one by one
    
    Nms = cell(0,1);
    if strcmp('y',input('Specify parameter names? [y/n] ','s'))
        
        if strcmp('c',input('Names in a cell array (else specify 1 by 1)? [c/rtn]: ','s'))
            CA = input('File name or variable name? ','s');
            E = ['exist(''' CA ''')'];
            while 1
                switch evalin('base',E)
                    
                    case 0 % doesn't exist as variable in base workspace or on search path
                        fprintf('\nCannot find that variable or that file\n')
                        [FN,PN] = uigetfile('*.mat','Find file with ParameterName cell array','*.mat');
                        load([PN FN])
                        ProtStruc.ParameterNames = ParameterNames;
                        
                    case 1 % variable in base work space
                        ProtStruc.ParameterNames = evalin('base',CA);
                        
                    case 2 % file on search path
                        ProtStruc.ParameterNames = load([PN FN]);
                end
                break
            end
            
        else % specify 1 by 1
                        
           for nm = 1:length(ProtStruc.Parameters)
               Nms{nm,1} = input(sprintf('Name for Parameter %d: ',nm),'s');
           end
           Nm = true;
        end
    else
        Nm = false;
    end
    
    L = length(ProtStruc.Parameters);
    if L>0 && L<15
        ProtStruc.Parameters=[ProtStruc.Parameters;zeros(15-L,1)];
    end

    for S = Subjects
        
        if isfield(Experiment.Subject(S),'Protocols') &&...
                isfield(Experiment.Subject(S).Protocols,'Parameters')
            % there is a Protocols field and it contains a Parameters field
            
            if ~isempty(ProtStruc.Parameters)
                Experiment.Subject(S).Protocols.Parameters(:,end+1) = ProtStruc.Parameters;
            end
            
            if ~isempty(ProtStruc.ParameterNames)
                Experiment.Subject(S).Protocols.ParameterNames(:,end+1) = ProtStruc.ParameterNames;
            end
           
        else % no Protocols field
            
            Experiment.Subject(S).Protocols = ProtStruc;
            
        end

    end
    
    return
    
end % if not one of the standard 3 protocols (Matching, Autoshape2H, Switch)
        

N ={'Dawn';'Dusk';'ErlStrt';'ErlStp';'LtStrt';'LtStp';'ITI';...
    'p(S)';'p(O)';'FdLat1';'FdLat2';'VI1';'VI2';'Flag';'None'}; % possible
% subjects in subject-value pairs, i.e., the names of parameters that may
% be set

SV = [{'Protocol'};N;];
if ~isempty(varargin)
    for a = 1:2:length(varargin)-1
        if sum(strcmp(varargin{a},SV)) < 1
            fprintf('\n''%s'' is not the name of a subject in a subject-value pair;\ncheck spelling\n',varargin{a})
            return
        end
    end
end

if evalin('base','exist(''Experiment'',''var'')')
    
    if Exp == Experiment.Id
        
        yn = input('\nThis Experiment structure is in the base workspace. Use it? [y/n] ','s');
        
        if strcmp('n',yn)
            
            yn2 = input('\nContinue and overwrite Experiment structure now in base workspace? [y/n] ','s');
            
            if strcmp('n',yn2)
                
                return
                
            elseif strcmp('y',yn2)
                
                TSloadexperiment(sprintf('Experiment%d.mat',Exp));
                
                Exper = sprintf('Experiment%d.mat',Exp);
                
                FN = which(Exper);
                
            end
            
        elseif strcmp('y',yn)
            
            Exper = sprintf('Experiment%d.mat',Exp);
            
            if exist(Exper,'file') % saved version of Experiment is on
                % search path
                
                FN = which(Exper); % prepends full path
                
            else % saved version of Experiment not on search path
                
                fprintf('\nFind directory to which Experiment structure will be saved\n')
                
                Path = uigetdir('/Users/galliste/Dropbox','Directory to save to');
                
                FN = [Path '/' Exper]; % full path for saving structure
            end % if saved version on/not on search path
                
        end
        
    else % there is another Experiment structure in the base workspace
        
        fprintf('\nThere is another Experiment structure in the base workspace;\n')
        
        yn = input('\nContinue & overwrite it? [y/n] ','s');
        
        if strcmp('n',yn)
            return
        end
    end % if structure in base workspace is or is not same 
end % if there is an Experiment structure in base workspace

if ~exist('yn','var') || strcmp('n',yn) % if there is no Experiment
    % structure in the base workspace or there is, but it is to be
    % overwritten
    
    Exper = sprintf('Experiment%d.mat',Exp);
    
    if (exist(Exper,'file') == 2)% the Experiment structure is on the search path

        TSloadexperiment(Exper)

    else % Specified file not on search path

        [FN,Path] = uigetfile('Experiment*.mat','Find Experiment file');
        
        FN = [Path FN];

        if FN % if user finds the Experiment file

            TSloadexperiment(FN)

        else
            return
        end
    end % if file on search path or not
end % if Experiment structure is to be loaded
    

if ~isempty(varargin) % user has specified in the call the kind of protocol
    % and the parameters to be changed from their default values
    
    while iscell(Subjects) || ischar(Subjects)
        
        disp('\nSubjects argument is a cell array or string; it must be a numerical row vector\n\n')
        
        clear Subjects
        
        Subjects = input('Row vector of subject index numbers: ');
        
    end
    
    LVprot = strcmp('Protocol',varargin); % flags location of the "subject"
    % in the protocol-specifying subject-value pair in varargin
    
    if sum(LVprot) < 1
        
        disp(char({' ';'The subject-value pair arguments do not specify';...
            'the kind of protocol (M, A or S). To specify a kind';...
            'of protocol, enter as an argument ''Protocol'', then';...
            'a comma (to separate arguments), then ''M'', ''A'' or ''S''';' '}))
        return
        
    else % a kind of protocol is specified in varargin
        
        rw = find(LVprot)+1; % index # of varargin cell containing the letter
        % identifying the kind of protocol
        
        if sum(strcmp(varargin{rw},{'M' 'A' 'S'}))==1 % if the value
            % entered is one of the three that designates a kind of
            % protocol
            
            Kind = varargin{rw}; % the kind of protocol
            
            switch Kind % load appropriate default protocol
                case 'M'
                    disp('\nLoading default matching protocol\n')
                    [Pdef,FldsDef,CodeDef,CritDef] = DefaultMatchingParameters;
                case 'A'
                    disp('\nLoading default autoshape protocol\n')
                    [Pdef,FldsDef,CodeDef,CritDef] = DefaultAutoshapeParameters;
                case 'S'
                    disp('\nLoading default switch protocol\n')
                    [Pdef,FldsDef,CodeDef,CritDef] = DefaultSwitchParameters;
            end
            
            NumChanges = 0;
            
            for i = 1:length(N) % stepping through the parameters changing
                % those that are to be changed
                
                LVpar = strcmp(N{i},varargin); % flags the cell (if any)
                % that is the "subject" part of a subject-value pair for
                % the parameter N{i}
                
                if sum(LVpar) < 1 % not a parameter whose value is to be changed
                    continue
                else
                    rw = find(LVpar > 0)+1; % index # of cell 
                    % in varargin containing the new value for parameter N{i}
                    Pdef(i) = varargin{rw};
                    
                    NumChanges = NumChanges + 1;
                end
            end % of making the parameter changes
            
        else % value for subject 'Protocol' is not one of the permissible values
            
            disp('\nArgument error:\n  Value for ''Protocol'' must be ''M'', ''A'' or ''S''\n\n')
            return
        end
    end
    
    if NumChanges==0
        disp('\nWarning: No changes made in default parameters\n')
    end
    
    Params = Pdef;
    
    for S = Subjects
        if ~isfield(Experiment.Subject(S),'Protocols') || isempty(Experiment.Subject(S).Protocols) % Protocols field
            % not yet created for this subject
            Experiment.Subject(S).Protocols =ProtocolStructure;
            % Creates Protocols field for this subject
        end  
        Experiment.Subject(S).Protocols.Parameters(:,end+1) = Params; 
        % adds column to Parameters field
    end
    
    if strcmp('y',input('\nUse default Decision Field(s)? [y/n] ','s'))
        
        for S = Subjects
            Experiment.Subject(S).Protocols.DecisionFields{end+1} = FldsDef;
        end
        
    elseif strcmp('y',input('\nUse most recent Decision Field(s)? [y/n] ','s'))
        
        for S = Subjects
            Experiment.Subject(S).Protocols.DecisionFields{end+1} = ...
                Experiment.Subject(S).Protocols.DecisionFields{end};
        end
        
    else
        
        NewDF = input('\nComplete path to new decision field(s): ');
        
        for S = Subjects
            Experiment.Subject(S).Protocols.DecisionFields{end+1} = NewDF;
        end
    end % of putting in decision field(s)
    
    
    if strcmp('y',input('\nUse default DecisionCode? [y/n] ','s'))
        
        for S = Subjects
            Experiment.Subject(S).Protocols.DecisionCode{end+1} = CodeDef;
        end
        
    elseif strcmp('y',input('\nUse most recent DecisionCode? [y/n] ','s'))
        
        for S = Subjects
            Experiment.Subject(S).Protocols.DecisionCode{end+1} = ...
                Experiment.Subject(S).Protocols.DecisionCode{end};
        end
        
    else
        
        NewDC = input('\nVariable containing new decision-code string: ');
        
        for S = Subjects
            Experiment.Subject(S).Protocols.DecisionCode{end+1} = NewDC;
        end
    end % of putting in decision code
    
    
    if strcmp('y',input('\nUse default Decision Criteria? [y/n] ','s'))
        
        for S = Subjects
            Experiment.Subject(S).Protocols.DecisionCriteria{end+1} = CritDef;
        end
        
    elseif strcmp('y',input('\nUse most recent Decision Criteria? [y/n] ','s'))
        
        for S = Subjects
            Experiment.Subject(S).Protocols.DecisionCriteria{end+1} = ...
                Experiment.Subject(S).Protocols.DecisionCriteria{end};
        end
        
    else
        
        NewDCrit = input('\nNew decision criteria: \n','s');
        
        for S = Subjects
            Experiment.Subject(S).Protocols.DecisionCriteria{end+1} = NewDCrit;
        end
    end % of putting in decision criteria
    
    ProtocolStructure.Parameters = Params;
    ProtocolStructure.DecisionFields = Experiment.Subject(Subjects(1)).Protocols.DecisionFields{end};
    ProtocolStructure.DecisionCode = Experiment.Subject(Subjects(1)).Protocols.DecisionCode{end};
    ProtocolStructure.DecisionCriteria = Experiment.Subject(Subjects(1)).Protocols.DecisionCriteria{end};
    % Notice that all the above code leaves the contents of the Current and
    % Info fields unchanged, which is what one wants
    
    fprintf('\nUse browser to inspect the column that\nhas been added to the fields of Protocols.\nType "return" to continue\n\n')
    
    keyboard
    
    if strcmp('y',input('Okay to save Experiment structure? [y/n] ','s'))
        TSsaveexperiment(FN) 
    end

    return
    
end
                  
% Code from here on has been only partially tested -CRG 11/23/2013
P = []; % initializing
    
if nargin < 2 % subjects not specified in function call
    
    while 1
        Subjects = input('\nVector of subject INDICES(NB not IDs): ');
        
        if ischar(Subjects) && strcmp('all',Subjects)
            
            TSlimit('Subjects',1:Experiment.NumSubjects)
            Subjects = Experiment.Info.ActiveSubjects;
            % vector of subject index numbers
                        
        elseif isnumeric(Subjects) && any(~ismember(Subjects,1:Experiment.NumSubjects))
            
            fprintf('\nOne or more numbers in the input vector\n is not a valid subject INDEX #\n\n')
            continue
            
        else
            fprintf('\n\nInput is not a numerical vector\n\n')
            continue
            
        end
        
        if all(ismember(Subjects,1:Experiment.NumSubjects))
            break
        end
    end % getting row vector of subject indices
end

c=1;
for S = Subjects

    if isfield(Experiment.Subject(S),'Protocols') &&...
            isstruct(Experiment.Subject(S).Protocols) &&...
            ~isempty(Experiment.Subject(S).Protocols.Parameters)

        P(:,c) = Experiment.Subject(S).Protocols.Parameters(:,end);

        c=c+1; % Successive columns of P contain parameters for successive
        % subjects in Subjects vector
        
    else % add protocols 1 by 1        
        
        Experiment.Subject(S).Protocols = ProtocolStructure; % creates
        % Protocol field in Experiment.Subject(S), which field contains 6 empty
        % subfields: Parameters, DecisionField, DecisionCode,
        % DecisionCriteria, Current & Info
        
        P(:,c) = nan(15,1);
        
        c=c+1;
        
    end
end % retrieving from Experiment structure the latest protocol
% parameter values or adding a Protocols field
        
fprintf('\nThe most recent protocol parameters for these subjects are:\n')
disp(P)
disp(['           ';'***********';'           '])

Pdef =[];

Str = char({' ';'You will now be asked to specify the type of protocol';...
    '(Matching, Autoshaping or Switch) to be added. Whichever type';...
    'you select will be added to the subjects you have specified.';...
    'You will then be able to specify new values for its parameters.';' '});

disp(Str)

while 1
    Kind = input('\nKind of protocol to be added? [answer M, A or S] ','s');

    switch Kind
        case 'M'
            fprintf('\nThis is the default matching protocol\n')
            [Pdef,FldsDef,CodeDef,CritDef] = DefaultMatchingParameters;
        case 'A'
            fprintf('\nThis is the default autoshape protocol\n')
            [Pdef,FldsDef,CodeDef,CritDef] = DefaultAutoshapeParameters;
        case 'S'
            fprintf('\nThis is the default switch protocol\n')
            [Pdef,FldsDef,CodeDef,CritDef] = DefaultSwitchParameters;
        otherwise
            fprintf('\nMust answer ''M'', ''A'' or ''S''\n')
    end

    if ~isempty(Pdef);break;end
end
%%
disp(char({' ';'******';' '}))

fprintf('\n\nNew protocols of a given type are specified\nby starting with either the Default for that \ntype or the Latest protocol\n')

if ~isempty(P)
    M = input('\nUse Latest protocol? -or Default protocol? [answer L or D] ','s');
else
    M = 'D';
end

while 1 % choosing basis for new column of parameter vectors
    switch M
        case 'L'
            NPV = P; % new parameter column vector
            break
        case 'D'
            NPV = Pdef;
            break
        otherwise
            fprintf('\nYou did not answer with an L or a D\n')
            M = input('\nUse Latest protocol? -or Default protocol? [answer L or D]','s');
    end
end % of choosing basis for new column vector of parameter values

%%
disp(char({' ';'******';' '}))

fprintf('\nTo specify which parameters are to be changed,\nuse the following names, enclose each name in\nsingle quotes and enclose the set in curly braces:\n\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s',...
    N{1},N{2},N{3},N{4},N{5},N{6},N{7},N{8},N{9},N{10},N{11},N{12},N{13},N{14},N{15})
        
    
Prms = input('\n\nWhich parameters are to be changed\n[answer from above list; sample answer: {''VI1'' ''VI2''}]? ');

Day = 24*3600; % seconds in a day

if ~strcmp('None',Prms{end}) % if there are changes to be made

    str = char({'In giving values for these parameters, use the following';...
        '   formats &/or units:';...
        ' -HH:MM (military time) for Dusk, Dawn and the starts and stops of';...
        '    feeding phases (these will be converted to time in seconds).';...
        ' -Use seconds for ITI, feeding latencies and VIs.';...
        ' -Use decimal probabilities for p(S) and p(O) (They will be';...
        '    converted to chances out of 10,000).';...
        ' -When giving a cell array of parameter values in which each cell';...
        '    contains only a single number, enclose each number in parentheses';...
        '    inside the curly braces [e.g., {(160) (320)} gives values';...
        '    for VI1 and VI2]'});
    disp('    ')
    disp(str)

    Vals = input('\n\nGive  cell array of new values for the selected parameters: ');

    for p = 1:length(Prms) % stepping through the parameters to be changed
        
        LV = strcmp(Prms{p},N); % flags parameter to be changed
        
        if find(LV>0)<=6 % if any of the 1st 6 parameters are among those
            % that need to be changed. The 1st 6 are all times of day
            
            NPV(LV) = Day*(datenum(Vals{p})-floor(datenum(Vals{p})));
            % converts military time of day to time in seconds since
            % midnight (MedPC units)
            
        elseif ismember(find(LV>0),[8 9]) % if parameters 8 &/or 9 are among
            % those that need to be changed
            
            NPV(LV) = Vals{p}*10000; % chances out of 10000
            
        else % entry needs no transformation, because they are intervals in seconds
            
            NPV(LV) = Vals{p}; 
            
        end
    end % changing values in NPV, the new parameter vector
    
end % no changes to be made
            
ProtocolStructure.Parameters = NPV;
%%
disp(char({' ';'******';' '}))

fprintf('\nThis/these is/are the default decision field(s)\nfor this protocol:\n')

if iscell(FldsDef)
    for i = 1:length(FldsDef)
        fprintf('\n%s\n',FldsDef{i})
    end
else
    fprintf('\n%s\n',FldsDef)
end


while 1
    DF = input('\nDo you want to use it/them in this instance (answer ''D'')\nor a field already specified in one of the "DecisionFields"\nof the Protocols structure in the current Experiment structure\n(answer ''C'') or to specify a new field(s) (answer ''N'')? ','s');

    switch DF
        case 'D'
            NDF = FldsDef;
            break
        case 'C'
            try
                NDF = eval(input('\nEnter full path(e.g., ''Experiment.Subject(1).Protocols.DecisionFields{end}'': ','s'));
            catch ME
                disp(getReport(ME))
                fprintf('\nThe string you entered did not specify an existing cell\nin Experiment.Subject(S).Protocols.DecisionFields{F},\nwhere S and F stand for numbers or ''end''\n');
                try
                    NDF = eval(input('\nEnter full path(e.g., ''Experiment.Subject(1).Protocols.DecisionFields{end}'': ','s'));
                catch ME1
                    disp(getReport)
                    fprintf('\nSetting to default; put desired fields in "by hand" when finished')
                    NDF = FldsDef;
                end
            end
            break
        case 'N'
            NDF = input('\nEnter complete path(s) to new decision field(s);\enclose in single quotes;\nif more than one, enclose set in curly braces: ');
            if ~iscell(NDF)
                try
                    cl = regexp(NDF,'\.\w+');
                    if ~isfield(NDF(1:cl(end)-1),NDF(cl(end+1:end)))
                        fprintf('\nNot a field in this Experiment structure; setting to default\nput desired fields in "by hand" when finished\n')
                        NDF = FldsDef;
                    end
                catch ME
                    disp(getReports(ME))
                end
            end
            break
        otherwise
            fprintf('\nYour answer was not ''D'', ''C'' or ''N''\n')
    end
end
                        
%%
disp(char({' ';'******';' '}))

fprintf('\nThis is the default decision code for this protocol:\n\n%s\n',...
    regexprep(CodeDef,';',';\n'))

while 1
    Dcode = input('\nDo you want to use it in this instance (answer ''D'')\nor a field already specified in a "DecisionCode" field\nof the Protocols structure in the current Experiment structure\n(answer ''C'') or to specify new decision code (answer ''N'')? ','s');

    switch Dcode
        case 'D'
            NDC = CodeDef;
            break
        case 'C'
            try
                NDC = eval(input('\nEnter full path(e.g., ''Experiment.Subject(1).Protocols.DecisionCode{end}'': ','s'));
            catch ME
                disp(getReport(ME))
                fprintf('\nThe string you entered did not specify an existing cell\nin Experiment.Subject(S).Protocols.DecisionCode{F},\nwhere S and F stand for numbers or ''end''\n');
                try
                    NDC = eval(input('\nEnter full path(e.g., ''Experiment.Subject(1).Protocols.DecisionCode{end}'': ','s'));
                catch ME1
                    disp(getReport)
                    fprintf('\nSetting to default; put desired code in "by hand" when finished')
                    NDC = CodeDef;
                end
            end
            break
        case 'N'
            fprintf('\nBrowse for the m-file with the new decision code.\nIt must have a '';'' at the end of every line and no comments!\n')
            [FN1,Path1] = uigetfile('*.m','Find m-file');
            NDC = regexprep(readfile([FN1,Path1],'\n|\r','')); % read file
            % and convert to a Matlab string, i.e., a row vector of characters
            break
        otherwise
            fprintf('\nYour answer was not ''D'', ''C'' or ''N''\n')
    end
end

disp(char({' ';'******'}))

fprintf('\nThis/these is/are the default decision criterion/a:\n')
disp(CritDef)

while 1
    DCrit =input('If you want to change this/them,\nenter new values as col vector (else rtn): ');
    if iscell(DCrit)
        fprintf('You entered a cell array; entry must be numerical column vector')
    elseif ischar(DCrit)
        fprintf('You entered texts, entry must be numerical column vector')
    else
        break
    end
end
if isempty(DCrit)
    NDCrt = CritDef;
else
    NDCrt = DCrit;
end



for S = Subjects
    Experiment.Subject(S).Protocols.Parameters(:,end+1) = ProtocolStructure.Parameters;
    Experiment.Subject(S).Protocols.DecisionFields{end+1} = NDF;
    Experiment.Subject(S).Protocols.DecisionCode{end+1} = NDC;
    Experiment.Subject(S).Protocols.DecisionCriteria{end+1} = NDCrt;
    
end

disp(char({' ';'******'}))

fprintf('\nUse browser to inspect the column that\nhas been added to the fields of Protocols.\nType "return" to continue\n\n')
    
keyboard

disp(char({' ';'******'}))

if strcmp('y',input('\nOkay to save Experiment structure? [y/n] ','s'))
        TSsaveexperiment(FN) 
end
