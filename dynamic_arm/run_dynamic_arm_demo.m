% run_dynamic_arm_bmi
cd('C:\Users\ricar_000\Documents\Miller Lab\Matlab\s1_analysis')
load_paths
current_location = mfilename('fullpath');
[current_folder,~,~] = fileparts(current_location);
cd(current_folder)
add_these = strfind(current_folder,'\');
add_these = current_folder(1:add_these(end)-1);
addpath([add_these filesep 'lib'])
addpath([add_these filesep 'default_parameters'])
addpath(genpath([add_these filesep 'SDK for Windows']))
% addpath(genpath(add_these))

clear params
params.monkey_name = 'Chewie';
% params.monkey_name = 'Test';
params.save_dir = ['E:\' params.monkey_name];
params.mode = 'emg'; % emg | n2e | n2e_cartesian | vel | iso | test_force | test_torque
params.arm_model = 'hu'; % hill | prosthesis | hu | miller | perreault | ruiz | bmi | point_mass
params.task_name = ['RP_' params.mode];
params.decoders(1).decoder_file = '';
params.decoders(1).decoder_type = 'n2e1';
% params.decoders(4).decoder_file = '\\citadel\data\TestData\Ricardo_2014-09-11_DCO_iso_ruiz\Output_Data\muscle_force_filter.mat';
% params.decoders(4).decoder_type = 'emg2muscle_force';
% params.decoders(5).decoder_file = '\\citadel\data\TestData\Ricardo_2014-09-11_DCO_iso_ruiz\Output_Data\muscle_torque_filter.mat';
% params.decoders(5).decoder_type = 'emg2muscle_torque';
% params.arm_params_file = '\\citadel\data\Chewie_8I2\Ricardo\Chewie_2014-11-19_RP_n2e_ruiz\Chewie_2014-11-19_RP_n2e_ruiz_001_params.mat';
% params.arm_params_file = 'E:\Chewie\Chewie_2014-11-20_RP_n2e_hu\Chewie_2014-11-20_RP_n2e_hu_001_params.mat';
params.arm_params_file = [];
params.output = 'xpc';
params.force_to_cursor_gain = .3;
params.stop_task_if_x_artifacts = 1;
params.stop_task_if_x_force = 0;
params.save_firing_rates = 1;
params.display_plots = 0;
params.left_handed = 1;
params.debug = 1;
params.offset_time_constant = 60;
params.decoder_offsets = [];
params.artifact_removal = 0;
params.artifact_removal_window = 0.001;
params.artifact_removal_num_channels = 10;

if exist('params','var')
    params = bmi_params_defaults(params);
else
    params = bmi_params_defaults;
end

arm_params = [];
if ~isempty(params.arm_params_file)
    load(params.arm_params_file,'arm_params')
end
arm_params = get_default_arm_params(arm_params);

save('temp_arm_params','arm_params')
clear arm_params

% run_decoder: This function connects to the Cerebus stream via
% the Central application, produces cursor position predictions
%
% INPUTS : Additional parameters: "params" structure -> see adapt_params_defaults.m

% params = evalin('base','params');

[m_data_1, m_data_2] = open_dynamic_arm_instance(params);

% Initialization

%globals
ave_op_time = 0.0;
bin_count = 0;
reached_cycle_t = false;
w = Words;

% Setup figures
handles = setup_display_plots(params);

offline_data = [];
max_cycles = 0;


% data structure to store inputs
% data = get_default_data(params);

% Setup data files and directories for recording

t_buf = tic; %data buffering timer
drawnow;
iCycle = 0;
old_handleforce = [0 0];
% Run cycle
% try
    recording = 0;
    current_mode = params.mode;
    
    while(~get(handles.stop_bmi,'Value'))
        iCycle = iCycle+1;
        params = evalin('base','params');
        if (reached_cycle_t)
                        
            % timers and counters
            cycle_t = toc(t_buf); %this should be equal to bin_size, but may be longer if last cycle operations took too long.
            t_buf   = tic; % reset buffering timer
            bin_count = bin_count +1;
            
            if ~strcmpi(current_mode,params.mode)
                if strcmpi(params.mode,'n2e1')
                    temp = find(strcmpi({params.decoders.decoder_type},'n2e'));
                    params.current_decoder = params.decoders(temp(1));
                elseif strcmpi(params.mode,'n2e2')
                    temp = find(strcmpi({params.decoders.decoder_type},'n2e'));
                    params.current_decoder = params.decoders(temp(2));
                elseif strcmpi(params.mode,'n2e_cartesian')
                    params.current_decoder = params.decoders(strcmpi({params.decoders.decoder_type},'n2e_cartesian'));
                elseif strcmpi(params.mode,'vel')
                    params.current_decoder = params.decoders(strcmpi({params.decoders.decoder_type},'vel'));
                else
                    temp = find(strcmpi({params.decoders.decoder_type},'n2e'));
                    params.current_decoder = params.decoders(temp(1));
%                     params.current_decoder = params.decoders(strcmpi({params.decoders.decoder_type},'null'));
                end
                data = get_default_data(params);
                current_mode = params.mode;
            end
            
            % Predictions
           
            predictions = [];
            
            EMG_data = zeros(1,4);
            EMG_labels = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'};
%             [EMG_data,~,EMG_labels] = process_emg(params,data,predictions);
            m_data_1.Data.EMG_data = EMG_data;
            m_data_1.Data.EMG_labels = EMG_label_conversion(EMG_labels);
            m_data_1.Data.forces = [0 0];
            
            if strncmpi(params.mode,'iso',3) % ...if task was isometric
                cursor_pos = -params.force_to_cursor_gain*data.handleforce + params.force_offset;                
            else % ...if task was a movement task
                cursor_pos = m_data_2.Data.x_hand;
            end
            
            
            params.stop_trial = 0;
            
            %display targets and cursor plots
            if params.display_plots && ~isnan(any(data.tgt_pos)) && ishandle(handles.curs_handle)
                
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
     
    m_data_1.Data.bmi_running = 0;
    echoudp('off');
    fclose('all');
    close all;
   
    clear m_data_1 m_data_2
    
% catch e
%     if params.online
%         if params.save_data
%             cbmex('fileconfig', handles.cerebus_file, '', 0);
%         end
%         cbmex('close');
%     end
%     recorded_files = dir(handles.save_dir);
%     recorded_files = {recorded_files(:).name};
%     if numel(recorded_files)<3 && exist(handles.save_dir,'dir')
%         rmdir(handles.save_dir);
%     end
%     m_data_1.Data.bmi_running = 0;
%     echoudp('off');
%     fclose('all');
%     close all;
%     clear m_data_1 m_data_2
%     rethrow(e);    
% end