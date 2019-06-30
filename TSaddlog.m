function TSaddlog
% adds a log field with dated subfields to the top level of Experiment
% structure, so that user can keep dated experimental notes

global Experiment

Txt = date;

Txt = [Txt(4:6) '_' Txt(1:2) '_' Txt(8:end)];

if exist('Experiment','var')
    
    
    eval(sprintf('Experiment.DatedLog.%s.Notes=[]',Txt))
    
else
    
    display('No Experiment structure in workspace')
    
end
    