function emg_to_force_backprop_server(S2EMG_w, EMG2F_w, learning_rate, ...
    varargin)
%EMG_TO_FORCE_BACKPROP_SERVER This server produces prediction by a two step
% process in which spike trains predict emgs and emgs predict forces.
% the emg-to-force prediction is expected to be precomputed and passed as
% EMG2F_w weight matrix. The spikes to EMG weight matrix is trained online
% and it uses the % backpropagated discrepancy between the predicted forces
% and the target position in the task.
%
% INPUTS
%
%   S2EMG_w   : initial spikes to EMG weight matrix. it could be initialized
%               as a random matrix that will be slowly adapted
%   EMG2F_w   : EMG to force decoder which assumes that there is no
%               bias term (Intercept = 0)
%   learning_rate:gradient descent learning rate
%
% Additional parameters:
%
%   'n_port'        : What port is the server running (Default: 8000)
%   'n_lag'         : Number of lags to use (Default: 10)
%   'n_neurons'     : Number of neurons
%   'display_plots' : Plot adaptation procedure (Default: true)
%   'n_adapt_to_last':Adapt to last n sets of targets (look back for the
%                     last n instances in which the target appear and run
%                     gradient descent on them)
%   'simulate'      : Simulate four neurons each tuned to different halfs
%                     of the screen (vertical and horizontal)
%   'adaptation_time':duration of adaptation periods in seconds (default: Inf)
%   'fixed_time'    : duration of fixed periods in seconds. (def:0)
%   'adaptation_progress':display adaptation progress (Default: false)
%   'cursor_assist' : moves the cursor

% Therefore, the protocol for this server is as follows:
% - Receive last spikes
% - Receive last target position
% - Receive bin 'type' (i.e., it will depend on the trial type the animal
%       is performing. Only for 'catch' trials, the back propagation
%       adaptation will be triggered)
% - Send cursor prediction

p = inputParser;
addParamValue(p, 'n_port', 8000, @(x)(x>0));
addParamValue(p, 'n_lag', 10, @(x)(x > 0));
addParamValue(p, 'n_neurons', NaN, @isnumeric);
addParamValue(p, 'n_emg', NaN, @isnumeric);
addParamValue(p, 'display_plots', true, @islogical);
addParamValue(p, 'n_adapt_to_last', 1, @isnumeric);
addParamValue(p, 'simulate', false, @islogical);
addParamValue(p, 'adaptation_time', Inf, @isnumeric);
addParamValue(p, 'fixed_time',0,@isnumeric);
addParamValue(p, 'show_adaptation_progress', false, @islogical);
addParamValue(p, 'cursor_assist', false, @islogical);
parse(p, varargin{:});

n_port = p.Results.n_port;
n_lag = p.Results.n_lag;
n_neurons = p.Results.n_neurons;
n_emg = p.Results.n_emg;
display_plots = p.Results.display_plots;
n_adapt_to_last = p.Results.n_adapt_to_last;
simulate = p.Results.simulate;
adaptation_time = p.Results.adaptation_time;
fixed_time = p.Results.fixed_time;
show_adaptation_progress = p.Results.show_adaptation_progress;
cursor_assist = p.Results.cursor_assist;


n_lag_emg = size(EMG2F_w, 1)/n_emg;
n = 0;
total_time = 0;
server = [];
bin_count = 0;
savedir = ['/home/limblab/Desktop/Adapt_files/' date];
if ~isdir(savedir)
    mkdir(savedir);
end
adapt_delay    = 100;
adapt_duration = 300;

