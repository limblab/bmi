%
% ripple, 2016
% Brian Crofts
%
% test
%  wireless_stim.m class test function launcher
%
% sequence - test function selector (see case statement below)
% wireless_stim_params - param struct (see member descriptions below)
% varargin - use for optional parameter passing to test functions
%
function ret = test(sequence, ws_param, varargin)
    if (nargin < 2)
        % wireless_stim param struct
        % serial_string - "/dev/ttyUSB0" e.g. on linux or "COM4" on Windows
        % dbg_lvl
        %   1 = no trace, use for returning time meas
        %   2 = function level trace
        %   3 = register level trace
        %   4 = message (wireless packet) level trace
        % comm_timeout_ms - -1 to disable, 0 to 65534 ms
        % blocking - true for synchronous message passing, false for lower
        %            latency async message passing
        % zb_ch_page - 0,2,5,16,17,18,19 are valid values:
        %  0: 20kbps ch0 868.3MHz, 40kbps ch1-10 902-928MHz, BPSK
        %  2: 100kbps ch0 868.3MHz, 250kbps ch1-10 902-928MHz, O-QPSK
        %  5: 250kbps 779-787MHz O-QPSK
        %  16: 200kbps ch0 868.3MHz, 500kbps ch1-10 902-928MHz, O-QPSK
        %  17: 400kbps ch0 868.3MHz, 1Mbps ch1-10 902-928MHz, O-QPSK
        %  18: 500kbps 779-787MHz O-QPSK
        %  19: 1Mbps 779-787MHz O-QPSK

        % cut and paste this line to the Matlab shell to use as an example input param set
        ws_param = struct('serial_string','/dev/ttyUSB0','dbg_lvl',0,'blocking',true,'zb_ch_page',17,'comm_timeout_ms',-1);
    end
    if nargin < 1
        sequence = -1;
    end
    ret = 0;
        
    ws = wireless_stim(ws_param);
    cleanup_func = onCleanup(@() test_cleanup(ws));
    dbg_lvl = ws.get_dbg_lvl();
    
    ws.init();
    %timeout_ms = ws.get_comm_timeout();
        
    ws.version();      % print version info, call after init
    %ws.set_enable(1);  % global enable/disable, also called in init
    %ws.set_action(0);  % 0 for curcyc, 1 for allcyc, also called in init
    %action = ws.get_action();        

    ws.check_battery();
    
    switch sequence
      case 0
        keyboard();
      case 1
        ret = train_sequence1(ws, [1:ws.num_channels], varargin);
      case 2
        ret = train_sequence2(ws, varargin);
      case 3
        ret = train_sequence3(ws, varargin);
      case 4
        ret = time_meas(ws, ws_param.dbg_lvl, varargin);
      otherwise
        warning('no sequence selected');
    end
    ws.check_battery();
    
    if dbg_lvl >= 2 && dbg_lvl <= 3
        % retrieve & display settings from all channels
        channel_list = [1:ws.num_channels];
        commands = ws.get_stim(channel_list);
        ws.display_command_list(commands, channel_list);
    end
    
    errs = ws.get_errs();
    disp(sprintf('completed with %d communication errors', length(errs)));
    ret = [ret, errs]; % append errs to return array
    % delete(ws) handled by onCleanup func
end

% helps avoid left-open serial port handles and leaving
% the Atmel wireless modules' firmware in a bad state
function test_cleanup(obj)
    delete(obj);
    disp(datestr(datetime(),'HH:MM:ss:FFF exiting...'));    
end


% example train sequence, setup specified channels to run continuously
% for delay seconds with charge balanced parameters
function ret = train_sequence1(ws, channel_list, varargin)
    [ST, I] = dbstack();

    amp_offset_10k_ohm = 100;   % 100uA, 1V into 10k ohms
    amp_offset_100_ohm = 10000; % 10mA, 1V into 100 ohms
    
    if ws.get_device_id() == 1          % micro stim
        amp = amp_offset_10k_ohm;
    elseif ws.get_device_id() == 0      % macro stim
        amp = amp_offset_100_ohm;
    end
    
    if isempty(cell2mat(varargin{1}))
        delay_in_minutes = 5;
    else
        delay_in_minutes = cell2mat(varargin{1});
    end

    % Setup a single element struct array to configure param settings
    command{1} = struct('TL', 100, ...         % 100ms
                        'Freq', 30, ...        % 30 Hz
                        'CathAmp', 32768+amp, ...  % 16-bit DAC setting
                        'AnodAmp', 32768-amp, ...  % 16-bit DAC setting
                        'CathDur', 200, ...    % 200 us
                        'AnodDur', 200, ...    % 200 us
                        'PL', 1 ...           % Cathodic first
                        );
    ws.set_stim(command, channel_list);  % set the parameters
    
    disp(sprintf('%s:%s: starting continuous sequence', ...
                 ST(1).name, datestr(datetime(),'HH:MM:ss:FFF')));
    ws.set_Run(ws.run_cont, channel_list);
    %ws.idle(1);  % for idle power testing

    for idx = 1:delay_in_minutes
        ws.check_battery();
        pause(60);

        % check in every 15 minutes
        if mod(idx,15) == 0
            disp(sprintf('%s:%s: continuing sequence', ...
                         ST(1).name, datestr(datetime(),'HH:MM:ss:FFF')));
            % perform regular communication to make sure stimulator is
            % still there and operating
            ws.get_Run(channel_list);
        end
    end

    disp(sprintf('%s:%s: stopping continuous sequence', ...
                 ST(1).name, datestr(datetime(),'HH:MM:ss:FFF')));
    ws.idle(0);
    ws.set_Run(ws.run_stop, channel_list);
    
    ret = 0;
