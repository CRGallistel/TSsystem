%% TSendsession
% TSendsession is a script to close a specified subset of active boxes in
% an experiment. It takes as arguments ExpIDnum which is an integer
% identifying the experiment having a session ended and SubIDs which is a
% vector of all the subject IDs having sessions closed

function TSendsession(ExpIDnum,SubIDs)

try
% use the GUI to have the user find the experiment structure

global Experiment;

if (isempty(Experiment)) 
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
end

if ~(Experiment.Id==ExpIDnum)
    
    display('Warning: user-specified ID and structure Experiment.Id do not match')
    display('type return to continue or dbquit to abort')
    keyboard
    
end

j=0;
for S=SubIDs
    %S = find(i==Experiment.Subjects);
    j=j+1;
    TmpDrives(j) = Experiment.Subject(S).MacroInfo(end).progpath(1);
    TmpBoxes(j) = Experiment.Subject(S).MacroInfo(end).box;
    %TmpIDs(j) = Experiment.Subject(S).MacroInfo(end).id;
    TmpIDs(j) = S;
end
%Drives = unique(Drives);

% sort arrays by drive letter
%indices = [];
DriveData = {'', [], []};
for m = 1:length(TmpDrives)
    % see if current drive is already in drive data
    tmpInd = 0;
    
    for j = 1:size(DriveData,1)
        if DriveData{j,1} == TmpDrives(m)
            tmpInd = j;
            break;
        end
    end
    
    if tmpInd == 0
        % doesnt exist in list; add to list
        if isempty(DriveData{1,1})
            DriveData(1,:) = {TmpDrives(m), TmpBoxes(m), TmpIDs(m)};
        else
            DriveData(size(DriveData,1)+1,:) = {TmpDrives(m), TmpBoxes(m), TmpIDs(m)};
        end
    else
        % append to list's data
        DriveData{tmpInd,2} = [DriveData{tmpInd,2}, TmpBoxes(m)];
        DriveData{tmpInd,3} = [DriveData{tmpInd,3}, TmpIDs(m)];
    end
%     max = 'A';
%     max_ind = 0;
%     
%     for o = 1:length(TmpDrives)
%         if (TmpDrives{o} > max && ~ismember(o, indices))
%             max = TmpDrives{o};
%             max_ind = o;
%         end
%     end
%     indices(end+1) = max_ind;
%     
%     Drives(m) = TmpDrives(max_ind);
%     Boxes(m) = TmpBoxes(max_ind);
%     IDs(m) = TmpIDs(max_ind);
end


% issue closing command for each subject
for p=1:size(DriveData, 1)

[s, w] = dos(['net use | find /i "', DriveData{p,1}, ':"']);
b = strfind(w,'\\');
e = strfind(w,'\');
e = e(end);
server = w(b:e);
server = server(3:end-1);

% tell the user what they need to close and ask to press ENTER
disp(['You need to top Subject(s) # ', num2str(DriveData{p,3}), ' running on box(es) ', num2str(DriveData{p,2}), ' on machine ', server]);
input('Press RETURN when you are ready. Remote desktop will open automatically.');

switch server 
    case 'gallanalysis'
        ipadd = '172.17.34.132';
    case 'nel-gallistel03'
        ipadd = '172.17.34.138';
    case 'gallistallab3'
        ipadd = '172.17.34.27';
    case 'nel7-glab3'
        ipadd = '172.17.34.193';
    case 'nel7-glab1'
        ipadd = '172.17.34.128';
    case 'nel7-galistel5'
        ipadd = '172.17.34.173';
end

% start remote desktop
dos(['mstsc.exe /v:', ipadd]);

% %schedule taskkill command on remote machine -- commented out as it
% closes all active boxes on the target machine. Will use remote desktop
% instead.
% curTime = clock; 
%     StartTime = sprintf('%02d:%02d:00', curTime(4), curTime(5)+2);
%     if (strcmp(server,'gallanalysis') || strcmp(server,'nel-gallistel03') || strcmp(server,'gallistallab3'))
%         % if windows xp computer
%         KillCmd = ['winrs -r:', server, ' -u:LIFE_SCIENCES\Gallistellab -p:McCogGen1 schtasks /create /sc ONCE /tn StopMedPCMacro /tr "taskkill /IM MEDPC_IV.exe" /st ', StartTime, ' /ru LIFE_SCIENCES\Gallistellab /rp McCogGen1'];
%     elseif (strcmp(server,'nel7-glab3') || strcmp(server,'nel7-glab1'))
%         % else if windows 7 computer
%         KillCmd = ['winrs -r:', server, ' -u:LIFE_SCIENCES\Gallistellab -p:McCogGen1 schtasks /create /sc ONCE /tn StopMedPCMacro /tr "taskkill /IM MEDPC_IV.exe" /st ', StartTime, ' /f'];
%     end
% 
%     dos(KillCmd);
%     display(['stopped ', D, ' drive'])
end

catch err
   disp(err.message); 
end

end