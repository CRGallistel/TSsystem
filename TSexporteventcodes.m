function TSexporteventcodes(filename)
% TSEXPORTEVENTCODES Exports event codes to a textfile.
%   TSexporteventcodes(filename) exports codes to an ascii textfile. This
%   file can be imported later by TSimporteventcodes, or set to the default
%   codeset using TSsetdefaulteventcodes. 
%
%   You can use this to send your code set to someone else or make a backup
%   of the codeset that you have used for several experiments. 
%
%   You can also use this to edit your codes in a text editor, and then
%   reimport them. This may be easier or quicker than using TSaddeventcodes
%   and TSrmeventcodes. 
%
%   If the filename is left out, a UI dialog will pop up to choose a
%   location to save.

if evalin('base','isempty(who(''global'',''Experiment''))');
    error('There is no Experiment structure defined');
end

global Experiment

if ~isfield(Experiment, 'EventCodes') || ~isstruct(Experiment.EventCodes)
    error('No codes were found in Experiment to export.');
    return;
end

if nargin < 1
    %Call up a file window for the output code list
    [filename, pathname] = uiputfile('*.*', 'Where to save the Event Codes file');
	filename = [pathname filename];
end

codes = Experiment.EventCodes;
fn = fieldnames(codes);


fid = fopen(filename,'w');

for (x = 1 : length(fn))
    fprintf(fid, '%s = %s;\n',fn{x}, mat2str(codes.(fn{x})));
end

fclose(fid);

disp('Successful writing code file.');