end


% example train sequence, pw modulated, same params for all channels
function ret = train_sequence2(ws, varargin)
    [ST, I] = dbstack();
    channel_list = 1:ws.num_channels;  % all channels
    channel_list_len = length(channel_list);

    disp(sprintf('%s:%s: setup params', ...
                 ST(1).name, datestr(datetime(),'HH:MM:ss:FFF')));
    amp_offset_10k_ohm = 100;   %  100uA, 1V into 10k ohms
    amp_offset_100_ohm = 5000;  %  5mA, 0.5V into 100 ohms
    
    if ws.get_device_id() == 1          % micro stim
        amp = amp_offset_10k_ohm;
    elseif ws.get_device_id() == 0      % macro stim
        amp = amp_offset_100_ohm;
    end
    
    % Configure train delay differently for each channel
    stagger = 100;  % us
    td = [stagger:stagger:stagger*channel_list_len];
    
    % Setup a single element struct array to configure param settings
    command{1} = struct('TL', 100, ...         % 100ms
                        'Freq', 30, ...        % 30 Hz
                        'CathAmp', 32768+amp, ...  % 16-bit DAC setting
                        'AnodAmp', 32768-amp, ...  % 16-bit DAC setting
                        'TD', td, ...           % train delay per channel
                        'PL', 1, ...           % Cathodic first
                        'Run', ws.run_once ... % Single train mode
                        );
    ws.set_stim(command, channel_list);  % set the parameters

    % Alternative way to set the train delays:
    if 0
        ws.set_TD(td, channel_list);
    end
    
    if isempty(cell2mat(varargin{1}))
        loops = 1;
    else
        loops = cell2mat(varargin{1});
    end

    % 150us to 400us in 5us steps
    pw_min = 200;
    pw_step_size = 5;
    pw_num_steps = 50;
    pw_max = pw_min + pw_step_size*pw_num_steps;
    
    for loop = 1:loops
        ws.check_battery();

        for pw_offset = pw_min:pw_step_size:pw_max
            % varying pw per channel
            pw = pw_offset + [-50:10:(channel_list_len-1)*10-50];
            
            disp(sprintf('%s:%s: applying pulse widths %s starting train', ...
                         ST(1).name, datestr(datetime(),'HH:MM:ss:FFF'), ...
                         sprintf('%d ', pw)));
            
            % Use a single element cell array of command structs to setup the
            % durations for all channels and start the train.
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
    end
    % restore nominal
    command{1} = struct('CathDur', 200, 'AnodDur', 200);
    ws.set_stim(command, channel_list);
    
    ret = 0;
end


