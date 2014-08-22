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
if strcmpi(params.output,'xpc')
    XPC_IP   = '192.168.0.1';
    XPC_PORT = 24999;
    echoudp('on',XPC_PORT);
    xpc = udp(XPC_IP,XPC_PORT);
    set(xpc,'ByteOrder','littleEndian');
    set(xpc,'LocalHost','192.168.0.10');
    fopen(xpc);
end

%% Read Decoders and other files

[neuron_decoder, emg_decoder,params] = load_decoders(params);
if ~strcmp(params.mode,'direct')
    spike_buf_size = params.n_lag + params.n_lag_emg - 1; 
else
    spike_buf_size = params.n_lag;
end

% load template trajectories
if params.cursor_assist
    % cursor_traj is a file name to a structure containing the fields
    % 'mean_paths' and 'back_paths', each of size < 101 x 2 x n_tgt >
    cursor_traj = load(params.cursor_traj);
end

%% Initialization

%globals
ave_op_time = 0.0;
bin_count = 0;
reached_cycle_t = false;
cursor_pos = [0 0];
w = Words;

% data structure to store inputs
data = struct('spikes'      , zeros(spike_buf_size,params.n_neurons),...
              'ave_fr'      , 0.0,...
              'words'       , [],...
              'db_buf'      , [],...
              'emgs'        , zeros( params.n_lag_emg, params.n_emgs),...
              'adapt_trial' , false,...
              'adapt_bin'   , false,...
              'adapt_flag'  , false,...
              'tgt_on'      , false,...
              'tgt_bin'     , NaN,...
              'tgt_ts'      , NaN,...
              'tgt_id'      , NaN,...
              'tgt_pos'     , [NaN NaN],...
              'tgt_size'    , [NaN NaN],...
              'pending_tgt_pos' ,[NaN NaN],...
              'pending_tgt_size',[NaN NaN],...
              'sys_time'    , 0.0,...
              'fix_decoder' , false,...
              'effort_flag' , false,...
              'traj_pct'    , 0,...
              'trial_count' , 0);
          
% dataset to store older data for batch adaptation
data_buffer = dataset();                 
for i=params.batch_length
    data_buffer = [data_buffer;...
        dataset({{data.trial_count}, 'trial_number'}, ...
        {{data.spikes} ,'spikes'},...
        {{data.tgt_id} ,'tgt_id'},...
        {{data.tgt_pos},'tgt_pos'},...
        {{data.emgs}   ,'emg_pred'},...
        {{nan(1,params.n_forces)},'force_pred'})];%#ok<AGROW>
end


%% Setup figures

keep_running = msgbox('Click ''ok'' to stop the BMI','BMI Controller');
set(keep_running,'Position',[200 700 125 52]);

if params.display_plots
    curs_handle = plot(0,0,'ko');
    set(curs_handle,'MarkerSize',6,'MarkerFaceColor','k','MarkerEdgeColor','k');
    xlim([-12 12]); ylim([-12 12]);
    axis square; axis equal; axis manual;
    hold on;
    tgt_handle  = plot(0,0,'bo');
    set(tgt_handle,'LineWidth',2,'MarkerSize',15);
%     xpred_disp = annotation(gcf,'textbox', [0.65 0.85 0.16 0.05],...
%     'FitBoxToText','off','String',sprintf('xpred: %.2f',cursor_pos(1)));
%     ypred_disp = annotation(gcf,'textbox', [0.65 0.79 0.16 0.05],...
%     'FitBoxToText','off','String',sprintf('ypred: %.2f',cursor_pos(2)));
end

