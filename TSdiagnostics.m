function Diagnostics = TSdiagnostics(s,d)
% Performs diagnostic tests on the data in the active sessions, looking for
% indications of common mistakes in the MedPC code, revealed by, for
% example, PokeOns that are not paired with PokeOffs or LightOns that are
% not paired with LightOffs, or Pellet Errors.
% Syntax Diagnostics = TSdiagnostics(s,d)
% s is a single session number or the string 'latest'. If a session number
% is specified, then the function will check that session for all of the
% subjects that have it.
% The optional argument(d) allows one to suppress the display of
% the results in the workspace. If omitted, the results will be displayed
% 
% Diagnostics is a 1xS structure, where S is the number of active subjects.
% It has the following fields:
%     ExperID
%     Subject
%     Session
%     HsLtOnOff % House light on and off
%     PksOnOff  % For each hopper # of Ons & Offs and the difference
%     LtsOnOff  % For each hopper # of Ons & Offs and the difference
%     StrEndTrl % Numbers of starts & stops and their difference
%     FdRtrv  % For ea of 2 feeding hoppers, #s of feeds, # of retrieves &
%                       difference
%     TnOnOff  % #s of tone-ons and tone-offs and their difference
%     NsOnOff  % #s of noise-ons and noise-offs and their difference
%     StrStpFdPhase  % for 3 possible feeding phases (Early, Middle, Late)
%                       #s of Starts & Stops and their difference


if nargin<2
    d=true;
end
   
global Experiment

TSdeclareeventcodes

ActiveS = Experiment.Info.ActiveSubjects; % used later to restore setting

if isscalar(s)
        
    S = 1:Experiment.NumSubjects;
    
    TSlimit('Subjects',S([Experiment.Subject.NumSessions]>=s));
    
    AS = Experiment.Info.ActiveSubjects;
    
    s = repmat(s,1,length(AS));
    
elseif strcmp(Experiment.Info.ActiveSubjects,'all')
        
    AS = 1:Experiment.NumSubjects;
    
    s = [Experiment.Subject(AS).NumSessions];
    
else 
    
    AS = Experiment.Info.ActiveSubjects;
    
    s = [Experiment.Subject(AS).NumSessions];
    
end

Diagnostics(length(AS)) = ...
    struct('ExperID',[],'Subject',[],'Session',[],'HsLtOnOff',[],'PksOnOff',zeros(3,3),'LtsOnOff',zeros(3,3),...
    'StrEndTrl',zeros(1,3),'FdRtrv',zeros(2,3),'TnOnOff',zeros(1,3),...
    'NsOnOff',zeros(1,3),'StrStpFdPhase',zeros(3,3));

if isempty(Experiment.Id)
    display(strvcat('There is no ID number for this experiment;',...
        'Put a number in the Experiment.Id field & run diagnostics again'))
    return
else
    Diagnostics(1,1).ExperID = Experiment.Id;
end

% FldNms ={'PokeOn1';'PokeOff1';'PokeOn2';'PokeOff2';'PokeOn3';'PokeOff3';...
%     'LightOn1';'LightOff1';'LightOn2';'LightOff2';'LightOn3';'LightOff3';...
%     'ToneOn';'ToneOff';'NoiseOn';'NoiseOff';'Feed1';'Feed2';'Pretrieve1';...
%     'Pretriev2'};
% 
% EOI = isfield(Experiment.EventCodes,FldNms); % logical vector flagging
% % events of interest whose codes exist in the workspace when this
% % Experiment is analyzed

i=1;

