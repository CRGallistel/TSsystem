%% TSendsession
% TSendsession is a script to close a specified subset of active boxes in
% an experiment. It takes as arguments ExpIDnum which is an integer
% identifying the experiment having a session ended and SubIDs which is a
% vector of all the subject IDs having sessions closed

function TSendsession(ExpIDnum,SubIDs)

% use the GUI to have the user find the experiment structure

display(strvcat('Use the GUI to find the file of the Experiment structure.',...
    'That structure will be loaded,',' '))
[StrucName,PathName] = uigetfile('Experiment*.mat','Find Experiment Structure');

i = length(num2str(ExpIDnum));

% compare the i letters following 'Experiment' in the file name to the
% user-specified experiment ID

if ~(str2double(StrucName(11:10+i))==ExpIDnum)
    
    display('Warning: user-specified ID and filename do not match')
    display('type return to continue or dbquit to abort')
    keyboard
    
end

TSloadexperiment([PathName StrucName]);

global Experiment;

if ~(Experiment.Id==ExpIDnum)
    
    display('Warning: user-specified ID and structure Experiment.Id do not match')
    display('type return to continue or dbquit to abort')
    keyboard
    
end

if ~(Experiment.Id==ExpIDnum)
    
    display('Warning: user-specified ID and structure Experiment.Id do not match')
    display('type return to continue or dbquit to abort')
    keyboard
    
end

% HK - The following lines are deprecated since we can now stop only some
% % of the subjects, instead of all of them
% % create vector with the subject Ids of the active subjects as specified in
% % the experiment structure
% ExpAS=[Experiment.Subject(Experiment.Info.ActiveSubjects).SubId];
% 
% % check to make sure SubIDs is a vector representing the same set of
% % subject IDs as ExpAS
% 
% if ~(isempty(setdiff(SubIDs,ExpAS))) || ~(isempty(setdiff(ExpAS,SubIDs)))
%     
%     display('Warning: user-specified subject IDs and Experiment.Info.ActiveSubjects are not the same')
%     display('user specified ', num2str(SubIDs))
%     display('currently active ', num2str(ExpAS))
%     display('type return to continue or dbquit to abort')
%     keyboard
%     
% end

j=0;
for i=SubIDs
    
    S = find(i==Experiment.Subjects);
    
    j=j+1;
    
    Drives(j) = Experiment.Subject(S).MacroInfo(end).progpath(1);
    
end

Drives = unique(Drives);

% issue closing command for each subject
for D=Drives

[s, w] = dos(['net use | find /i "', D, ':"']);
b = strfind(w,'\\');
e = strfind(w,'\');
e = e(end);
server = w(b:e);
server = server(3:end-1);

curTime = clock; 
    StartTime = sprintf('%02d:%02d:00', curTime(4), curTime(5)+2);
    if (strcmp(server,'gallanalysis') || strcmp(server,'nel-gallistel03') || strcmp(server,'gallistallab3'))
        % if windows xp computer
        KillCmd = ['winrs -r:', server, ' -u:LIFE_SCIENCES\Gallistellab -p:McCogGen1 schtasks /create /sc ONCE /tn StopMedPCMacro /tr "taskkill /IM MEDPC_IV.exe" /st ', StartTime, ' /ru LIFE_SCIENCES\Gallistellab /rp McCogGen1'];
    elseif (strcmp(server,'nel7-glab3') || strcmp(server,'nel7-glab1'))
        % else if windows 7 computer
        KillCmd = ['winrs -r:', server, ' -u:LIFE_SCIENCES\Gallistellab -p:McCogGen1 schtasks /create /sc ONCE /tn StopMedPCMacro /tr "taskkill /IM MEDPC_IV.exe" /st ', StartTime, ' /f'];
    end

    dos(KillCmd);
    display(['stopped ', D, ' drive'])
end

end