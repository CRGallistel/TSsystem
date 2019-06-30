function TSaddpositioncol(StartPosition)
% Creates a TSDataP field that contains same data as TSData field, but
% with 3rd col giving position of wheel at each event in meters from the
% nominal 0 position of 85000 turns. One can make this the
% active data field when analyzing wheel data. TSparseP is a TSparse
% modified to include postion as a special word. This enable one to write
% code for position with the same facility as one writes code for time
%
% Syntax:  TSaddpositioncol(StartPosition)
%
% StartPosition is the position of the wheel in 1/4 turns when session begins,
% e.g. 85000. If the nest is assumed to be at 85000 and the session starts
% with the mouse in the test box and the test box is 35 full turns from the
% nest box in the downward direction, then MedPC will report the first
% wheel position as 85000 - 4x35 = 84860

global Experiment

AS = Experiment.Info.ActiveSubjects;


for S = AS % stepping through the active subjects
    
    
    if strcmp('all',Experiment.Info.ActiveSessions)

        Experiment.Info.ActiveSessions = 1:Experiment.Subject(S).NumSessions;
        
    end

    As = Experiment.Info.ActiveSessions;
    
    for s= As % stepping through the active sessions
        
        if isempty(Experiment.Subject(S).Session(s).TSData)
            continue % go to next session    
        end

        D = Experiment.Subject(S).Session(s).TSData;

        LVpos = D(:,2)>2100; % logical vector flags position events

        FrstPosR = find(D(:,2)>2100,1); % row # of first position event

        if isempty(FrstPosR) % wheel never moved

            D(:,3) = StartPosition; 
            Experiment.Subject(S).Session(s).TSDataP = D;

            continue % go to next session

        end % if wheel never moved

        NonPosR = find(D(:,2)<2100); % row #s for non-position events

        D(LVpos,3) = D(LVpos,2); % copying positions into 3rd col


        if FrstPosR > 1 % if first event is not a position event

            D(1,3) = StartPosition; % (assumed) position of wheel at start of session

        end
        %%
        for r = NonPosR(2:end)' % stepping through the rows that record non-positional
          % events filling in the most recent recorded position of the
          % wheel

          D(r,3) = D(r-1,3); % filling in the immediately preceding position

        end
        
        D(:,3) = (D(:,3)-85000)*.1414; % converts wheel positions into
        % distance in meters from nominal 0 position at 85000. One
        % positional increment represents one quarter turn and a quarter
        % turn is 14.14 cm

        Experiment.Subject(S).Session(s).TSDataP = D;
        
    end % of stepping through active sessions
    
end % of stepping through active subjects