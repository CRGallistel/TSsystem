function TSbegin
% Leads the user through the creation of an Experiment structure by reading
% the Excel spreadsheet containing all the required information. Older code,
% which is now more or less irrelevant [Sept 2015], sets up
% folder structure, copies script and helper functions into MatlabCode
% subfolder, and puts folder and its subfolders at top of Matlab's search path
% Prompts user for load parameters, the parameters that must be specified
% in order to properly load a raw data file into the Experiment structure

% Modified by Randy Gallistel - Nov 10, 2009. Extensively modified by RZ &
% CRG Jan-Feb 2015 and again in Sept 2015

global DropboxPath

if isempty(DropboxPath)
    
    disp(char({'';'The variable ''DropboxPath'' is empty.';...
        'It must contain the path to the parent directory,';...
        'the directory that contains the Experiment folders.';...
        'Change current directory to the parent directory';...
        'and then type "Dropbox = cd" in command window.';...
        'Do not subsequently delete this global variable!';''}));    
    keyboard
    
end
%%Template
Str = input('\nIs the required information in the Excel Template? [y/n] ','s');

if strcmp('y',Str) % get info from Excel template
  %%  
    [Template,PathNm] = uigetfile ({'*.xls;*.xlsx;*.xlsm;*.xlsb'}); % code asking user to browse for template.
    Template = [PathNm Template]; % full name of template (including path)
   %% 
    [~,ParentDir,~] = xlsread (Template,'A2:A2'); %Extract info for Parent Directory.
    
    ParentDir = strcat(char (ParentDir),'/'); %Generate the string for Par Dir.
    
    %if isempty(ParentDir)
    %    disp(char({'';'Please fill in all the required information before';...
    %        'you go on: Path To Parent Directory, Experiment ID #,';...
    %        'Full Name of Event Codes File, Lab Name,';...
    %        'Path To Folder With Helper Funtions, Load Function,';...
    %        'Time Unit (in seconds) for Time Stamps in Raw Data File,';...
    %        'Time Unit for Time Stamps in TSData,';...
    %        'Subject Information (ID, Species, Strain, Sex)';''}));
    %end
    
    % code reading template [Nm,Txt,Raw] = xlsread(TEMPLATE)
    
    % code that creates the Experiment structure and fills it with all the
    % information extracted from the the template: Exper ID, load function,
    % SubIDs, Species, Weights, etc, etc
    
    ExperID = xlsread (Template,'A4:A4'); %Extract info for Experiment ID.
    
    [~,Mess] = mkdir(ParentDir,['Experiment' num2str(ExperID)]); %Generate the folder for the experiment.
    
    if ~isempty(Mess)
    disp(char(' ',['Warning: ',Mess]))
    fprintf('\nFolder for this experiment already created;\ndid not overwrite it.\n')
    end
    
    clear cd; % Avoid the bug of 2014b when using cd.
    
    cd ([ParentDir ['Experiment' num2str(ExperID)]]);
    
    Pth = cd;
    
    copyfile(Template,[ParentDir ['Experiment' num2str(ExperID)] '\' ...
        ['Experiment' num2str(ExperID)] 'Info.xlsx']) % copy the Experiment
    % Information spreadsheet into the folder for this experiment, renaming 
    % it with the ID# ofthis experiment
    
    
    [~,Mess] = mkdir('DataArchive'); %The same as old codes.
    if ~isempty(Mess)
        disp(char(' ',['Warning: ',Mess]))
        fprintf('\nDataArchive folder already created;\ndid not overwrite it.\n')
    end

    [~,Mess] = mkdir('DataTemp');
    if ~isempty(Mess)
        disp(char(' ',['Warning: ',Mess]))
        fprintf('\nDataTemp folder already created;\ndid not overwrite it.\n')
    end

    [~,Mess] = mkdir('MatlabCode');
    if ~isempty(Mess)
        disp(char(' ',['Warning: ',Mess]))
        fprintf('\nMatlabCode folder already created;\ndid not overwrite it.\n')
    end

    PthToMatlabCode = [Pth '/MatlabCode/'];

    [~,Mess] = mkdir('Plots');
    if ~isempty(Mess)
        disp(char(' ',['Warning: ',Mess]))
        fprintf('\nPlots folder already created;\ndid not overwrite it.\n')
    end
    
    
    [~,Lab,~] = xlsread (Template,'A8:A8'); %Extract info for lab.
    Lab = char(Lab);
    %%
    SubIDs = xlsread (Template,'A38:A1048576'); %--Use this or find the last row 
    %of data?
   %%
     [~,Species,~] = xlsread (Template,'B39:B39'); %--Same as above.
    if isempty (Species) 
        [~,Species,~] = xlsread (Template,'B38:B38');
        Species = repmat (Species,length(SubIDs),1);
    elseif  ~isempty (Species)
        [~,Species,~] = xlsread (Template,'B38:B1048576');
        if length (Species) ~= length (SubIDs)  
            fprintf('\nWarning:\nLength of Species not equal to # of subjects\n');
        end
    end   
   %% 
    TSinitexperiment(['Experiment' num2str(ExperID)],ExperID,SubIDs,Species,Lab);
    
    global Experiment
    % Argument to dynamic structure reference must evaluate to a valid field name.
    [~,Evts,~] = xlsread (Template,'A6:A6');% Col B will either contain
    % a number or it will be empty. In the first case, the user will have
    % specifed event names and corresponding numerical codes in successive
    % columns of Row 6 of the template. In the 2nd case, the user will have
    % specified the path to an event codes file in Col A of Row 6
    
    if ~isempty(strfind(char(Evts),'.')) % checking that this is a file name and not a field name            
            TSimporteventcodes (char(Evts)); % read in event codes from text filed 
    else % assume row contains alternating event names and codes     
        [Codes,Evts,~] = xlsread (Template,'6:6'); % read whole row
        if isempty(Codes)
            fprintf('\nFatal error:\nRow 6 must contain either a complete file name in A6\nOR alternating event code names and event code numbers\n')
            return
        end
        Evts = cellstr(Evts(~cellfun (@isempty,Evts))); % Gets
        % rid of the empty cells in Evts (the cells that contained event
        % numbers), leaving only the cells that contain event names
        Codes = Codes(~isnan(Codes)); % getting rid of NaNs
        if length(Evts)~=length(Codes)
            fprintf('\nFatal error:\nNumber of event names in Row 6\n~= number of event codes in Row 6\n')
            return
        end
        for i = 1:length (Codes)
            Experiment.EventCodes.(Evts{i}) = Codes(i); % creating fields
            % with event names and entering corresponding event codes
        end
     end % if Row 6 contains a file name or alternating event names and codes   
        
