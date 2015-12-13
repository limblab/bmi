
function setup_wireless_stim_fes( ws, bmi_fes_params )

channel_list            = 1:ws.num_channels;  % all channels
channel_list_len        = length(channel_list);

amp_offset_10k_ohm      = 1000;  % ~1mA
amp_offset_100_ohm      = 5000;  % ~5mA
amp                     = amp_offset_100_ohm;   % adjust amplitude per load


switch bmi_fes_params.return
    case 'monopolar'

        command{1}      = struct('TL', 100, ...        % 100ms
                                'Freq', 30, ...        % 30 Hz
                                'CathAmp', 32768+amp, ...  % 16-bit DAC setting
                                'AnodAmp', 32768-amp, ...  % 16-bit DAC setting
                                'PL', 1, ...           % Cathodic first
                                'Run', ws.run_once ... % Single train mode
                                );
        ws.set_stim(command, channel_list);  % set the parameters

        % Configure train delay differently for each channel
        for ch = 1:channel_list_len
            td          = ( ch - 1 ) * 500 + 50;   % stagger by 500 us. Minimum 50 us to avoid problems with the waveforms
            ws.set_TD( td, channel_list(ch) );
        end
         
    case 'bipolar'
        
        command{1}      = struct('TL', 100, ...        % 100ms
                                'Freq', 30, ...        % 30 Hz
                                'CathAmp', 32768+amp, ...  % 16-bit DAC setting
                                'AnodAmp', 32768-amp, ...  % 16-bit DAC setting
                                'Run', ws.run_once ... % Single train mode
                                );
        ws.set_stim(command, channel_list);  % set the parameters

        % For the anodes...
        % read what electodes are set as anodes
        anode_list      = [ bmi_fes_params.anode_map{1,:} ];
        for i = 1:numel([ bmi_fes_params.anode_map{1,:} ])
            % Configure train delay differently for each channel
            % -- Stagger by 500 us, to minimize fatigue
            td          = (i-1) * 500 + 50;   % Minimum TD = 50 us, to avoid problems with the waveforms
            ws.set_TD( td, anode_list(i) );
            % Set polarity to anodic first 
            ws.set_PL( 0, anode_list(i) );
        end
        
        % For the cathodes...
        % read what electodes are set as cathodes
        cathode_list    = [ bmi_fes_params.cathode_map{1,:} ];
        for i = 1:numel([ bmi_fes_params.cathode_map{1,:} ])
            % Configure train delay differently for each channel
            % -- Stagger by 500 us, to minimize fatigue
            td          = (i-1) * 500 + 50;   % Minimum TD = 50 us, to avoid problems with the waveforms
            ws.set_TD( td, cathode_list(i) );
            % Set polarity to anodic first 
            ws.set_PL( 1, cathode_list(i) );
        end
end