% Function that converts stimulation commands to a string that can be
% passed to the wireless stimulator. Stimulation commands are defined in
% 'stim_PW'/'stim_amp', dependending on whether we do PW-modulated or
% amplitudes-modulated FES, and 'bmi_fes_stim_params'.
%
% function cmd_combined = stim_elect_mapping_wireless( stim_PW, stim_amp, bmi_fes_stim_params )
%
%


function cmd_combined = stim_elect_mapping_wireless( stim_PW, stim_amp, bmi_fes_stim_params )


cmd_combined                    = []; % the command that will be passed to the stimulator
