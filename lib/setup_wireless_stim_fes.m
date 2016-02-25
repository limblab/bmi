
function setup_wireless_stim_fes( ws, bmi_fes_params )


% read the channels that will be used
switch bmi_fes_params.return
    case 'monopolar'
        channel_list    = [bmi_fes_params.anode_map{1,:}];
    case 'bipolar'
        channel_list    = [[bmi_fes_params.anode_map{1,:}] ...
                            [bmi_fes_params.cathode_map{1,:}]];
end
channel_list_len        = length(channel_list);
% the stimulator channels need to be ordered
[channel_list, indx_ch] = sort(channel_list);

% stim amplitude in mA
amp                     = bmi_fes_params.amplitude_max*1000;

% Set up the parameters that will be constant during FES
switch bmi_fes_params.mode
    
    % For PW-modulated FES
    case 'PW_modulation'

        % set train duration, stim freq and run mode 
        % ToDo: check if TL and Run are necessary if we are then doing cont
        ws.set_TL( 100, channel_list );
        ws.set_Freq( bmi_fes_params.freq , channel_list );
                                
        % set pulse width to zero
        ws.set_AnodDur( 0, channel_list );
        ws.set_CathDur( 0, channel_list );
        
        % Now choose between monopolar and bipolar FES 
        switch bmi_fes_params.return
            case 'monopolar'

                % reorder the stim amplitude according to the channel_list
                amp             = amp(indx_ch);
                
                % set amplitude -- done in a different command because of
                % limitations in command length (register write in zigbee)
                ws.set_AnodAmp( 32768-amp, channel_list );
                ws.set_CathAmp( 32768+amp, channel_list );
                
                % set polarity for all channels 
                ws.set_PL( 1, channel_list )
                
                % Configure train delay differently for each channel
                % -- Stagger by 500 us, to minimize fatigue
                % Minimum TD = 50 us, to avoid problems with the waveforms
                for ch = 1:channel_list_len
                    td          = ( ch - 1 ) * 500 + 50;
                    ws.set_TD( td, channel_list(ch) );
                end

            case 'bipolar'

                % define arrays with the anodes and cathodes
                anode_list      = [ bmi_fes_params.anode_map{1,:} ];
                cathode_list    = [ bmi_fes_params.cathode_map{1,:} ];                
                
                % reorder the anodes and the cathodes
                [anode_list, indx_an]   = sort(anode_list);
                [cathode_list, indx_ca] = sort(cathode_list);
                
                % reorder the stim amplitudes according to the anodes
                % -supposedly this is fine
                amp             = amp(indx_an);
                
                % set amplitude -- done in a different command because of
                % limitations in command length (register write in zigbee)
                ws.set_AnodAmp( 32768-amp, anode_list );
                ws.set_CathAmp( 32768+amp, anode_list );
                ws.set_AnodAmp( 32768-amp, cathode_list );
                ws.set_CathAmp( 32768+amp, cathode_list );
                
                % Set polarity for the anodes...
                % read what electodes are set as anodes
                for i = 1:numel(anode_list)
                    % Configure train delay differently for each channel
                    % -- Stagger by 500 us, to minimize fatigue
                    % Minimum TD = 50 us, to avoid problems with the waveforms
                    td          = (i-1) * 500 + 50;
                    ws.set_TD( td, anode_list(i) );
                end
                % Set polarity to anodic first
                ws.set_PL( 0, anode_list );
                
                % ... and for the cathodes
                % read what electodes are set as cathodes
                for i = 1:numel(cathode_list)
                    % Configure train delay differently for each channel
                    % -- Stagger by 500 us, to minimize fatigue
                    td          = (i-1) * 500 + 50;   % Minimum TD = 50 us, to avoid problems with the waveforms
                    ws.set_TD( td, cathode_list(i) );
                end
                % Set polarity to anodic first 
                ws.set_PL( 1, cathode_list );
           
        end
        
    % For PW-modulated FES
    case 'amplitude_modulation'

        error('amplitude-modulated FES not implemented yet');
end

% set to run continuous
ws.set_Run( ws.run_cont, channel_list );