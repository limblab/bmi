function varargout = run_decoder_adaptation(varargin)
% run_decoder_adaptation: This function connects to the Cerebus stream via
% the Central application, produces prediction by a two step
% process in which spike trains predict emgs and emgs predict forces.
% the emg-to-force decoder is expected to be precomputed and passed as
% EMG2F_w weight matrix. The spikes to EMG weight matrix is trained online
% and it uses the backpropagated discrepancy between the predicted forces
% and the target position in the task.
%
% INPUTS : Additional parameters: "params" structure -> see adapt_params_defaults.m


%% Parameters

params = adapt_params_defaults;

if strcmp(params.N2E_dec,'new_rand')
    S2EMG_w = randn(1 + params.n_neurons*params.n_lag, params.n_emgs)*0.00001;
elseif strcmp(params.N2E_dec,'new_zeros')
    S2EMG_w = zeros(1 + params.n_neurons*params.n_lag, params.n_emgs);
else
    d = load(params.N2E_dec);
    if isfield(d, 'S2EMG_w')
        S2EMG_w = d.S2EMG_w;
    else
        disp('Invalid initial spike-to-EMG decoder');
        return;
    end
end

%% Initialization

bin_count = 0;
spikes = zeros(params.n_lag + params.n_lag_emg - 1, params.n_neurons); %spike buffer
words  = nan(100,2); %word buffer
tgt_buf= nan(100,6); %target buffer: [ts id xpos ypos width height];
db_buf = []; %databurst buffer
emgs = zeros( params.n_lag_emg, params.n_emgs); %predicted EMG buffer
last_target_bin = NaN;
target_pos = NaN;
cursor_pos = [0 0];
w = Words;
adapt_trial= false;
tgt_on = false;
CT_size = [3 3];

adaptation_idx = 1;

% Store information about previous trials
% previous_trials = dataset();
% last_20R = [NaN NaN];


if ~isdir(params.save_dir)
    mkdir(params.save_dir);
end

%% UDP port for XPC

XPC_IP   = '192.168.0.1';
XPC_PORT = 24999;
echoudp('on',XPC_PORT);
xpc = udp(XPC_IP,XPC_PORT);
set(xpc,'ByteOrder','littleEndian');
set(xpc,'LocalHost','192.168.0.10');
fopen(xpc);

%% Setup figures

keep_running = msgbox('Click ''ok'' to stop the program','Adapt');
set(keep_running,'Position',[200 700 125 52]);

if params.display_plots
    fig_h = figure;
    curs_handle = plot(0,0,'ko');
    set(curs_handle,'MarkerSize',6,'MarkerFaceColor','k','MarkerEdgeColor','k');
    xlim([-12 12]); ylim([-12 12]);
    axis square; axis equal; axis manual;
    hold on;
    tgt_handle  = plot(0,0,'bo');
    set(tgt_handle,'LineWidth',2,'MarkerSize',12);
end
    

%% Setup data stream
if params.online
    % Cerebus Stream via Central
    connection = cbmex('open',1);
    if ~connection
        echoudp('off');
        fclose(xpc);
        delete(xpc);
        close(keep_running);
        error('Connection to Central Failed');
    end
    max_cycles = 0;
    % start data buffering
    cbmex('trialconfig',1,'nocontinuous');
else
    %Binned Data File
    offline_data = LoadDataStruct(params.binnedDataFile);
    max_cycles = length(offline_data.timeframe);
end

t_buf = tic; %data buffering timer

