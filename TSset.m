% TSSET  Set a field in the Experiment structure%   TSSETTRIAL(TRIALNAME) sets TRIALNAME as the active trial that will be%   used for computing statistics.  %%   When a trial is defined, it becomes the active trial.%%	See also TSsetdata, TSsetoverwritemode, TStrialstat%%% FIX ABOVEfunction TSset(arg1,arg2,arg3,arg4)if evalin('base','isempty(who(''global'',''Experiment''))')    error('There is no experiment structure');    return;end;global Experiment;if nargin==1 % Added by CRG Jul 25, 2008        trialname=arg1;    end % end of CRG additionif nargin==2                   % If there is just a fieldname and a value then find the field    if isfield(Experiment,arg1)        Experiment.(arg1)=arg2;     % in Experiment, Info    elseif isfield(Experiment.Info,arg1)        Experiment.Info.(arg1)=arg2;    end;    return;end;if strcmp(arg1, 'Experiment');    Experiment.(arg2)=arg3;    returnendif strcmp(arg1, 'Info');    Experiment.Info.(arg2)=arg3;    returnendif strcmp(arg1, 'Subject');    Experiment.Subject(arg2).(arg3)=arg4;    returnendif strcmp(arg1, 'Subject');    Experiment.Subject(arg2).(arg3)=arg4;    returnend    if strcmp(trialname, 'none');    Experiment.Info.ActiveTrialType = trialname;    returnendname=['Trial' trialname];if ~ismember(name,fields(Experiment))    disp(['There is no trial type called: ' trialname]);    return;end;Experiment.Info.ActiveTrialType = name;               