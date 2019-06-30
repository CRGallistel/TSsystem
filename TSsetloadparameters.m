function [result] = TSsetloadparameters(varargin)% TSSETLOADPARAMETERS Sets parameters used when loading data files%% Syntax: [result] = TSsetloadparameters(parameter, value, parameter, value, ...)%%   Parameter - The name of a parameter to set (e.g.,'InputTimeUnit')%   Value     - The value to set it to (e.g., .01)%%   Any number of parameter-value pairs can be passed. Parameter names are%   case-insensitive.%%   Supported Parameters and value types:%       INPUTTIMEUNIT - Double%       OUTPUTTIMEUNIT - Double%       LOADFUNCTION - Function Handle or String function name%       FILEPREFIX - String%%   InputTimeUnit - The unit in which the timestamps are specified in the%                   data files. Should be measured in seconds. e.g. If the%                   data file uses 50ths of a second, InputTimeUnit should%                   be set to .02%%   OutputTimeUnit- The unit which timestamps should be measured in once%                   loaded into the experiment. If you would like them in%                   seconds, this should be 1. If you would like them in%                   10ths of a second, this should be .1%%   LoadFunction  - Specifies the function to be used to load an individual%                   file. It can be a string name or it can%                   be a function handle. %%                   Custom routines used as load functions must be able to%                   accept only a filename. They are responsible for%                   implementing the InputTimeUnit and OutputTimeUnit%                   fields; see the implementation of TSloadtab for an%                   example of how this is done. They must also add the%                   loaded session to the structure array and set the%                   appropriate fields and information.%%                   Listing of Standard Functions:%                   * TSloadMEDPC, loads MEDPC files written using our%                   time-stamped MEDPC format. See the manual for more%                   information.%                   * TSloadstdtab, loads tab-delimited files using our%                   generic time-stamped data format. See the manual for%                   more information.%                   * TSloadstdcsv, loads comma-seperated *.CSV files using%                   our generic time-stamped data format. See the manual%                   for more information.%                   * TSloadstdxls, loads Excel files using our generic%                   time-stamped data format. See the manual for more%                   information.%%   FilePrefix    - Sets the file prefix used by TSloadsessions to decide%                   which files to pass to the loadfunction. Only files%                   with names that start with the prefix will be loaded.%                   If the prefix is set to '' then it is effectively%                   disabled. The default is ''. This is good to use as a%                   means of distinguishing data files from .m files and%                   other experiment files.%%   FileExtension - Sets the file extension required for files to be loaded %                   in. Works like FilePrefix except that it works from the%                   end of the filename. If this is set to '' then it is%                   effectively disabled. The default is ''.%%   Inter   - Interrogates user for parameter values. This is not a%   variable-value pair. It can be specified anywhere in the varargin%   PROVIDED THAT IT DOES NOT COME BETWEEN A VARIABLE AND ITS VALUE!result = 0;if evalin('base','isempty(who(''global'',''Experiment''))')    error('There is no experiment structure');    return;end;global Experimentwhile length(varargin) > 1 % This assumes a fixed order in the variable-value pairs    % rewrite so that it no longer does (use for loop instead of while and    % assume that when a string in varargin cell matches one of the    % variable name, the value of that variable is in the next varargin    % cell)    if ~ischar(varargin{1})        warning('Nonstring parameter has been skipped.'); % rewrite will no longer have this warning    else        switch upper(varargin{1}) % converts string to upper case            case 'INTER'                Interrogate % calling the Interrogate function embedded below            case 'INPUTTIMEUNIT'                if isnumeric(varargin{2})                    Experiment.Info.InputTimeUnit = varargin{2};                else                    warning(['Unacceptable parameter value pair: ' varargin{1} ' and ' varargin{2} ]);                end            case 'OUTPUTTIMEUNIT'                if isnumeric(varargin{2})                    Experiment.Info.OutputTimeUnit = varargin{2};                else                    warning(['Unacceptable parameter value pair: ' varargin{1} ' and ' varargin{2} ]);                end            case 'LOADFUNCTION'                if  isa(varargin{2}, 'function_handle') || ischar(varargin{2})                    Experiment.Info.LoadFunction = varargin{2};                else                    warning(['Unacceptable parameter value pair: ' varargin{1} ' and ' varargin{2} ]);                end            case 'FILEPREFIX'                if ischar(varargin{2})                    Experiment.Info.FilePrefix = varargin{2};                else                    warning(['Unacceptable parameter value pair: ' varargin{1} ' and ' num2str(varargin{2}) ]);                end            case 'FILEEXTENSION'                if ischar(varargin{2})                    Experiment.Info.FileExtension = varargin{2};                else                    warning(['Unacceptable parameter value pair: ' varargin{1} ' and ' num2str(varargin{2}) ]);                end            otherwise                warning(['Unrecognized parameter variable: ' varargin{1}]);        end    end    varargin(1:2) = []; % when for loop is used rather than while, you will    % not use this somewhat bizaare way of keeping track of progress    % through the vararginendresult = 1;% begin embedded function that interrogates user to get load parametersfunction Interrogate% Obtains parameter values by interrogating user and loads them into the% appropriate fields in the Experiment structureglobal Experiment % so this function can access the Experiment structurestr1 = ['\n\nWhen the number 100 appears as the time stamp\n' ...    'in the raw data, how many seconds of session time\n' ...    'have elapsed?  [Plausible answers are:\n' ...    '  100     if the second is the unit of time in the raw data\n' ...    '  1       if 1/100th of a second is the unit of time\n' ...    '  2       if 1/50th of a second is the unit of time\n' ...    '  10      if 1/10th of a second is the unit of time\n' ...    '  6000    if the minute is the unit of time\n' ...    '  360000  if the hour is the unit of time]: '];Experiment.Info.InputTimeUnit = input(str1)/100; % getting the input time unit from the userfprintf('\n\nExperiment.Info.InputTimeUnit set to %ss\n',num2str(Experiment.Info.InputTimeUnit))while 1    OUT = input('\n\nWhat do you want the unit for the time stamps\nin the Experiment structure to be? [ms,s,m,h,d]','s');    switch OUT        case 'ms'            Experiment.Info.OutputTimeUnit = .001;            fprintf('Experiment.Info.OutputTimeUnit set to %ss\n(= ms)\n',num2str(.001))            break % out of while loop        case 's'            Experiment.Info.OutputTimeUnit = 1;            fprintf('Experiment.Info.OutputTimeUnit set to %ss\n',num2str(1))            break % out of while loop        case 'm'            Experiment.Info.OutputTimeUnit = 60;            fprintf('Setting Experiment.Info.OutputTimeUnit to %ss\n(= min)\n',num2str(60))            break % out of while loop        case 'h'            Experiment.Info.OutputTimeUnit = 3600;            fprintf('Experiment.Info.OutputTimeUnit set to %ss\n(= #s in 1 hr)\n',num2str(3600))            break % out of while loop        case 'd'            Experiment.Info.OutputTimeUnit = 86400;            fprintf('Experiment.Info.OutputTimeUnit set to %ss\n(= #s in one day)\n',num2str(86400))            break % out of while loop        otherwise            fprintf('\n\nYour answer does not specify a plausible unit of time\n')            % go round the while loop again    end % of switchend % of whilewhile 1 % finding and loading the load function    LoadFun = input('\n\nWhat is the name of the load function for your data\n(the function that understands the structure of your raw data files)?','s');        if exist(LoadFun)~=2 % can't find load function        BorL = input('\n\nThat is not a function on Matlab''s current search path.\nDo you want to browse for it [answer B]\nor specify it later [answer L]? ','s');                if isempty(BorL) || ~any(strcmp({'B' 'L'},BorL)) % not an acceptable answer?            fprintf('\nMust answer B or L (not enclosed in single quotes)\n')            continue        end % is an accpetable answer                switch borL            case 'B'                Experiment.Info.LoadFunction = uigetfile('*.m','Find Load Function'); % browse for load function                fprintf('\n\nExperiment.Info.LoadFunction set to: %s\n',Experiment.Info.LoadFunction)                fprintf('\nWarning: TSloadsessions won''t load data into Experiment\nwhen %s is not on Matlab''s search path\n\n',Experiment.Info.LoadFunction)            case 'L'                fprintf('\n\nNot putting a load function into Experiment.Info.LoadFunction at this time\n')                break % out of while loop        end    else % load function is on the search path        Experiment.Info.LoadFunction = LoadFun;        fprintf('\n\nExperiment.Info.LoadFunction set to: %s\n',Experiment.Info.LoadFunction)    endenddisp(char({'';'Folders that contain raw data files';...    'also usually contain other files,';...    'some of which are hidden files';...    'put there by the operating system.';...    'To prevent the load function from';...    'trying to read them when you call TSloadsessions';...    'to load your data into the Experiment structure,';...    'you need to specify a prefix character and/or';...    'an extension that will distinguish your data files';...    'files from all other files in the same folder.';''}))Experiment.Info.FilePrefix=input('\nIf your data files begin with a character unique to them\n(e.g., ''!''), what is that character?\n[Do not enclose answer in single quotes.\nIf no such character, just hit rtn]? ','s');fprintf('\n\nExperiment.Info.FilePrefix set to: %s\n',Experiment.Info.FilePrefix)Experiment.Info.FileExtension = input('\nTo use an extension to distinguish your data files\nor an extension together with the prefix you may have just specified,\nanswer with the extension (e.g, ''.txt''): ','s');fprintf('\n\nExperiment.Info.FileExtension set to: %s\n',Experiment.Info.FileExtension)