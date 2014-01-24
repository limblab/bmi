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
    load(params.cursor_traj);
end


%% Initialization
%globals
adaptation_idx = 0;
bin_count = 0;
cursor_pos = [0 0];

% data structure to store inputs
data = struct('spikes'      , zeros(spike_buf_size,params.n_neurons),...
              'ave_fr'      , 0.0,...
              'words'       , [],...
              'db_buf'      , [],...
              'emgs'        , zeros( params.n_lag_emg, params.n_emgs),...
              'adapt_trial' , false,...
              'tgt_on'      , false,...
              'tgt_bin'     , NaN,...
              'tgt_ts'      , NaN,...
              'tgt_id'      , NaN,...
              'tgt_pos'     , [NaN NaN],...
              'tgt_size'    , [NaN NaN],...
              'pending_tgt_pos' ,[NaN NaN],...
              'pending_tgt_size',[NaN NaN],...
              'effort_flag' , false,...
              'traj_pct'    , 0 );
          
% dataset to store older data
previous_trials = dataset();
for i=params.batch_length
    previous_trials = [previous_trials;...
        dataset({bin_count, 'bin_count'}, ...
        {{data},'data'},...
        {data.tgt_id,'target_id'},...
        {nan(1,params.n_forces),'predictions'})];%#ok<AGROW>
end

if ~isdir(params.save_dir)
    mkdir(params.save_dir);
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

%% Setup data stream

if params.save_data
    %save parameters
    date_str = strrep(strrep(datestr(now),':',''),' ','-');
    save([params.save_dir '\Saved_Params_' date_str '.mat'] ,'-struct','params');
    % files to stream data:
    spike_file = [params.save_dir '\Spikes_' date_str '.txt'];
    if ~strcmp(params.mode,'direct')
        emg_file = [params.save_dir '\EMGPreds_' date_str '.txt'];
    end
    curs_pred_file = [params.save_dir '\CursorPreds_' date_str '.txt'];
    % cursor position may be different than prediction is cursor_assist is on
    curs_pos_file  = [params.save_dir '\CursorPos_' date_str '.txt'];
end

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

    data.ave_fr = calc_ave_fr(params);
    
    % Trigger Cerebus Recording
    if params.save_data
        cerebus_file = [params.save_dir '\Cerebus_File_' date_str];
        cbmex('fileconfig', cerebus_file, '', 0); % open 'file storage' app, or stop ongoing recordings
        drawnow; %wait until the app opens
        cbmex('fileconfig', cerebus_file, '', 1); % starts recording.
    end    
   
    % start data buffering
    cbmex('trialconfig',1,'nocontinuous');
else
    %Binned Data File
    offline_data = LoadDataStruct(params.offline_data);
    max_cycles = length(offline_data.timeframe);
    data.ave_fr = calc_ave_fr(params,offline_data);
end

t_buf   = tic; %data buffering timer

