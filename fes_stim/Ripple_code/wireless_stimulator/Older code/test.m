function test(serial_string, sequence, dbg_lvl)
    if nargin < 3
        dbg_lvl = 0;
    end
    
    ws = wireless_stim(serial_string, dbg_lvl);
    
    % try/catch helps avoid left-open serial port handles and leaving
    % the Atmel wireless modules' firmware in a bad state
    try
        % comm_timeout specified in ms, or disable
        reset = 1;   % reset FPGA stim controller
        ws.init(reset, ws.comm_timeout_disable);
        %timeout_ms = ws.get_comm_timeout();
        
        ws.version();      % print version info, call after init
        %ws.set_enable(1);  % global enable/disable, also called in init
        %ws.set_action(0);  % 0 for curcyc, 1 for allcyc, also called in init
        %action = ws.get_action();        

        switch sequence
          case 0
            keyboard();
          case 1
            train_sequence1(ws, [1:ws.num_channels]);
          case 2
            train_sequence2(ws);
          case 3
            train_sequence3(ws);
          otherwise
            warning('no sequence selected');
        end
            
        if dbg_lvl ~= 0
            % retrieve & display settings from all channels
            channel_list = [1:ws.num_channels];
            commands = ws.get_stim(channel_list);
            ws.display_command_list(commands, channel_list);
        end
        
    catch ME
        delete(ws);
        %disp(ME);
        rethrow(ME);
    end

    delete(ws);
end

% example train sequence, setup specified channels to run continuously
% for 10s with charge balanced parameters
function train_sequence1(ws, channel_list)
    [ST, I] = dbstack();

    command{1} = struct('TL', 100, ...         % 100ms
                        'Freq', 30, ...        % 30 Hz
                        'CathAmp', 32768+300, ...  % 16-bit DAC setting
                        'AnodAmp', 32768-300, ...  % 16-bit DAC setting
                        'CathDur', 200, ...    % 200 us
                        'AnodDur', 200, ...    % 200 us
                        'PL', 1 ...           % Cathodic first
                        );
    ws.set_stim(command, channel_list);  % set the parameters
    
    disp(sprintf('%s:%s: starting continuous sequence', ...
                 ST(1).name, datestr(datetime(),'HH:mm:ss:FFF')));
    ws.set_Run(ws.run_cont, channel_list);
    pause(10);
    disp(sprintf('%s:%s: stopping continuous sequence', ...
                 ST(1).name, datestr(datetime(),'HH:mm:ss:FFF')));
    ws.set_Run(ws.run_stop, channel_list);
    
    % Alternative method:
    if 0
        % Use a single command struct to setup the durations for all
        % channels (broadcast) and start the train
        command{1} = struct('Run', ws.run_cont);
        ws.set_stim(command, channel_list);
        pause(5);
        command{1} = struct('Run', ws.run_stop);
        ws.set_stim(command, channel_list);
    end
end


% example train sequence, pw modulated, same params for all channels
function train_sequence2(ws)
    [ST, I] = dbstack();
    channel_list = 1:ws.num_channels;  % all channels
    channel_list_len = length(channel_list);

    % Setup a single element cell array of command structs to 
    % broadcast basic param settings to all channels
    disp(sprintf('%s:%s: setup params', ...
                 ST(1).name, datestr(datetime(),'HH:mm:ss:FFF')));
    amp_offset_10k_ohm = 1000;  % ~1mA
    amp_offset_100_ohm = 5000;  % ~5mA
    amp = amp_offset_100_ohm;   % adjust amplitude per load
    command{1} = struct('TL', 100, ...         % 100ms
                        'Freq', 30, ...        % 30 Hz
                        'CathAmp', 32768+amp, ...  % 16-bit DAC setting
                        'AnodAmp', 32768-amp, ...  % 16-bit DAC setting
                        'PL', 1, ...           % Cathodic first
                        'Run', ws.run_once ... % Single train mode
                        );
    ws.set_stim(command, channel_list);  % set the parameters
    
    % Configure train delay differently for each channel
    for c_idx = 1:channel_list_len
        td = c_idx * 200;   % stagger by 200 us
        ws.set_TD(td, [channel_list(c_idx)])
    end
    % Alternative way to set the train delays:
    %  Setup a cell array of command structs to configure train delay
    %  differently for each channel
    if 0
        for c_idx = 1:channel_list_len
            td = c_idx * 50;   % stagger by 50 us
            command{c_idx} = struct('TD', td);
        end
        ws.set_stim(command, channel_list);  % set the parameters
    end
    
    clear command;  % reset command cell array length
    for pw = 150:5:400  % 150us to 400us in 5us steps
        disp(sprintf('%s:%s: applying pw %d, starting train', ...
                     ST(1).name, datestr(datetime(),'HH:mm:ss:FFF'), pw));
        % Use a single element cell array of command structs to setup the
        % durations for all channels (broadcast) and start the train.
        %
        % This could be done with separate set_CathDur, set_AnodDur, and
        % set_Run calls as well.
        %
        % 'Run' should be the last parameter in the struct to ensure the pw
        % are applied before starting the train
        command{1} = struct('CathDur', pw, 'AnodDur', pw, 'Run', ws.run_once_go);
        ws.set_stim(command, channel_list);
        
        pause(0.5);  % wait 0.5s until next train
    end
    % restore nominal
    command{1} = struct('CathDur', 200, 'AnodDur', 200);
    ws.set_stim(command, channel_list);
end


% example train sequence, amplitude modulated, same params for all channels
function train_sequence3(ws)
    [ST, I] = dbstack();
    channel_list = 1:ws.num_channels;  % all channels
    channel_list_len = length(channel_list);

    % Setup a single element cell array of command structs to 
    % broadcast basic param settings to all channels
    disp(sprintf('%s:%s: setup params', ...
                 ST(1).name, datestr(datetime(),'HH:mm:ss:FFF')));
    command{1} = struct('TL', 100, ...         % 100ms
                        'Freq', 30, ...        % 30 Hz
                        'CathDur', 200, ...    % 200 us
                        'AnodDur', 200, ...    % 200 us
                        'PL', 1, ...           % Cathodic first
                        'Run', ws.run_once ... % Single train mode
                        );
    ws.set_stim(command, channel_list);  % set the parameters
    
    % Configure train delay differently for each channel
    for c_idx = 1:channel_list_len
        td = c_idx * 300;   % stagger by 300 us
        ws.set_TD(td, [channel_list(c_idx)])
    end

    clear command;  % reset command cell array length

    max_10k_ohm_load = 1700;  % ~1.7mA, max for 17v rail
    max_100_ohm_load = 32000; % ~32mA (very high)
    max = max_100_ohm_load;
    step = round((max-0)/50); % 50 steps
    for amp = 0:step:max
        disp(sprintf('%s:%s: applying amplitude offset %d, starting train', ...
                     ST(1).name, datestr(datetime(),'HH:mm:ss:FFF'), amp));

        command{1} = struct('CathAmp', 32768+amp, 'AnodAmp', 32768-amp, 'Run', ws.run_once_go);
        ws.set_stim(command, channel_list);
        
        pause(0.5);  % wait 0.5s until next train
    end
    % restore nominal
    command{1} = struct('CathAmp', 33100, 'AnodAmp', 32500);
    ws.set_stim(command, channel_list);
end
