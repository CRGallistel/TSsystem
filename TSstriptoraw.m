function TSstriptoraw
% removes the Trial level from the Experiment structure and all the Session
% level fields from the last up to, but not including, TSData. Removes all 
% the fields at the Subject level from the last one up to NumSessions.
%  Removes all the fields at the Experiment level below Programs. 
% This function is useful for creating a clean structure when the final code
% has been settled on. In this structure, the fields at any level will 
% appear in the order in which they are created in the script
global Experiment
str = input('This will strip everything below the Session level from the Experiment\n structure and all the fields below TSData at the Session level\nand all the fields below Programs at the Experiment level.\nProceed? (y/n)\n','s');
if ~strcmp(str,'y')
    return
else
    SesFlds = fieldnames(Experiment.Subject(1).Session); % cell array of field
    % names
    for c = 13:length(SesFlds)
        TSrmfield('Session',SesFlds{c},true)
    end
    SubFlds = fieldnames(Experiment.Subject);
    for c = 10:length(SubFlds)
        TSrmfield('Subject',SubFlds{c},true)
    end
    ExperFlds = fieldnames(Experiment);
    for c = 14:length(ExperFlds)
        TSrmfield('Experiment',ExperFlds{c},true)
    end
end