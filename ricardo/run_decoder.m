function run_decoder(varargin)
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

    params = evalin('base','params');

    [m_data_1, m_data_2] = open_dynamic_arm_instance(params);
    
    xpc = open_xpc_udp(params);

    % Read Decoders and other files
    params = load_decoders(params);    
    params = measure_force_offsets(params);
    assignin('base','params',params);

    % Initialization

    %globals
    ave_op_time = 0.0;
    bin_count = 0;
    reached_cycle_t = false;
    w = Words;

    % data structure to store inputs
    data = get_default_data(params);

    % Setup figures
    handles = setup_display_plots(params);
    handles = get_new_filename(params,handles);

    % Start data streaming
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

    % Setup data files and directories for recording
    % handles = setup_datafiles(params,handles,data,offline_data,w);

    %
    t_buf = tic; %data buffering timer
    drawnow;

    % Run cycle
%     try
        params = evalin('base','params');
        recording = 0;

        while(~get(handles.stop_bmi,'Value') && ... 
                ( params.online || ...
                    ~params.online && bin_count < max_cycles) )
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
                clc
                % timers and counters
                cycle_t = toc(t_buf); %this should be equal to bin_size, but may be longer if last cycle operations took too long.
                t_buf   = tic; % reset buffering timer
                bin_count = bin_count +1;
                
                if strcmp(params.mode,'N2E')
                    params.current_decoder = params.N2E_decoder;
                elseif strcmp(params.mode,'Vel')
                    params.current_decoder = params.vel_decoder;
                else
                    params.current_decoder = params.N2E_decoder;
                end

                % Get and Process New Data
                data = get_new_data(params,data,offline_data,bin_count,cycle_t,w,xpc,m_data_2);
                
                if size(data.spikes,1)<params.n_lag
                    data.spikes = zeros(params.n_lag,params.n_neurons);
                end
                % Predictions
                if strcmp(params.mode,'N2E')
                    predictions = [1 rowvec(data.spikes(1:params.n_lag,:))']*params.N2E_decoder.H;
                elseif strcmp(params.mode,'Vel')
                    predictions = [1 rowvec(data.spikes(1:params.n_lag,:))']*params.vel_decoder.H;
                    m_data_1.Data.vel_predictions = predictions;
                else
                    predictions = [];
                end
                [EMG_data,~,~] = process_emg(params,data,predictions);

                m_data_1.Data.EMG_data = EMG_data;
                
                if strncmpi(params.mode,'iso',3) % ...if task was isometric
                    cursor_pos = -params.force_to_cursor_gain*data.handleforce;
                else % ...if task was a movement task
                    cursor_pos = m_data_2.Data.x_hand;                       
                end

                bin_start_t = data.sys_time;

                if recording
                    if isempty(data.spikes)
                        spikes = [];
                    else
                        spikes = data.spikes(1,:);
                    end
                    tmp_data = [bin_start_t spikes cursor_pos ...
                        m_data_2.Data.shoulder_pos m_data_2.Data.elbow_pos ...
                        EMG_data m_data_2.Data.F_end m_data_2.Data.musc_force]; 
                    save(handles.data_file,'tmp_data','-append','-ascii');
                end

                if exist('xpc','var')
                    % send predictions to xpc
                    if ~strncmpi(params.mode,'iso',3)
                        shoulder_pos = m_data_2.Data.shoulder_pos;
                        elbow_pos = m_data_2.Data.elbow_pos;
                    else
                        shoulder_pos = cursor_pos;
                        elbow_pos = cursor_pos;
                    end
                    fwrite(xpc.xpc_write, [1 1 cursor_pos shoulder_pos elbow_pos],'float32');
                    fprintf('%.2f\t%.2f\n',cursor_pos);
                end


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

%     catch e
%         if params.online
%             if params.save_data
%                 cbmex('fileconfig', handles.cerebus_file, '', 0);
%             end
%             cbmex('close');
%         end
%         m_data_1.Data.bmi_running = 0;
%         echoudp('off');
%         fclose('all');
%         close all;
%         rethrow(e);
%     end

end
