function Name = TSeventname(EventNumber)
% finds the name for an event, given its numerical code. In other words,
% this function reads the event code dictionary backwards. This is useful
% when troubleshooting
%
% syntax: Name = TSeventname(EventNumber)
% or: TSeventname(EventNumber)

global Experiment

Name = 'not found';

EventNumber = reshape(EventNumber,1,length(EventNumber));

for n = EventNumber

    FldNms = fieldnames(Experiment.EventCodes);

    for c = 1:length(FldNms)

        if eval(['Experiment.EventCodes.' FldNms{c} '==n;'])

            disp(FldNms{c})

            Name = FldNms{c}; break;

        end

    end
end

if nargout<1
    
    clear Name
end