%%
    [~,HlpFunDr,~] = xlsread (Template,'A10:A10');
    if ~isempty (HlpFunDr)
        HlpFunDr = char(HlpFunDr);
        copyfile(HlpFunDr,PthToMatlabCode);
    else
        char({'';'Row 10 of the template is blank. Therefore,';...
            'no helper functions have been copied into';...
            'the MatlabCode subfolder.';''})
    end
    %Extract info for the Helper Function file
    %and copy it to the folder of "MatlabCode". If this cell in template is
    % blank, call file-browsing GUI. If user hits Cancel in file-browser,
    % leave "MatlabCode" subfolder empty 
    
    Experiment.Info.InputTimeUnit = xlsread (Template,'A18:A18');
    
    Experiment.Info.OutputTimeUnit = xlsread (Template,'A20:A20');
    
    [~,LoadFun,~] = xlsread (Template,'A12:A12');
    if ~ismember (LoadFun,'NaN')   
        Experiment.Info.LoadFunction = char (LoadFun);
    else
        Experiment.Info.LoadFunction == 0;
        fprintf('\n\nTo get data into the Experiment structure, you will need\nto find or create a load function for your raw data structure,\nput its name in the Experiment.Info.LoadFunction field,\nand make sure it is on Matlab''s search path\n');
    end
    % If this cell contains 'NA', leave the LoadFunction field in Experiment.Info empty
    % but display warning that they will need to create or find an
    % appropriate load function in order to get their data into the
    % Experiment structure and then fill in this field
    
   
    [~,PrefChar,~] = xlsread (Template,'A14:A14');
        if ~isempty(PrefChar) 
            Experiment.Info.FilePrefix = char (PrefChar);
        end
        % Roxanne: Try rewriting these if/else statements as
        % "if ~isempty(PrefCare);Experiment.Info.FilePrefix = char (PrefChar);end"
    
    [~,Ext,~] = xlsread (Template,'A16:A16');
        if ~isempty(Ext) 
            Experiment.Info.FileExtension = char (Ext);
        end        
   
    [~,Strain,~] = xlsread (Template,'C39:C39');
    if isempty (Strain)
        [~,Strain,~] = xlsread (Template,'C38:C38');
        Strain = repmat (Strain,length(SubIDs),1);
    elseif  ~isempty (Strain)
        [~,Strain,~] = xlsread (Template,'C38:C1048576');
        Strain = Strain(~cellfun (@isempty,Strain));
        if length (Strain) ~= length (SubIDs)
            fprintf('\nWarning:\nLength of Strain not equal to # of subjects\n');
        end
    end  
    
    [~,Sex,~] = xlsread (Template,'D39:D39');
    if isempty (Sex)
        [~,Sex,~] = xlsread (Template,'D38:D38');
        Sex = repmat (Sex,length(SubIDs),1);
    elseif ~isempty (Sex)
        [~,Sex,~] = xlsread (Template,'D38:D1048576');
        Sex = Sex(~cellfun (@isempty,Sex));
        if length (Sex) ~= length (SubIDs)
            fprintf('\nLength of sex string not equal to # of subjects\nTry again\n');
        elseif ~isempty (setdiff (Sex,['M';'F']))
            fprintf ('\nYour response contains letter(s) other than M and F\nbut it is not a variable in the base workspace\nTry again');
        end
    end
  %%  Weight
    [~,Wstr,~] = xlsread (Template,'E38:E8');
    if isempty (Wstr)
        Weight = xlsread (Template,'E38:E1048576');
        Weight = Weight(~isnan(Weight));
        if isempty (Weight)
            fprintf ('\nNo data for Weight\n');
        end
    elseif  ~isempty (Wstr)
        [~,Weight,~] = xlsread (Template,'E39:E39');
        if isempty (Weight)
            Weight = repmat (Wstr,length(SubIDs),1);
        else
            [~,Weight,~] = xlsread (Template,'E38:E1048576');
            Weight = Weight(~cellfun (@isempty,Weight));
        end
    end
    if ~isempty (Weight) && length (Weight) ~= length (SubIDs)
        fprintf('\nWarning:\nLength of Weight not equal to # of subjects\n');
    end
     %% Arrival Dates
   if ispc
    [~,ArvDates,~] = xlsread (Template,'F39:F39');
    if isempty (ArvDates)
        [~,ArvDates,~] = xlsread (Template,'F38:F38');
        if ~isempty (ArvDates)
            ArvDates = repmat (ArvDates,length(SubIDs),1);
        else
            fprintf ('\nNo data for Arrival Dates\n');
        end
    elseif  ~isempty (ArvDates)
        [~,ArvDates,~] = xlsread (Template,'F38:F1048576');
    end
    
   elseif ismac
       ArvDates = xlsread (Template,'F39:F39');
       if isempty (ArvDates)
           ArvDates = xlsread (Template,'F38:F38');
           if isempty (ArvDates)
               fprintf ('\nNo data for Arrival Dates\n');
           else
               ArvDates = x2mdate (ArvDates,1);
               ArvDates = datestr (ArvDates,2);
               ArvDates = repmat (ArvDates,length(SubIDs),1);
           end
       elseif ~isempty (ArvDates)
           ArvDates = xlsread (Template,'F38:F1048576');
           ArvDates = ArvDates(~isnan(ArvDates));
           ArvDates = x2mdate (ArvDates,1);
           ArvDates = datestr (ArvDates,2);
       end
        if ~isempty (ArvDates) && length (ArvDates) ~= length (SubIDs)
            fprintf('\nWarning:\nLength of Arrival Dates not equal to # of subjects\n');
        end
    end  
     %% Source 
    [~,Source,~] = xlsread (Template,'G39:G39');
    if isempty (Source)
        [~,Source,~] = xlsread (Template,'G38:G38');
        Source = repmat (Source,length(SubIDs),1);
    elseif  ~isempty (Source)
        [~,Source,~] = xlsread (Template,'G38:G1048576');
        Source = Source(~cellfun (@isempty,Source));
        if length (Source) ~= length (SubIDs)
            fprintf('\nWarning:\nLength of Source not equal to # of subjects\n');
        end
    end  
     %%
      if isempty(ParentDir) || isempty(ExperID) || isempty(Lab) || isempty(Experiment.Info.InputTimeUnit) || ...
          isempty(Experiment.Info.OutputTimeUnit) || isempty(SubIDs) || isempty(Species) || ...
          isempty(Strain) || isempty(Sex) || isempty(Source)
      fprintf ('\nYour Template is not complete.\n');
      end
     %%
     for sub = 1:Experiment.NumSubjects
         
         Experiment.Subject(sub).Sex = Sex{sub};
         
         Experiment.Subject(sub).Strain = Strain{sub};
         
         if ~isempty(Source)
         Experiment.Subject(sub).Source = Source{sub};
         end
         
         if ~isempty(Weight)
         Experiment.Subject(sub).ArrivalWeight = Weight{sub};
         end
         
         if ~isempty(ArvDates)
         Experiment.Subject(sub).ArrivalDate = ArvDates{sub};
         end
         
         Experiment.Subject(sub).MacroInfo = struct('date',[],'progpath',[],...
        'program',[],'box',[],'id',[],'ExpId',[],'group',0,'macroname',[]);
                 
     end % of stepping through subjects
     
