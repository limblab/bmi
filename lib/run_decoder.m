% run_dynamic_arm_bmi

cd('C:\Users\system administrator\Desktop\S1_analysis')
load_paths

current_location = mfilename('fullpath');
[current_folder,~,~] = fileparts(current_location);
cd(current_folder)
add_these = strfind(current_folder,'\');
add_these = current_folder(1:add_these(end)-1);
addpath([add_these filesep 'lib'])
addpath(genpath([add_these filesep 'SDK for Windows']))
clearxpc

clear params
params.monkey_name = 'Test';
params.save_dir = ['E:\' params.monkey_name];
params.mode = 'vel'; 
params.task_name = ['RW_' params.mode];
params.decoders(1).decoder_file = '\\citadel\data\Chewie_8I2\Ricardo\Chewie_2014-09-05_RW\Chewie_2014-09-05_RW_001_Binned_Decoder.mat';
params.decoders(1).decoder_type = 'vel';
params.map_file = '\\citadel\limblab\lab_folder\\Animal-Miscellany\Chewie 8I2\Blackrock implant surgery 6-14-10\1025-0394.cmp';
params.arm_model = '';
params.output = 'xpc';
params.save_firing_rates = 1;
params.display_plots = 1;
params.offset_time_constant = 60;
params.vel_offsets = [0 0];
params.artifact_removal = 0;
params.artifact_removal_window = 0.001;
params.artifact_removal_num_channels = 10;

if exist('params','var')
    params = bmi_params_defaults(params);
else
    params = bmi_params_defaults;
end
params.elec_map = read_cmp(params.map_file);

% run_decoder: This function connects to the Cerebus stream via
% the Central application, produces cursor position predictions
%
% INPUTS : Additional parameters: "params" structure -> see adapt_params_defaults.m

% params = evalin('base','params');

xpc = open_xpc_udp(params);

% Read Decoders and other files
params = load_decoders(params);
params.current_decoder = params.decoders(strcmpi({params.decoders.decoder_type},'vel'));
params = measure_force_offsets(params);

% Initialization

%globals
ave_op_time = 0.0;
bin_count = 0;
reached_cycle_t = false;
w = Words;
cursor_pos = [0 0];
m_data_2.Data.theta = [0 0];

% Setup figures
handles = setup_display_plots(params);
handles = get_new_filename(params,handles);

% Start data streaming
if params.online
    handles = start_cerebus_stream(params,handles,xpc);
    cbmex('trialconfig',1);
    offline_data = [];
    max_cycles = 0;
else
    %Binned Data File
    offline_data = LoadDataStruct(params.offline_data);
    max_cycles = length(offline_data.timeframe);
    bin_start_t = double(offline_data.timeframe(1));
end

% data structure to store inputs
data = get_default_data(params);

% Setup data files and directories for recording

t_buf = tic; %data buffering timer
drawnow;
iCycle = 0;
% Run cycle
try
    recording = 0;
    current_mode = params.mode;
    
    while(~get(handles.stop_bmi,'Value') && ...
            ( params.online || ...
            ~params.online && bin_count < max_cycles) )
        iCycle = iCycle+1;
        params = evalin('base','params');
        if (reached_cycle_t)
            if get(handles.record,'Value') && ~recording
                recording = 1;
                [params,handles] = setup_datafiles(params,handles,data,offline_data,w,xpc,m_data_2);
                cbmex('fileconfig', handles.cerebus_file, '', 1);
                data.sys_time = cbmex('time');
            end
            if ~get(handles.record,'Value') && recording
                recording = 0;
                cbmex('fileconfig', handles.cerebus_file, '', 0);
            end
            
            % timers and counters
            cycle_t = toc(t_buf); %this should be equal to bin_size, but may be longer if last cycle operations took too long.
            t_buf   = tic; % reset buffering timer
            bin_count = bin_count +1;
            
            % Get and Process New Data
            data = get_new_data(params,data,offline_data,bin_count,cycle_t,w,xpc,m_data_2);
            
            if size(data.spikes,1)<params.n_lag
                data.spikes = zeros(params.n_lag,params.n_neurons);
            end
            % Predictions
            try
                predictions = [1 rowvec(data.spikes(1:params.n_lag,:))']*params.current_decoder.H;
            catch
                predictions = [0 0];
            end            
            if ~isempty(params.current_decoder.P)
                for iP = 1:length(predictions)
                    predictions(iP) = polyval(params.current_decoder.P(:,iP),predictions(iP));
                end
            end
            if isempty(predictions)
                predictions = [0 0];
            end  
                        
            predictions = .01*predictions(1:2);
            hpf_predictions = params.offset_time_constant/(params.offset_time_constant+params.binsize)*...
                (predictions + params.vel_offsets);
            params.vel_offsets = hpf_predictions - predictions;
            if mod(iCycle,100)==0
                set(handles.textbox_offset_x,'String',num2str(params.vel_offsets(1)));
                set(handles.textbox_offset_y,'String',num2str(params.vel_offsets(2)));
            end
            predictions = hpf_predictions;
            cursor_pos = cursor_pos + predictions;
            cursor_pos(1) = min(max(cursor_pos(1),-16),16);
            cursor_pos(2) = min(max(cursor_pos(2),-12),12);
            
            bin_start_t = data.sys_time;
            
            if recording
                if isempty(data.spikes)
                    spikes = [];
                else
                    spikes = data.spikes(1,:);
                end
                tmp_data = [bin_start_t spikes predictions cursor_pos];
                save(handles.data_file,'tmp_data','-append','-ascii');
            end
            
            if exist('xpc','var')
                % send predictions to xpc                
                fwrite(xpc.xpc_write, [1 1 cursor_pos cursor_pos cursor_pos],'float32');
                %                     fprintf('%.2f\t%.2f\t%.2f\t%.2f\n',[cursor_pos predictions]);
            end
            
            %display targets and cursor plots
            if params.display_plots && ~isnan(any(data.tgt_pos)) && ishandle(handles.curs_handle) && mod(iCycle,10)==0
                
                set(handles.curs_handle,'XData',cursor_pos(1),'YData',cursor_pos(2));
                set(handles.xpred_disp,'String',sprintf('xpred: %.2f',cursor_pos(1)))
                set(handles.ypred_disp,'String',sprintf('ypred: %.2f',cursor_pos(2)))
                
                if data.tgt_on
                    set(handles.tgt_handle,'XData',data.tgt_pos(1),'YData',data.tgt_pos(2),'Visible','on');
                else
                    set(handles.tgt_handle,'Visible','off');
                end
                
                if  data.adapt_bin && ~data.fix_decoder
                    display_color = 'r';
                else
                    display_color = 'k';
                end
                set(handles.curs_handle,'MarkerEdgeColor',display_color,'MarkerFaceColor',display_color);
            end
            
            % Wrapping up
            % flush pending events
            drawnow;
            %check elapsed operation time
            et_op = toc(t_buf);
            ave_op_time = ave_op_time*(bin_count-1)/bin_count + et_op/bin_count;
            if et_op>0.05
                c = clock;
                fprintf('~~~~~~slow processing time: %.1f ms at %02.f:%02.f:%02.f~~~~~~~\n',[et_op*1000 c(4:6)]);
                %                       fprintf('~~~~~~slow processing time: %.1f ms~~~~~~~\n',[et_op*1000]);
            end
            
            reached_cycle_t = false;
        end
        
        et_buf = toc(t_buf); %elapsed buffering time
        % reached cycle time?
        if (et_buf>=params.binsize) || ...
                (~params.online && (~params.realtime || et_buf*params.realtime>=params.binsize))
            reached_cycle_t = true;
        end
    end
    
    if params.online
        if params.save_data
            cbmex('fileconfig', handles.cerebus_file, '', 0);
        end
        cbmex('close');
    end
    
    echoudp('off');
    fclose('all');
    close all;
    recorded_files = dir(handles.save_dir);
    recorded_files = {recorded_files(:).name};
    if numel(recorded_files)<3 && exist(handles.save_dir,'dir')
        rmdir(handles.save_dir);
    end    
    
catch e
    if params.online
        if params.save_data
            cbmex('fileconfig', handles.cerebus_file, '', 0);
        end
        cbmex('close');
    end
    recorded_files = dir(handles.save_dir);
    recorded_files = {recorded_files(:).name};
    if numel(recorded_files)<3 && exist(handles.save_dir,'dir')
        rmdir(handles.save_dir);
    end
    echoudp('off');
    fclose('all');
    close all;    
    rethrow(e);    
end
