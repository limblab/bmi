
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

        % because of how the zigbee communication is designed, you have to
        % pass the values for all sixteen channels
        chs_cmd         = 1:ws.num_channels;
        
        % set train duration, stim freq and run mode 
        % ToDo: check if TL and Run are necessary if we are then doing cont
        ws.set_TL( 100, chs_cmd );
        ws.set_Freq( bmi_fes_params.freq , chs_cmd );
                                
        % set pulse width to zero
        ws.set_AnodDur( 0, chs_cmd );
        ws.set_CathDur( 0, chs_cmd );
        
        % Now choose between monopolar and bipolar FES 
        switch bmi_fes_params.return
            case 'monopolar'

%                 % warning because this hasn't been tested yet
%                 warning('this has not been tested yet');
%                 pause;
                
                % reorder the stim amplitude according to the channel_list
                amp             = amp(indx_ch);
                % poulate a command for the sixteen channels, including
                % those we won't be using --this is a requirement for
                % zigbee communication
                amp_cmd         = zeros(1,length(chs_cmd));
                amp_cmd(channel_list)   = amp;
                
                % set amplitude -- done in a different command because of
                % limitations in command length (register write in zigbee)
                ws.set_AnodAmp( 32768-amp_cmd, chs_cmd );
                ws.set_CathAmp( 32768+amp_cmd, chs_cmd );
                
                % set polarity for all channels 
                ws.set_PL( 1, chs_cmd )
                
                % Configure train delay differently for each channel
                % -- Stagger by 500 us, to minimize fatigue
                % Minimum TD = 50 us, to avoid problems with the waveforms
                for ch = 1:channel_list_len
                    td          = ( ch - 1 ) * 500 + 50;
                    ws.set_TD( td, channel_list(ch) );
                end

                % set to run continuous
                ws.set_Run( ws.run_cont, channel_list );

            case 'bipolar'

                % define arrays with the anodes and cathodes
                anode_list      = [ bmi_fes_params.anode_map{1,:} ];
                cathode_list    = [ bmi_fes_params.cathode_map{1,:} ];
                
                % the zigbee command has to include all 16 channels
                % here we add all the channels (even those we are not
                % stimulating) and set up their stimulation amplitudes
                amp_cmd         = zeros(1,length(chs_cmd));
                amp_cmd(anode_list)     = amp;
                amp_cmd(cathode_list)   = amp;
                
                % set amplitude -- done in a different command because of
                % limitations in command length (register write in zigbee)
                ws.set_AnodAmp( 32768-amp_cmd, chs_cmd );
                ws.set_CathAmp( 32768+amp_cmd, chs_cmd );
                
                % Set polarity for the anodes...
                % read what electodes are set as anodes
                for i = 1:numel(anode_list)
                    % Configure train delay differently for each channel
                    % -- Stagger by 500 us, to minimize current density at
                    % the return
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
                
                % set to run continuous
                ws.set_Run( ws.run_cont, anode_list );
                ws.set_Run( ws.run_cont, cathode_list );
        end
        
    % For amplitude-modulated FES
    case 'amplitude_modulation'

        error('amplitude-modulated FES not implemented yet');
end

