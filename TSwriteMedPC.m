function TSwriteMedPC(Filename,ProgramNum)
% Creates a textfile with the name (Filename).MPC in the current Matlab directory
% and writes into it the MedPC program stored in the Experiment.Program
% structure of the currently active Experiment structure, with the
% index number specified by ProgramNum.
%
% For example: TSwriteMedPC('InhibitionAcquisition',#) creates a text file
% named 'InhibitionAcquisition.MPC' that contains the MedPC program stored
% in Experiment.Programs.Program(3).Code
%%
global Experiment

Filename = [Filename '.MPC'];

if exist(Filename,'file')
    
    if strcmp('y',...
            input(sprintf('A file named %s already exists. Delete it? [y/n] ',Filename),'s'))
        delete(Filename)
    else
        return
    end
end
        
diary(Filename)

disp(Experiment.Programs.Program(ProgramNum).Code)

diary off