function avg_time = prediction_server(dummy, n_port, n_neurons, ...
    n_lag, pred_func)
% Simple prediction server at IP and port n_port.
% It calls pred_func with the spikes, lagged n_lag times, and 
% the sampling rate where pred_func needs to return [x, y]

n = 0;
total_time = 0;
server = [];
try
    server = tcpip_c(n_port);
    disp('Client connected...');
    % Send ACK about connection
    send_ack(server);   

    spikes = zeros(n_neurons, n_lag);

    % Infinite loop
    tic;
    while(true)
        
        % Receive spikes
        newest_spikes = fread_matrix(server);
        
        % Shift spikes
        spikes(:, 2:end) = spikes(:, 1:(end-1));
        % put last spikes on first row
        spikes(:, 1) = newest_spikes(:, 1);
        
        %imagesc(spikes, [0 10]);
        
        % Call prediction function
        x = pred_func(spikes, []);
        x = [cos(n/10)*10; sin(n/10)*10];

        % Send prediction back
        fwrite_matrix(server, single(x(:)));
        subplot(1, 2, 1);
        plot(bsxfun(@plus, spikes', 50*(1:size(spikes, 1))))
        subplot(1, 2, 2);
        plot(x(1), x(2), 'o');
        xlim([-100 100]);
        ylim([-100 100]);
        drawnow;
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
    % close socket if server is interrupted
    if ~isempty(server)
        %tcpip_java_close(server);
        pnet(server.sockcon, 'close');
    end
    rethrow(e);
end

avg_time = total_time/n;