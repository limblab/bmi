function test_ws_latency( nbr_ch, nbr_reps )


% Initialize communication, etc
dbg_lvl             = 0; % no verbose
serial_string       = 'COM3'; % default port in lab 1 computer

ws                  = wireless_stim(serial_string, dbg_lvl);


% where the latencies will be stored
dirname             = 'E:\Data-lab1\TestData\wireless_stim_tests\latency_tests';
% go to this directory, to read the stimulation calibration file
cur_dir             = pwd;
cd(dirname);

% retrieve date and time to store the data
date4filename       = datestr(now,'yyyymmddTHHMMSS');


 try
     % comm_timeout specified in ms, or disable
     reset          = 1;   % reset FPGA stim controller
     ws.init(reset, ws.comm_timeout_disable);
     
     ws.version();      % print version info, call after init
     
     % stimulate 'nbr_ch' channels with different PWs
     ch_list        = 1:nbr_ch;
     if nbr_ch > 16
         warning('the stimulator has 16 channels; the test will be limited to these 16');
         ch_list    = 1:16;
     end
     
     % -------------------------
     % initialize the stimulator
     amp_offset_10k_ohm     = 1000;  % ~1mA
     amp_offset_100_ohm     = 5000;  % ~5mA
     amp            = amp_offset_100_ohm;   % select your load board here
     
     % configure train delay differently for each channel. Allow min TD =
     % 50 us, to avoid problems with waveform shape
     stagger        = 100;  % us
     td             = (50+stagger) : stagger : (50+ stagger*nbr_ch);
     
     % setup single element struct array to configure the params that won't
     % be changed
     cmd{1}         = struct(...
                        'TL', 100, ...
                        'Freq', 30, ...
                        'CathAmp', 32768+amp, ...  % 16-bit DAC setting
                        'AnodAmp', 32768-amp, ...  % 16-bit DAC setting
                        'TD', td, ...           % train delay per channel
                        'PL', 1, ...           % Cathodic first
                        'Run', ws.run_once ... % Single train mode
                        );
    
    % set the initial parameters
    ws.set_stim(cmd, ch_list);  % set the parameters

    
    % -------------------------
    % create matrix with pws
    % the PWs we will use
    pw             = 50:10:400;
    % this matrix will have in each column the PW that will be sent to
    % each channel (row)
    pw_matrix      = repmat(pw,nbr_ch,ceil(nbr_reps/numel(pw)));
    % randomize the PW sequence, independently for each channel
    for i = 1:nbr_ch
        pw_matrix(i,:) = pw_matrix(i,randperm(size(pw_matrix,2)));
    end
    % cut 'pw_matrix' to the desired number of repetitions
    pw_matrix      = pw_matrix(:,1:nbr_reps);
     
    
    % initialize a matrix will the latencies will be stored
    latencies       = zeros(1,nbr_reps);
    
    % create progress bar
    h_pb            = waitbar(0,'stim progress');
    
    % now update the pw for each channel, as many times as specified in
    % 'nbr_reps'
    for i = 1:nbr_reps
        % get current time, to compute latency
        cur_t       = tic;
        % update stimulation command, using 'run cont'
        cmd{1}      = struct('CathDur', pw_matrix(:,i), 'AnodDur', ...
                        pw_matrix(:,i), 'Run', ws.run_cont);
        ws.set_stim(cmd ,ch_list);
        % store latency
        latencies(i) = toc(cur_t);
        
        pause(0.1);
        
        % update progress bar every 10 %
        if rem(i,10) == 0
            waitbar(i/nbr_reps);
        end
    end
 
    % save data
    save( fullfile(dirname,date4filename), 'pw_matrix','latencies','nbr_ch','nbr_reps' );
    
    % plot histogram latencies
    histogram(latencies*1000);
    xlabel('latency (ms)');
    ylabel('counts');
     
    % go back to where you were
    cd(cur_dir);
    
    % close progress bar
    close(h_pb) 
    
 catch ME
     delete(ws);
     %disp(ME);
     rethrow(ME);
 end
 
 % delete WS object
 delete(ws);
end