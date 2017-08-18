function varargout = run_bmi_fes(varargin)
% run_decoder: This function connects to the Cerebus stream via
% the Central application, produces prediction by a two step
% process in which spike trains predict emgs and emgs predict forces.
% the emg-to-force decoder is expected to be precomputed and passed as
% EMG2F_w weight matrix. The spikes to EMG weight matrix is trained online
% and it uses the backpropagated discrepancy between the predicted forces
% and the target position in the task.
%
% INPUTS : Additional parameters: "params" structure -> see adapt_params_defaults.m


%%Read parameters
if nargin
    params          = varargin{1};
    params          = bmi_params_defaults(params);
else
    params          = bmi_params_defaults;
end


%% UDP port for XPC
xpc                 = open_xpc_udp(params);


%% Read Decoders and other files

[neuron_decoder,emg_decoder,params] = load_N2E2F_decoders(params);
% decoders = load_decoders(params);
if isempty(neuron_decoder)
    if params.online, clearxpc; end
    return;
end

% check that there's no error in the stimulation parameters 
if strcmpi(params.output,'stimulator') || strcmpi(params.output,'wireless_stim') 
    params          = check_bmi_fes_settings( neuron_decoder, params );
end


%% Initialization

% globals
% ave_op_time = 0.0;
bin_count               = 0;
reached_cycle_t         = false;
% cursor_pos = [0 0];
w                       = Words(params.bmi_fes_stim_params.task);
handles                 = [];

% data structure to store inputs --do not use the second argument because
% it's for online adaptation
[data, offline_data,params] = init_bmi_fes_data(params);


%% Setup figures

% message box to stop the experiment at any time
handles.keep_running    = msgbox('Press ''ok'' to stop'); % opens a figure to control the FES
set(handles.keep_running,'Position',[200 700 250 90]);

if params.display_plots
    % handle for the FES figure
    handles.ffes.fh     = figure('Name','FES commands');
    handles.ffes        = stim_fig( handles.ffes, [], [],  params.bmi_fes_stim_params, 'init' );
end

% If we are replaying data from a file, instead of doing an 'online'
% experiment, create a progress bar
if ~params.online
    prog_bar            = waitbar(0, sprintf('Replaying Offline Data'));
end


%% Setup data files and directories for recording

if params.save_data
    handles             = setup_recordings(params,handles);
end


%% Start data streaming

if params.online
    % connect to Cerebus
    handles             = start_cerebus_stream(params,handles,xpc);
    
    % init some variables
    max_cycles          = 0;
    offline_data        = [];
  
    bin_start_t         = 0.0; % time at beginning of next bin
        
    % start cerebus file recording :
    cbmex('fileconfig', handles.cerebus_file, '', 1);   
    data.sys_time       = cbmex('time');

    % start data buffering
    cbmex('trialconfig',1,'nocontinuous');

    
else  % If using pre-recorded signals in a file1
    max_cycles          = length(offline_data.timeframe);
    bin_start_t         = double(offline_data.timeframe(1));
end

% setup stimulator, if doing FES
if strcmpi(params.output,'stimulator') || strcmpi(params.output,'wireless_stim')
    handles             = setup_stimulator(params,handles);
end

% start data buffering timer
t_buf                   = tic; 
drawnow;

% profile on

%% Run cycle
% keep_running_data = guidata(handles.keep_running); % data from the keep running gui
% halt_flag = keep_running_data.Stop; % the stop flag
try
    plt = 1
    while( ishandle(handles.keep_running) && (params.online || (~params.online && bin_count < max_cycles)))
        
