function decoder_test(varargin)
current_location = mfilename('fullpath');
[current_folder,~,~] = fileparts(current_location);
cd(current_folder)
add_these = strfind(current_folder,'\');
add_these = current_folder(1:add_these(end)-1);
addpath(genpath(add_these))
clearxpc
% run_decoder: This function connects to the Cerebus stream via
% the Central application, produces prediction by a two step
% process in which spike trains predict emgs and emgs predict forces.
% the emg-to-force decoder is expected to be precomputed and passed as
% EMG2F_w weight matrix. The spikes to EMG weight matrix is trained online
% and it uses the backpropagated discrepancy between the predicted forces
% and the target position in the task.
%
% INPUTS : Additional parameters: "params" structure -> see adapt_params_defaults.m

[m_data_1, m_data_2] = open_dynamic_arm_instance;

%% Parameters
if nargin
    params = varargin{1};
    params = bmi_params_defaults(params);
else
    params = bmi_params_defaults;
end

params.output = 'xpc';

xpc = open_xpc_udp(params);

%% Read Decoders and other files

% [neuron_decoder, emg_decoder,params] = load_decoders(params);
% if ~strcmp(params.mode,'direct')
%     spike_buf_size = params.n_lag + params.n_lag_emg - 1; 
% else
%     spike_buf_size = params.n_lag;
% end

% load template trajectories
% if params.cursor_assist
%     % cursor_traj is a file name to a structure containing the fields
%     % 'mean_paths' and 'back_paths', each of size < 101 x 2 x n_tgt >
%     cursor_traj = load(params.cursor_traj);
% end

%% Initialization

%globals
ave_op_time = 0.0;
bin_count = 0;
reached_cycle_t = false;
w = Words;

% data structure to store inputs
% data = struct('spikes'      , zeros(spike_buf_size,params.n_neurons),...
data = get_default_data(params);
          
% % dataset to store older data for batch adaptation
% previous_trials = dataset();
% for i=params.batch_length
%     previous_trials = [previous_trials;...
%         dataset({bin_count, 'bin_count'}, ...
%         {{data},'data'},...
%         {data.tgt_id,'target_id'},...
%         {nan(1,params.n_forces),'predictions'})];%#ok<AGROW>
% end


%% Setup figures

handles = setup_display_plots(params);
handles = get_new_filename(params,handles);

%% Start data streaming
if params.online   
    handles = start_cerebus_stream(params,handles,xpc);
    cbmex('trialconfig',1);
    data.labels = cbmex('chanlabel',1:156);
    offline_data = [];
    max_cycles = 0;
else
    %Binned Data File
    offline_data = LoadDataStruct(params.offline_data);
    max_cycles = length(offline_data.timeframe);
    bin_start_t = double(offline_data.timeframe(1));
end

%% Setup data files and directories for recording
% handles = setup_datafiles(params,handles,data,offline_data,w);

%%
t_buf = tic; %data buffering timer
drawnow;

%% Run cycle
try
    recording = 0;
    while(~get(handles.stop_bmi,'Value') && ... 
            ( params.online || ...
                ~params.online && bin_count < max_cycles) )
        
        if (reached_cycle_t)
            if get(handles.record,'Value') && ~recording
                recording = 1;
                [params,handles] = setup_datafiles(params,handles,data,offline_data,w);
                cbmex('fileconfig', handles.cerebus_file, '', 1);
                data.sys_time = cbmex('time');
            end
            if ~get(handles.record,'Value') && recording
                recording = 0;
                cbmex('fileconfig', handles.cerebus_file, '', 0);
            end
            clc
            %% timers and counters
            cycle_t = toc(t_buf); %this should be equal to bin_size, but may be longer if last cycle operations took too long.
            t_buf   = tic; % reset buffering timer
            bin_count = bin_count +1;     
            
            %% Get and Process New Data
            data = get_new_data(params,data,offline_data,bin_count,cycle_t,w);
%             data.spikes
            
%             %% Predictions
%            
%             predictions = [1 rowvec(data.spikes(1:params.n_lag,:))']*neuron_decoder.H;
%             
%             if ~strcmp(params.mode,'direct')
%                 % emg cascade
%                 data.emgs = [predictions; data.emgs(1:end-1,:)];
%                 predictions = [1 rowvec(data.emgs(:))']*emg_decoder.H;                
%             end
            
            %% Cursor Output
%             if params.cursor_assist
%                 [cursor_pos,data] = cursor_assist(data,cursor_pos,cursor_traj);
%             else
%                 %normal behavior, cursor mvt based on predictions
%                 cursor_pos = predictions;
%             end
%             if ~exist('x0','var')
%                 x0 = zeros(1,4);
%             end

            [EMG_data,~,~] = process_emg(data);
            m_data_1.Data.EMG_data = EMG_data;
            predictions = 100*m_data_2.Data.x_hand;
            
            cursor_pos = predictions; 

%             datafile.t = [datafile.t; bin_start_t];
            bin_start_t = data.sys_time;

            if recording
                tmp_data = [bin_start_t data.spikes(1,:) predictions EMG_data m_data_2.Data.F_end m_data_2.Data.musc_force]; 
                save(handles.data_file,'tmp_data','-append','-ascii');
            end

%             datafile.spikes(end+1,1:96) = data.spikes(1,:);
            
%             datafile.spikes = [datafile.spikes; data.spikes(1,:)];   
%             datafile.analog = [datafile.analog; data.analog(1,:)];
%             datafile.musc_force = [datafile.musc_force; m_data_2.Data.musc_force];
%             datafile.F_end = [datafile.F_end; m_data_2.Data.F_end];
%             datafile.cursorpos = [datafile.cursorpos; cursor_pos];
%             datafile.curspreds = [datafile.curspreds; predictions];
%             datafile.emg = [datafile.emg; EMG_data];
%             
%             [data,x0,xH] = run_arm_model(data,x0);

%             predictions = xH(1:2);

%             predictions = [0 0];


            if exist('xpc','var')
                % send predictions to xpc
                fwrite(xpc, [1 1 cursor_pos m_data_2.Data.shoulder_pos m_data_2.Data.elbow_pos],'float32');                
                fprintf('%.2f\t%.2f\n',cursor_pos);
            end
            
%             %% Neurons-to-EMG Adaptation
%             if params.adapt
%                 [previous_trials,data,neuron_decoder] = decoder_adaptation(params,data,bin_count,previous_trials,neuron_decoder,emg_decoder,predictions);
%             end
                
            %% Save and display progress
            
%             % save adapting decoder every 30 seconds
%             if params.adapt && mod(bin_count*params.binsize, 30) == 0
%                 %                 save([params.handles.save_dir '\previous_trials_' strrep(strrep(datestr(now),':',''),' ','-')], 'previous_trials','neuron_decoder');
%                 save( [adapt_dir '\Adapt_decoder_' (datestr(now,'yyyy_mm_dd_HHMMSS'))],'-struct','neuron_decoder');
%                 fprintf('Average Matlab Operation Time : %.2fms\n',ave_op_time*1000);
%             end
            
            % save raw data
%             if params.save_data
%                 % spikes are timed from beginning of this bin
%                 % because they occured in the past relatively to now
%                 tmp_data = [bin_start_t data.spikes(1,:)];
%                 save(spike_file,'tmp_data','-append','-ascii');
%                 % the rest of the data is timed with end of this bin
%                 % because they are predictions made just now.
%                 bin_start_t = data.sys_time;
%                 if ~strcmp(params.mode,'direct')
%                     tmp_data   = [bin_start_t double(data.emgs(1,:))];
%                     save(emg_file,'tmp_data','-append','-ascii');
%                 end
%                 tmp_data = [bin_start_t double(cursor_pos)];
%                 save(curs_pos_file,'tmp_data','-append','-ascii');
%                 tmp_data = [bin_start_t double(predictions)];
%                 save(curs_pred_file,'tmp_data','-append','-ascii');
%             end
            
%             % each second show adaptation progress
%             if mod(bin_count*params.binsize, 1) == 0
%                 disp([sprintf('Time: %d secs, ', bin_count*params.binsize) ...
%                       'Adapting: ' num2str(~data.fix_decoder) ', ' ...
%                       'Online: ' num2str(params.online)]);
% %                     'prediction corr: ' num2str(last_20R)]);
%             end
            
            %display targets and cursor plots
            if params.display_plots && ~isnan(any(data.tgt_pos)) && ishandle(handles.curs_handle)                
               
                set(handles.curs_handle,'XData',predictions(1),'YData',predictions(2));
%                 
                set(handles.xpred_disp,'String',sprintf('xpred: %.2f',predictions(1)))
                set(handles.ypred_disp,'String',sprintf('ypred: %.2f',predictions(2)))

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
            
            %% Wrapping up            
            % flush pending events
            drawnow;
            %check elapsed operation time
            et_op = toc(t_buf);
            ave_op_time = ave_op_time*(bin_count-1)/bin_count + et_op/bin_count;
            if et_op>0.05
                fprintf('~~~~~~slow processing time: %.1f ms~~~~~~~\n',et_op*1000);
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
    m_data_1.Data.bmi_running = 0;
    echoudp('off');
    fclose('all');    
    close all;
    
catch e
    if params.online
        if params.save_data
            cbmex('fileconfig', handles.cerebus_file, '', 0);
        end
        cbmex('close');
    end
    m_data_1.Data.bmi_running = 0;
    echoudp('off');
    fclose('all');
    close all;
    rethrow(e);
end


% %% optionally Save decoder at the end
% if params.adapt
%     YesNo = questdlg('Would you like to save the adapted decoder?','Save Decoder?','Yes','No','Yes');
%     if strcmp(YesNo,'Yes')
%         dec_dir = [params.handles.save_dir filesep datestr(now,'yyyy_mm_dd')];
%         if ~isdir(dec_dir)
%             mkdir(dec_dir);
%         end
%         handles.filename = [dec_dir filesep 'Adapted_decoder_' (datestr(now,'yyyy_mm_dd_HHMMSS')) '_End.mat'];
%         save(handles.filename,'-struct','neuron_decoder');
%         fprintf('Saved Decoder File :\n%s\n',handles.filename);
%     else
%         disp('Decoder not saved');
%     end
% end

end
