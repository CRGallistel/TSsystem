function TSroomtemp(Yr,Mo,Dy,Hi,Lo)
% Creates or adds to field containing hi-lo room temperature info

global Experiment

if nargin<5
    
    Yr = input('Year? [yyyy] ');
    
    Mo = input('Month? [mm] ');
   
    Dy = input('Day? [dd] ');
    
    Hi = input('Hi rm temp rdg: [°C] ');
    
    Lo = input('Lo rm temp rdg: [°C] ');
    
end

if isfield(Experiment,'RmTempRdgs')
    
    Experiment.RmTempRdgs(end+1,:) = [Yr Mo Dy Hi Lo];
    
else
    
    Experiment.RmTempRdgs = [Yr Mo Dy Hi Lo];
    
end