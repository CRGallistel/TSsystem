function Protocols = TSchangeprotparams(P)
% Changes the operative MedPC protocol by writing new parameter values to
% the text file that the MedPC BKGRND command reads, the file that
% specifies the values in MedPC's O array. Called by a TSapplystat command
% within a protocol-specific analysis function, which passes it the
% 'Protocols' structure (in a field named 'Protocols' at the Session level). It
% has 5 fields: 1) Parameters - an array, each column of which specifies a
% full set of values for the MedPC O array; 2) DecisionFields - a cell array
% with the COMPLETE names of the fields in which the data are found on which
% the decision is based. COMPLETE means, for example:
% 'Experiment.Subject(S).Session(end).TrialSesPhase.Trial(end).NewAllTrials'
% the values for S = sub is obtained by this function from the
% workspace of TSapplystat (the function that calls this function)
% 3) DecisionCode - code that makes the decision using
% data in the DecisionFields and criteria in the DecisionCriteria;
% 4) DecisionCriteria - a 1-row cell array with as many columns as the
% Parameters array. The cell in each column contains the values of the
% decision criteria used by the decision making code for the corresponding
% protocol; 5) Current - contains an integer that is the column number of
% the current protocol. On 2/21/13, I added an Info field to the Protocols
% structure, into which the decision code can put informaition needed to
% make subsequent decisions. For example, in deciding whether to move to
% another set of matching parameters, the decision code may want to base
% the decision on the number of cycles since the last such change. To do
% that it has to know the number of cycles as of the last change. If this
% is to be used in the next decision, the decision code must include a
% statement that sets the Info field.

global Experiment

Protocols = P; % initializing output to be same as input. If a decision is
% taken to terminate the current protocol and go on to the next, then the
% 'Current' field in the Protocols structure will be updated. In either
% case, this structure will be passed back to TSapplystat

Info = P.Info; % information from previous decisions necessary to the making
% of current decision

S = evalin('caller','sub'); % current subject (in TSapplystat workspace, as
% it makes its way through the subjects). This TSchangeprotparams function
% does not obtain the session # from the TSapplystat workspace nor the
% trial # because those should always be the ones specified by 'end'

if ~ismember(Experiment.Subject(S).Session(end).Phase,Experiment.Info.ActivePhases)
    return
end

WriteFlag = false; % the code in P.DecisionCode must contain a statement
% that sets WriteFlag to true when the decision is to go on to the next
% protocol in P.Parameters.

C = P.Current; % column # of current protocol. Every field in P has the
% same number of columns, except the Current field, which has only an
% integer specifying the column in the other fields for the currently
% active protocol
%%

if ischar(P.DecisionFields{C}) % if the contents of that field are a string
    % (in which case, there is only one decision field and the string gives
    % the path to it)
    try % the following command crashes when there is a subject for which
        % the decision field does not exist (because no data from that
        % subject)
        DF{1}=eval(P.DecisionFields{C}); % make the contents of DF{1} be the
        % the contents of that decision field
    catch ME
        disp(['Subject =' num2str(S) ': ' getReport(ME)])
        return
    end
    
else % the contents of P.DecisionFields{C} is a cell array, each cell of
    % which is a string giving the path to a field
    
    for r = 1:length(P.DecisionFields{C}) % stepping through the decision fields
        try % see previous try comment
            DF{r} = eval(P.DecisionFields{C}{r}); % DF puts the CONTENTS of each
            % decision field into a cell of the DF cell array
        catch ME
            disp(['Subject =' num2str(S) ': ' getReport(ME)])
        return
        end
    end
end % of creating the cell array DF, whose cell(s) contain(s) the contents 
% of the decision field(s)
    
%%
DC = P.DecisionCriteria{C}; % for simplicity of reference
% This code assumes that the contents of a Protocol.DecisionCriteria cell
% is a numerical vector (NOT a cell array or a string). Moreover, the
% corresponding user-written code that goes in Protocols.DecisionCode must
% make that same assumption when it refers to DC: DC(1) refers to the first
% value in DC, etc

