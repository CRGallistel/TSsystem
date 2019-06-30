function E(O,F,varargin)
% Reads contents of field F of Subject S, Session s, Trial t into variable
% O in the Matlab workspace (or in the workspace from which this function
% is called. This is a sort of hotkey function that saves having to type
% out full expressions like
% "D = Experiment.Subject(2).Session(3).TSdata"
% Syntax:  E(O,F,S,s,t)
% where O & F are obligatory strings (or string variables): O gives the
% name of the variable that will contain the result, e.g., 'D" in the above
% example. F gives the name of the field whose contents are to be assigned
% to that variable, e.g., 'TSData' in the above example. S,s, and t are
% integer-valued indices picking out the subject, session and trial where
% the desired field is to be found, e.g., S=2 & s=3 in the above example.
% These indices are optional; if none is given, field is assumed to be at
% Experiment level; if one, it is assumed to be at Subject level, if 2, it
% is assumed to be at Session level; if 3, it is assumed to be at trial
% level. Trial type is assumed to be the active trial in the Experiment
% structure. For the above example, the command would be:
% E('D','TSData',2,3). To make a variable Pks in the workspace, containing
% the data in a field named Pks in Trial(12) of the active trial type in
% Session(3) of Subject(5), the command would be:
% E('Pks','Pks',5,3,12);

global Experiment

if nargin < 2 || ~ischar(O) || ~ischar(F)
    
    disp('First two arguments must be strings')
    return
end

if ~isempty(varargin) % checking that these are integers greater than 0
    
    for a = 1:length(varargin)
        
        if ischar(varargin{a}) || varargin{a} < 1
            disp('Arguments 3 & greater must be integers > 0')
            return
        end
        
    end
    
end

switch length(varargin)
    
    case 0
        
        if isfield(Experiment,F)
    
            evalin('caller',sprintf('%s=Experiment.%s;',O,F));
            
        else
            
            fprintf('%s is not a field of Experiment',F)

        end
        
    case 1
        
        if varargin{1} <= length(Experiment.Subject) ...
                && isfield(Experiment.Subject(varargin{1}),F)
                    
            evalin('caller',sprintf('%s=Experiment.Subject(%d).%s;',O,varargin{1},F));
            
        elseif varargin{1} > length(Experiment.Subject)
            
            disp('Not that many subjects in Experiment')
            
        else
            
            fprintf('%s is not a field of Experiment.Subject(%d)',F,varargin{1});
            
        end
        
    case 2
        
        if varargin{2} <= length(Experiment.Subject(varargin{1}).Session) ... 
            && isfield(Experiment.Subject(varargin{1}).Session(varargin{2}),F)
    
            evalin('caller',sprintf('%s = Experiment.Subject(%d).Session(%d).%s;',...
                O,varargin{1},varargin{2},F));
            
        elseif varargin{2} > length(Experiment.Subject(varargin{1}).Session) 
            
            fprintf('Not that many sessions in Experiment(%d).Subject(%d)',...
                varargin{1},varargin{2});
            
        else
            
            fprintf('%s is not a field of Experiment.Subject(%d).Session(%d)',...
                F,varargin{1},varargin{2});
            
        end
        
    case 3
        
        TT = Experiment.Info.ActiveTrialType; % active trial
        
        eval(sprintf('NumT = length(Experiment.Subject(%d).Session(%d).%s.Trial);',...
        varargin{1},varargin{2},TT));
        
        eval(sprintf('IsFld=isfield(Experiment.Subject(%d).Session(%d).%s.Trial,''%s'');',...
            varargin{1},varargin{2},TT,F));
        
        if varargin{3} <= NumT && IsFld
            
            evalin('caller',...
                sprintf('%s = Experiment.Subject(%d).Session(%d).%s.Trial(%d).%s;',...
                O,varargin{1},varargin{2},TT,varargin{3},F));
            
        elseif varargin{3} > NumT
            
            fprintf('Not that many trials in Experiment.Subject(%d).Session(%d).%s',...
                varargin{1},varargin{2},TT);
            
            
        else
            
            fprintf('%s is not a field in Experiment.Subject(%d).Session(%d).%s.Trial(%d)',...
                F,varargin{1},varargin{2},TT,varargin{3})
            
        end
        
        
        
end % need to write conditionals for trial case 