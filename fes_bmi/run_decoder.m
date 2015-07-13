function varargout = run_decoder(varargin)
% run_decoder: This function connects to the Cerebus stream via
% the Central application, produces prediction by a two step
% process in which spike trains predict emgs and emgs predict forces.
% the emg-to-force decoder is expected to be precomputed and passed as
% EMG2F_w weight matrix. The spikes to EMG weight matrix is trained online
% and it uses the backpropagated discrepancy between the predicted forces
% and the target position in the task.
%
% INPUTS : Additional parameters: "params" structure -> see adapt_params_defaults.m


%% Parameters
if nargin
    params = varargin{1};
    params = bmi_params_defaults(params);
else
    params = bmi_params_defaults;
end

%% UDP port for XPC
xpc = open_xpc_udp(params);

%% Read Decoders and other files

[neuron_decoder,emg_decoder,params] = load_N2E2F_decoders(params);
% decoders = load_decoders(params);
if isempty(neuron_decoder)
    if params.online, clearxpc; end
    return;
end

% load template trajectories
if params.cursor_assist
    % cursor_traj is a file name to a structure containing the fields
    % 'mean_paths' and 'back_paths', each of size < 101 x 2 x n_tgt >
    cursor_traj = load(params.cursor_traj);
end

% check that there's no error in the stimulation parameters 
if strcmpi(params.output,'stimulator')
    params = check_bmi_fes_settings( neuron_decoder, params );
end

%% Initialization

%globals
ave_op_time = 0.0;
bin_count = 0;
reached_cycle_t = false;
cursor_pos = [0 0];
w = Words;
handles = [];

% data structure to store inputs
[data,data_buffer,offline_data,params] = init_bmi_data(params);
          
%% Setup figures

handles.keep_running = msgbox('Click ''ok'' to stop the BMI','BMI Controller');
set(handles.keep_running,'Position',[200 700 125 52]);

if params.display_plots
    handles.fh = figure;
    set(handles.fh,'Color','k','MenuBar','none','name','BMI cursor output');

    hold on;
    tgt_handle  = plot(0,0,'rs');
    set(tgt_handle,'LineWidth',2,'MarkerSize',30,'MarkerFaceColor','r');
    set(gca,'color','k');    
    curs_handle = plot(0,0,'yo');
    
    set(curs_handle,'MarkerSize',10,'MarkerFaceColor','y','MarkerEdgeColor','y');
    xlim([-12 12]); ylim([-12 12]);
    axis square; axis equal; axis manual;

%     xpred_disp = annotation(gcf,'textbox', [0.65 0.85 0.16 0.05],...
%     'FitBoxToText','off','String',sprintf('xpred: %.2f',cursor_pos(1)));
%     ypred_disp = annotation(gcf,'textbox', [0.65 0.79 0.16 0.05],...
%     'FitBoxToText','off','String',sprintf('ypred: %.2f',cursor_pos(2)));
end

if strcmpi(params.output,'stimulator')
    ffes.fh = figure('Name','FES commands');
    ffes = stim_fig( ffes, [], [],  params.bmi_fes_stim_params, 'init' );
end

if ~params.online
    prog_bar = waitbar(0, sprintf('Replaying Offline Data'));
end
%% Setup data files and directories for recording
if params.save_data
    handles = setup_recordings(params,handles);
end
%% Start data streaming
if params.online
    handles = start_cerebus_stream(params,handles,xpc);
    max_cycles = 0;
    offline_data = [];
  
    bin_start_t = 0.0; % time at beginning of next bin
        
    %start cerebus file recording :
    cbmex('fileconfig', handles.cerebus_file, '', 1);
    data.sys_time = cbmex('time');

    % start data buffering
    cbmex('trialconfig',1,'nocontinuous');
else
    %Binned Data File
    max_cycles = length(offline_data.timeframe);
    bin_start_t = double(offline_data.timeframe(1));
end

t_buf   = tic; %data buffering timer
drawnow;

