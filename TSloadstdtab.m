function [ SUCCESS , ExperimentID, SubjectID, Phase, Box, MatlabStartDate, Duration, TSdata, Notes, Weight, Program, FileReportedUnits ] = TSloadstdtab ( filename )%% Assumptions:%   File is tab delimited%   Dlm file forms a 2 column matrix%   First 12 rows are various session fields with indicator numbers on the %   right column which tell the program which field it is. These do not%   have to be in any specific order. At the end, a row of 0,0 seperates%   the tsdata from the codes.%   Month,      1%   Date,       2%   Year,       3%   Hours,      4%   Minutes,    5%   Seconds,    6%   Experiment, 7%   Subject,    8%   Phase,      9%   Box,        10%   TimeUnit,   11%   Weight,     12%   0,          0%   ... (tsdata)...%   ...         ...%   ...         ...%%   Only Subject and date are really required. Other things are not%   strictly required but are good to have. TimeUnit is strictly optional, and%   represents the unit the time stamps are measured in, using%   seconds e.g. if your unit is 50ths of a seconds, this field should be%   .02. If this field is not provided the load parameters will be used. If%   this field does not match the load parameters setting, a warning will%   be passed and the data file will override the load parameters setting.%%   Weight is strictly optional and if your apparatus does not take note of%   this, you are encouraged to use the TSexperimentbrowser to enter this%   data at the end of the Experiment.SUCCESS = 0;% raw = dlmread(filename, '\t');raw = dlmread(filename)seperator = find(raw(:,2) == 0, 1, 'first'); % first row with a 0 in the% 2nd column separates the header rows from the time-stamped data rowsmonth = [];date = [];year = [];hours = [];minutes = [];seconds = [];ExperimentID = [];SubjectID = [];Phase = [];Box = [];FileReportedUnit = [];Notes = '';Weight = [];Program = '';FileReportedUnits = [];Duration = [];TSdata = [];x = 1;while x < seperator    switch raw(x,2)        case 1            month = raw(x,1);        case 2            date = raw(x,1);                    case 3            year = raw(x,1);                    case 4            hours = raw(x,1);        case 5            minutes = raw(x,1);        case 6            seconds = raw(x,1);        case 7            ExperimentID = raw(x,1);        case 8            SubjectID = raw(x,1);        case 9            Phase = raw(x,1);        case 10            Box = raw(x,1);        case 11            FileReportedUnit = raw(x,1);        case 12            Weight = raw(x,1);    end    x = x + 1;endif isempty(month)    warning('TSload:NoMonth', 'This sesssion data file %s did not provide the month of the session.', filename);endif isempty(date)    warning('TSload:NoDate', 'This sesssion data file %s did not provide the date of the session.', filename);endif isempty(year)    warning('TSload:NoYear', 'This sesssion data file %s did not provide the year of the session.', filename);endif isempty(hours)    warning('TSload:NoHour', 'This sesssion data file %s did not provide the hour of the session.', filename);    hours = 12;endif isempty(minutes)    warning('TSload:NoMinute', 'This sesssion data file %s did not provide the minutes of the session.', filename);    minutes = 0;endif isempty(seconds)    seconds = 0;endMatlabStartDate = datenum(year, month, date, hours, minutes, seconds);TSdata = raw(seperator+1:end, :);TSdata = sortrows(TSdata, 1);TSdata(all((TSdata == circshift(TSdata, 1))'),:) = [];SUCCESS = 1;