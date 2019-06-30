function TSsequencer(arg1,arg2)
% This function is called by the timer. It calls the DailyAnalysis function
% for each experiment in ActiveExperiments.

Dr = cd;

clear global Experiment

load('ActiveExperiments.mat') % This is a cell array created and updated by
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


ErrorMess = cell(size(ActiveExperiments,1),2); % cell array with two columns
% and as many rows as there are active experiments. First column gets
% the error reports passed on by DailyAnalysis containing errors thrown by
% the functions it calls. Second column contains error messages thrown by
% DailyAnalysis itself

Diagnostics = cell(size(ActiveExperiments,1),2);


for E = 1:size(ActiveExperiments,1) % stepping through the active experiments
    % extracting from it the values of the variables that will be passed to
    % DailyAnalysis
    
    ExperId = ActiveExperiments{E,1};
    Format = ActiveExperiments{E,2};
    Rows = ActiveExperiments{E,3};
    FdgPhases = ActiveExperiments{E,4};
    ProtSpecFuns = ActiveExperiments{E,5};
    EmailFigs = ActiveExperiments{E,6};
    Emails = ActiveExperiments{E,7};
    
    try
     
        [ErrorMess{E,1},Diagnostics{E,1}] =...
            DailyAnalysis(ExperId,Format,Rows,FdgPhases,ProtSpecFuns,...
            EmailFigs,Emails);
        % Calls DailyAnalysis and receives in return the updated ErrorRprts
        % variable that is persistent in that function and the results of
        % running TSdiagnostics to look for abnormalities
        
    catch ME
        
        ER = getReport(ME);
        
        ErrorMess{E,2} = sprintf('Experiment%d, %s, %s',E,datestr(now),ER);
        % if DailyAnalysis itself throws and error, then it is recorded
        % in the ErrorMess cell array, which gets saved in the file
        % ErrorMessages
    end
    
    save ErrorMessages ErrorMess
    % Because I use persistent variables to gather ErrorRprts, contents of
    % these saved files should contain the cumulative record of the error
    % reports from the different active experiments
    
    save Diagnostics Diagnostics % see immediately preceding comment

    cd(Dr)
    % Just in case a crash has left the current directory in a
    % directory other than its home directory
    
end % of stepping through the active experiments