else % user enters info
        
    if exist('TextForTSbegin.txt','file')==2
        type TextForTSbegin.txt

       Str = input('\nReady to continue? (Respond y) \nIf not, hit return and start again when you are. ','s');

       if strcmp('y',Str) % continue
       else
           return % stop
       end
    end

    ExperID = input('\n\nLaboratory''s ID number for this experiment? \n It must be a  number and unique to this experiment. ');

    disp(char(' ','Pick or create the parent directory, in which',...
        'the folder for this experiment will be placed. If',...
        'the script is to be run on line, analyzing the',...
        'data at regular intervals as they are generated,',...
        'then, the folder must be one that the data files',...
        'to which MedPC writes can be copied into, for',...
        'example, Dropbox. The script and associated helper',...
        'functions will be copied into the folder for this',...
        'experiment. The folder will be placed at the top',...
        'of Matlab''s search path.',' '))

    ParentDir = [uigetdir([],'Parent directory (e.g., Dropbox') '/']; % get this
    % from reading template

    [~,Mess] = mkdir(ParentDir,['Experiment' num2str(ExperID)]); % Equivalent
    % of this must be in template-processing code

    if ~isempty(Mess)
        disp(char(' ',['Warning: ',Mess]))
        fprintf('\nFolder for this experiment already created;\ndid not overwrite it.\n')
    end

    cd ([ParentDir ['Experiment' num2str(ExperID)]]); % equiv in template code

    Pth = cd; % path to folder for this experiment

    [~,Mess] = mkdir('DataArchive');
    if ~isempty(Mess)
        disp(char(' ',['Warning: ',Mess]))
        fprintf('\nDataArchive folder already created;\ndid not overwrite it.\n')
    end

    [~,Mess] = mkdir('DataTemp');
    if ~isempty(Mess)
        disp(char(' ',['Warning: ',Mess]))
        fprintf('\nDataTemp folder already created;\ndid not overwrite it.\n')
    end

    [~,Mess] = mkdir('MatlabCode');
    if ~isempty(Mess)
        disp(char(' ',['Warning: ',Mess]))
        fprintf('\nMatlabCode folder already created;\ndid not overwrite it.\n')
    end

    PthToMatlabCode = [Pth '/MatlabCode/'];

    [~,Mess] = mkdir('Plots');
    if ~isempty(Mess)
        disp(char(' ',['Warning: ',Mess]))
        fprintf('\nPlots folder already created;\ndid not overwrite it.\n')
    end

    SubIDs = input('\n Vector of Subject ID numbers(!): \n e.g., [107 114 34 1011] or 1011:1023 ');

    Species = input('\n Species? [e.g. Mouse] ','s');
     % prompts user (strings must be finished on the line on which they are
     % started)

    Lab = input('\n Laboratory? [e.g., Gallistel] ','s');

    TSinitexperiment(['Experiment' num2str(ExperID)],ExperID,SubIDs,Species,Lab);

    global Experiment

    if strcmp('Enter',input('\n\nWill you enter event codes [answer Enter]\nor browse for a text file containing the event codes [rtn]? ','s'))
        disp(char('','Event code entries must be of the form:',...
        '          VarName = Code#',...
        'where VarName is a valid Matlab variable name, e.g. PokeOn',...
        '(only letters and numerals allowed in variable names)',...
        'and Code# is the numerical code for that event in the data',...
        'The event code number must be >10!',...
        'If your event codes are <=10, they will replaced with',...
        'numbers > 10 after your data have been loaded into the',...
        'Experiment structure. At that time, you will be queried',...
        'for which of those codes correspond to which VarNames',...
        'and the original numbers for those events will be replaced',...
        'with the numbers you specify here.',...
        'Do not enclose your answers in single quotes.',...
        'An example of an appropriate answer is: PokeOn1=20',...
        'Hit Return to terminate following event name queries:',''))
    
        while 1 % prompting for event names and numbers
            FldNm = input('Name of event [must be valid Matlab variable name]: ','s');

            if isempty(FldNm);break;end % stop queries in response to Return

            Ecode = input('Corresponding numerical code [Must be >10]: ');

            Experiment.EventCodes.(FldNm)=Ecode;
        end % prompting
    
    else % browse for event codes file

        fprintf('\n\nBrowse for text file that contains event codes\n')

        TSimporteventcodes; % this opens a browser window for user to find the file
    end % enter event codes or browse for event code file

    %% Source
    while 1

        estr = input('\nSingle string [e.g., Harlan\nor cell array of strings\n[e.g. {''Harlan'';''Harlan'';''Jackson'';etc}]\nspecifying source for each subject: ','s');

        if strfind(estr,'{') % if cell array was returned (at this point, it
        % is just a string)

            Srce = eval(estr); % converts string to an actual cell array

        elseif evalin('base',['exist(''' estr ''',''var'')']) % if response is a variable in the base workspace

                Srce = evalin('base',estr);           

        else % response is assumed to be a single string

            Srce = repmat(estr,length(SubIDs),1); % every subject same strain

        end


        if size(Srce,1) ~= length(SubIDs)

                fprintf('\nRows in source array not equal to number of subjects\nTry again\n')
        else
            break % exit while loop
        end

    end
    %% Strain

    Str=char({'\nIf all subjects are from the same strain, enter\nthe strain (not enclosed in single quotes!);\nif they are of different strains, enter cell\narray containing the strain-specifying strings\n[e.g. {''wt'';''++'';''--'';''+-'';''CD-1'', etc}]\nor enter the name of a variable in the workspace\ncontaining such a cell array (w/o single quotes!): '});
    %%
    while 1

        estr = input(Str,'s');

        if strfind(estr,'{') % if cell array was returned (at this point, it
        % is just a string)

            Strain = eval(estr); % converts string to an actual cell array

        elseif evalin('base',['exist(''' estr ''',''var'')'])
            % if response is a variable in the base workspace, this will be
            % 2, which is taken by Matlab as true

                Strain = evalin('base',estr);           

        else % response is assumed to be a single string

            Strain = repmat(estr,length(SubIDs),1); % every subject same strain

        end


        if size(Strain,1) ~= length(SubIDs)

                fprintf('\nRows in strain cell array not equal to number of subjects\nTry again\n')
        else
            break % exit while loop
        end

    end

    %% Sex
    Str = '\nIf all subjects are the same sex, enter M or F.\nIf sex differs, enter either a string of M''s & F''s\nequal in length to number of subjects or the name\nof a workspace variable containing such a string.\n(Do NOT enclose your response in single quotes!): ';
    while 1
        estr = input(Str,'s');

        if (length(estr)==1) && (strcmp('M',estr) || strcmp('F',estr)) % response was a single M or F

            Sx = repmat(estr,length(SubIDs),1); % every subject has same sex

        elseif any(~ismember(estr,'MF')) % string contains characters other than M & F

            if evalin('base',['exist(''' estr ''',''var'')']) % if response is a variable in the base workspace

                Sx = evalin('base',estr);

            else % string contains characters other than M & F but is not a variable
                % in the base workspace

                fprintf('\nYour response contains letter(s) other than M and F\nbut it is not a variable in the base workspace\nTry again')

            end

        else % doesn't contain any characters other than M & F

            Sx = estr;        

        end

        if ~isempty(Sx) && (length(Sx) ~= length(SubIDs))

                fprintf('\nLength of sex string not equal to # of subjects\nTry again\n')
        else
            break % exit while loop
        end
    end
    %% Weights
    while 1
        while 1

            estr = input('\n Vector of arrival weights. To skip this, hit Rtn ', 's');

            if isempty(estr) % vector not provided

                ArWt = [];
                fprintf('\nWhen you come to publish, you will regret\nnot having recorded arrival weights\n')
                break % exit inner while loop

            elseif isempty(str2num(estr)) % answer is not a numerical vector

                if evalin('base',['exist(''' estr ''',''var'')']) % if response is a 
                    % variable in the base workspace

                    ArWt = evalin('base',estr);
                    break % exit inner while loop

                else

                    fprintf('\nYour response isn''t a numerical vector\nor a variable in the base workspace\nTry again\n')

                end

            else % response is a numerical vector (by elimination)

                ArWt = str2num(estr);
                break % exit inner while loop   
            end
        end

        if ~isempty(ArWt) && (length(ArWt) ~= length(SubIDs))

                fprintf('\nLength of arrival-weight vector ~= # subjects\nTry again\n')
        else
            break % exit outer while loop
        end
    end
    %% Arrival date(s)   
    while 1
        while 1
            estr = input('\n Matlab date vector (or array) specifying arrival date(s), \n e.g. [2009 08 21] or [2010 03 13;2010 03 22;etc]\nTo skip this, hit Rtn ','s');

            if isempty(estr) % vector or array not provided

                fprintf('\nYou may regret not recording the arrival date(s) for your subjects!\n')
                ArDt = [];
                break % exit inner while loop

            elseif isempty(str2num(estr)) % answer is not a numerical vector

                if evalin('base',['exist(''' estr ''',''var'')']) % if response is a 
                    % variable in the base workspace

                    ArDt = evalin('base',estr);
                    break % exit inner while loop

                else

                    fprintf('\nYour response isn''t a numerical vector\nor a variable in the base workspace\nTry again\n')

                end

            else % response is a numerical vector or array (by elimination)

                ArDt = str2num(estr);
                break % exit inner while loop   
            end
        end % inner while loop


        if isempty(ArDt)

            break % exit outer while loop

        elseif isequal(size(ArDt),[1 3]) % single arrival date

            ArDt = repmat(ArDt,length(SubIDs),1); % all subjects arrived on same date
            break % exit outer while loop

        elseif isequal(size(ArDt),[length(SubIDs) 3]); % One date for each subject

            break

        else

            fprintf('\nNumber of rows in arrival-date array ~= # subjects\nor there are not exactly 3 columns in the array.\nTry again\n')

        end
    end


    for sub = 1:Experiment.NumSubjects % entering data for each subject

        Experiment.Subject(sub).Sex = Sx(sub);

        if ~isempty(ArWt)
            Experiment.Subject(sub).ArrivalWeight = ArWt(sub);
        end

        if ~isempty(ArDt)
            Experiment.Subject(sub).ArrivalDate = ArDt(sub,:);
        end

        if ischar(Strain)

            Experiment.Subject(sub).Strain = Strain(sub,:);

        elseif iscell(Strain)

            Experiment.Subject(sub).Strain = Strain{sub};

        end

        if ~isempty(Srce) && ischar(Srce)

            Experiment.Subject(sub).Source = Srce(sub,:);

        elseif ~isempty(Srce) && iscell(Srce)

            Experiment.Subject(sub).Source = Srce{sub,:};
        end

        Experiment.Subject(sub).MacroInfo = struct('date',[],'progpath',[],...
            'program',[],'box',[],'id',[],'ExpId',[],'group',0,'macroname',[]);

    end % of stepping through subjects


    %%

    disp(char(' ','Browse for folder containing the helper functions',...
        'In the unlikely event that no helper functions are used,',...
        'click on Cancel.'))

    HlprFunDr = uigetdir([],'Find helper functions folder');

    if HlprFunDr(1)==0;return;end % If browse was canceled, result returned is 0

    [Suc,Mess] = copyfile(HlprFunDr,PthToMatlabCode);

    if Suc
        disp(char(' ','Have copied helper functions to MatlabCode subdirectory,',...
            'which has been placed at top of Matlab''s search path.',...
            'These helper functions will now overshadow functions',...
            'with same name elsewhere on Matlab''s search path.'))
    else
        disp(Mess)
    end
    %%
    disp(char(' ','The load parameters specify:',...
        ' i) time unit in the raw data files',...
        ' ii) time unit to be used in Experiment structure',...
        ' iii) the load function to be used to read the raw data files',...
        ' iv) the prefix character, if any, that marks raw data files',...
        ' v) the extension, if any, that marks raw data files',' '))

    LP = input('Use the default values for load parameters? \n Answer Rtn for yes or ''?'' to answer queries. ','s');


    if ~isempty(LP) && strcmp(LP,'?')

        fprintf('\nTo accept default values in following queries, hit Rtn. \nWhen making string responses, do not enclose in single quotes\n\n')

        RawUnit =...
            input('What is the unit of time, in seconds, for time stamps in raw data? \n Default = .02 ');

        if isempty(RawUnit);else Experiment.Info.InputTimeUnit = RawUnit;end

        StrucUnit =...
            input('\n What is the unit of time, in seconds, \n to be used in Experiment structure? \n Default = 1; for minutes, enter 60 ');

        if isempty(StrucUnit);else Experiment.Info.OutputTimeUnit = StrucUnit;end

        disp(char(' ','If uncertain how to answer following query,',...
            'hit Rtn & to accept default and subsequently type',...
            'help TSloadsessions   &/or help TSsetloadparameters.',...
            'You may need to create a custom load function; it depends',...
            'on the format of your raw data files.',' '))
        LdFun =...
            input('What is the function to be used in reading raw data files? \n Default = TSloadMEDPC ','s');

        if isempty(LdFun);else Experiment.Info.LoadFunction = LdFun;end

        PrefChar =...
            input('\n What prefix character marks raw data files? Default = ''! ','s');

        if isempty(PrefChar);else Experiment.Info.FilePrefix = PrefChar;end

        Ext =...
            input('\n What extension distinguishes raw data files? Default = none','s');

        if isempty(Ext);else Experiment.Info.FileExtension = Ext;end

    end % else/if default or custom load parameters
end % if get info from template or else from user

if strcmp('y',input('\nWould you like Matlab to make the decision to advance from one\nprotocol to the next within a single session? [y/n] ','s'))
    
    if strcmp('y',input('\nLoad same custom sequence of protocols for all subjects? [y/n] ','s'))
        
       [CustomParameters,Pth] = uigetfile('*.mat','Load Protocol Structure');
       
       load([Pth CustomParameters])
       
       StrucName = input('\nName of the variable containing the structure\nwith the desired sequence of protocols? ','s');
        
        for S = 1:Experiment.NumSubjects
            
            Experiment.Subject(S).Protocols = eval(StrucName);
            
        end
        
    else
    
        fprintf('\n\nUse TSaddprotocol to add protocol sequence for each subject\nto the Experiment structure before calling TSstartsession\n')
    
    end
    
end % if fully automated
        
cd(ParentDir)

TSsaveexperiment(sprintf('Experiment%d/Experiment%d',ExperID,ExperID));
    
