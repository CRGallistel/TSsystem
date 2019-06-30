function Result = TSaddsubjects(SubIDs,Species,Strain,Sx,ArWt,ArDt,Srce)
% adds subject(s) to the Experiment structure. The optional input argument
% is a row vector of ID numbers for the new subjects. If this is not given
% in the call, user is prompted for vector of ID numbers.

global Experiment

if nargin<1 % query user for info
    
    while query % getting new subject ID #s and checking that there are no duplications
    
        SubIDs = input('\n Vector of Subject ID numbers(!): \n e.g., [107 114 34 1011] or 1011:1023 ');

        if length(unique(SubIDs)) < length(SubIDs)

            display(char({'Same ID # assigned to more than one subject! Please correct'}))

        elseif sum(ismember(SubIDs,OldIDs)) > 0

            display(char({'One or more of these ID #s same as ID #'...
                'of subject already in the structure!'...
                'Please correct'}))
        elseif min(SubIDs) < max(OldIDs)
            Str = {'' 'One or more of these new ID numbers is less than the ID'...
                'number of one or more subjects already in the structure.'...
                'This will cause those old subjects with greater ID numbers'...
                'to be assigned new index numbers. The vector of active'...
                'subject will be adjusted so that currently active subjects'...
                'will remain in the active subject list, albeit with their'...
                'new index number.' ''};

            display(char(Str))

            if strcmp('y',input('To reassign ID#s to new Ss, type "y"; otherwise hit return ','s'))
                break % exit while loop if reassignment is accepted
            else
                continue
            end
        else
            break % exit while loop if none of above conditions     
        end
    end % getting new sub ids


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

    end % getting sources
    %% Strain
    while 1

        estr = input('\nSingle string [e.g., C57BL/6j]\nor cell array of strings\n[e.g. {''wt'';''++'';''--'';''+-'';etc}]\nspecifying strain for each subject: ','s');

        if strfind(estr,'{') % if cell array was returned (at this point, it
        % is just a string)

            Strain = eval(estr); % converts string to an actual cell array

        elseif evalin('base',['exist(''' estr ''',''var'')']) % if response is a variable in the base workspace

                Strain = evalin('base',estr);           

        else % response is assumed to be a single string

            Strain = repmat(estr,length(SubIDs),1); % every subject same strain

        end


        if size(Strain,1) ~= length(SubIDs)

                fprintf('\nRows in strain array not equal to number of subjects\nTry again\n')
        else
            break % exit while loop
        end

    end % getting strains

    %% Sex
    while 1
        estr = input('\n String or string variable specifying sex for each subject, e.g., MMMFFF\nIf you want to skip this, hit Rtn ','s');

        if isempty(estr)

            fprintf('\nYou may regret not recording the sex of your subjects!\n')
            Sx = [];
            break % exit while loop

        elseif (length(estr)==1) && (strcmp('M',estr) || strcmp('F',estr)) % response was a single M or F

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
    end % getting sexes
    
    %% Weights
    while 1
        while 1

            estr = input('\n Vector of arrival weights. To skip this, hit Rtn ', 's');

            if isempty(estr) % vector not provided

                ArWt = [];
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
    end % getting arrival weights
    
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

        end % getting arrival dates
    end % query while loop
    
elseif nargin<7
    fprintf('\nNumber of arguments in call must be 0 or 7\n')
    return
end % if nargin < 1 (query) or else info in call arguments

%% Begin entering info into Experiment structure
OldIDs = [Experiment.Subject.SubId]'; 

Experiment.NumSubjects = Experiment.NumSubjects + length(SubIDs);

Experiment.Subjects = [Experiment.Subjects SubIDs]; % concatenate the vector
% of new subject IDs with the vector of old subject IDs, BUT DO NOT SORT!!
% Thus, for the time being, the numerical ordering of ID numbers may not be
% the same as the ordering of their index numbers. (This will be the case
% if some of the new subjects have ID #s lower than those of old subjects.)
%%
for sub = 1:length(SubIDs) % entering data for each new subject

    Experiment.Subject(end+1).Sex = Sx(sub);
    
    Experiment.Subject(end).SubId = SubIDs(sub);

    if ~isempty(ArWt)
        Experiment.Subject(end).ArrivalWeight = ArWt(sub);
    end

    if ~isempty(ArDt)
        Experiment.Subject(end).ArrivalDate = ArDt(sub,:);
    end

    if ischar(Strain)

        Experiment.Subject(end).Strain = Strain(sub,:);

    elseif iscell(Strain)

        Experiment.Subject(end).Strain = Strain{sub};

    end

    if ~isempty(Srce) && ischar(Srce)
        
        Experiment.Subject(end).Source = Srce(sub,:);
        
    elseif ~isempty(Srce) && iscell(Srce)
        
        Experiment.Subject(end).Source = Srce{sub,:};
    end
    
    Experiment.Subject(end).MacroInfo = struct('date',[],'progpath',[],...
        'program',[],'box',[],'id',[],'ExpId',[],'group',0,'macroname',[]);
                 
end % of stepping through new subjects


%% Resorting the subjects so that index order same as ID order
% TSloadsessions assumes this to be the case!!

if ~strcmp('all',Experiment.Info.ActiveSubjects)
    
    IDs = [Experiment.Subject.SubId]'; % presort list of IDs
    
    IndxOfNewSs = ~ismember(IDs,OldIDs); % vector flagging the IDs of the
    % newly added subjects. OldIDs variable was computed at start of
    % function
    
    NewAS = 1:length(IDs); % this will become the new list of active subjects
    % (see later if)
    
    OldIndxOfNewSs = NewAS(IndxOfNewSs); % index numbers of the
    % newly added subjects before the sort
    
    OldAS = Experiment.Info.ActiveSubjects; % presort index numbers of the old
    % subjects that are active subjects.
    
end


[SubIDs,I] = sort([Experiment.Subject.SubId]'); % I is the old index #s
% in the new order
%%
for S = 1:Experiment.NumSubjects
    % stepping through the subjects in their current order
    
    NwIndx = find(SubIDs==Experiment.Subject(S).SubId);
    
    Tmp(NwIndx) = Experiment.Subject(S);
    
end
%%
Experiment.Subject(1:length(Tmp))=Tmp;

if ~strcmp('all',Experiment.Info.ActiveSubjects)
    
    Experiment.Info.ActiveSubjects = NewAS(ismember(I,OldIndxOfNewSs)...
        | ismember(I,OldAS)); % new active Ss are the newly added subjects
    % together with those that were active before the additions
    
end

Experiment.Subjects = sort(Experiment.Subjects);

display(char({'Warning: Subjects resorted to make the order';...
    'of their index numbers the same as order of their ID numbers';...
    'If any subject just added has a lower ID number';...
    'than subject(s) already in the structure, those';...
    'old subjects will now have new index numbers!!';...
    'Use TSexperimentbrowser to determine their';...
    'new index numbers.'}))