%% Setup data files and directories for recording
if params.save_data
        
        if params.online
            date_str = datestr(now,'yyyy_mm_dd_HHMMSS');
            filename = [params.save_name '_' date_str '_'];
            date_str = datestr(now,'yyyy_mm_dd');
        else
            [path_name,filename,~] = fileparts(params.offline_data);
            filename = [filename '_'];
            date_str = path_name(find(path_name==filesep,1,'last')+1:end);
        end

        save_dir = [params.save_dir filesep date_str];
        if ~isdir(save_dir)
            mkdir(save_dir);
        end
        
        if params.adapt
            adapt_dir = [save_dir filesep filename 'adapt_decoders'];
            conflict_dir = isdir(adapt_dir);
            num_iter = 1;
            while conflict_dir
                num_iter = num_iter+1;
                adapt_dir = sprintf('%s%d%s',[save_dir filesep filename 'adapt_decoders('],num_iter,')');
                conflict_dir = isdir(adapt_dir);
            end
            mkdir(adapt_dir);
        end
        
        %Setup files for recording parameters and neural and cursor data:
        save(            fullfile(save_dir, [filename 'params.mat']),'-struct','params');
        spike_file     = fullfile(save_dir, [filename 'spikes.txt']);
        if ~strcmp(params.mode,'direct')
            emg_file   = fullfile(save_dir, [filename 'emgpreds.txt']);
        end
        curs_pred_file = fullfile(save_dir, [filename 'curspreds.txt']);
        curs_pos_file  = fullfile(save_dir, [filename 'cursorpos.txt']);     
end

%% Start data streaming
if params.online   
    % Cerebus Stream via Central
    connection = cbmex('open',1);
    if ~connection
        echoudp('off');
        if exist('xpc','var')
            fclose(xpc);
            delete(xpc);
        end
        close(keep_running);
        error('Connection to Central Failed');
    end
    max_cycles = 0;
    offline_data = [];
    
    if params.save_data
        cerebus_file   = fullfile(save_dir, filename);
        cbmex('fileconfig', cerebus_file, '', 0);% open 'file storage' app, or stop ongoing recordings
        drawnow; %wait until the app opens
        drawnow; %wait some more to be sure. if app was closed, it did not always start recording otherwise
        bin_start_t = 0.0; % time at beginning of next bin
        
        %start cerebus file recording :
        cbmex('fileconfig', cerebus_file, '', 1);
        data.sys_time = cbmex('time');
    end    
    % start data buffering
    cbmex('trialconfig',1,'nocontinuous');
else
    %Binned Data File
    offline_data = LoadDataStruct(params.offline_data);
    max_cycles = length(offline_data.timeframe);
    bin_start_t = double(offline_data.timeframe(1));
end

t_buf   = tic; %data buffering timer
drawnow;