%         % get new data from the keep running gui.
%         % theres_got_to_be_a_better_way.billymays
%         plt = 1; % runs plot only every other time
%         keep_running_data = guidata(handles.keep_running);
%         halt_flag = keep_running_data.Stop;
%         pause_flag = keep_running_data.Pause;
%         
%         % pause if we clicked pause
%         if pause_flag 
%             keep_running_data.Pause = 0;
%             [stim_cmd, channel_list]    = stim_elect_mapping_wireless(zeros(1,9), ...
%                         data.stim_amp, params.bmi_fes_stim_params );
%             for which_cmd = 1:length(stim_cmd)
%                 handles.ws.set_stim(stim_cmd(which_cmd), channel_list);
%             end
%             keyboard();
%             guidata(handles.keep_running,keep_running_data);            
%         end
        
        % when a full cycle has elapsed
        if (reached_cycle_t)
            
            % ------------------------------------------------------------
            %% Update timers and counters
            
            cycle_t     = toc(t_buf); %this should be equal to bin_size, but may be longer if last cycle operations took too long.
            t_buf       = tic; % reset buffering timer
            bin_count   = bin_count +1;
            
            
            % ------------------------------------------------------------
            %% Get and Process New Data
            
            data        = get_new_data(params,data,offline_data,bin_count,cycle_t,w);
            
            
            % ------------------------------------------------------------
            %% Predictions
            
            % get a new prediction by transforming the data into a row
            % vector and multiply by the decoder 
            pred        = [1 rowvec(data.spikes(1:params.n_lag,:))']*neuron_decoder.H;
             
            % apply the static non-linearity, if there is one
            if isfield(neuron_decoder,'P')
                nonlinearity = zeros(1,length(pred));
                for e = 1:length(pred)
                    nonlinearity(e) = polyval(neuron_decoder.P(:,e),pred(e));
                end
                pred    = nonlinearity;
            end
            
%             % high-pass filter the predictions --not done, by default
%             if params.hp_rc
%                 pred    = pred*(params.hp_rc/(params.hp_rc+params.binsize));
%             end
            
            % For some types of decoder, do some more actions
            % ToDo: get rid of the second two options, because they won't
            % be used for BMI-controlled FES
            if strcmp(params.mode,'emg_only') 
                data.emgs = pred;
            % for a neuron-to-EMG decoder followed by an EMG-to-force decoder    
            elseif strcmp(params.mode,'emg_cascade')
                % apply sigmoid?
                if params.sigmoid_pred == sigmoid(pred,'direct'); end
%                 % remove negative emg preds
%                 pred(pred<0) = 0;
                % store new emg preds
                data.emgs = [pred; data.emgs(1:end-1,:)];
                % force predictions:
                data.curs_pred = rowvec(data.emgs(:))'*emg_decoder.H;
%             % for a velocity decoder
%             else
%                 if strcmpi(neuron_decoder.decoder_type,'N2V')
%                     if any( isnan(data.curs_pred)) data.curs_pred = [0 0]; end
%                     data.curs_pred = data.curs_pred + pred(1:2)*params.binsize;
%                 else
%                     data.curs_pred = pred;
%                 end
            end
            
            
            % ------------------------------------------------------------
            %% Stimulation
            
            % Translate EMG predictions into stimulator parameters
            [data.stim_PW, data.stim_amp]   = EMG_to_stim( data.emgs, params.bmi_fes_stim_params );

            % And send those parameters to the stimulator, if we are
            % doing online, and this is not a catch trial
            if data.fes_or_catch
                if strcmpi(params.output,'wireless_stim')
                    [stim_cmd, channel_list]    = stim_elect_mapping_wireless( data.stim_PW, ...
                                                    data.stim_amp, params.bmi_fes_stim_params );
                    for which_cmd = 1:length(stim_cmd)
                        handles.ws.set_stim(stim_cmd(which_cmd), channel_list);
                    end
                elseif strcmpi(params.output,'stimulator')
                    stim_cmd                    = stim_elect_mapping( data.stim_PW, [], params.bmi_fes_stim_params );
                    xippmex( 'stimseq', stim_cmd );
                end
            else        % if it is a catch trial, stop the stimulation
                if strcmpi(params.output,'wireless_stim')
                    data.stim_PW = repmat(0,1,8);
                    data.stim_amp = repmat(0,1,8);
                    
                    [stim_cmd, channel_list]    = stim_elect_mapping_wireless( 0, ...
                                                    0, params.bmi_fes_stim_params, 'catch' );
                    for which_cmd = 1:length(stim_cmd)
                        handles.ws.set_stim(stim_cmd(which_cmd), channel_list);
                    end
                        
                elseif strcmpi(params.output,'stimulator')
                    warning('Catch trials not implemented for the grapevine yet');
                end
            end

            % Plot the stimulation value
            if plt == 1
                plt = 0;
                handles.ffes   = stim_fig( handles.ffes, data.stim_PW, data.stim_amp, params.bmi_fes_stim_params, 'exec', data.fes_or_catch);
            elseif plt == 0
                plt = 1;
            end            
            
            % ------------------------------------------------------------
            %% Save and display progress
                  
            if params.save_data

                %check elapsed operation time, to store it in the FES file
                cycle_t                 = toc(t_buf);
                
                % - Save the binned spikes
                % spikes are timed from beginning of this bin
                % because they occured in the past relative to now
                tmp_data                = [bin_start_t data.spikes(1,:)];
                save(handles.spike_file,'tmp_data','-append','-ascii');

                % the rest of the data is timed with end of this bin
                % because they are predictions made just now.
                bin_start_t             = data.sys_time;

                % - save EMG predictions
                if ~strcmp(params.mode,'direct')
                    tmp_data            = [bin_start_t double(data.emgs(1,:))];
                    save(handles.emg_file,'tmp_data','-append','-ascii');
                end

                % - save stimulator parameters
                if strcmpi(params.output,'wireless_stim') || strcmpi(params.output,'stimulator')
                    switch params.bmi_fes_stim_params.mode
                        case 'PW_modulation'
                            tmp_data    = [bin_start_t double(data.stim_PW)];
                        case 'amplitude_modulation'
                            tmp_data    = [bin_start_t double(data.stim_amp)];
                    end
                    % add FES (1) vs catch (0) trial flag
                    % ToDo add
                    % add cycle time (it will be the cycle time of the
                    tmp_data            = [tmp_data double(cycle_t)];
                    % add the FES or catch flag
                    tmp_data            = [tmp_data data.fes_or_catch];
                    save(handles.stim_out_file,'tmp_data','-append','-ascii');
                end
                
                % - save word if there is a new one
                if ~isempty(data.words)
                    tmp_data                = [bin_start_t data.words(1,:)];
                    save(handles.word_file,'tmp_data','-append','-ascii');
                end
             
%                 % - save cursor position
%                 tmp_data                = [bin_start_t double(cursor_pos)];
%                 save(handles.curs_pos_file,'tmp_data','-append','-ascii');
%                 tmp_data                = [bin_start_t double(data.curs_pred)];
%                 save(handles.curs_pred_file,'tmp_data','-append','-ascii');
            end
            
            
            % ------------------------------------------------------------
            %% Wrapping up
            
            % flush pending events
            drawnow;
            
            %check elapsed operation time
            et_op                           = toc(t_buf);
            
            % if the cycle time was greater than it should have, display a
            % message
%            ave_op_time = ave_op_time*(bin_count-1)/bin_count + et_op/bin_count;
            if et_op>0.05 && params.print_out
                fprintf('~~~~~~slow processing time: %.1f ms~~~~~~~\n',et_op*1000);
            end
            
            reached_cycle_t = false;
        end
        
        
        % -----------------------------------------------------------------
        %% Wait for the control cycle to be over
        
        % get elapsed buffering time
        et_buf                              = toc(t_buf); 
        
        % when reached cycle time, update flag to enter in the control loop
        if (et_buf>=params.binsize) || (~params.online && (~params.realtime || ...
                                        et_buf*params.realtime>=params.binsize))
            reached_cycle_t                 = true;
        end
        
        
    end

    
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    %% if the user stopped execution
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
%     profile viewer
    if ishandle(handles.keep_running)
        close(handles.keep_running);
    end
    if isfield(handles,'fh')
        if ishandle(handles.fh)
            close(handles.fh);
        end
    end
    if isfield(handles,'ffes')
        if ishandle(handles.ffes.fh)
            close(handles.ffes.fh);
        end
    end
    

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% if there is an error close everything
catch e
    if params.online
        if params.save_data
            cbmex('fileconfig', handles.cerebus_file, '', 0);
        end
        cbmex('close');
    else
        close(prog_bar);
    end
    if strcmpi(params.output,'wireless_stim')
        handles.ws.set_Run(handles.ws.run_stop,1:16);
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
    if isfield(handles,'ffes')
        if ishandle(handles.ffes.fh)
            close(handles.ffes.fh);
        end
    end
    rethrow(e);
end

end






%% Accessory Functions :

%% 
% Read new data, either online from central, or from a binned file, if
% going an offline experiment
% 
%   function data = get_new_data(params,data,offline_data,bin_count,bin_dur,w)
%
% Inputs: 
%   params              : struct of type bmi_params  
%   data                : struct to store the data. Created with
%                           init_bmi_data or init_bmi_fes_data
%   bin_count           : counter that stores the current bin
%   bin_dur             : bin duration
%   w                   : struct with word definitions
%
% Outputs: 
%   data                : struct with the read data
%

function data = get_new_data(params,data,offline_data,bin_count,bin_dur,w)
    
    % get the data
    if params.online
        % read and flush data buffer
        ts_cell_array       = cbmex('trialdata',1);
        % get current cerebus time
        data.sys_time       = cbmex('time');
        % get new spike counts
        new_spikes          = get_new_spikes( ts_cell_array, params, bin_dur );
        [new_words,new_target,data.db_buf] = get_new_words(ts_cell_array{151,2:3},data.db_buf);
    else
        data.sys_time       = double(offline_data.timeframe(bin_count));
        [~,spike_idx,~]     = intersect(offline_data.neuronIDs,params.neuronIDs,'rows','stable');
        new_spikes          = offline_data.spikeratedata(bin_count,spike_idx)';
        new_words           = offline_data.words(offline_data.words(:,1)>= data.sys_time & ...
            offline_data.words(:,1) < data.sys_time+params.binsize,:);
        new_target          = offline_data.targets.corners(offline_data.targets.corners(:,1)>= data.sys_time & ...
            offline_data.targets.corners(:,1)< data.sys_time+params.binsize,2:end);
%         data.curs_act       = offline_data.cursorposbin(bin_count,:);
    end

    data.spikes             = [new_spikes'; data.spikes(1:end-1,:)];
    data.ave_fr             = data.ave_fr*(bin_count-1)/bin_count + mean(new_spikes)/bin_count;
    num_new_words           = size(new_words,1);
    data.words              = [new_words; data.words(1:end-num_new_words,:)];

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
%                 if strcmp(params.adapt_params.type,'supervised_full')
%                     data.adapt_flag = true;
%                 end
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
            if new_words(i,2) == w.CT_On  % "w" is the word definitions. It's defined in Words()
                data.tgt_id   = 0;
                data.tgt_ts   = new_words(i,1);
                %Center target, always at [0 0];
                [data.tgt_pos,data.tgt_size] = get_default_tgt_pos_size(data.tgt_id);
                data.tgt_bin  = bin_count;
                data.tgt_on   = true;
                % fprintf('CT_on\n');
                % check if this is a catch trial, if we have catch trials
                % at all
                if params.bmi_fes_stim_params.perc_catch_trials
                    if  find(mod(data.trial_count,100) == data.catch_trial_indx); % random number [1:100] <= catch trial percentage?
                        % if it is set the flag to no FES
                        data.fes_or_catch = 0;
                        fprintf('*~*~*~catch trial~*~*~*\n');
                    else
                        % otherwise set the flag to FES
                        data.fes_or_catch = 1;
                    end
                end
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
%                 % offline, only on successful trials, but all trials online
%                 if data.adapt_trial && (params.online || new_words(i,2)==w.Reward)
%                     if ~strcmp(params.adapt_params.type,'supervised_full')
%                         data.adapt_flag = true;
%                     end
%                 end
%                 data.adapt_trial = false;
                data.tgt_on      = false;
%                 data.effort_flag = false;
            end
        end
    end
end    



%%
%
% Get spike data from cerebus
%
%   function new_spikes = get_new_spikes(ts_cell_array,params,binsize)
%
% Inputs:
%   ts_cell_array       : time stamps of the threshold crossings for each
%                           Cerebus channel, read with cbmex
%   params              : params struct
%   binsize             : bin duration
%
% Output:
%   new_spikes          : firing rate for each channel (Hz)
%
% Note: the code caps down the instantaneous firing rate to 400 Hz when
% it is larger than that
%

function new_spikes = get_new_spikes(ts_cell_array,params,binsize)

    new_spikes              = zeros(params.n_neurons,1);
    new_ts                  = ts_cell_array(params.neuronIDs(:,1),:);
 
    % remove stim artefacts!
    new_ts                  = remove_stim_artifacts( new_ts, params, binsize );
    
    %firing rate for new spikes
    for i = 1:params.n_neurons
        unit                = params.neuronIDs(i,2);
        new_spikes(i)       = length(new_ts{i,unit+2})/binsize;
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



%%
%
% Get new words from cerebus

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


%% time sync -- getting the ripple and blackrock synced up
%
% we know that it's supposed to be around 30 ms, so mostly we need to just
% get the offset synced up. 
%
% T_next = .5*(T_last+30 ms) + .5*(T_est)
% T_est = time(#spike>thresh) iff 0 ms < time < 30 ms
%
%
function tsync = timeSync(params)

    cycleLength = 1/params.bmi_fes_stim_params.freq; % what's our stim freq
    tCycle_old = cbmex('time');
    cbmex('trialdata',1)
    
    % set all of the stimulation to high
    [data.stim_PW, data.stim_amp]   = EMG_to_stim( ones(size(...
        params.bmi_fes_stim_params.PW_max)),params.bmi_fes_stim_params );
    [stim_cmd, channel_list]    = stim_elect_mapping_wireless(...
        data.stim_PW, data.stim_amp, params.bmi_fes_stim_params );
    for which_cmd = 1:length(stim_cmd)
        handles.ws.set_stim(stim_cmd(which_cmd), channel_list);
    end
    
    
    
    for ii = 1:100 % 100 cycles should be super overkill
        tCycle_new = cbmex('time');
        dtCycle = tCycle_new-tCycle_old;
        pause(cycleLength-dtCycle);
        ts_cell_array = cbmex('trialdata',1) ; % get the data
        new_spikes = ts_cell_array(params.neuronIDs(:,1),:); % get the spikes out of the cell array
        
        
        % params for artifact removal
        max_nbr_chs             = 10;
        reject_bin_size         = 0.001;


        % -------------------------------------------------------------------------
        % 1. Bin the threshold crossings into bins of size 'reject_bin_size'

        % time support for binning, made equal to the length of the recorded bin
        rejection_t             = 0:reject_bin_size:ceil(bin_dur/reject_bin_size)*reject_bin_size;
        % preallocate matrix for storing bin counts
        counts                  = zeros(length(rejection_t),params.n_neurons);
        % bin the data
        for n = 1:params.n_neurons
            unit                = params.neuronIDs(n,2);
            temp_counts         = histc(double(ts{n,unit+2})/30000,rejection_t)';
            if ~isempty(temp_counts)
                counts(:,n)     = temp_counts;
            end
        end







    
    
end