eval(P.DecisionCode{C}); % P.DecisionCode{C} contains the decision code. It
% sets WriteFlag to true when the decision criteria are satisfied. The code
% for making the decision to end a matching protocol would probably be:
%{
'if isempty(Info);Info=0;end;if length(DF{1})-Info>DC;WriteFlag=true;Info=length(DF{1});end'
% where DF{1} =  the contents of
% Experiment.Subject(S).Session(end).CmCycleTms and DC = the number in
% P.DecisionCriteria{C} and Info is the field in the Protocol structure
% that contains the number of cycles completed as of the preceding change
% in matching parameters. For the first matching segment, this must be set
% to 0
%}
% In this example, there is only one decision field 'CmCycleTms'. Its
% length is the number of cycles the subject has made. The decision is
% based on that length. The desired length is specified in
% P.DecisionCriteria{C}, where C is the column number of a matching
% protocol in the Protocols.Parameters field of the structure in the
% Protocols field at the Subject level
%
% For an autoshape protocol, the decision is more complex, because it is
% based on whether the subject as begun to show positive CS-ITI rate
% differences on at least one hopper or some upper limit on the number of
% trials has been exceeded. The 2 DecisionFields would be
% {'Experiment.Subject(S).Session(end).LngCS_PreLngITI_RateDiff' ...
% 'Experiment.Subject(S).Session(end).ShrtCS_PreShrtITI_RateDiff' ...}
%
% The code to make the decision might be:
%{
'if length(DF{1})>DC(1)&&sum(DF{1}(end-DC(1):end))>DC(2);WriteFlag=true;elseif length(DF{2})>DC(1)&&sum(DF{2}(end-DC(1):end))>DC(2);WriteFlag=true;elseif length(DF{2})+length(DF{1})>DC(3);WriteFlag=true;end'
% As this example illustrates, THE CODE MUST BE ALL ON A SINGLE LINE 
%}
% This decision code would terminate the autoshape protocol whenever Y out
% of the last X rate differences were positive on either the short or the
% long hopper (where X & Y are specified by P.DecisionCriteria{C}(1 & 2))
% or when the total number of autoshape trials exceeded the number
% specified in P.DecisionCriteria{C}(3). Note that for eval to work, the
% string that it evaluates must be a single line!! It can only handle a
% text row vector; it cannot handle a character matrix
%
% For a switch protocol, the decision to go on to the next protocol
% (usually also a switch protocol) might be based simply on the number of
% successful switch trials in the current protocol. In that case, the
% decision field would be
% 'Experiment.Subject(S).Session(end).TrialSesPhase.Trial(end).OLsucFlg'
% and the decision code would be
%{
'if sum(DF{1}(:,end))>DC;WriteFlag=true;end'
%}
% sum(DF{1}(:,end)) gives the number of successful switch trials by summing
% the flags in the last column of the field that flags those trials

if WriteFlag && C < size(Experiment.Subject(S).Protocols.Parameters,2)
    DL = Experiment.Subject(S).MacroInfo(end).progpath(1); % drive letter
    % the Matlab editor thinks this statement (& those that follow) cannot
    % be reached because WritFlag was set to false back at the start. What
    % the editor does not know is that it gets set to true by the code
    % contained in the fields of P.DecisionCode
    BN = Experiment.Subject(S).MacroInfo(end).box; % box number
    
    FN =sprintf('%s:/Med-PC IV/Data/Box%dCurrentParameters.txt',DL,BN);
    % complete name of remote file to be written to

    dlmwrite(FN, P.Parameters(:,C+1), 'newline', 'pc')
    % Prashanth-- Note that I have set the dlmwrite command to write
    % directly to the remote file
    
    P.Info = Info;
    
    P.Current = C+1; % update the field that indicates the currently
    % operative protocol for this subject and session
    
end

Protocols = P; % updated Protocols structure. This is passed back to
% TSapplystat (the calling function), which puts it into the Protocols
% field at the session level (overwriting what was there). The only
% difference between what was there and this new version is in the
% 'Current' field, the field that specifies the protocol currently being
% executed