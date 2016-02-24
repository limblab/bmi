%
% Function that converts stimulation commands to a string that can be
% passed to the wireless stimulator. Stimulation commands are defined in
% 'stim_PW'/'stim_amp', dependending on whether we do PW-modulated or
% amplitudes-modulated FES, and 'bmi_fes_stim_params'.
%
% function cmd_combined = stim_elect_mapping_wireless( stim_PW, stim_amp, bmi_fes_stim_params )
%
%


function [cmd, ch_list] = stim_elect_mapping_wireless( stim_PW, stim_amp, bmi_fes_stim_params, ws )


switch bmi_fes_stim_params.mode
    
    % For PW-modulated FES
    case 'PW_modulation'
        
        % converts input PWs from ms to us (those are the units the wireless
        % stimulator takes
        stim_PW             = stim_PW*1000;
        
        switch bmi_fes_stim_params.return
            
            case 'monopolar'
        
                % create the stimulation command
                cmd{1}      = struct('CathDur', stim_PW, 'AnodDur', stim_PW, 'Run', ws.run_cont); % run_once_go

                % assign it to the stim anode
                elecs_this_muscle = zeros(1,length(stim_PW));
                for i = 1:length(elecs_this_muscle)
                    elecs_this_muscle(i) = bmi_fes_stim_params.anode_map{1,i};
                end
                
            case 'bipolar'
                
                % create the stimulation command. The PW repeats twice, for
                % the anodes and cathodes
                cmd{1}      = struct('CathDur', repmat(stim_PW,1,2), ...
                                    'AnodDur', repmat(stim_PW,1,2) ...
                                    );
                % there was a run_cont here. ToDo: Check if it's necessary
                            
                % assign it to the corresponding stim anode and cathode
                elecs_this_muscle = zeros(1,2*length(stim_PW));
                for i = 1:length(stim_PW)
                    elecs_this_muscle(i) = bmi_fes_stim_params.anode_map{1,i};
                end
                for i = 1:length(stim_PW)
                    elecs_this_muscle(i+length(stim_PW)) = bmi_fes_stim_params.cathode_map{1,i};
                end
        end
       
    % For amplitude-modulated FES
    case 'amplitude_modulation'
        
        % converts input PWs from ms to us (those are the units the wireless
        % stimulator takes
        stim_amp            = stim_amp*1000;
        
        error('amplitude-modulated FES not implemented yet');
end

% output params
ch_list                     = elecs_this_muscle;