% example train sequence, amplitude modulated, same params for all channels
function ret = train_sequence3(ws, varargin)
    [ST, I] = dbstack();
    channel_list = 1:ws.num_channels;  % all channels
    channel_list_len = length(channel_list);

    disp(sprintf('%s:%s: setup params', ...
                 ST(1).name, datestr(datetime(),'HH:MM:ss:FFF')));
    
    % Configure train delay differently for each channel
    stagger = 150;  % us
    td = [stagger:stagger:stagger*channel_list_len];
    
    % Setup a single element struct array to configure param settings
    command{1} = struct('TL', 100, ...         % 100ms
                        'Freq', 30, ...        % 30 Hz
                        'CathDur', 200, ...    % 200 us
                        'AnodDur', 200, ...    % 200 us
                        'TD', td, ...           % train delay per channel
                        'PL', 1, ...           % Cathodic first
                        'Run', ws.run_once ... % Single train mode
                        );
    ws.set_stim(command, channel_list);  % set the parameters
    
    % set limits very high
    max_10k_ohm_load = 400;  % 400uA, 4V into 10k ohms
    max_100_ohm_load = 32000; % 32mA, 3.2V into 100 ohms
    
    if ws.get_device_id() == 1         % micro stim
        max = max_10k_ohm_load;
    elseif ws.get_device_id() == 0     % macro stim
        max = max_100_ohm_load;
    end    
    
    step = round((max-0)/50); % 50 steps
    
    if isempty(cell2mat(varargin{1}))
        loops = 1;
    else
        loops = cell2mat(varargin{1});
    end

    for loop = 1:loops
        ws.check_battery();

        for amp_offset = 0:step:max
            % varying amplitude per channel, within a step range
            amp = amp_offset + [0:step/channel_list_len:step-(step/channel_list_len)];
            
            disp(sprintf('%s:%s: applying amplitude offsets %s starting train', ...
                         ST(1).name, datestr(datetime(),'HH:MM:ss:FFF'), ...
                         sprintf('%d ', amp)));
            
            command{1} = struct('CathAmp', 32768+amp, 'AnodAmp', 32768-amp, 'Run', ws.run_once_go);
            ws.set_stim(command, channel_list);
            
            pause(0.5);  % wait 0.5s until next train
        end
    end
    % restore nominal
    command{1} = struct('CathAmp', 32768+300, 'AnodAmp', 32768-300);
    ws.set_stim(command, channel_list);
    
    ret = 0;
end


% example train sequence for latency measurements
function ret = time_meas(ws, dbg_lvl, varargin)
    [ST, I] = dbstack();
    channel_list = 1:ws.num_channels;  % all channels
    channel_list_len = length(channel_list);

    %if dbg_lvl == 0
    %    disp(sprintf('%s:%s: dbg_lvl=%d must be 1 or greater. Returning...', ...
    %                 ST(1).name, datestr(datetime(),'HH:MM:ss:FFF'), dbg_lvl));
    %    return;
    %end
    
    disp(sprintf('%s:%s: setup params', ...
                 ST(1).name, datestr(datetime(),'HH:MM:ss:FFF')));
    amp_offset_10k_ohm = 100;   % 100uA, 1V into 10k ohms
    amp_offset_100_ohm = 5000;  % 5mA, 0.5V into 100 ohms

    if ws.get_device_id() == 1          % micro stim
        amp = amp_offset_10k_ohm;
    elseif ws.get_device_id() == 0      % macro stim
        amp = amp_offset_100_ohm;
    end    
    
    % Configure train delay differently for each channel
    stagger = 100;  % us
    td = [stagger:stagger:stagger*channel_list_len];
    
    % Setup a single element struct array to configure param settings
    command{1} = struct('TL', 100, ...         % 100ms
                        'Freq', 30, ...        % 30 Hz
                        'CathAmp', 32768+amp, ...  % 16-bit DAC setting
                        'AnodAmp', 32768-amp, ...  % 16-bit DAC setting
                        'TD', td, ...           % train delay per channel
                        'PL', 1, ...           % Cathodic first
                        'Run', ws.run_once ... % Single train mode
                        );
    ws.set_stim(command, channel_list);  % set the parameters

    % for testing reduced channel count updates
    channel_list = 1:ws.num_channels;  % all channels
    channel_list_len = length(channel_list);
        
    if isempty(cell2mat(varargin{1}))
        num_iter = 100;
    else
        num_iter = cell2mat(varargin{1});
    end
    
    % varying pw per channel
    pw = 200 + [-50:10:(channel_list_len-1)*10-50];
    disp(sprintf('%s:%s: applying pulse widths %s for %d iterations', ...
                 ST(1).name, datestr(datetime(),'HH:MM:ss:FFF'), ...
                 sprintf('%d ', pw), num_iter));
    % Use a single element cell array of command structs to setup the
    % durations for all channels and start the train.
    %
    % 'Run' should be the last parameter in the struct to ensure the pw
    % are applied before starting the train
    command{1} = struct('CathDur', pw, 'AnodDur', pw, 'Run', ws.run_once_go);
    
    % clear lantency measurement arrays
    ws.time_meas_host = [];
    ws.time_meas_usb = [];
    
    for idx = 1:num_iter
        ws.set_stim(command, channel_list);
        %pause(0.025);
    end
    
    ret{1} = ws.time_meas_host;
    ret{2} = ws.time_meas_usb;
    
    ret_avg = [];
    for item = 1:length(ret)
        if ret{item}
            histogram(cell2mat(ret(item)));
            ret_avg = [ret_avg mean(ret{item})];
        end
        hold on;
    end
    hold off;
    disp(['latency histogram means: ', sprintf('%d ', ret_avg)]);
end
