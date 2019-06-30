function Sequencer(arg1,arg2)
% This function is called by the timer. It calls the DailyAnalysis function
% for each experiment in ActiveExperiments. When called by the timer, the
% timer object itself supplies arguments for arg1 and arg2. It is essential
% to have these two "dummy" arguments as the first two arguments in any
% function that is called by a timer object. Otherwise, you get an error message
% about too many outputs requested. To understand why these "dummy"
% arguments have to be there, read "Providing Callbacks for Components" in
% the Matlab Help. When you call this function directly, you can supply the
% number of a currently active experiment (or a vector of Experiment ID
% numbers) as the one and only argument in the call. This will call
% DailyAnalysisFA for only that/those experiments. I learned by trial and
% error thatf when a timer object calls a timer function, it passes in two
% arguments: 1) a timer object 2) a structure. The timer object passed in
% is a copy of the timer object that called the function. Thus, within the
% function called by the timer, you can obtain from this object information
% about the timer itself. To do this, you use, for example,
% TE=get(arg1,'TasksExecuted') will set the variable TE (within the
% workspace of the called timer function equal to the number of times that
% the timer has called the function. You can also use this object to store
% results generated within (or passed back to) the called timer function:
% Suppose that A is an array in the workspace of the called timer function,
% then set(arg1,'UserData',A) will store that array in the UserData field.
% Later, one can retrieve that data from the timer object: Suppose, for
% example, that the timer object is analysistimer, then V =
% get(analysistimer,'UserData') will set V to the contents of the UserData
% field, which contents will have been read in the last time the timer
% object called the timer function. The structure stored in arg2 also has
% potentially useful information. For example, T=arg2.Data.time sets T
% equal to the date-time vector for the most recent call made by the timer

global DropboxPath; % The startup.m file on any computer running the fully
% automated system should/must contain commands that create the global
% variable DropboxPath containing the path from the root directory of that
% computer to the Dropbox folder (whatever its name may be) that is the
% home folder for all the experiments run using the fully automated
% software. This command gives this function access to that path

if length(DropboxPath) < 6 % in case it has been deleted or messed with
    DropboxPath = cd; % this assumes call was made from home directory
    
    disp(char({'';'The variable ''DropboxPath''was corrupted.';...
        'It must contain the path to the parent directory,';...
        'the directory that contains the Experiment folders.';...
        'The value of this variable has been set to the path';
        'to the directory from which the call to Sequencer was';...
        'made, on the assumption it was the parent directory.';''}));    
end

Dr = DropboxPath; % sets the current directory to the home folder

clear global Experiment % in case an Experiment structure lurks

if exist([DropboxPath '\ActiveExperiments.mat'],'file')
    load([DropboxPath '\ActiveExperiments.mat']) % This is a cell array created and updated by
    % TSstartsession. It has one row of cells for each active experiment. The first
    % column in each row is the ID# of the experiment. The 2nd column is the
    % format in which the figures are to be saved. The 3rd is the number of
    % rows of subplots on one page of a figure. The 4th column is a cell array,
    % each cell contains a 2D vector of start and stop event codes for a
    % restricted feeding phase. This argument may be empty, indicating that
    % there are no restricted feeding phases or that it is not desired to have
    % them plotted on the figures that can plot them. The 5th column contains a
    % cell array, each row of which specified a protocol-specific
    % data-analyzing function that is to be called by the the DailyAnalysis
    % function when it has completed doing the analyis for pokes and feedings
    % common to all sessions. There are three columns. The first specifies the
    % phases/groups/conditions (i.e., distinct protocols) to which the analysis
    % should be applied; the 2nd is the name of the function that does the
    % analysis; the 3rd is a string giving the arguments to be passed to that
    % function. The 6th cell in a row of ActiveExperiments is a cell array
    % listing the names of the plots that are to be emailed. The 7th col is a
    % cell array listing the email addresses. ActiveExperiments is saved in the
    % Dropbox by TSstartsession.
else
    fprintf('\nThere is no ActiveExperiments.mat file in the home folder\n')
    return
end

if ~exist('ActiveExperiments','var')
    fprintf('\nThe ActiveExperiments.mat file in the home folder \ndoes not contain an ActiveExperiments variable\n')
    return
end

if ~iscell(ActiveExperiments)
    fprintf('\nThe ActiveExperiments variable in the ActiveExperiments file \nis not a cell array\n')
    return
end

if size(ActiveExperiments,2)~=5
    fprintf('\nActiveExperiments cell array does not have required 5 columns\n')
    return
end

if ~isobject(arg1) && ~isempty(arg1) % Sequencer was called directly rather
    % than by a timer and the call gave a vector of Experiment ID numbers,
    % specifying the experiments to be analyzed. When a timer calls this
    % function, it passes an object as the value of arg1. (And, it passes a
    % structure as the value of arg2.) If the call did not specify a vector
    % of ID numbers, then the default is to analyze all of the currently
    % active experiments
    
    if ~isnumeric(arg1)
        fprintf('\nNon-numeric experiment ID #s specified in call\n')
        return
    end
    
    Expers = arg1; % sets Expers = to vector of experiment ID numbers
    % given in the call
        
    for E = 1:length(Expers) % stepping through the vector of ID #s
        ExpId = Expers(E);
        LV = ismember(vertcat(ActiveExperiments{:,1}),ExpId); % flags those
        % experiments that are to be analyzed
        if sum(LV)<1
            fprintf('\nNo active experiments with ID #s specified in call\n')
            return
        end
        Format = ActiveExperiments{LV,2};
        Rows = ActiveExperiments{LV,3};
%         FdgPhases = ActiveExperiments{LV,4};
        ProtSpecFuns = ActiveExperiments{LV,4};
        Emails = ActiveExperiments{LV,5};
        OverRideAS = true;
        
        try

            ErrorMess{E,1} =...
                DailyAnalysis(ExpId,Format,Rows,ProtSpecFuns,Emails,OverRideAS);
            % Calls DailyAnalysisFA and receives in return the updated ErrorRprts
            % variable that is persistent in that function

        catch ME

            ER = getReport(ME);

            ErrorMess{E,2} = sprintf('Experiment%d, %s, %s',E,datestr(now),ER);
            % if DailyAnalysisFA itself throws an error, then it is recorded
            % in the ErrorMess cell array, which gets saved in the file
            % ErrorMessages
        end

        save ErrorMessages ErrorMess
        % Because I use persistent variables to gather ErrorRprts, contents of
        % these saved files should contain the cumulative record of the error
        % reports from the different active experiments
    end

    cd(Dr) % sets current directory to home directory (in case a crash
    % somewhere has left it set to an experiment directory
    return
end % end of code that applies when Sequencer is called directly

%% Code that applies when Sequencer called by analysistimer

ErrorMess = cell(size(ActiveExperiments,1),2); % cell array with two columns
% and as many rows as there are active experiments. First column gets
% the error reports passed on by DailyAnalysis containing errors thrown by
% the functions it calls. Second column contains error messages thrown by
% DailyAnalysis itself

for E = 1:size(ActiveExperiments,1) % stepping through the rows of active
    % experiments, extracting from the cells in each row the values of the
    % variables that to be passed to DailyAnalysisFA

    ExpId = ActiveExperiments{E,1};
    Format = ActiveExperiments{E,2};
    Rows = ActiveExperiments{E,3};
%     FdgPhases = ActiveExperiments{E,4};
    ProtSpecFuns = ActiveExperiments{E,4};
    Emails = ActiveExperiments{E,5};
    OverRideAS = true;

    if ExpId <300 % if it's a wheel experiment


%         try
%                 DailyAnalysis_Wheel(ExpID,Format,Rows,Emails);
% 
%             % Calls DailyAnalysis and receives in return the updated ErrorRprts
%             % variable that is persistent in that function
%         catch ME
% 
%             ER = getReport(ME);
% 
%             ErrorMess{E,2} = sprintf('Experiment%d, %s, %s',E,datestr(now),ER);
%             % if DailyAnalysis itself throws and error, then it is recorded
%             % in the ErrorMess cell array, which gets saved in the file
%             % ErrorMessages
%         end

    else % it's an ordinary experiment

        try

            ErrorMess{E,1} =...
                DailyAnalysis(ExpId,Format,Rows,ProtSpecFuns,Emails,OverRideAS);

            % Calls DailyAnalysis and receives in return the updated ErrorRprts
            % variable that is persistent in that function 

        catch ME
            
            evalin('base','start(datatimer)') % in case a crash in
            % DailyAnalysis leaves this timer stopped
            
            cd(Dr) % in case a crash leaves system in an experiment directory

            ER = getReport(ME);

            ErrorMess{E,2} = sprintf('Experiment%d, %s, %s',E,datestr(now),ER);
            % if DailyAnalysis itself throws an error, then it is recorded
            % in the ErrorMess cell array, which gets saved in the file
            % ErrorMessages
        end


        save ErrorMessages ErrorMess
        % Because I use persistent variables to gather ErrorRprts, contents of
        % these saved files should contain the cumulative record of the error
        % reports from the different active experiments

    end

    cd(Dr)
    % Just in case a crash has left the current directory in a
    % directory other than its home directory

end % of stepping through the active experiments
         
clear global Experiment
