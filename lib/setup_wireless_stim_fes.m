
function setup_wireless_stim_fes( ws )

channel_list        = 1:ws.num_channels;  % all channels
channel_list_len    = length(channel_list);

amp_offset_10k_ohm  = 1000;  % ~1mA
amp_offset_100_ohm  = 5000;  % ~5mA
amp                 = amp_offset_100_ohm;   % adjust amplitude per load


command{1}          = struct('TL', 100, ...         % 100ms
    'Freq', 30, ...        % 30 Hz
    'CathAmp', 32768+amp, ...  % 16-bit DAC setting
    'AnodAmp', 32768-amp, ...  % 16-bit DAC setting
    'PL', 1, ...           % Cathodic first
    'Run', ws.run_once ... % Single train mode
    );
ws.set_stim(command, channel_list);  % set the parameters


 % Configure train delay differently for each channel
 for c_idx = 1:channel_list_len
     td             = c_idx * 500 + 50;   % stagger by 500 us. Minimum 50 us
     ws.set_TD(td, channel_list(c_idx))
 end