%% Run cycle
try
    while( ishandle(handles.keep_running) && ...
            ( params.online || ...
                ~params.online && bin_count < max_cycles) )
        
        if (reached_cycle_t)
            %% timers and counters
            cycle_t = toc(t_buf); %this should be equal to bin_size, but may be longer if last cycle operations took too long.
            t_buf   = tic; % reset buffering timer
            bin_count = bin_count +1;
            
            %% Get and Process New Data
            data = get_new_data(params,data,offline_data,bin_count,cycle_t,w);
            
            %% Predictions
            pred = [1 rowvec(data.spikes(1:params.n_lag,:))']*neuron_decoder.H;
            
            % high-pass filtering
            if params.hp_rc
                pred = pred*(params.hp_rc/(params.hp_rc+params.binsize));
            end
            
            if strcmp(params.mode,'emg_cascade') %emg cascade
                % apply sigmoid?
                if params.sigmoid pred = sigmoid(pred,'direct'); end
%                 % remove negative emg preds
%                 pred(pred<0) = 0;
                % store new emg preds
                data.emgs = [pred; data.emgs(1:end-1,:)];
                % force predictions:
                data.curs_pred = rowvec(data.emgs(:))'*emg_decoder.H;
            elseif strcmp(params.mode,'emg_only') 
                data.emgs = pred;
            else
                if strcmpi(neuron_decoder.decoder_type,'N2V')
                    if any( isnan(data.curs_pred)) data.curs_pred = [0 0]; end
                    data.curs_pred = data.curs_pred + pred(1:2)*params.binsize;
                else
                    data.curs_pred = pred;
                end
            end
            
            % bound predictions to monitor screen?
            cursor_pos = sign(data.curs_pred).*min(sign(data.curs_pred).*data.curs_pred,params.pred_bounds);
                
            %% Output
            if params.cursor_assist
                [cursor_pos,data] = cursor_assist(data,cursor_pos,cursor_traj);
                data.curs_act = cursor_pos;
            else
                %normal behavior, cursor mvt based on predictions
                cursor_pos = data.curs_pred;
            end
            
            if strcmpi(params.output,'xpc')
                % send predictions to xpc
                fwrite(xpc, [1 1 cursor_pos],'float32');
            end
            
            if strcmpi(params.output,'stimulator')
                [data.stim_PW,data.stim_amp] = EMG_to_stim( data.emgs, params.bmi_fes_stim_params );
                stim_cmd = stim_elect_mapping( data.stim_PW, data.stim_amp,params.bmi_fes_stim_params );
                ffes = stim_fig( ffes, data.stim_PW,data.stim_amp, params.bmi_fes_stim_params, 'exec' ); 
                if params.online, xippmex( 'stimseq', stim_cmd ), end;
            end
            
            %% Neurons-to-EMG Adaptation
            if params.adapt
                switch params.adapt_params.type
                    case 'normal'
                        % fixed expected emg value for each muscle and each target
                        [data_buffer,data,neuron_decoder] = decoder_adaptation_N2E2F(params,data,bin_count,data_buffer,neuron_decoder);
                    case 'N2F_target'
                        % adaptation of neuron to force decoder using target force
                        [data_buffer,data,neuron_decoder] = decoder_adaptation_N2F_target(params,data,bin_count,data_buffer,neuron_decoder);
                    case 'tvp'
                        % time-varying emg patterns for each target
                        [data_buffer,data,neuron_decoder] = decoder_adaptation_N2E2F_traj(params,data,bin_count,data_buffer,neuron_decoder);
                    case 'supervised'
                        % adapt using actual force
                        [data_buffer,data,neuron_decoder] = decoder_adaptation_supervised(params,data,bin_count,data_buffer,neuron_decoder);
                    otherwise
                        error('Unknown decoder adaptation type : %s',params.adapt_params.adapt_type);
                end     
            end
                
            %% Save and display progress
            
            % save adapting decoder every 30 seconds
            if params.adapt && (mod(bin_count*params.binsize, 30) == 0)
                %                 save([params.save_dir '\previous_trials_' strrep(strrep(datestr(now),':',''),' ','-')], 'previous_trials','neuron_decoder');
                if params.save_data
                    save( [handles.adapt_dir '\Adapt_decoder_' (datestr(now,'yyyy_mm_dd_HHMMSS'))],'-struct','neuron_decoder');
                end
                if params.online
                    fprintf('Average Matlab Operation Time : %.2fms\n',ave_op_time*1000);
                else
                    prog = bin_count/max_cycles;
                    waitbar(prog,prog_bar);
%                     fprintf('Progress: %.0f %%\n',100*prog);
                end
            end
                  
            % save raw data
            if params.save_data
                % spikes are timed from beginning of this bin
                % because they occured in the past relatively to now
                tmp_data = [bin_start_t data.spikes(1,:)];
                save(handles.spike_file,'tmp_data','-append','-ascii');
                % the rest of the data is timed with end of this bin
                % because they are predictions made just now.
                bin_start_t = data.sys_time;
                if ~strcmp(params.mode,'direct')
                    tmp_data   = [bin_start_t double(data.emgs(1,:))];
                    save(handles.emg_file,'tmp_data','-append','-ascii');
                end
                if strcmp(params.output,'stimulator')
                    tmp_data   = [bin_start_t double(data.stim_PW) double(data.stim_amp)];
                    save(handles.stim_out_file,'tmp_data','-append','-ascii');
                end
                tmp_data = [bin_start_t double(cursor_pos)];
                save(handles.curs_pos_file,'tmp_data','-append','-ascii');
                tmp_data = [bin_start_t double(data.curs_pred)];
                save(handles.curs_pred_file,'tmp_data','-append','-ascii');
            end
            
            % each second show adaptation progress
            if mod(bin_count*params.binsize, 1) == 0 && params.realtime
                disp([sprintf('Time: %d secs, ', bin_count*params.binsize) ...
                      'Adapting: ' num2str(~data.fix_decoder) ', ' ...
                      'Online: ' num2str(params.online)]);
%                     'prediction corr: ' num2str(last_20R)]);
            end
            
            %display targets and cursor plots
            if params.display_plots && ~isnan(any(data.tgt_pos)) && ishandle(curs_handle)
                