try
    if ~simulate
        disp('Server waiting for client...');
        server = tcpip_c(n_port);
        disp('Client connected');
        % Send ACK about connection
        send_ack(server);
    end
    
    spikes = zeros(n_neurons, n_lag + n_lag_emg);
    emgs = zeros(n_emg, n_lag_emg);
    errors = [];
    targets = [];
    last_target_bin = NaN;
    target_position = NaN;
    tic;
    % Infinite loop
    adaptation_idx = 1;
    % Store information about previous trials
    previous_trials = dataset();
    last_20R = [NaN NaN];
    while(true)
        
        bin_count = bin_count + 1;
        %send_ack(server);
        
        if mod(bin_count/20,adaptation_time+fixed_time)>=adaptation_time
            fix_decoder = 1;
        else
            fix_decoder = 0;
        end
        
        if ~simulate
            % Receive spikes
            newest_spikes = fread_matrix(server);
            % Receive target ID
            target_id = double(fread_matrix(server));
            % remove artifacts simultaneous in >75% of all chanels
            if length(nonzeros(newest_spikes))>.75*n_neurons
                warning('artifact detected, spikes removed');
                newest_spikes(newest_spikes>0) = newest_spikes(newest_spikes>0) - 20;
            end
            % remove artifacts (high freq thresh x-ing)
            % by capping FR at 400 Hz
            if any(newest_spikes>400)
                newest_spikes(newest_spikes>400) = 400;
                warning('noise detected, FR capped at 400 Hz');
            end
        else
            target_id = mod(round(bin_count/10), 9);
            newest_spikes = zeros(n_neurons, 1);
        end
        
        targets = unique([targets target_id]);
        
        % decode target position
        if target_id == 0
            target_position = [0; 0];
            LR = learning_rate/8;
        elseif target_id > 0 && target_id <= 8
            LR = learning_rate;
            angle = (target_id - 1)*45*pi/180;
            rotation_matrix = ...
                [cos(angle) -sin(angle);
                sin(angle) cos(angle)];
            target_position = rotation_matrix*[8 0]';
        end
        if target_id >= 0 && target_id <= 8
            last_target_bin = bin_count;
            last_target = target_id;
        end
        
        if simulate
            % when simulating, there are four simulated neurons tunned to
            % the different halves of the screen (bottom, top, left, and
            % right halves)
            if all(~isnan(target_position))
                if ~isempty(target_position)
                    newest_spikes(1) = target_position(1)>2;
                    newest_spikes(2) = target_position(2)>2;
                    newest_spikes(3) = target_position(1)<2;
                    newest_spikes(4) = target_position(2)<2;
                end
            end
        end
        
        % Shift spikes
        spikes(:, 2:end) = spikes(:, 1:(end-1));
        % put newest spikes on first column
        spikes(:, 1) = newest_spikes;
        
        % Receive bin type
        if ~simulate
            bin_type = double(fread_matrix(server));
        else
            bin_type = 1;
        end
        
        % Predict cursor position
        cursor_pred = emgs(:)'*EMG2F_w;
        cursor_pos  = cursor_pred;
        
        % Its a catch trial
        if (((bin_type == 1 && ~isnan(target_position(1)) && ...
                (bin_count - last_target_bin)*50 >= adapt_delay && ...
                (bin_count - last_target_bin)*50 <= (adapt_delay+adapt_duration))) || ...
                (bin_type == 1 && simulate))
            
            % save info for this trial
            previous_trials = [previous_trials;
                dataset({bin_count, 'bin_count'}, ...
                {last_target_bin, 'target_bin'}, ...
                {last_target, 'target_id'}, ...
                {{target_position}, 'target_position'}, ...
                {{cursor_pred}, 'target_predicted'}, ...
                {{spikes}, 'spikes'}, ...
                {{emgs}, 'emgs'})]; %#ok<AGROW>
            
            % show how well are the last trial catches being predicted
            tmp_true = previous_trials.target_position;
            tmp_predicted = previous_trials.target_predicted;
            tmp_true = horzcat(tmp_true{:})';
            tmp_predicted = vertcat(tmp_predicted{:});
            
            min_idx = max(1, size(tmp_true, 1)-20);
            max_idx = size(tmp_true, 1);
            
            last_20R = diag(corr(...
                tmp_true(min_idx:end, :), ...
                tmp_predicted(min_idx:max_idx, :)))';
            
            % check if it is a trial in which we need to adapt
            if (~fix_decoder)
                if ~simulate && show_adaptation_progress
                    % adapt trial and within adapt window
                    disp(sprintf('Adaptation idx %d', adaptation_idx));
                    disp(['Task target position: ' ...
                        sprintf('%.2f %.2f', target_position(1), target_position(2))]);
                    disp(['Cursor prediction: ' ...
                        sprintf('%.2f %.2f', cursor_pred(1), cursor_pred(2))]);
                    disp(sprintf('Adapting to target %d',last_target));
                end
                
                % gradient accumulator
                accum_g = zeros(size(S2EMG_w));
                accum_n = 0;
