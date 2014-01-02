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
parse(p, varargin{:});

n_port = p.Results.n_port;
n_lag = p.Results.n_lag;
n_neurons = p.Results.n_neurons;
n_emg = p.Results.n_emg;
display_plots = p.Results.display_plots;
n_lag_emg = size(EMG2F_w, 1)/n_emg;
n = 0;
total_time = 0;
server = [];
bin_count = 0;
try
    disp('Server waiting for client...');
    server = tcpip_c(n_port);
    disp('Client connected');
    % Send ACK about connection
    send_ack(server);

    %spikes = zeros(n_neurons, n_lag);
    spikes = [];
    emgs = zeros(n_emg, n_lag_emg);
%     emgs = zeros(n_emg, n_lag);
    errors = [];
    targets = [];
    last_target_bin = NaN;
    target_position = NaN; 
    tic;
    % Infinite loop    
    adaptation_idx = 1;
    while(true)        
        
        bin_count = bin_count + 1;       
        %send_ack(server);
        
        % Receive spikes            
        newest_spikes = fread_matrix(server);
        newest_spikes = [0;0;0;0];
        if isempty(spikes)
            spikes = zeros(length(newest_spikes(:)), n_lag + ...
                n_lag_emg-1);
        end        
        
        
%         spikes = zeros(length(newest_spikes(:)), n_lag + ...
%                 n_lag_emg);
        
%         tic;
    
        % Receive target ID        
        target_id = double(fread_matrix(server));
        %disp(target_id);
        targets = unique([targets target_id]);
        %disp(targets);
        
        % decode target position
        if target_id == 0
            target_position = [0; 0];                
        elseif target_id > 0 && target_id <= 8
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
        
        target_position = [0; 0];
        target_position(1) = 10*mod(round(bin_count/100), 2) - 5;
        target_position(2) = 10*mod(round(bin_count/25), 2) - 5;
        
        
        % Shift spikes
        spikes(:, 2:end) = spikes(:, 1:(end-1));        
        % put newest spikes on first column
        newest_spikes = zeros(size(newest_spikes));
        newest_spikes(1) = target_position(1)>2;
        newest_spikes(2) = target_position(2)>2;
        newest_spikes(3) = target_position(1)<2;
        newest_spikes(4) = target_position(2)<2;
        spikes(:, 1) = newest_spikes;
        
        % Receive bin type
        bin_type = double(fread_matrix(server));
        %bin_type = 1; % 1-Adapt, 0-Don't
        
        %disp([target_id bin_type]);
        
        
        % predict EMG and store it in lagged matrix
        emgs(:, 2:end) = emgs(:, 1:(end-1));
        emgs(:, 1) = [1 rowvec(spikes(:, 1:n_lag))']*S2EMG_w;
        
        % Predict cursor position
        cursor_pred = emgs(:)'*EMG2F_w;
        
        %Send prediction
        fwrite_matrix(server, single(cursor_pred(:)));
        
%         disp(sprintf('%f ms messaging time', toc*1000));
        
        
        if bin_type == 1
%             disp(bin_count - last_target_bin);
        end
        if (bin_type == 1 && ~isnan(target_position(1)) && ...
                (bin_count - last_target_bin)*50 >= 0 && ...
                (bin_count - last_target_bin)*50 <= 2000) || true
            % adapt trial and within adapt window
%             disp(sprintf('Adaptation idx %d', adaptation_idx));
%             disp(['Task target position: ' num2str(target_position(:)')]);
%             disp(['Cursor prediction: ' num2str(cursor_pred(:)')]);
%             disp(sprintf('Adapting to target %d',last_target));
            
            % 
            g = backpropagation_through_time(S2EMG_w, EMG2F_w, ...
                spikes, emgs, target_position(:)', ...
                n_lag, n_lag_emg);
            
            S2EMG_w = S2EMG_w - learning_rate*g;
            
%             S2EMG_w = adapt_func(S2EMG_w, spikes(:)', ...
%                 target_position(:)');
            disp(sqrt(sum(S2EMG_w(:).^2)));
            adaptation_idx = adaptation_idx + 1;
%             S2EMG_w = adapt_func(S2EMG_w, [1; spikes(:)]', ...
%                 target_position);
        end
%         errors = [errors; ...
%             mean((target_position - target_pred).^2)];
        if display_plots
            subplot(1, 3, 1);
            hold off;
            plot(bsxfun(@plus, spikes', 50*(1:size(spikes, 1))))
            xlim([1 n_lag+1]);
            ylim([0 n_neurons*50]);
            subplot(1, 3, 2);
            hold off;
            plot(target_position(1), target_position(2), 'o');
            hold on;
            plot(cursor_pred(1), cursor_pred(2), 'or');
            xlim([-20 20]);
            ylim([-20 20]);
            subplot(1, 3, 3);
            imagesc(S2EMG_w, [-0.5 0.5]);
            colormap(gray);
            %colorbar;
            %subplot(1, 4, 4);
            %plot(smooth(errors, 100));
            %drawnow;
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