%                 set(curs_handle,'XData',cursor_pos(1),'YData',cursor_pos(2));
                set(curs_handle,'XData',data.curs_pred(1),'YData',data.curs_pred(2));
%                 
%                 set(xpred_disp,'String',sprintf('xpred: %.2f',predictions(1)))
%                 set(ypred_disp,'String',sprintf('ypred: %.2f',predictions(2)))

                if data.tgt_on
                    set(tgt_handle,'XData',data.tgt_pos(1),'YData',data.tgt_pos(2),'Visible','on');
                else
                    set(tgt_handle,'Visible','off');
                end
                
                if  data.adapt_trial && ~data.fix_decoder
                    display_color = 'b';
                else
                    display_color = 'y';
                end
                set(curs_handle,'MarkerEdgeColor',display_color,'MarkerFaceColor',display_color);
            end
            
            %% Wrapping up            
            % flush pending events
            drawnow;
            %check elapsed operation time
            et_op = toc(t_buf);
            ave_op_time = ave_op_time*(bin_count-1)/bin_count + et_op/bin_count;
            if et_op>0.05 && params.print_out
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
    else
        close(prog_bar);
    end
    echoudp('off');
    fclose('all');
    if ishandle(handles.keep_running)
        close(handles.keep_running);
    end
    if isfield(handles,'fh')
        if ishandle(handles.fh)
            close(handles.fh);
        end
    end
    
catch e
    if params.online
        if params.save_data
            cbmex('fileconfig', handles.cerebus_file, '', 0);
        end
        cbmex('close');
    else
        close(prog_bar);
    end
    echoudp('off');
    fclose('all');
    if ishandle(handles.keep_running)
        close(handles.keep_running);
    end
    if isfield(handles,'fh')
        if ishandle(handles.fh)
            close(handles.fh);
        end
    end
    rethrow(e);
end


%% optionally Save decoder at the end
if params.adapt
    % auto save:
%     dec_dir = [params.save_dir filesep datestr(now,'yyyy_mm_dd')];
%     if ~isdir(dec_dir)
%         mkdir(dec_dir);
%     end
%     filename = [dec_dir filesep 'Adapted_decoder_' (datestr(now,'yyyy_mm_dd_HHMMSS')) '_End.mat'];
%     save(filename,'-struct','neuron_decoder');
%     fprintf('Saved Decoder File :\n%s\n',filename);
%     assignin('base','new_decoder_str',filename);
%     assignin('base','new_decoder',neuron_decoder);