for S = AS
    
    Diagnostics(i).ExperID = Experiment.Id;
    
    Diagnostics(i).Subject=S;
    
    Diagnostics(i).Session=s(i);
        
    D = Experiment.Subject(S).Session(s(i)).TSData;
    
    if isfield(Experiment.EventCodes,'HouseLightOn')
        if isfield(Experiment.EventCodes,'HouseLightOff')
            m = TSmatch(D,{(HouseLightOn) (HouseLightOff)});
            Diagnostics(i).HsLtOnOff = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('HouseLightOn but no HouseLightOff among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'PokeOn1')
        if isfield(Experiment.EventCodes,'PokeOff1')
            m = TSmatch(D,{(PokeOn1) (PokeOff1)});
            Diagnostics(i).PksOnOff(1,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('PokeOn1 but no PokeOff1 among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'PokeOn2')
        if isfield(Experiment.EventCodes,'PokeOff2')
            m = TSmatch(D,{(PokeOn2) (PokeOff2)});
            Diagnostics(i).PksOnOff(2,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('PokeOn2 but no PokeOff2 among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'PokeOn3')
        if isfield(Experiment.EventCodes,'PokeOff3')
            m = TSmatch(D,{(PokeOn3) (PokeOff3)});
            Diagnostics(i).PksOnOff(3,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('PokeOn3 but no PokeOff3 among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'LightOn1')
        if isfield(Experiment.EventCodes,'LightOff1')
            m = TSmatch(D,{(LightOn1) (LightOff1)});
            Diagnostics(i).LtsOnOff(1,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('LightOn1 but no LightOff1 among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'LightOn2')
        if isfield(Experiment.EventCodes,'LightOff2')
            m = TSmatch(D,{(LightOn2) (LightOff2)});
            Diagnostics(i).LtsOnOff(2,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('LightOn2 but no LightOff2 among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'LightOn3')
        if isfield(Experiment.EventCodes,'LightOff3')
            m = TSmatch(D,{(LightOn3) (LightOff3)});
            Diagnostics(i).LtsOnOff(3,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('LightOn3 but no LightOff3 among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'StartTrial')
        if isfield(Experiment.EventCodes,'EndTrial')
            m = TSmatch(D,{(StartTrial) (EndTrial)});
            Diagnostics(i).StrEndTrl(1,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('StartTrial but no EndTrial among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'Feed1') && ...
            isfield(Experiment.EventCodes,'PRetrieve1')
            m = TSmatch(D,{(Feed1) (PRetrieve1)});
            Diagnostics(i).FdRtrv(1,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
    end

    if isfield(Experiment.EventCodes,'Feed2') && ...
            isfield(Experiment.EventCodes,'PRetrieve2')
            m = TSmatch(D,{(Feed2) (PRetrieve2)});
            Diagnostics(i).FdRtrv(2,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
    end

    if isfield(Experiment.EventCodes,'StartEarly')
        if isfield(Experiment.EventCodes,'StopEarly')
            m = TSmatch(D,{(StartEarly) (StopEarly)});
            Diagnostics(i).StrStpFdPhase(1,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('StartEarly but no StopEarly among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'StartMiddle')
        if isfield(Experiment.EventCodes,'StopMiddle')
            m = TSmatch(D,{(StartMiddle) (StopMiddle)});
            Diagnostics(i).StrStpFdPhase(2,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('StartMiddle but no StopMiddle among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'StartLate')
        if isfield(Experiment.EventCodes,'StopLate')
            m = TSmatch(D,{(StartLate) (StopLate)});
            Diagnostics(i).StrStpFdPhase(3,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('StartLate but no StopLate among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'ToneOn')
        if isfield(Experiment.EventCodes,'ToneOff')
            m = TSmatch(D,{(ToneOn) (ToneOff)});
            Diagnostics(i).TnOnOff(1,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('ToneOn but no ToneOff among event codes')
            return
        end
    end

    if isfield(Experiment.EventCodes,'NoiseOn')
        if isfield(Experiment.EventCodes,'NoiseOff')
            m = TSmatch(D,{(NoiseOn) (NoiseOff)});
            Diagnostics(i).NsOnOff(1,:) = [sum(m==1) sum(m==2) sum(m==1)-sum(m==2)];
        else
            display('NoiseOn but no NoiseOff among event codes')
            return
        end
    end
    
    i=i+1;
    
end % stepping through active subjects

Experiment.Info.ActiveSubjects = ActiveS; % restoring active subjects to the
% setting it had when function was called
%%
if d
    
    i=1;
    for S=1:size(Diagnostics,2)
        
        display(strvcat('',['Subject ' num2str(Diagnostics(i).Subject)]))
            
        display(strvcat('',['  Session ' num2str(Diagnostics(i).Session)]))
        
        display(' ')
        display('     HsLtOn HsLtOff Diff')
        fprintf('       %d       %d     %d\n\n',Diagnostics(i).HsLtOnOff)

        display('         PksOn PksOff  Diff')
        display([['     H1:  ';'     H2:  ';'     H3:  '] num2str(Diagnostics(i).PksOnOff)])
        display(' ')

        display('         LtsOn LtsOff  Diff')
        display([['     H1:  ';'     H2:  ';'     H3:  '] num2str(Diagnostics(i).LtsOnOff)])
        display(' ')

        display('  StrTrl EndTrl  Diff')
        display(['   ' num2str(Diagnostics(i).StrEndTrl)])
        display(' ')

        display('        Fd  Rtrv  Diff')
        display([['   H1:  ';'   H2:  '] num2str(Diagnostics(i).FdRtrv)])
        display(' ')

        display('       TnOn TnOff Diff')
        display(['        ' num2str(Diagnostics(i).TnOnOff)])
        display(' ')

        display('       NsOn NsOff Diff')
        display(['        ' num2str(Diagnostics(i).NsOnOff)])
        display(' ')
        
        display(strvcat('Starts & Stops of Feeding Phases','        Str Stp Dif'))
        display([['  Earl:  ';'  Midl:  ';'  Late:  '] num2str(Diagnostics(i).StrStpFdPhase)])
        display(' ')
        
        i=i+1;

    end
end
    