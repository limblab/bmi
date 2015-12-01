classdef wireless_stim < handle
    properties (Constant, Access = public)
        num_channels = 8;
        comm_timeout_disable = -1;
        
        % enums for set_Run/get_Run
        run_stop = 0;
        run_once = 1;
        run_cont = 2;
        run_once_go = 3;
    end        
    properties (Access = public)
        trim_cal;
    end
    methods (Access = public)
        % Contstructor
        %
        % serial_port_str - serial port name, e.g. "COM4"
        function obj = wireless_stim(serial_port_str, dbg_lvl)
            if  nargin > 0
                obj.dbg_lvl = dbg_lvl;
                if obj.dbg_lvl >= 1
                    disp('wireless_stim:constructor');
                end
                obj.serial = serial(serial_port_str);
                set(obj.serial, 'BaudRate', 115200);
                obj.serial.InputBufferSize = 2000;
                obj.serial.Timeout = 0.1; % in seconds
                
                try
                    if obj.dbg_lvl >= 1
                        disp([' opening serial port: ', obj.serial.Port]);
                    end
                    fopen(obj.serial);
                catch ME
                    warning('Failed to open serial port.\nME id=\"%s\"\nME msg=\"%s\"\nTrying again after 100ms.\n', ...
                            ME.identifier, ME.message);
                    pause(0.1);
                    fopen(obj.serial);
                end
                obj.trim_cal = obj.reg_trim_uamp.def.*ones(1, obj.num_channels);
            end
        end
        
        % Destructor
        function delete(obj)
            if obj.dbg_lvl >= 1
                disp('wireless_stim:delete');
            end
            
            % if we're deleting due to a serial port failure the disconnect
            % request will fail, so catch and close anyway
            try
                % turn off all of the analog switches
                obj.set_switch(0, 0, 0, [1:obj.num_channels]);
                % turn off the 5V supply
                obj.set_5V(0);
                % global stim disable
                obj.set_enable(0);

                rsp = obj.send_message(obj.peer_disconnect_req, [0]);
                if obj.dbg_lvl >= 2
                    disp([' peer_disconnect_req rsp:', sprintf(' %02x', rsp)]);
                end
            catch ME
                warning('ME id=\"%s\"\nME msg=\"%s\"\n', ME.identifier, ME.message);
                if isvalid(obj.serial)
                    warning('closing serial port: %s', obj.serial.Port);
                    fclose(obj.serial);
                else
                    warning('invalid serial port %s, could not close', obj.serial.Port);
                end
                return
            end
            if obj.dbg_lvl >= 1
                disp([' closing serial port: ', obj.serial.Port]);
            end
            if isvalid(obj.serial)
                fclose(obj.serial);
            else
                warning('invalid serial port %s, could not close', obj.serial.Port);
            end
        end
        
        
        % Initialize a wireless_stim object
        %
        % reset - toggle the controller's global reset which resets all
        %         register values
        % comm_timeout_ms - communication timeout in ms. -1 disables
        function init(obj, reset, comm_timeout_ms)
            if obj.dbg_lvl >= 1
                tic;  % for time measurements
                disp('wireless_stim:init');
            end
                        
            rsp = obj.send_message(obj.identify_board_req, [0]);
            fields = obj.parse_identify_message(rsp);
            obj.atmel_local_version = fields.ver;

            if obj.dbg_lvl >= 2
                disp([' identify_board_req rsp:', sprintf(' %02x', rsp)]);
            end
            if obj.dbg_lvl >= 1
                disp(sprintf(' identify_board_req:\n  soc: %s, trx: %s, brd: %s', ...
                             fields.soc, fields.trx, fields.brd));
                disp(['   mac:', sprintf(' %02x', fields.mac), ...
                      sprintf(', features 0x%08x', fields.feat)]);
            end

            rsp = obj.send_message(obj.peer_disconnect_req, [0]);
            if obj.dbg_lvl >= 2
                disp([' peer_disconnect_req rsp:', sprintf(' %02x', rsp)]);
            end
            rsp = obj.send_message(obj.perf_start_req, [1]);
            if obj.dbg_lvl >= 2
                disp([' perf_start_req rsp:', sprintf(' %02x', rsp)]);
            end

            rsp = obj.send_message(obj.identify_board_remote_req, [0]);
            fields = obj.parse_identify_message(rsp);
            obj.atmel_remote_version = fields.ver;
            if obj.dbg_lvl >= 2
                disp([' identify_board_remote_req rsp:', sprintf(' %02x', rsp)]);
            end
            if obj.dbg_lvl >= 1
                disp(sprintf(' identify_board_remote_req:\n  soc: %s, trx: %s, brd: %s', ...
                             fields.soc, fields.trx, fields.brd));
                disp(['   mac:', sprintf(' %02x', fields.mac), ...
                      sprintf(', features 0x%08x', fields.feat)]);
            end

            if obj.dbg_lvl >= 2
                obj.perf_display_params(false);
                obj.perf_display_params(true);
            end
            % set to channel 2 running at 1000kb/s
            obj.perf_set_param(false, 0, 2); % channel, local only!
            obj.perf_set_param(false, 1, 17); % channel_page, local only!
            if obj.dbg_lvl >= 1
                obj.perf_display_params(false);
                obj.perf_display_params(true);
            end
            
            if reset
                warning('resetting stim, all registers will be loaded with defaults');
                obj.reg_write(obj.reg_g_global_reset.addr, 1);
            end
            
            obj.set_comm_timeout(comm_timeout_ms);
            
            % enable 5V supply only after 18V is detected
            obj.set_5V(1);
            
            % testbus, exhaust, electrode
            % enable exhaust for capacitively-coupled outputs to bleed off DC build-up
            % through 100k resistors to GND-tied VBIAS.
            obj.set_switch(0, 1, 1, [1:obj.num_channels]);

            obj.set_enable(1);  % global enable/disable
            obj.set_action(0);  % 0 for curcyc, 1 for allcyc

            % load trim calibration file if it exists
            try
                m = matfile(obj.trim_cal_fname);
                
                if ~isequal(m.channel_list, [1:obj.num_channels])
                    warning('Trim calibration data is incomplete. Please run trim_calibrate on all channels')
                end

                % this is equivalent to non-indexed assignment if m.channel_list == [1:obj.num_channels]
                channel_list = m.channel_list;
                obj.trim_cal(channel_list) = m.trim_cal;
                for ch_idx = 1:length(channel_list)
                    ch = channel_list(ch_idx);
                    obj.set_TrimAmp(obj.trim_cal(ch), ch);
                end
            catch ME
                warning('ME id=\"%s\"\nME msg=\"%s\"\n', ME.identifier, ME.message);

                prompt = 'Trim calibration data not found. Would you like to run trim_calibrate? y/n [y]';
                answer = input(prompt, 's');
                if isempty(answer)
                    answer = 'Y';
                end
                if upper(answer) == 'Y'
                    obj.trim_calibrate([1:obj.num_channels]);
                end
            end
        end
        
        % display version information
        function version(obj)
            [ST, I] = dbstack();
            disp(sprintf('%s version: %.2f', ST(1).file, obj.VERSION));
            
            disp(sprintf('Atmel ZigBit local version: %.2f', obj.atmel_local_version));
            disp(sprintf('Atmel ZigBit remote version: %.2f', obj.atmel_remote_version));
            
            fpga_version = obj.reg_read(obj.reg_g_version.addr);
            fpga_major = bitshift(fpga_version, -8);
            fpga_minor = bitand(fpga_version, hex2dec('0ff'));
            disp(sprintf('FPGA controller version: %02x.%02x', fpga_major, fpga_minor));
        end
        

        % Inividual stim parameter set/get functions
        %
        % value list, e.g. train_ms, or freq_hz - 
        %                Passed to set as a list of parameter values
        %                to set, one list item per channel. If the list has
        %                a single item, that item is written to all 
        %                channels in the channel list.
        %
        %                Returned from get as a list of parameter values
        %                read, one list item per channel.
        %
        % channel_list - 1-based vector of electrode channel indices
        %                set to 1:num_channels for broadcast
        %
        % commit       - for command batch queuing. Set to false
        %                to queue up commands for a single transaction
        %                then true on the last parameter set.
        %                supported for set only; defaults to true

        function set_TL(obj, train_ms, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            obj.set_param(train_ms, channel_list, obj.reg_train_ms, commit);
        end
        function train_ms = get_TL(obj, channel_list)
            train_ms = obj.get_param(channel_list, obj.reg_train_ms);
        end
        
        function set_Freq(obj, freq_hz, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            min_freq_hz = 1e6/obj.reg_period_us.max;
            if (freq_hz < min_freq_hz || freq_hz > 1e6)
                error('invalid frequency %f. min=%f max=1e6', freq_hz, min_freq_hz, freq_hz);
            end
            period_us = round(1e6/freq_hz);
            obj.set_param(period_us, channel_list, obj.reg_period_us, commit);
        end
        function freq_hz = get_Freq(obj, channel_list)
            period_us = obj.get_param(channel_list, obj.reg_period_us);
            freq_hz = 1e6./period_us;
        end
        
        function set_CathDur(obj, cathode_us, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            obj.set_param(cathode_us, channel_list, obj.reg_cathode_us, commit);
        end
        function cathode_us = get_CathDur(obj, channel_list)
            cathode_us = obj.get_param(channel_list, obj.reg_cathode_us);
        end
        function set_AnodDur(obj, anode_us, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            obj.set_param(anode_us, channel_list, obj.reg_anode_us, commit);
        end
        function anode_us = get_AnodDur(obj, channel_list)
            anode_us = obj.get_param(channel_list, obj.reg_anode_us);
        end

        function set_CathAmp(obj, cathode_uamp, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            obj.set_param(cathode_uamp, channel_list, obj.reg_cathode_uamp, commit);
        end
        function cathode_uamp = get_CathAmp(obj, channel_list)
            cathode_uamp = obj.get_param(channel_list, obj.reg_cathode_uamp);
        end
        function set_AnodAmp(obj, anode_uamp, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            obj.set_param(anode_uamp, channel_list, obj.reg_anode_uamp, commit);
        end
        function anode_uamp = get_AnodAmp(obj, channel_list)
            anode_uamp = obj.get_param(channel_list, obj.reg_anode_uamp);
        end
        
        function set_TD(obj, delay_us, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            obj.set_param(delay_us, channel_list, obj.reg_delay_us, commit);
        end
        function delay_us = get_TD(obj, channel_list)
            delay_us = obj.get_param(channel_list, obj.reg_delay_us);
        end

        function set_PL(obj, polarity, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            switch polarity
              case 0
                anode_first_en = 1;
              case 1
                anode_first_en = 0;
              otherwise
                error('invalid polarity %d. Polarity must be 0 or 1', polarity)
            end
            obj.set_param(anode_first_en, channel_list, obj.reg_anode_first_en, commit);
        end
        function polarity = get_PL(obj, channel_list)
            anode_first_en = obj.get_param(channel_list, obj.reg_anode_first_en);
            polarity = ~anode_first_en;
        end
        
        function set_IPIDur(obj, ipi_us, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            obj.set_param(ipi_us, channel_list, obj.reg_ipi_us, commit);
        end
        function ipi_us = get_IPIDur(obj, channel_list)
            ipi_us = obj.get_param(channel_list, obj.reg_ipi_us);
        end
        
        % Set/get stimulation run state
        %
        % run_state - obj.run_cont for continuous train mode and enable
        %             obj.run_once for single train mode
        %             obj.run_stop to stop all stim
        %             obj.run_once_go to start a single train when in 
        %              single train mode
        %             run_cont overrides run_once if both are set
        % channel_list - 1-based vector of electrode channel indices
        %                set to 1:num_channels for broadcast
        function set_Run(obj, run_state, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            switch run_state
              case obj.run_stop
                obj.set_param(0, channel_list, obj.reg_stim_en, false);
                obj.set_param(0, channel_list, obj.reg_single_mode_en, commit);
              case obj.run_once
                obj.set_param(0, channel_list, obj.reg_stim_en, false);
                obj.set_param(1, channel_list, obj.reg_single_mode_en, commit);
                % trigger a single shot train for run-once enbled channels
              case obj.run_once_go
                obj.set_param(1, [1:obj.num_channels], obj.reg_single_mode_go, commit);
              case obj.run_cont
                obj.set_param(0, channel_list, obj.reg_single_mode_en, false);
                obj.set_param(1, channel_list, obj.reg_stim_en, commit);
              otherwise
                error('invalid run_state setting %d', run_state)
            end
        end
        function run_state = get_Run(obj, channel_list)
            run_cont = obj.get_param(channel_list, obj.reg_stim_en);
            run_once = obj.get_param(channel_list, obj.reg_single_mode_en);
            
            channel_list_len = length(channel_list);
            for c_idx = 1:channel_list_len
                % continuous run overrides single shot trains
                if run_cont(c_idx)
                    run_state(c_idx) = obj.run_cont;
                elseif run_once(c_idx)
                    run_state(c_idx) = obj.run_once;
                else
                    run_state(c_idx) = obj.run_stop;
                end
            end
        end

        function set_TrimAmp(obj, trim_uamp, channel_list, commit)
            if nargin < 4
                commit = true;
            end
            obj.set_param(trim_uamp, channel_list, obj.reg_trim_uamp, commit);
        end
        function trim_uamp = get_TrimAmp(obj, channel_list)
            trim_uamp = obj.get_param(channel_list, obj.reg_trim_uamp);
        end
        
        function trim_cal = trim_calibrate(obj, channel_list)
            failure = 0;
            
            % disconnect the output electrode to avoid interactions with the 
            % output cap and load
            obj.set_switch(0, 1, 0, channel_list);    % testbus, exhaust, electrode
            %obj.reg_write(obj.reg_g_testbus_sel.addr, 1);  % select TESTSW1 on testbus
            
            % initialize cathode and anode amp to mid scale as well because
            % a train must be triggered to have new trim settings take effect,
            % and we want to avoid sampling a pulse
            obj.set_CathAmp(32768, channel_list, false);
            obj.set_AnodAmp(32768, channel_list, false);

            % initialize trim amp from any existing cal data
            trim_cal = obj.trim_cal;
            obj.set_TrimAmp(trim_cal, channel_list, false);
            
            channel_list_length = length(channel_list);

            % trigger a single pulse
            obj.set_Run(obj.run_once, channel_list, false);
            obj.set_Run(obj.run_once_go, channel_list, true);  % commit settings
            
            failsafe_thresh = 250;
            
            % keep a high threshold on the first pass to avoid swinging to the 
            % opposite rail with a larger adjustment value
            num_passes = 3;
            p_thresh = [15000, 300, 80];
            p_avg = [3, 7, 15];
            p_adj = [100, 9, 3];

                
            for ch_idx = 1:channel_list_length
                for p_idx = 1:num_passes
                    cal_failsafe = zeros(1, channel_list_length);
                    ch = channel_list(ch_idx);
                    %obj.set_switch(1, 0, 0, [ch]);    % connect testbus to ch
                    %[tb, ex, elec] = obj.get_switch([1:8])
                    [config, adc] = obj.get_adc([ch], 16); % lots of averages on the first read
                    
                    str = sprintf('pass %d, iter %d, ch %d, adc %d, trim %d', ...
                                  p_idx, cal_failsafe(ch_idx), channel_list(ch_idx), ...
                                  int16(adc), trim_cal(ch));
                    disp(str);
                    
                    while abs(adc) > p_thresh(p_idx) && cal_failsafe(ch_idx) < failsafe_thresh
                        trim_cal(ch) = trim_cal(ch) + ...
                            p_adj(p_idx)*(adc < p_thresh(p_idx)) - p_adj(p_idx)*(adc > p_thresh(p_idx));
                        obj.set_TrimAmp(trim_cal(ch), [ch], false);
                        obj.set_Run(obj.run_once_go, [ch], true);
                        [config, adc] = obj.get_adc([ch], p_avg(p_idx));
                        cal_failsafe(ch_idx) = cal_failsafe(ch_idx) + 1;

                        num_backsp = length(str);
                        str = sprintf('pass %d, iter %d, ch %d, adc %d, trim %d', ...
                                      p_idx, cal_failsafe(ch_idx), channel_list(ch_idx), ...
                                      int16(adc), trim_cal(ch));
                        disp(str);
                    end
                    %obj.set_switch(0, 0, 0, [ch]);    % disconnect testbus from ch
                
                    if ~isempty(find(cal_failsafe == failsafe_thresh))
                        warning('pass %d trim cal did not converge for channel %d', p_idx, ch);                        
                        % revert to original values
                        trim_cal(ch) = obj.trim_cal(ch);
                        obj.set_TrimAmp(trim_cal(ch), ch, true);
                        break;
                    end
                end
            end

            % restore to defaults
            obj.set_switch(0, 1, 1, channel_list);  % testbus, exhaust, electrode
            obj.set_CathAmp(obj.reg_cathode_uamp.def, channel_list, false);
            obj.set_AnodAmp(obj.reg_anode_uamp.def, channel_list, false);
            obj.set_Run(obj.run_stop, channel_list, true);
            
            % always save the full channel list cal data, even if calibrating
            % on a subset of channels
            channel_list = [1:obj.num_channels];
            obj.trim_cal = trim_cal;
            save (obj.trim_cal_fname, 'channel_list', 'trim_cal');
            
            if obj.dbg_lvl >= 1
                disp(['trim_cal =', sprintf(' %d:%d', [channel_list; trim_cal])]);
            end
        end
        
        % get ADC config register value and conversion data
        %
        % Every 1ms a conversion is initiated on each channel's ADC.
        % The result and previous ADC config register value is 
        % stored in FPGA registers. This function returns those values.
        %
        % channel_list - 1-based vector of electrode channel indices
        % config - ADC configuration register value
        % data - result of 16 bit ADC conversion
        % 
        function [config, data] = get_adc(obj, channel_list, num_avg)
            if nargin == 2
                num_avg = 1;
            end
            config = obj.get_param(channel_list, obj.reg_adc_cfg);
            
            data = zeros(1,length(channel_list));
            for idx = 1:num_avg
                cur_data = obj.get_param(channel_list, obj.reg_adc_data);
                % adc data is 16 bit twos complement
                cur_data = double(typecast(uint16(cur_data), 'int16'));
                data = data + cur_data;
            end
            data = data ./ num_avg;
        end
        
        % Set/get switch state
        %
        % testbus - nonzero enables output on testbus; zero disables
        %           testbus is connected to one of 8 terminations
        % exhaust - nonzero enables output on exhaust; zero disables
        % electrode - nonzero enables output on electrode; zero disables
        % channel_list - 1-based vector of electrode channel indices
        %                set to 1:num_channels for broadcast
        function set_switch(obj, testbus, exhaust, electrode, channel_list)
            obj.set_param(testbus ~= 0, channel_list, obj.reg_sw_testbus, true);
            obj.set_param(exhaust ~= 0, channel_list, obj.reg_sw_exhaust, true);
            obj.set_param(electrode ~= 0, channel_list, obj.reg_sw_swout, true);
        end
        function [testbus, exhaust, electrode] = get_switch(obj, channel_list)
            testbus = obj.get_param(channel_list, obj.reg_sw_testbus);
            exhaust = obj.get_param(channel_list, obj.reg_sw_exhaust);
            electrode = obj.get_param(channel_list, obj.reg_sw_swout);
        end
        
        % set/get global connection for testbus-selected channels
        %
        % selection - 8 element array
        %             [ TESTSW8, TESTSW7, ... , TESTSW1 ]
        %             TESTSW1 - resistor to GND
        %             TESTSW2 - resistor to VREF (2.5V)
        %             TESTSW3 - resistor to -5V
        %             TESTSW4 - resistor to +5V
        %             TESTSW5 - 47uF capacitor to GND
        %             TESTSW6 - resistor to GND
        %             TESTSW7 - resistor to GND
        %             TESTSW8 - resistor to GND
        function set_testbus_sel(obj, selection)
            if length(selection) ~= 8
                error('selection array must be of size 8, %d length detected', length(selection));
            end
            sel_bit = find(selection);
            if length(sel_bit) > 1
                error('only a single testbus selection is possible, %d were specified', length(sel_bit));
            end
            val = 0;
            for idx = 1:8
                val = bitor(val, bitshift(selection(idx), 8-idx));
            end
            obj.reg_write(obj.reg_g_testbus_sel, val);
        end
        function selection = get_testbus_sel(obj)
            val = obj.reg_read(obj.reg_g_testbus_sel);            
            selection = str2num(reshape(dec2bin(val), [], 1))';
        end

        
        % Set stim parameters for the specified electrode channels
        %
        % commands     - single element struct array with stim params & values
        % channel_list - 1-based vector of electrode channel indices
        %                set to 1:num_channels for broadcast
        %
        function set_stim(obj, commands, channel_list)
            channel_list_len = length(channel_list);
            if length(commands) > 1
                error('commands struct array must have only 1 element');
            end
            
            command = commands{1};
            fields = fieldnames(command);
            num_fields = length(fields);
            
            if length(unique(fields)) ~= num_fields
                error('duplicate fields found in command list entry %d', c_idx);
            end

            for f_idx = 1:num_fields
                field = fields{f_idx};
                
                if isempty(find(strcmp(obj.command_fields, field)))
                    error('invalid field %s in command %d', field, c_idx);
                end
                
                val_list = command.(field);
                func = ['set_',field];
                
                if f_idx == num_fields
                    obj.(func)(val_list, channel_list, true);  % commit if last item
                else
                    obj.(func)(val_list, channel_list, false);
                end
            end
        end % set_stim
        
        % Retrieve stim parameters for the specified electrode channels
        %
        % channel_list - 1-based vector of electrode channel indices
        % command_list - cell array of command structures of the same length
        %                as channel_list
        function command_list = get_stim(obj, channel_list)
            channel_list_len = length(channel_list);
            
            for f_idx = 1:length(obj.command_fields)
                field = obj.command_fields{f_idx};
                func = ['get_',field];
                val_list = obj.(func)(channel_list);
                for ch_idx = 1:channel_list_len
                    command_list{ch_idx}.(field) = val_list(ch_idx);
                end
            end            
        end
        
        % Display a list of stim parameter command structures
        %
        % command_list - cell array of command structures
        % channel_list - 1-based vector of electrode channel indices
        %
        % command_list length and channel_list lengths must match
        function display_command_list(obj, command_list, channel_list)
            channel_list_len = length(channel_list);
            command_list_len = length(command_list);
            if command_list_len ~= channel_list_len
                error('number of parameter commands must match number of channels');
            end

            for c_idx = 1:command_list_len
                disp(sprintf('command %d : channel %d', c_idx, channel_list(c_idx)));
                command = command_list{c_idx};
                fields = fieldnames(command);
                
                c_list = arrayfun(@(idx) sprintf(' %s=%d(%x)',fields{idx},command.(fields{idx}),command.(fields{idx})), ...
                                  1:length(fields), 'Unif', false);
                s_list = regexprep(reshape(char(c_list)',1,[]), '\s+', ' ');
                disp(s_list);
            end
        end
        
        % Set/get communication timeout value in ms
        % 
        % timeout_ms - timeout. -1 indicates timeout is disabled
        %              Default is 10,000ms
        function set_comm_timeout(obj, timeout_ms)
            if timeout_ms == -1
                obj.reg_write(obj.reg_g_comm_timeout_ms.addr, obj.reg_g_comm_timeout_ms.max);
                return
            end
            
            if timeout_ms > (obj.reg_g_comm_timeout_ms.max-1) || timeout_ms < 0
                error('invalid comm timeout value %d', timeout_ms);
            end
            obj.reg_write(obj.reg_g_comm_timeout_ms.addr, timeout_ms);
        end
        function timeout_ms = get_comm_timeout(obj)
            timeout_ms = obj.reg_read(obj.reg_g_comm_timeout_ms.addr);
            if timeout_ms == obj.reg_g_comm_timeout_ms.max
                timeout_ms = -1;
            end
        end
        
        % Set/get the update action
        %
        % action - 0 for curcyc, update at the end of the current pulse
        %          1 for allcyc, update at the end of the current train of pulses
        function set_action(obj, action)
            if action ~= 0 && action ~= 1
                error('invalid action %d, must be 0 (curcyc) or 1 (allcyc)', action)
            end
            obj.reg_write(obj.reg_g_action.addr, action)
        end
        function action = get_action(obj)
            action = obj.reg_read(obj.reg_g_action.addr);
        end

        % Set/get global stimulation enable
        %
        % enable - 0 to disable, 1 to enable
        function set_enable(obj, enable)
            obj.reg_write(obj.reg_g_stim_en.addr, enable ~= 0);
        end
        function enable = get_enable(obj)
            enable = obj.reg_read(obj.reg_g_stim_en.addr);
        end
        
        
        
    end  % methods (Access = public)

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant, Access = private)
        VERSION = 0.07;
        
        identify_board_req = 0;
        identify_board_remote_req = 0 + 128;
        perf_start_req = 1;
        perf_set_req = 2;
        perf_set_remote_req = 2 + 128;
        perf_get_req = 3;
        perf_get_remote_req = 3 + 128;
        peer_disconnect_req = 13; % 0xd
        spi_write_req = 64 + 128; % 0x40 | 0x80 to indicate remote request
        spi_read_req = 96 + 128; % 0x60 | 0x80 to indicate remote request

        spi_write_confirm = 64 + 1; % 0x41
        spi_read_confirm = 96 + 1; % 0x61
        
        message_id_to_rcv_bytes = containers.Map( ...
            { ...
                wireless_stim.identify_board_req, ...
                wireless_stim.identify_board_remote_req, ...
                wireless_stim.perf_start_req, ...
                wireless_stim.perf_set_req, ...
                wireless_stim.perf_set_remote_req, ...
                wireless_stim.perf_get_req, ...
                wireless_stim.perf_get_remote_req, ...
                wireless_stim.peer_disconnect_req, ...
                wireless_stim.spi_write_req, ...
                wireless_stim.spi_read_req ...
            }, ...
            {64, 65, 86, 8, 8, 8, 8, 6, 13, 13});
        
        % param_idx, param_name, param_len
        perf_req_params = { {0,'channel',2}, {1,'channel_page',1}, ...
                            {3,'tx_power_dbm',1}, {4,'csma',1}, {5,'frame_retry',1}, ...
                            {6,'ack_req',1}, ...
                            {9,'rcv_desense',1}, {10,'xcvr_state',1}, ...
                            {12,'num_test_frames',4}, {13,'phy_frame_len',2} };    
        
        % 'Run' must be the last entry in this cell array so that the next stim
        % pulse includes the settings in the current command
        %
        command_fields = {'TL', ...      % Train length, length of train pulse (ms)
                          'Freq', ...    % Frequency of pulses (Hz)
                          'CathDur', ... % Duration of just Cathode phase (us)
                          'AnodDur', ... % Duration of just Anode phase (us)
                          'CathAmp', ... % Amplitude of Cathode pulse 0-65535 levels
                          'AnodAmp', ... % Amplitude of Anode pulse 0-65535 levels
                          'TD', ...      % Train Delay, time to delay a pulse (us)
                          'PL', ...      % Polarity, 1=Cathodic first, 0=Anodic first
                          'IPIDur', ...  % Intra-phase Interval (us)
                          'Run', ...     % Start/Stop the stim, 0=stop, 1=run, 2=continuous
                          };
        % 'FS', ...       % Fast Settle, not supported
        
        % register addresses are 2 bytes
        % bits   7:0 - per channel register address, mask = 0x00ff
        %            - global register address if global bit is set
        % bits  12:8 - channel address, mask = 0x1f00
        % bit     13 - broadcast channel address, 0x2000
        % bit     14 - global register bit, 0x4000
        reg_g_global_reset =    struct('addr',[64, 0], 'def',0,     'min',0, 'max',1);
        reg_g_stim_en =         struct('addr',[64, 1], 'def',0,     'min',0, 'max',1);
        reg_g_comm_timeout_ms = struct('addr',[64, 2], 'def',10000, 'min',0, 'max',65535);  % 10s 0x2710 0xffff 16 bits
        reg_g_comm_echo_on =    struct('addr',[64, 3], 'def',0,     'min',0, 'max',1);
        reg_g_action =          struct('addr',[64, 4], 'def',0,     'min',0, 'max',1);
        reg_g_version =         struct('addr',[64, 5]);  % read only
        % 8 independent bits: TESTSW8-1
        reg_g_testbus_sel =     struct('addr',[64, 6], 'def',0,     'min',0, 'max',255);
        % 3 independent bits: COM5, COM4, COM3; COM4 is an input, COM5 & COM3 are outputs
        reg_g_debug_com_out =   struct('addr',[64, 7], 'def',0,     'min',0, 'max',5);
        reg_g_debug_com_in  =   struct('addr',[64, 8]);  % read only

        broadcast_addr_bit = [32, 0];  % 0x2000

        reg_bipolar_en =     struct('addr',[0, 0],  'def',0,     'min',0, 'max',1);
        reg_stim_en =        struct('addr',[0, 1],  'def',0,     'min',0, 'max',1);
        reg_single_mode_en = struct('addr',[0, 2],  'def',0,     'min',0, 'max',1);
        reg_period_us =      struct('addr',[0, 3],  'def',33333, 'min',0, 'max',1048575); % 30Hz 0x8235 0xfffff 20 bits
        % enforce 50us on delay min due to firmware bug related to DAC SPI write timing
        reg_delay_us =       struct('addr',[0, 4],  'def',3000,  'min',50, 'max',65535);   % 3ms 0xbb8 16 bits          
        reg_train_ms =       struct('addr',[0, 5],  'def',100,   'min',0, 'max',16383);   % 100ms 0x64 0x3ff 14 bits   
        reg_cathode_uamp =   struct('addr',[0, 6],  'def',33068, 'min',32768, 'max',65535); % 0x812c 0xffff 16 bits      
        reg_anode_uamp =     struct('addr',[0, 7],  'def',32468, 'min',0, 'max',32768);   % 0x7ed4 0xffff 16 bits      
        reg_cathode_us =     struct('addr',[0, 8],  'def',200,   'min',0, 'max',16383);   % 200us 0xc8 0x3ff 14 bits   
        reg_anode_us =       struct('addr',[0, 9],  'def',200,   'min',0, 'max',16383);   % 200us 0xc8 0x3ff 14 bits   
        reg_ipi_us =         struct('addr',[0, 10], 'def',50,    'min',0, 'max',127);     % 50us 0x32 0x7f 7 bits      
        reg_anode_first_en = struct('addr',[0, 11], 'def',0,     'min',0, 'max',1);
        reg_trim_uamp =      struct('addr',[0, 12], 'def',32768, 'min',0, 'max',65535);   % 0x8000 0xffff 16 bits
        reg_single_mode_go = struct('addr',[0, 13], 'def',0,     'min',0, 'max',1);  % write only
        reg_adc_cfg =        struct('addr',[0, 14]);                        % read only
        reg_adc_data =       struct('addr',[0, 15]);                        % read only
        reg_sw_testbus =     struct('addr',[0, 16], 'def',0,     'min',0, 'max',1);
        reg_sw_exhaust =     struct('addr',[0, 17], 'def',0,     'min',0, 'max',1);
        reg_sw_swout =       struct('addr',[0, 18], 'def',0,     'min',0, 'max',1);
        
        trim_cal_fname = 'trim_cal_data.mat';
    end
    properties (Access = private)
        serial
        dbg_lvl
        atmel_local_version
        atmel_remote_version
        batch_q
    end
    methods %(Access = private)
        function addr_out = reg_ch_addr(obj, addr, channel, broadcast)
            addr_out(2) = addr(2);
            
            if broadcast
                addr_out_1 = obj.broadcast_addr_bit(1);
            else
                addr_out_1 = channel - 1;  % channel is 1-based
            end
            addr_out(1) = addr_out_1;
        end
        
        function val = reg_read(obj, addr)
            if length(addr) ~= 2
                error('addr must be length 2, len=%d', length(addr));
            end
            rsp = obj.send_message(obj.spi_read_req, [addr]);
            status = rsp(1);
            if status
                error('failing status detected in serial message: 0x%x', status);
            end
            val = swapbytes(typecast(uint8([0,rsp(6:8)]), 'uint32'));
            if obj.dbg_lvl >= 2
                addr = bitand(swapbytes(typecast(uint8(rsp(4:5)), 'uint16')), hex2dec('7fff'));
                disp(sprintf('read 0x%06x(%d) from 0x%04x', val, val, addr));
            end
        end

        % batch is an optional parameter
        function reg_write(obj, addr, val, batch)
            if nargin < 4
                batch = false;
            end
            
            if length(addr) ~= 2
                error('addr must be length 2, len=%d', length(addr));
            end
            val_a = typecast(swapbytes(int32(val)), 'uint8');
            if val_a(1) ~= 0
                % registers are 24 bits max
                error('invalid data value %d', val);
            end

            payload = [addr, val_a(2:4)];
            if batch
                % threshold at 254 queued bytes
                threshold = 254;
                if length(obj.batch_q) > threshold
                    error('register write queue full at %d bytes, max %d bytes', ...
                          length(obj.batch_q), threshold);
                end
                obj.batch_q = [obj.batch_q, payload];  % append
                return;
            end
            
            rsp = obj.send_message(obj.spi_write_req, payload);
            status = rsp(1);
            if status
                error('failing status detected in serial message: 0x%x', status);
            end
            if obj.dbg_lvl >= 2
                addr = bitand(swapbytes(typecast(uint8(rsp(4:5)), 'uint16')), hex2dec('7fff'));
                disp(sprintf('wrote 0x%06x(%d) to 0x%04x', val, val, addr));
            end
        end
        
        function reg_commit(obj)
            if length(obj.batch_q) == 0
                return;
            end
            
            if obj.dbg_lvl >= 1
                start = toc;
            end
            rsp = obj.send_message(obj.spi_write_req, obj.batch_q);
            status = rsp(1);
            if status
                error('failing status detected in serial message: 0x%x', status);
            end


            if obj.dbg_lvl >= 1
                stop = toc;
                addr_size = 2;
                data_size = 3;
                payload_size = addr_size + data_size;

                disp(sprintf('committed %d regs, %d bytes, %f sec', ...
                             length(obj.batch_q)/payload_size, length(obj.batch_q), stop-start));

                if obj.dbg_lvl >= 2
                    for idx = 1:payload_size:length(obj.batch_q)
                        addr_a = obj.batch_q(idx:idx+addr_size-1);
                        addr = bitand(swapbytes(typecast(uint8(addr_a), 'uint16')), hex2dec('7fff'));
                        val_a = obj.batch_q(idx+addr_size:idx+payload_size-1);
                        val = swapbytes(typecast(uint8([0,val_a]), 'uint32'));
                        disp(sprintf('wrote 0x%06x(%d) to 0x%04x', val, val, addr));
                    end
                end
            end
            obj.batch_q = [];  % clear the queue
        end
        
        function perf_set_param(obj, remote, param_type, param_val)
            cmd = obj.perf_set_req;
            if remote == true
                cmd = obj.perf_set_remote_req;
            end

            val_a = typecast(int32(param_val), 'uint8');
            
            for idx = 1:length(obj.perf_req_params)
                param = obj.perf_req_params{idx}; % obtain {idx,name,len}
                cur_param_type = param{1};
                if cur_param_type == param_type
                    param_len = param{3};
                    val = val_a(1:param_len);

                    rsp = obj.send_message(cmd, [param_type, param_len, val], param_len);
                    status = rsp(1);
                    if status
                        error('failing status detected in serial message: 0x%x', status);
                    end

                    ret_param_type = rsp(2);
                    ret_param_len = rsp(3);
                    ret_param_val = fliplr(rsp(4:4+param_len-1));

                    if obj.dbg_lvl >= 1
                        disp([sprintf('set perf param %d: ', ret_param_type), param{2}, ...
                              sprintf(' len=%d ', ret_param_len), 'val=', sprintf('%02x ',ret_param_val)]);
                    end
                end
            end
        end
        
        % default parameter values:
        %
        % local perf params:
        %     0:0: channel len=2 val=00 01 
        %     1:1: channel_page len=1 val=00 
        %     3:3: tx_power_dbm len=1 val=0a 
        %     4:4: csma len=1 val=01 
        %     5:5: frame_retry len=1 val=00 
        %     6:6: ack_req len=1 val=01 
        %     9:9: rcv_desense len=1 val=00 
        %     10:10: xcvr_state len=1 val=16 
        %     12:12: num_test_frames len=4 val=00 00 00 64 
        %     13:13: phy_frame_len len=2 val=00 14 
        % remote perf params:
        %     0:0: channel len=2 val=00 01 
        %     1:1: channel_page len=1 val=00 
        %     3:3: tx_power_dbm len=1 val=0a 
        %     4:4: csma len=1 val=01 
        %     5:5: frame_retry len=1 val=00 
        %     6:6: ack_req len=1 val=01 
        %     9:9: rcv_desense len=1 val=00 
        %     10:10: xcvr_state len=1 val=11 
        %     12:12: num_test_frames len=4 val=00 00 00 64 
        %     13:13: phy_frame_len len=2 val=00 14 
        function perf_display_params(obj, remote)
            cmd = obj.perf_get_req;
            if remote == true
                disp('remote perf params:');
                cmd = obj.perf_get_remote_req;
            else
                disp('local perf params:');
            end
                
            for idx = 1:length(obj.perf_req_params)
                param = obj.perf_req_params{idx}; % obtain {idx,name,len}
                param_type = param{1};
                rsp = obj.send_message(cmd, [param_type], param{3});
                status = rsp(1);
                if status
                    error('failing status detected in serial message: 0x%x', status);
                end
                ret_param_type = rsp(2);
                param_len = rsp(3);
                param_val = fliplr(rsp(4:4+param_len-1));

                disp([sprintf('    %d:%d: ', param_type, ret_param_type), param{2}, ...
                      sprintf(' len=%d ', param_len), 'val=', sprintf('%02x ',param_val)]);
            end
        end
        
        function fields = parse_identify_message(obj, message)
            pos = 4;
            len = message(pos-1);
            fields.soc = native2unicode(message(pos:pos+len-1));
            pos = pos+len+1;
            len = message(pos-1);
            fields.trx = native2unicode(message(pos:pos+len-1));
            pos = pos+len+1;
            len = message(pos-1);
            fields.brd = native2unicode(message(pos:pos+len-1));
            pos = pos+len;
            len = 8;
            fields.mac = message(pos:pos+len-1);
            pos = pos+len;
            len = 4;
            fields.ver = typecast(uint8(message(pos:pos+len-1)), 'single');
            pos = pos+len;
            len = 4;
            fields.feat = typecast(uint8(message(pos:pos+len-1)), 'uint32');
        end
        
        % var_rcv_bytes is optional
        function out = send_message(obj, message_id, payload, var_rcv_bytes)
            if  nargin < 4
                var_rcv_bytes = 0;
            end
            
            sot = 1;
            protocol_id = 0;
            eot = 4;
            internal_payload = [protocol_id, message_id, payload];
            message = [sot, length(internal_payload), internal_payload, eot];
            if obj.dbg_lvl >= 3
                disp(['in =', sprintf(' %02x', message)]);
            end
            
            if obj.dbg_lvl >= 3
                start = toc;
            end
            fwrite(obj.serial, message);

            lastwarn('');
            out = fread(obj.serial, obj.message_id_to_rcv_bytes(message_id) + var_rcv_bytes);
            rxlen = length(out);
            if obj.dbg_lvl >= 3
                disp(['out =', sprintf(' %02x', out)]);
            end
            if (~isempty(lastwarn))
                disp(['rsp length: ', num2str(length(out))]);
                error('Invalid response to command 0x%02x', message_id);
            else
                % parse the payload
                message_len = out(2);
                payload = out(5:5+message_len-3);
                out = payload';
            end
            if obj.dbg_lvl >= 3
                stop = toc;
                disp(sprintf('send_message id=0x%02x time=%f', message_id, stop-start));
            end
        end
        
        % commit is optional, true by default
        function set_param(obj, val_list, channel_list, reg, commit)
            if nargin < 5
                commit = true;
            end
            
            if obj.dbg_lvl >= 3
                disp(sprintf('set_param ch %s val %s reg %s commit %d', ...
                             sprintf('%d ', channel_list), sprintf('%d ', val_list), ...
                             sprintf('%d ', reg.addr), commit));
            end
            if max(val_list) > reg.max
                error('invalid set value %d, max=%d', max(val_list), reg.max)
            end
            if min(val_list) < reg.min
                error('invalid set value %d, min=%d', min(val_list), reg.min)
            end

            channel_list_len = length(channel_list);
            if channel_list_len > obj.num_channels || channel_list_len <= 0
                error('invalid number of channels %d', channel_list_len);
            end
            if channel_list_len ~= length(unique(channel_list))
                error('duplicate channels are not allowed');
            end
            
            val_list_len = length(val_list);
            if val_list_len ~= channel_list_len && val_list_len ~= 1
                error('one value per channel required');
            end
            
            % broadcast single value to all channels
            if channel_list_len == obj.num_channels && val_list_len == 1
                addr = obj.reg_ch_addr(reg.addr, 0, 1);
                obj.reg_write(addr, val_list, true);  % batch writes
                if commit
                    obj.reg_commit();
                end
                return
            end

            for ch_idx = 1:channel_list_len
                channel = channel_list(ch_idx);
                if (channel > obj.num_channels || channel < 1)
                    error('invalid channel %d', channel);
                end
                if val_list_len == 1
                    cur_val = val_list;
                else
                    cur_val = val_list(ch_idx);
                end
                    
                addr = obj.reg_ch_addr(reg.addr, channel, 0);
                obj.reg_write(addr, cur_val, true);  % batch writes
            end
            if commit
                obj.reg_commit();
            end
        end % set_param
        
        function val_list = get_param(obj, channel_list, reg)
            channel_list_len = length(channel_list);
            if channel_list_len > obj.num_channels || channel_list_len <= 0
                error('invalid number of channels %d', channel_list_len);
            end
            if channel_list_len ~= length(unique(channel_list))
                error('duplicate channels are not allowed');
            end
            
            for ch_idx = 1:channel_list_len
                channel = channel_list(ch_idx);
                if (channel > obj.num_channels || channel < 1)
                    error('invalid channel %d', channel);
                end
                addr = obj.reg_ch_addr(reg.addr, channel, 0);
                val_list(ch_idx) = obj.reg_read(addr);
            end
        end % get_param
        
        function set_5V(obj, enable)
            val = obj.reg_read(obj.reg_g_debug_com_out.addr);
            % COM5 = 5V enable/disable
            % reg_g_debug_com_out = { COM5, 0, COM3 }
            
            if enable == 0
                val = bitand(val, 3); % val & 3'b011
                obj.reg_write(obj.reg_g_debug_com_out.addr, val);
                return
            end
            
            tries = 5;
            status = 0;
            while tries > 0 && status == 0
                status = obj.detect_18V();
                pause(0.1);
                tries = tries - 1;
            end
            if status == 0
                error('+/- 18V supply not detected. Cannot enable +/-5V supply');
                %warning('+/- 18V supply not detected. Cannot enable +/-5V supply');
            else
                val = bitor(val, 4);  % val | 3'b100
                obj.reg_write(obj.reg_g_debug_com_out.addr, val);
            end
        end
        % returns nonzero if +/- 18V supply is up as reported
        % by the on-board monitor
        function status = detect_18V(obj)
            val = obj.reg_read(obj.reg_g_debug_com_in.addr);
            val = bitand(val, 2); % val & 3'b010
            
            if val ~= 0
                status = 1;
            else
                status = 0;
            end
        end        
    end  % methods (Access = private)
end % classdef wireless_stim