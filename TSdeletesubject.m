function TSdeletesubject(SubId)
% deletes a subject from the Experiment structure, eliminates its ID # from
% the Experiment.Subject field and reduces the Experiment.NumSubjects by 1
% 
%Syntax: TSdeletesubject(SubId)
% NB the input arguments is the subject's ID# --NOT its index #
% Also IF THE STRUCTURE CONTAINS FIELDS THAT LIST SUBJECTS BY THEIR INDEX
% NUMBERS (FOR EXAMPLE, FIELD FOR GROUPS), THE INDEX NUMBERS FOR ALL
% SUBJECTS WITH INDEX #S GREATER THAN THAT OF THE DELETED SUBJECT WILL HAVE
% TO BE CORRECTED (REDUCED BY 1)
global Experiment
c = find(Experiment.Subjects==SubId);
Experiment.Subject(c) = [];
Experiment.NumSubjects = Experiment.NumSubjects-1;
Experiment.Subjects(c)=[];