%                target_list = unique(previous_trials.target_id)';
                target_list = previous_trials.target_id(end);
                if 1 %nnz(target_list) > 5 % start adapting only when 5 or more different targets have been shown
                    for t = target_list
                        % find the last n_adapt_to_last target t and adapt
                        idx_list = find(previous_trials.target_id == t, ...
                            n_adapt_to_last, 'last');
                        for idx = idx_list(:)'
                            tmp_spikes = previous_trials.spikes{idx};
                            tmp_emgs = previous_trials.emgs{idx};
                            tmp_target_position = ...
                                previous_trials.target_position{idx};
                            
                            accum_g = backpropagation_through_time(S2EMG_w, EMG2F_w, ...
                                tmp_spikes, tmp_emgs, ...
                                tmp_target_position(:)', ...
                                n_lag, n_lag_emg);
                            
                            % count how many gradients we have accumulated
                            accum_n = accum_n + 1;
                        end
                    end
                    
                    g = accum_g/accum_n;
                    
                    S2EMG_w = S2EMG_w - LR*g;
                end
                
                emgs_new = emgs;
                emgs_new(:, 1) = [1 rowvec(spikes(:, 1:n_lag))']*S2EMG_w;
                %disp(target_position(:)');
                if show_adaptation_progress
                    old_se = (emgs(:)'*EMG2F_w - target_position(:)');
                    new_se = (emgs_new(:)'*EMG2F_w - target_position(:)');
                    disp(sprintf('Old sse: (%.2f, %.2f) T=%.2f  New sse: (%.2f, %.2f) T=%.2f', ...
                        old_se(1)^2, old_se(2)^2, sum(old_se.^2), ...
                        new_se(1)^2, new_se(2)^2, sum(new_se.^2)));
                end
                
                adaptation_idx = adaptation_idx + 1;
            end
        end
        
        % predict EMG and store it in lagged matrix
        emgs(:, 2:end) = emgs(:, 1:(end-1));
        emgs(:, 1) = [1 rowvec(spikes(:, 1:n_lag))']*S2EMG_w;
        
        % Predict cursor position
        cursor_pred_adapted = emgs(:)'*EMG2F_w;
        
        if ~cursor_assist
            cursor_pos = cursor_pred;
        else
            prev_assist_dist = cursor_pos - cursor_pred;
            
            tgt_dist = target_position - cursor_pos;
            cursor_pos = cursor_pos + 0.2*tgt_dist;
            assist_dist = cursor_pos - cursor_pred;
        end
        
        if ~simulate
            %Send prediction
            fwrite_matrix(server, single(cursor_pos));
        end
        
        % save results every 30 seconds
        if mod(bin_count*1/20, 30) == 0
            save([savedir '/previous_trials_' datestr(now) '.mat'], 'previous_trials','S2EMG_w');
        end
        
        % each second show adaptation progress
        if mod(bin_count*1/20, 1) == 0
            disp([sprintf('Time: %d secs, ', bin_count*1/20) ...
                'Adapting: ' num2str(~fix_decoder) ', ' ...
                'Simulation: ' num2str(simulate) ', '...
                'prediction corr: ' num2str(last_20R)]);
        end
        
        
        if display_plots && ~isnan(target_position(1)) %%&& ...
            %             (bin_type == 1 && ~isnan(target_position(1)) && ...
            %                 (bin_count - last_target_bin)*50 >= 150 && ...
            %                 (bin_count - last_target_bin)*50 <= 1000)
            %subplot(1, 3, 1);
            hold off;
%             plot(bsxfun(@plus, spikes', 50*(1:size(spikes, 1))))
%             xlim([1 n_lag+1]);
%             ylim([0 n_neurons*50]);
            %subplot(1, 3, 2);
            hold off;
            plot(target_position(1), target_position(2), 'o');
            hold on;
            if  (bin_type == 1 && ~isnan(target_position(1)) && ...
                    (bin_count - last_target_bin)*50 >= 150 && ...
                    (bin_count - last_target_bin)*50 <= 1000)
                display_color = 'r';
            else
                display_color = 'k';
            end
            plot(cursor_pred(1), cursor_pred(2), [display_color 'o']);
%             plot(cursor_pred_adapted(1), cursor_pred_adapted(2), ...
%                 [display_color '+']);
%             
            xlim([-20 20]);
            ylim([-20 20]);
%             subplot(1, 3, 3);
            
%             imagesc(S2EMG_w, [-0.5 0.5]);
%             colormap(gray);
            %             colorbar;
            drawnow;
            %subplot(1, 4, 4);
            %plot(smooth(errors, 100));
            %drawnow;
        end
        if simulate
            %pause(0.05);
        end
        %total_time = total_time + toc;
        n = n + 1;
        %disp(n);
        if mod(n, 1000) == 0
            elapsed = toc;
            fprintf('%.2f MB/s ', numel(newest_spikes)*4*n/(elapsed*2^20));
            fprintf('%.1f msg/s\n', n/elapsed);
            n=0;
            tic;
        end
    end
catch e
    close all;
    % close socket if server is interrupted
    if ~isempty(server)
        %tcpip_java_close(server);
        pnet(server.sockcon, 'close');
    end
    
    rethrow(e);
end

avg_time = total_time/n;

end

