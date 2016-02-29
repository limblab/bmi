%
% Function that converts stimulation commands to a string that can be
% passed to the wireless stimulator. Stimulation commands are defined in
% 'stim_PW'/'stim_amp', dependending on whether we do PW-modulated or
% amplitudes-modulated FES, and 'bmi_fes_stim_params'.
%
% function cmd_combined = stim_elect_mapping_wireless( stim_PW, stim_amp, bmi_fes_stim_params, varargin )
%
%


function [cmd, ch_list] = stim_elect_mapping_wireless( stim_PW, stim_amp, bmi_fes_stim_params, varargin )

% bool to tell if this is a catch trial
catch_trial                     = false;

if nargin == 4
    if strcmpi(varargin{1},'catch')
        catch_trial             = true;
    end
end

% channels in the stimulator -we have to update the PW/I in all of them
% because of how the zigbee communication works. If not using some
% channels, just add zeroes
ch_list                         = 1:16;


switch bmi_fes_stim_params.mode
    
    % For PW-modulated FES
    case 'PW_modulation'
        
        % converts input PWs from ms to us (those are the units the wireless
        % stimulator takes
        if ~catch_trial
            stim_PW             = stim_PW*1000;
        % if it's a catch trial, make all PWs zero
        else
            stim_PW             = zeros(1,length(stim_PW));
        end
        
        switch bmi_fes_stim_params.return
            
            case 'monopolar'
        
                % assign it to the stim anode
                elecs_this_muscle = zeros(1,length(stim_PW));
                for i = 1:length(elecs_this_muscle)
                    elecs_this_muscle(i) = bmi_fes_stim_params.anode_map{1,i};
                end
                
                % we new to arrange the stimulator channel numbers to pass
                % the command
                [elecs_this_muscle, indx_ch] = sort(elecs_this_muscle);
                
                % now rearrange the stim_PW accordingly
                stim_PW         = repmat(stim_PW,1,2);
                stim_PW         = stim_PW(indx_ch);
                
                % create the stimulation command. 
                cmd{1}          = struct('CathDur', stim_PW, ...
                                    'AnodDur', stim_PW); 
                
            case 'bipolar'
                
                % assign it to the corresponding stim anode and cathode
                elecs_this_muscle = zeros(1,2*length(stim_PW));
                for i = 1:length(stim_PW)
                    elecs_this_muscle(i) = bmi_fes_stim_params.anode_map{1,i};
                end
                for i = 1:length(stim_PW)
                    elecs_this_muscle(i+length(stim_PW)) = bmi_fes_stim_params.cathode_map{1,i};
                end
                
                % we new to arrange the stimulator channel numbers to pass
                % the command
                [elecs_this_muscle, indx_ch] = sort(elecs_this_muscle);
                
                % now rearrange the stim_PW accordingly
                stim_PW         = repmat(stim_PW,1,2);
                stim_PW         = stim_PW(indx_ch);
               
                % add the channels we are not stimulating to the command,
                % and populate their PW with zeroes
                % --the wireless stimulator expect a 16-channel command
                PW_cmd          = zeros(1,length(ch_list));
                PW_cmd(elecs_this_muscle)   = stim_PW;
                
                % create the stimulation command. 
                cmd{1}          = struct('CathDur', PW_cmd, ...
                                    'AnodDur', PW_cmd);
        end
       
    % For amplitude-modulated FES
    case 'amplitude_modulation'
        
        % converts input PWs from ms to us (those are the units the wireless
        % stimulator takes
        stim_amp                = stim_amp*1000;
        
        error('amplitude-modulated FES not implemented yet');
end