%% Run cycle
try
    while( ishandle(keep_running) && ...
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
            predictions = [1 rowvec(data.spikes(1:params.n_lag,:))']*neuron_decoder.H;
%             predictions = sigmoid([1 rowvec(data.spikes(1:params.n_lag,:))']*neuron_decoder.H,'direct',params.N2Esig);
            
            if ~strcmp(params.mode,'direct')
                % emg cascade
                data.emgs = [predictions; data.emgs(1:end-1,:)];
%                 predictions = [1 rowvec(data.emgs(:))']*emg_decoder.H;
                predictions = rowvec(data.emgs(:))'*emg_decoder.H;
            end
            
            %% Cursor Output
            if params.cursor_assist
                [cursor_pos,data] = cursor_assist(data,cursor_pos,cursor_traj);
            else
                %normal behavior, cursor mvt based on predictions
                cursor_pos = predictions;
            end

            if exist('xpc','var')
                % send predictions to xpc
                fwrite(xpc, [1 1 cursor_pos],'float32');
            end
            
            %% Neurons-to-EMG Adaptation
            if params.adapt
                [data_buffer,data,neuron_decoder] = decoder_adaptation2(params,data,bin_count,data_buffer,neuron_decoder,emg_decoder,predictions);
            end
                
            %% Save and display progress
            
            % save adapting decoder every 30 seconds
            if params.adapt && (mod(bin_count*params.binsize, 30) == 0)
                %                 save([params.save_dir '\previous_trials_' strrep(strrep(datestr(now),':',''),' ','-')], 'previous_trials','neuron_decoder');
                if params.save_data
                    save( [adapt_dir '\Adapt_decoder_' (datestr(now,'yyyy_mm_dd_HHMMSS'))],'-struct','neuron_decoder');
                end
                if params.online
                    fprintf('Average Matlab Operation Time : %.2fms\n',ave_op_time*1000);
                else
                    prog = bin_count/max_cycles;
                    fprintf('Progress: %.0f %%\n',100*prog);
                end
            end
            
                
            
            % save raw data
            if params.save_data
                % spikes are timed from beginning of this bin
                % because they occured in the past relatively to now
                tmp_data = [bin_start_t data.spikes(1,:)];
                save(spike_file,'tmp_data','-append','-ascii');
                % the rest of the data is timed with end of this bin
                % because they are predictions made just now.
                bin_start_t = data.sys_time;
                if ~strcmp(params.mode,'direct')
                    tmp_data   = [bin_start_t double(data.emgs(1,:))];
                    save(emg_file,'tmp_data','-append','-ascii');
                end
                tmp_data = [bin_start_t double(cursor_pos)];
                save(curs_pos_file,'tmp_data','-append','-ascii');
                tmp_data = [bin_start_t double(predictions)];
                save(curs_pred_file,'tmp_data','-append','-ascii');
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
                set(curs_handle,'XData',predictions(1),'YData',predictions(2));
%                 
%                 set(xpred_disp,'String',sprintf('xpred: %.2f',predictions(1)))
%                 set(ypred_disp,'String',sprintf('ypred: %.2f',predictions(2)))

                if data.tgt_on
                    set(tgt_handle,'XData',data.tgt_pos(1),'YData',data.tgt_pos(2),'Visible','on');
                else
                    set(tgt_handle,'Visible','off');
                end
                
                if  data.adapt_trial && ~data.fix_decoder
                    display_color = 'r';
                else
                    display_color = 'k';
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
            cbmex('fileconfig', cerebus_file, '', 0);
        end
        cbmex('close');
    end
    echoudp('off');
    fclose('all');
    if ishandle(keep_running)
        close(keep_running);
    end
    close all;
    
catch e
    if params.online
        if params.save_data
            cbmex('fileconfig', cerebus_file, '', 0);
        end
        cbmex('close');
    end
    echoudp('off');
    fclose('all');
    if ishandle(keep_running)
        close(keep_running);
    end
    close all;
    rethrow(e);
end


%% optionally Save decoder at the end
if params.adapt
%     YesNo = questdlg('Would you like to save the adapted decoder?','Save Decoder?','Yes','No','Yes');
    YesNo = 'Yes';
    if strcmp(YesNo,'Yes')
        dec_dir = [params.save_dir filesep datestr(now,'yyyy_mm_dd')];
        if ~isdir(dec_dir)
            mkdir(dec_dir);
        end
        filename = [dec_dir filesep 'Adapted_decoder_' (datestr(now,'yyyy_mm_dd_HHMMSS')) '_End.mat'];
        save(filename,'-struct','neuron_decoder');
        fprintf('Saved Decoder File :\n%s\n',filename);
        assignin('base','new_decoder',filename);        
    else
        disp('Decoder not saved');
    end
end

varargout = {neuron_decoder};
end

%% Accessory Functions :
function [neuron_decoder,emg_decoder,params] = load_decoders(params)
    switch params.mode
        case 'emg_cascade'
            if strncmp(params.neuron_decoder,'new',3)
                % create new neuron decoder from scratch
                neuron_decoder = struct(...
                    'P'        , [] ,...
                    'neuronIDs', params.neuronIDs,...
                    'binsize'  , params.binsize,...
                    'fillen'   , params.binsize*params.n_lag);
                if strcmp(params.neuron_decoder,'new_rand')
                    neuron_decoder.H = randn(1 + params.n_neurons*params.n_lag, params.n_emgs)*0.00001;
                elseif strcmp(params.neuron_decoder,'new_zeros')
                    neuron_decoder.H = zeros(1 + params.n_neurons*params.n_lag, params.n_emgs);
                end
            else
                % load existing neuron decoder
                neuron_decoder = LoadDataStruct(params.neuron_decoder);
                if ~isfield(neuron_decoder, 'H')
                    disp('Invalid neuron-to-emg decoder');
                    return;
                end
                % overwrite parameters according to loaded decoder
                params.n_lag     = round(neuron_decoder.fillen/neuron_decoder.binsize);
                params.n_neurons = size(neuron_decoder.neuronIDs,1);
                params.binsize   = neuron_decoder.binsize;
                params.neuronIDs = neuron_decoder.neuronIDs;
            end
            
            % load existing emg decoder
            emg_decoder = LoadDataStruct(params.emg_decoder);
            if ~isfield(emg_decoder, 'H')
                error('Invalid emg-to-force decoder');
            end
            params.n_lag_emg = round(emg_decoder.fillen/emg_decoder.binsize);
%             params.n_emgs = round((size(emg_decoder.H,1)-1)/params.n_lag_emg);
            if round(emg_decoder.binsize*1000) ~= round(neuron_decoder.binsize*1000) 
                error('Incompatible binsize between neurons and emg decoders');
            end
            if params.n_emgs ~= size(neuron_decoder.H,2)
                error(sprintf(['The number of outputs from the neuron_decoder (%d) does not match\n' ...
                               'the number of inputs of the emg_decoder...(%d).'],...
                               size(neuron_decoder.H,2),params.n_emgs));
            end
            params.n_forces = size(emg_decoder.H,2);
        case 'direct'
            neuron_decoder = LoadDataStruct(params.neuron_decoder);
            if ~isfield(neuron_decoder, 'H')
                error('Invalid Decoder');
            end
            % overwrite parameters according to loaded decoder            
            params.n_lag = round(neuron_decoder.fillen/neuron_decoder.binsize);
            params.n_neurons = size(neuron_decoder.neuronIDs,1);
            params.binsize   = neuron_decoder.binsize;
            params.neuronIDs = neuron_decoder.neuronIDs;
            emg_decoder = [];
            params.n_emgs = 0;
            params.n_lag_emg = 0;
        otherwise
            error('Invalid decoding mode. Please specifiy params.mode = [''emgcascade'' | ''direct'' ]');
    end

end
function data = get_new_data(params,data,offline_data,bin_count,bin_dur,w)
    if params.online
        % read and flush data buffer
        ts_cell_array = cbmex('trialdata',1);
        data.sys_time = cbmex('time');
        new_spikes = get_new_spikes(ts_cell_array,params,bin_dur);
        [new_words,new_target,data.db_buf] = get_new_words(ts_cell_array{151,2:3},data.db_buf);
    else
        data.sys_time = double(offline_data.timeframe(bin_count));
        [~,spike_idx,~] = intersect(offline_data.neuronIDs,params.neuronIDs,'rows');
        new_spikes = offline_data.spikeratedata(bin_count,spike_idx)';
        new_words  = offline_data.words(offline_data.words(:,1)>= data.sys_time & ...
            offline_data.words(:,1) < data.sys_time+params.binsize,:);
        new_target = offline_data.targets.corners(offline_data.targets.corners(:,1)>= data.sys_time & ...
            offline_data.targets.corners(:,1)< data.sys_time+params.binsize,2:end);
    end

    data.spikes = [new_spikes'; data.spikes(1:end-1,:)];
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
                if ~params.online
                    data.adapt_trial = true;
                end
            end
            
            % new word Ot_On?
            if bitand(hex2dec('F0'),new_words(i,2))==w.OT_On
                data.tgt_id   = bitand(hex2dec('0F'),new_words(i,2))+1;
                data.tgt_ts   = new_words(i,1);
%                 data.tgt_pos  = data.pending_tgt_pos;
%                 data.tgt_size = data.pending_tgt_size;
                [data.tgt_pos,data.tgt_size] = get_default_tgt_pos_size(data.tgt_id);
                data.tgt_bin  = bin_count;
                data.tgt_on   = true;
                data.pending_tgt_pos = [NaN NaN];
                data.pending_tgt_size= [NaN NaN];
                % fprintf('OT_on : %d\n',new_tgt_id);
            end
            % new word CT_ON?
            if new_words(i,2) == w.CT_On
                data.tgt_id   = 0;
                data.tgt_ts   = new_words(i,1);
%                 data.tgt_pos  = [0 0];
%                 data.tgt_size = CT_size;
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
                if data.adapt_trial
                    data.adapt_flag = true;
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
function [tgt_pos,tgt_size] = get_default_tgt_pos_size(tgt_id)
    tgt_size = [4 4];
    def_tgt_pos  = [ 0      0;...
                     10      0;... 
                     7.07   7.07;...
                     0      10;...
                     -7.07  7.07;...
                     -10     0;...
                     -7.07  -7.07;...
                     0      -10;...
                     7.07   -7.07];
      tgt_pos = def_tgt_pos(tgt_id+1,:);
end