%% Run cycle
try
    while( ishandle(keep_running) && ...
            ( params.online || ...
                ~params.online && bin_count < max_cycles) )
        
        et_buf = toc(t_buf); %elapsed buffering time
        
        % reached cycle time?
        if (floor(et_buf/params.binsize)>= bin_count) || ...
             (~params.online && floor(et_buf*params.realtime/params.binsize)>= bin_count)
            cycle_t = t_buf; %this should be equal to bin_size, but may be longer if last cycle operations took too long.
            t_buf   = tic; % reset buffering timer
            t_op = tic; % reset operation timer
            bin_count = bin_count +1;
            
            % Get and Process New Data
            data = get_new_data(params,data,offline_data,bin_count,cycle_t);
            new_ave_fr = mean(mean(data.spikes));
            
            %% Predictions
            
            predictions = [1 rowvec(data.spikes(1:params.n_lag,:))']*neuron_decoder.H;
            
            if ~strcmp(params.mode,'direct')
                % emg cascade
                data.emgs = [predictions; data.emgs(1:end-1,:)];
                predictions = [1 rowvec(data.emgs(:))']*emg_decoder.H;                
            end
            
            %% Cursor Output
            if params.cursor_assist
                % cursor is moved towards outer target proportionally with ave fr.
                % maximum displacement is reached at new_ave_fr = 1.3*ave_fr;
                data.adapt_trial = true;
                pct_effort = (new_ave_fr-ave_fr)/ave_fr/0.3;
                if data.tgt_id
                    cursor_pos = pct_effort*data.tgt_pos;
                else
                    % tgt not on yet or next trial has started already
                    % make the cursor move around zero
                    cursor_pos = max([-1 -1],min([1 1],cursor_pos + 0.5*rand(1,2) - 0.25));
                end
                
% %                 % cursor is moved towards outer target automatically if effort is detected.
% %                 % full target trajectory if ave_fr reaches 1.25x baseline value.
% %                 data.adapt_trial = true; % always adapt during cursor assist
% %                 if data.tgt_on && data.tgt_id % outer target on
% %                     if ~data.effort_flag && new_ave_fr >= 1.25*data.ave_fr
% %                         data.effort_flag = true;
% %                         fprintf('effort detected\n');
% %                     end
% %                     if data.effort_flag
% %                         %increase trajectory by increments of 4% (25 bins to complete traj)
% %                         cursor_pos = mean_paths(data.traj_pct+1,:,data.tgt_id);
% %                         data.traj_pct = min(100,data.traj_pct+4);
% %                     else
% %                         %tgt on , but no effort detected yet, move around zeros, within center target
% %                         cursor_pos = max([-1 -1],min([1 1],cursor_pos + 0.5*rand(1,2) - 0.25));
% %                     end
% %                 elseif data.traj_pct && data.tgt_id
% %                     %tgt off but not back to center yet
% %                     cursor_pos = back_paths(101-data.traj_pct,:,data.tgt_id);
% %                     data.traj_pct = max(0,data.traj_pct-4);
% %                 else
% %                     % tgt not on yet, already completed back path, or next trial has started already
% %                     % make the cursor move around zero
% %                     cursor_pos = max([-1 -1],min([1 1],cursor_pos + 0.5*rand(1,2) - 0.25));
% %                 end
            else
                %normal behavior, cursor mvt based on predictions
                cursor_pos = predictions;           
            end

            if exist('xpc','var')
                % send predictions to xpc
                fwrite(xpc, [1 1 cursor_pos],'float32');
            end
            
            %% Neurons-to-EMG Adaptation
            if params.adapt_freeze && mod(bin_count*params.binsize,params.adapt_time+params.fixed_time)>=params.adapt_time
                fix_decoder = true;
            else
                fix_decoder = false;
            end
            
            % adapt trial and within adapt window?
            if data.adapt_trial && data.tgt_on && params.adapt && ~any(isnan(data.tgt_pos)) && ... 
                (bin_count - data.tgt_bin)*params.binsize >= params.delay && ...
                (bin_count - data.tgt_bin)*params.binsize <= (params.delay+params.duration)
                adapt_bin = true;
            else
                adapt_bin = false;
            end
            
            if adapt_bin
                % Save data for batch adapt
                previous_trials = [ dataset({bin_count, 'bin_count'}, ...
                                            {{data},'data'},...
                                            {data.tgt_id,'target_id'},...
                                            {predictions,'predictions'});...
                                        previous_trials(1:end-1,:)];              
                if ~fix_decoder
                   % gradient accumulator
                    accum_g = zeros(size(neuron_decoder.H));
                    accum_n = 0;
                    for trial = 1:params.batch_length
                        tmp_spikes = previous_trials.data{trial}.spikes;
                        tmp_emgs = previous_trials.data{trial}.emgs;
                        tmp_target_pos = previous_trials.data{trial}.tgt_pos;

                        accum_g = backpropagation_through_time(neuron_decoder.H, emg_decoder.H, ...
                            tmp_spikes, tmp_emgs, ...
                            tmp_target_pos(:)', ...
                            params.n_lag, params.n_lag_emg);
                        
%                         %??? temp: prevent divergence caused possibly by
%                         %floating point error? divide by 0 ????
%                         if any(any(accum_g))>100/params.LR
%                             high_weights = find(accum_g>100/params.LR);
%                             w   = num2str(accum_g(high_weights));
%                             w_i = num2str(high_weights);
%                             fprintf('super high weight(s) : %s\nDetected at indexes %s\n',w,w_i);
%                             accum_g(abs(accum_g)>100/params.LR) = 0;
%                         end

                        % count how many gradients we have accumulated
                        accum_n = accum_n + 1;
                    end
                    g = accum_g/accum_n;
                    neuron_decoder.H = neuron_decoder.H - params.LR*g;
                    adaptation_idx = adaptation_idx + 1;
                end
            end
                
            %% Save and display progress
            
            % save decoder every 30 seconds
            if mod(bin_count*params.binsize, 30) == 0
                %                 save([params.save_dir '\previous_trials_' strrep(strrep(datestr(now),':',''),' ','-')], 'previous_trials','neuron_decoder');
                save([params.save_dir '\Adapt_decoder_' strrep(strrep(datestr(now),':',''),' ','-')],'-struct','neuron_decoder');
            end
            
            % save raw data
            if params.save_data
                new_spikes = data.spikes(1,:);
                save(spike_file,'new_spikes','-append','-ascii');
                if ~strcmp(params.mode,'direct')
                    new_emgs   = double(data.emgs(1,:));
                    save(emg_file,'new_emgs','-append','-ascii');
                end
                new_curs = double(cursor_pos);
                save(curs_pos_file,'new_curs','-append','-ascii');
                new_preds = double(predictions);
                save(curs_pred_file,'new_preds','-append','-ascii');
            end
            
            % each second show adaptation progress
            if mod(bin_count*params.binsize, 1) == 0
                disp([sprintf('Time: %d secs, ', bin_count*params.binsize) ...
                      'Adapting: ' num2str(~fix_decoder) ', ' ...
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
                
                if  adapt_bin && ~fix_decoder
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
            et_op = toc(t_op); 
            if et_op>0.05
                fprintf('~~~~~~slow processing time: %.1f ms~~~~~~~\n',et_op*1000);
            end
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
    YesNo = questdlg('Would you like to save the adapted decoder?',...
                        sprintf('Adapted over %d bins',adaptation_idx),...
                        'Yes','No','Yes');
    if strcmp(YesNo,'Yes')
        filename = [params.save_dir '\Adapt_decoder_' strrep(strrep(datestr(now),':',''),' ','-') '_End.mat'];
        save(filename,'-struct','neuron_decoder');
        fprintf('Saved Decoder File :\n%s\n',filename); 
    else
        disp('Decoder not saved');
    end
end

end
    
function [neuron_decoder,emg_decoder,params] = load_decoders(params)
    switch params.mode
        case 'emg_cascade'
            if strncmp(params.neuron_decoder,'new',3)
                % create new neuron decoder from scratch
                neuron_decoder = struct(...
                    'P'        , [] ,...
                    'neuronIDs', [(1:params.n_neurons)' zeros(params.n_neurons,1)],...
                    'binsize'  , params.binsize,...
                    'fillen'   , params.binsize*params.n_lag);
                if strcmp(params.neuron_decoder,'new_rand')
                    neuron_decoder.H = randn(1 + params.n_neurons*params.n_lag, params.n_emgs)*0.00001;
                elseif strcmp(params.neuron_decoder,'new_zeros')
                    neuron_decoder.H = zeros(1 + params.n_neurons*params.n_lag, params.n_emgs);
                end
            else
                % load existing neuron decoder
                neuron_decoder = load(params.neuron_decoder);
                if ~isfield(neuron_decoder, 'H')
                    disp('Invalid neuron-to-emg decoder');
                    return;
                end
                % overwrite parameters according to loaded decoder
                params.n_lag     = round(neuron_decoder.fillen/neuron_decoder.binsize);
                params.n_neurons = size(neuron_decoder.neuronIDs,1);
                params.binsize   = neuron_decoder.binsize;
            end
            
            % load existing emg decoder
            emg_decoder = load(params.emg_decoder);
            if ~isfield(emg_decoder, 'H')
                error('Invalid emg-to-force decoder');
            end
            params.n_lag_emg = round(emg_decoder.fillen/emg_decoder.binsize);
            params.n_emgs = round((size(emg_decoder.H,1)-1)/params.n_lag_emg);
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
            neuron_decoder = load(params.neuron_decoder);
            if ~isfield(neuron_decoder, 'H')
                error('Invalid Decoder');
            end
            % overwrite parameters according to loaded decoder            
            params.n_lag = round(neuron_decoder.fillen/neuron_decoder.binsize);
            params.n_neurons = size(neuron_decoder.neuronIDs,1);
            params.binsize   = neuron_decoder.binsize;
            emg_decoder = [];
            params.n_emgs = 0;
            params.n_lag_emg = 0;
        otherwise
            error('Invalid decoding mode. Please specifiy params.mode = [''emgcascade'' | ''direct'' ]');
    end

end
function ave_fr = calc_ave_fr(varargin)
    params = varargin{1};
    if params.online
        Redo = 'Redo';
        while(strcmp(Redo,'Redo'))
            ave_fr = 0.0;
            h = waitbar(0,'Averaging Firing Rate');
            cbmex('trialconfig',1,'nocontinuous');
            for i = 1:10
                pause_t = tic;
                pause(0.5);
                ts_cell_array = cbmex('trialdata',1);
                pause_t = toc(pause_t);
                new_spikes = get_new_spikes(ts_cell_array,params.n_neurons,pause_t);
                ave_fr = ave_fr + mean(new_spikes);
                waitbar(i/10,h);
            end
            ave_fr = ave_fr/10;
            close(h);
            Redo = questdlg(sprintf('Ave FR = %.2f Hz',ave_fr),'Looks good?','OK','Redo','OK');
        end
    else
        offline_data = varargin{2};
        ave_fr = mean(mean(offline_data.spikeratedata));
        uiwait(msgbox(sprintf('Ave FR = %.2f Hz',ave_fr)));
    end
end
function data = get_new_data(params,data,offline_data,bin_count,bin_dur)
    w = Words;
    if params.online
        % read and flush data buffer
        ts_cell_array = cbmex('trialdata',1);
        new_spikes = get_new_spikes(ts_cell_array,params.n_neurons,bin_dur);
        [new_words,new_target,data.db_buf] = get_new_words(ts_cell_array{151,2:3},data.db_buf);
    else
        off_time   = offline_data.timeframe(bin_count);
        new_spikes = offline_data.spikeratedata(bin_count,:)';
        new_words  = offline_data.words(offline_data.words(:,1)>= off_time & ...
            offline_data.words(:,1) < off_time+params.binsize,:);
        new_target = offline_data.targets.corners(offline_data.targets.corners(:,1)>= off_time & ...
            offline_data.targets.corners(:,1)< off_time+params.binsize,2:end);

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
            if new_words(i,2)==w.Adapt || ~params.online
                data.adapt_trial = true;
                % fprintf('Adapt Trial\n');
            end
            if new_words(i,2) == w.Catch
                %catch_flag?
            end
            % End trial
            if w.IsEndWord(new_words(i,2))
                data.adapt_trial = false;
                data.tgt_on      = false;
                data.effort_flag = false;
            end
        end
    end
end                
function new_spikes = get_new_spikes(ts_cell_array,n_neurons,binsize)

    new_spikes = zeros(n_neurons,1);

    %firing rate for new spikes
    for i = 1:n_neurons
        new_spikes(i) = length(ts_cell_array{i,2})/binsize;
    end

    %remove artifact (80% of neurons have spikes for this bin)
    while (length(nonzeros(new_spikes))>.8*n_neurons)
        warning('artifact detected, spikes removed');
        new_spikes(new_spikes>0) = new_spikes(new_spikes>0) - 1/binsize;
    end
    
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
    tgt_size = [3 3];
    def_tgt_pos  = [ 0      0;...
                     8      0;... 
                     5.66   5.66;...
                     0      8;...
                     -5.66  5.66;...
                     -8     0;...
                     -5.66  -5.66;...
                     0      -8;...
                     5.66   -5.66];
      tgt_pos = def_tgt_pos(tgt_id+1,:);
end
