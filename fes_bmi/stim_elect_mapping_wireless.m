% Function that converts stimulation commands to a string that can be
% passed to the wireless stimulator. Stimulation commands are defined in
% 'stim_PW'/'stim_amp', dependending on whether we do PW-modulated or
% amplitudes-modulated FES, and 'bmi_fes_stim_params'.
%
% function cmd_combined = stim_elect_mapping_wireless( stim_PW, stim_amp, bmi_fes_stim_params )
%
%


function [cmd, ch_list] = stim_elect_mapping_wireless( stim_PW, stim_amp, bmi_fes_stim_params, ws )

stim_PW = stim_PW*1000; % converts from ms (input) to us (output)

switch bmi_fes_stim_params.mode
    
    case 'PW_modulation'
        
        % create the stimulation command
        cmd{1} = struct('CathDur', stim_PW, 'AnodDur', stim_PW, 'Run', ws.run_cont); % run_once_go
        
        % assign it to the stimulation electrode
        elecs_this_muscle = zeros(1,length(stim_PW));
        for i = 1:length(stim_PW)
            elecs_this_muscle(i) = bmi_fes_stim_params.anode_map{1,i};
        end
       
    case 'amplitude_modulation'
        
end

ch_list = elecs_this_muscle;