%% Run cycle
try
    while( ishandle(keep_running) && ...
            ( params.online || ...
                ~params.online && bin_count < max_cycles) )
        
        et_buf = toc(t_buf); %elapsed buffering time
        
        % reached cycle time?
        if (floor(et_buf/params.binsize)>= bin_count) || ...
             (~params.online && floor(et_buf*params.realtime/params.binsize)>= bin_count)
            t_op = tic; %operation time
            bin_count = bin_count +1;
            
            %% Get and Process New Data
            if params.online
                % read and flush data buffer
                ts_cell_array = cbmex('trialdata',1);
                new_spikes = get_new_spikes(ts_cell_array,params.n_neurons,params.binsize);
                [new_words,new_target,db_buf] = get_new_words(ts_cell_array{151,2:3},db_buf);
            else
               off_time   = offline_data.timeframe(bin_count);
               new_spikes = offline_data.spikeratedata(bin_count,:)'; 
               new_words  = offline_data.words(offline_data.words(:,1)>= off_time & ...
                                               offline_data.words(:,1) < off_time+params.binsize,:);
               new_target = offline_data.targets.corners(offline_data.targets.corners(:,1)>= off_time & ...
                                                         offline_data.targets.corners(:,1)< off_time+params.binsize,2:end);
                                                     
            end

            spikes = [new_spikes'; spikes(1:end-1,:)];
            num_new_words = size(new_words,1);
            words  = [new_words;     words(1:end-num_new_words,:)];
            
            if ~isempty(new_target)
                new_tgt_pos  = [ (new_target(3)+new_target(1))/2 ...
                                     (new_target(4)+new_target(2))/2 ];
                new_tgt_size = [   new_target(3)-new_target(1) ...
                                  new_target(2)-new_target(4) ];
%                 fprintf('tgt from db: %d\n',get_tgt_id(new_target(2:end)));
            end
            
            if ~isempty(new_words)
                for i=1:size(new_words,1)
                    % new word Ot_On?
                    if bitand(hex2dec('F0'),new_words(i,2))==w.OT_On
                        new_tgt_id = bitand(hex2dec('0F'),new_words(i,2))+1;
                        new_tgt_ts   = new_words(i,1);
                        target_pos = new_tgt_pos;
                        target_size = new_tgt_size;
                        tgt_buf = [new_tgt_ts new_tgt_id target_pos target_size; tgt_buf(1:end-1,:)];
                        last_target_bin = bin_count;
                        tgt_on = true;
                        % fprintf('OT_on : %d\n',new_tgt_id);
                    end
                    % new word CT_ON?
                    if new_words(i,2) == w.CT_On
                        new_tgt_id = 0;
                        new_tgt_ts   = new_words(i,1);
                        target_pos = [0 0];
                        target_size = CT_size;
                        tgt_buf = [new_tgt_ts new_tgt_id target_pos target_size; tgt_buf(1:end-1,:)];
                        last_target_bin = bin_count;
                        tgt_on = true;
                        % fprintf('CT_on\n');
                    end
                    % Adapt word
                    if new_words(i,2)==w.Adapt || ~params.online
                        adapt_trial = true;
                        % fprintf('Adapt Trial\n');
                    end
                    if new_words(i,2) == w.Catch
                        %catch_flag?
                    end
                    % End trial
                    if w.IsEndWord(words(i,2))
                        adapt_trial = false;
                        tgt_on      = false;
                    end
                end
            end
                
            %% Predictions

%             emgs(2:end,:) = emgs(1:(end-1),:);
%             emgs(1,:) = [1 rowvec(spikes(1:params.n_lag,:))']*S2EMG_w;
%             force_pred = emgs(:)'*params.EMG2F_w;
            
            % Predict dEMGs
            new_emgs = zeros(1,params.n_emgs);
            for i = 1:params.n_emgs
                new_emgs(i) = max(0,[1 spikes(:)']*rowvec(S2EMG_w(:,i)'));
%                 new_emgs(i) = [1 spikes(:)']*rowvec(S2EMG_w(:,i)');
            end
            if params.n_lag_emg > 1
                emgs = [new_emgs; emgs(1:end-1,:)];
            else
                emgs = new_emgs;
            end
            
            % Predict force
            force_pred = emgs(:)'*params.EMG2F_w;
            cursor_pos = force_pred;
            
            %% Neurons-to-EMG Adaptation
                        
            if mod(bin_count/20,params.adapt_time+params.fixed_time)>=params.adapt_time
                fix_decoder = 1;
            else
                fix_decoder = 0;
            end
            
            % adapt trial and within adapt window
            if adapt_trial && tgt_on &&...
                    (bin_count - last_target_bin)*params.binsize >= params.delay && ...
                    (bin_count - last_target_bin)*params.binsize <= (params.delay+params.duration)
                
% % %                 %save info for this trial
% % %                 previous_trials = [previous_trials;
% % %                     dataset({bin_count, 'bin_count'}, ...
% % %                     {adapt_flag, 'adapt_flag'},...
% % %                     {last_target_bin, 'target_bin'}, ...
% % %                     {new_tgt_id, 'target_id'}, ...
% % %                     {{target_pos}, 'target_pos'}, ...
% % %                     {{target_size}, 'target_size'},...
% % %                     {{force_pred}, 'force_predicted'}, ...
% % %                     {{spikes}, 'spikes'}, ...
% % %                     {{emgs}, 'emgs'})]; %#ok<AGROW>
%                 
%                 % show how well are the last trial catches being predicted
%                 tmp_true = previous_trials.target_pos;
%                 tmp_predicted = previous_trials.force_predicted;
%                 tmp_true = vertcat(tmp_true{:});
%                 tmp_predicted = vertcat(tmp_predicted{:});
%                 
%                 min_idx = max(1, size(tmp_true, 1)-20);
%                 max_idx = size(tmp_true, 1);
%                 
%                 last_20R = diag(corr(...
%                     tmp_true(min_idx:end, :), ...
%                     tmp_predicted(min_idx:max_idx, :)))';
                
                
               % check if it is a trial in which we really need to adapt
                if (~fix_decoder)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %This would replace Daniel's Adaptation Code
                    df = target_pos - cursor_pos;
                    de = df*params.EMG2F_w';
                    de(de<0) = max(de(de<0),-emgs(de<0));
                    dw = [1 rowvec(spikes(1:params.n_lag,:))']'*de;
                    S2EMG_w = S2EMG_w + dw*params.LR;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %    %This is Daniel's Adaptation Code
% % %                    %
% % %                    % gradient accumulator
% % %                    accum_g = zeros(size(S2EMG_w));
% % %                    accum_n = 0;
% % % 
% % %                    target_list = new_tgt_id;
% % %                    %                    target_list = unique(previous_trials.target_id)';
% % %                    for t = target_list
% % %                        % find the last n_adapt_to_last target t and adapt
% % %                        idx_list = find(previous_trials.target_id == t, ...
% % %                            params.batch_length, 'last');
% % %                        for idx = idx_list(:)'
% % %                            tmp_spikes = previous_trials.spikes{idx};
% % %                            tmp_emgs = previous_trials.emgs{idx};
% % %                            tmp_target_pos = previous_trials.target_pos{idx};
% % % 
% % %                            accum_g = backpropagation_through_time(S2EMG_w, params.EMG2F_w, ...
% % %                                tmp_spikes, tmp_emgs, ...
% % %                                tmp_target_pos(:)', ...
% % %                                params.n_lag, params.n_lag_emg);
% % % 
% % %                            % count how many gradients we have accumulated
% % %                            accum_n = accum_n + 1;
% % %                        end
% % %                    end
% % % 
% % %                     g = accum_g/accum_n;
% % %                    S2EMG_w = S2EMG_w - params.LR*g;
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



                    %% update predictions with new decoder

%                     % predict EMG and store it in lagged matrix
%                     emgs(2:end,:) = emgs(1:(end-1),:);
%                     emgs(1,:) = [1 rowvec(spikes(1:params.n_lag,:))']*S2EMG_w;

% %                     % Predict EMGs
% %                     new_emgs = zeros(1,params.n_emgs);
% %                     for i = 1:params.n_emgs
% %                         new_emgs(i) = [1 spikes(:)']*rowvec(S2EMG_w(:,i)');
% %                     end
% %                     if params.n_lag_emg > 1
% %                         emgs = [new_emgs emgs(1:end-1,:)];
% %                     else
% %                         emgs = new_emgs;
% %                     end
% % 
% %                     % Predict force
% %                     force_pred = emgs(:)'*params.EMG2F_w;
% %                     cursor_pos = force_pred;
% %                    
% %                    new_emgs = [1 rowvec(spikes(:, 1:n_lag))']*S2EMG_w;
% %                    emgs = [new_emgs emgs(:,2:end)];

                   %                    force_pred_adapted = emg(:)'*EMG2F_w;

                   adaptation_idx = adaptation_idx + 1;
                end
            end
            
            %% Cursor Output
            
            
%             if ~params.cursor_assist
%                 cursor_pos = force_pred;
%             else
%                 % cursor is moved towards target as a function of
%                 % average firing rate?
%                 cursor_pos = force_pred;
%                 prev_assist_dist = cursor_pos - cursor_pred;
%                 tgt_dist = target_pos - cursor_pos;
%                 cursor_pos = cursor_pos + 0.2*tgt_dist;
%                 assist_dist = cursor_pos - cursor_pred;
%             end
            
            % send predictions to xpc
            fwrite(xpc, [1 1 cursor_pos],'float32');

            %% Save and display progress
            
            % save results every 30 seconds
            if mod(bin_count*params.binsize, 30) == 0
                %                 save([params.save_dir '\previous_trials_' strrep(strrep(datestr(now),':',''),' ','-')], 'previous_trials','S2EMG_w');
                save([params.save_dir '\Adapt_decoder_' strrep(strrep(datestr(now),':',''),' ','-')],'S2EMG_w');
                
            end
            
            % each second show adaptation progress
            if mod(bin_count*params.binsize, 1) == 0
                disp([sprintf('Time: %d secs, ', bin_count*params.binsize) ...
                      'Adapting: ' num2str(~fix_decoder) ', ' ...
                      'Online: ' num2str(params.online)]);
%                     'prediction corr: ' num2str(last_20R)]);
            end
            
            %display targets and cursor plots
            if params.display_plots && ~isnan(target_pos(1)) && ishandle(fig_h)
                
                set(curs_handle,'XData',cursor_pos(1),'YData',cursor_pos(2));
                
                if tgt_on
                    set(tgt_handle,'XData',target_pos(1),'YData',target_pos(2),'Visible','on');
                else
                    set(tgt_handle,'Visible','off');
                end
                
                if  adapt_trial && tgt_on && ~fix_decoder && ...
                        (bin_count - last_target_bin)*params.binsize >= params.delay && ...
                        (bin_count - last_target_bin)*params.binsize <= (params.delay+params.duration)
                    display_color = 'r';
                else
                    display_color = 'k';
                end
                set(curs_handle,'MarkerEdgeColor',display_color,'MarkerFaceColor',display_color);
            end
            
            %% Wrapping up            
            et_op = toc(t_op); %elapsed operation time
            if et_op>0.05
                warning('slow matlab processing time: %.1f ms',et_op*1000);
            end
        end
        
        % flush pending events
        drawnow;
        
    end
    
    if params.online
        cbmex('close');
    end
    echoudp('off');
    fclose(xpc);
    
    if ishandle(keep_running)
        close(keep_running);
    end
    close all;
    
catch e
    if params.online
        cbmex('close');
    end
    echoudp('off');
    fclose(xpc);
    
    close(keep_running);
    close all;
    rethrow(e);
end


%% optionally Save decoder at the end
YesNo = questdlg('Would you like to save the decoder?',...
    sprintf('End of Adaptation',bin_count),...
    'Yes','No','Yes');
if strcmp(YesNo,'Yes')
    filename = [params.save_dir '\Adapt_decoder_' strrep(strrep(datestr(now),':',''),' ','-') '_End.mat'];
    save(filename,'S2EMG_w','adaptation_idx');
    fprintf('Saved Decoder File :\n%s\n',filename);    
else
    disp('Decoder not saved');
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

        % databursts:
        new_db = all_words( all_words(:,2) >= min_db_val & all_words(:,2) <= max_db_val, :);

        if isempty(new_db)
            %no databurst this time
            if ~isempty(db_buf)
                % we should have received more bytes
                warning('missing databurst bytes, databurst info discarded');
            end
            new_target = [];
            db_buf = [];
        else
            if ~isempty(db_buf)
                % continue filling databurst buffer started previous bin
                num_bytes = (db_buf(1,2) - min_db_val) + 16*(db_buf(2,2) - min_db_val);
            else
                num_bytes = (new_db(1,2) - min_db_val) + 16*(new_db(2,2) - min_db_val);
            end
            
            
            db_buf = [db_buf; new_db];
            
            if size(db_buf,1) >= num_bytes*2
                if size(db_buf,1)>num_bytes*2
                    fprintf('extra bytes in databurst (%d out of %d)\n',size(db_buf,1),num_bytes*2);
                end
                % we have the whole data burst, process and flush.
                raw_bytes  = db_buf(1:num_bytes*2, 2);
                half_bytes = reshape(raw_bytes,2,[]) - min_db_val;
                databurst  = double(16*half_bytes(2,:) + half_bytes(1,:));
                new_target = bytes2float(databurst(num_bytes-15:end))';
                db_buf = [];
%             elseif size(db_buf,1) >= num_bytes*2
%                 %we have more data then expected, something is wrong
%                 warning('unexpected bytes for databurst, databurst info discarded');
%                 new_target = [];
%                 db_buf = [];
            else
                % partial databurst, wait for next bin for rest of databurst
                new_target = [];
            end
        end
    else
        if ~isempty(db_buf)
            % we should have received more bytes
            warning('missing databurst bytes, databurst info discarded');
        end
        new_target = [];
        db_buf = [];
    end
end