%     %Save dialog
%         dec_dir = [params.save_dir];
%         filename = ['Adapted_decoder_' (datestr(now,'yyyy_mm_dd_HHMMSS')) '_End.mat'];
%         [filename, filepath] = uiputfile(fullfile(dec_dir,filename),'Save your new decoder');
%     if filepath
%         save(fullfile(filepath,filename),'-struct','neuron_decoder');
%         fprintf('Saved Decoder File :\n%s\n',filename);
%         assignin('base','new_decoder_str',filename);
%         assignin('base','new_decoder',neuron_decoder);
%     else
%         disp('Decoder not saved');
%     end
end

varargout = {neuron_decoder};
end

%% Accessory Functions :

function data = get_new_data(params,data,offline_data,bin_count,bin_dur,w)
    if params.online
        % read and flush data buffer
        ts_cell_array = cbmex('trialdata',1);
        data.sys_time = cbmex('time');
        new_spikes = get_new_spikes(ts_cell_array,params,bin_dur);
        [new_words,new_target,data.db_buf] = get_new_words(ts_cell_array{151,2:3},data.db_buf);
    else
        data.sys_time = double(offline_data.timeframe(bin_count));
        [~,spike_idx,~] = intersect(offline_data.neuronIDs,params.neuronIDs,'rows','stable');
        new_spikes = offline_data.spikeratedata(bin_count,spike_idx)';
        new_words  = offline_data.words(offline_data.words(:,1)>= data.sys_time & ...
            offline_data.words(:,1) < data.sys_time+params.binsize,:);
        new_target = offline_data.targets.corners(offline_data.targets.corners(:,1)>= data.sys_time & ...
            offline_data.targets.corners(:,1)< data.sys_time+params.binsize,2:end);
        data.curs_act = offline_data.cursorposbin(bin_count,:);
    end

    data.spikes = [new_spikes'; data.spikes(1:end-1,:)];
    data.ave_fr = data.ave_fr*(bin_count-1)/bin_count + mean(new_spikes)/bin_count;
    num_new_words = size(new_words,1);
    data.words  = [new_words;     data.words(1:end-num_new_words,:)];

    if ~isempty(new_target)
        data.pending_tgt_pos  = [ (new_target(3)+new_target(1))/2 ...
            (new_target(4)+new_target(2))/2 ];
        data.pending_tgt_size = [   new_target(3)-new_target(1) ...
            new_target(2)-new_target(4) ];
        %                 fprintf('tgt from db: %d\n',get_tgt_id(new_target(2:end)));
    end

    if ~isempty(new_words)
        for i=1:size(new_words,1)
            % new word Start
            if new_words(i,2) == w.Start
                data.traj_pct = 0;
                data.tgt_id   = nan;
                data.trial_count = data.trial_count+1;
                if ~params.online && params.adapt
                    data.adapt_trial = true;
                end
                if strcmp(params.adapt_params.type,'supervised_full')
                    data.adapt_flag = true;
                end
            end
            
            % new word Ot_On?
            if bitand(hex2dec('F0'),new_words(i,2))==w.OT_On
                data.tgt_id   = bitand(hex2dec('0F'),new_words(i,2))+1;
                data.tgt_ts   = new_words(i,1);
                if params.online
                    % until we can get the tgt info from databurst:
                    [data.tgt_pos,data.tgt_size] = get_default_tgt_pos_size(data.tgt_id);
                else
                    data.tgt_pos  = data.pending_tgt_pos;
                    data.tgt_size = data.pending_tgt_size;
                end
                data.tgt_bin  = bin_count;
                data.tgt_on   = true;
            end
            % new word CT_ON?
            if new_words(i,2) == w.CT_On
                data.tgt_id   = 0;
                data.tgt_ts   = new_words(i,1);
                %Center target, always at [0 0];
                [data.tgt_pos,data.tgt_size] = get_default_tgt_pos_size(data.tgt_id);
                data.tgt_bin  = bin_count;
                data.tgt_on   = true;
                % fprintf('CT_on\n');
            end
            % Adapt word
            if new_words(i,2)==w.Adapt
                data.adapt_trial = true;
                % fprintf('Adapt Trial\n');
            end
            if new_words(i,2) == w.Catch
                %catch_flag?
            end
            % End trial
            if w.IsEndWord(new_words(i,2))
                % offline, only on successful trials, but all trials online
                if data.adapt_trial && (params.online || new_words(i,2)==w.Reward)
                    if ~strcmp(params.adapt_params.type,'supervised_full')
                        data.adapt_flag = true;
                    end
                end
                data.adapt_trial = false;
                data.tgt_on      = false;
                data.effort_flag = false;
            end
        end
    end
end                
function new_spikes = get_new_spikes(ts_cell_array,params,binsize)

    new_spikes = zeros(params.n_neurons,1);
    new_ts = ts_cell_array(params.neuronIDs(:,1),:);
 
    %firing rate for new spikes
    for i = 1:params.n_neurons
        unit = params.neuronIDs(i,2);
        new_spikes(i) = length(new_ts{i,unit+2})/binsize;
    end

%     %remove artifact (80% of neurons have spikes for this bin)
%     while (length(nonzeros(new_spikes))>.8*params.n_neurons)
%         warning('artifact detected, spikes removed');
%         new_spikes(new_spikes>0) = new_spikes(new_spikes>0) - 1/binsize;
%     end
    
    % remove artifacts (high freq thresh x-ing)
    % by capping FR at 400 Hz
    if any(new_spikes>400)
        new_spikes(new_spikes>400) = 400;
        warning('noise detected, FR capped at 400 Hz');
    end
end
function [new_words, new_target, db_buf] = get_new_words(new_ts,new_words,db_buf)
    if ~isempty(new_ts)
        all_words = [new_ts, uint32(bitshift(bitand(hex2dec('FF00'),new_words),-8))];
        all_words = all_words(logical(all_words(:,2)),:);

        min_db_val = hex2dec('F0');
        max_db_val = hex2dec('FF');
        
        % behavior words:
        new_words = double(all_words( all_words(:,2) < min_db_val, :));
        
        %Todo: debug this following code. It kind of works, but there is
        %sometimes duplicate or missing bits when databursts are split
        %between two cycles (which is most of the time!)
%         % databursts:
          new_db = [];
          new_target = [];
%         new_db = all_words( all_words(:,2) >= min_db_val & all_words(:,2) <= max_db_val, :);
% 
%         if isempty(new_db)
%             %no databurst this time
%             if ~isempty(db_buf)
%                 % we should have received more bytes
%                 warning('missing databurst bytes, databurst info discarded');
%             end
%             new_target = [];
%             db_buf = [];
%         else
%             try
%                 if ~isempty(db_buf)
%                     % continue filling databurst buffer started previous bin
%                     num_bytes = (db_buf(1,2) - min_db_val) + 16*(db_buf(2,2) - min_db_val);
%                 else
%                     num_bytes = (new_db(1,2) - min_db_val) + 16*(new_db(2,2) - min_db_val);
%                 end
% 
% 
%                 db_buf = [db_buf; new_db];
% 
%                 if size(db_buf,1) >= num_bytes*2
%                     if size(db_buf,1)>num_bytes*2
%                         fprintf('extra bytes in databurst (%d out of %d)\n',size(db_buf,1),num_bytes*2);
%                     end
%                     % we have the whole data burst, process and flush.
%                     raw_bytes  = db_buf(1:num_bytes*2, 2);
%                     half_bytes = reshape(raw_bytes,2,[]) - min_db_val;
%                     databurst  = double(16*half_bytes(2,:) + half_bytes(1,:));
%                     new_target = bytes2float(databurst(num_bytes-15:end))';
%                     db_buf = [];
%                 else
%                     % partial databurst, wait for next bin for rest of databurst
%                     new_target = [];
%                 end
%             catch e
%                 warning('error reading databurst, no target info extracted');
%                 new_target = [NaN NaN NaN NaN];
%                 db_buf = [];
%             end
%         end
    else
        if ~isempty(db_buf)
            % we should have received more bytes
            warning('missing databurst bytes, databurst info discarded');
        end
        new_target = [];
        db_buf = [];
    end
end
