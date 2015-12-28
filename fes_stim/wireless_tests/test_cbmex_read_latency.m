%
% Function to test CBMEX reading latency. The function creates data files
% that can be automatically deleted 

function lats = test_cbmex_read_latency( nbr_reps, keep_cb_file ) 


% read cerebus time after reading data?
read_cb_time        = false;

% path were blackrock's data will be stored
dir_name            = 'E:\Data-lab1\TestData\cbmex_latency';


% -------------------------
% Setup data storage

% create file name
file_name           = [datestr(now,'yyyymmdd_HHMMSS') '_cbmex_lat'];

% connect to central; if connection fails, return error message and quit
if ~cbmex('open', 1)
    echoudp('off');
    error('ERROR: Connection to Central Failed');
end

 % start 'file storage' app, or stop ongoing recordings
cbmex('fileconfig',fullfile(dir_name,file_name),'',0) ;

% waiting ritual to make sure it will work
drawnow; pause(1); drawnow;

% start cerebus file recording
cbmex('fileconfig',fullfile(dir_name,file_name), '', 1);

% configure to buffer only event data
cbmex('trialconfig',1,'nocontinuous');


% ---------------
% Perform the data reads

% create progress bar
h_pb                = waitbar(0,'cbmex read progress');

% latency vector
latencies           = zeros(1,nbr_reps);

for i = 1:nbr_reps
    % get current time, to compute latency
    cur_t       = tic;
    % read data (and flush buffer)
    ts_cell_array = cbmex('trialdata',1);
    
    if read_cb_time
        sys_time  = cbmex('time');
    end
    % store latency
    latencies(i) = toc(cur_t);
    % wait for a little bit...
    pause(0.1);
    
    % update progress bar every 10 %
    if rem(i,10) == 0
        waitbar(i/nbr_reps);
    end
end


% ---------------
% Finish recording and close communication

% stop cerebus file recording
cbmex('fileconfig', fullfile(dir_name,file_name), '', 0);
cbmex('close');

% close progress bar
close(h_pb)

% ---------------
% Plot hist of latencies 
figure;
histogram(latencies*1000);
xlabel('latency (ms)');
ylabel('counts');

% save data
save( fullfile(dir_name,file_name), 'latencies','nbr_reps' );

% return variables
lats                = latencies;


% delete cerebus files, if chosen
if ~keep_cb_file
    cur_dir         = pwd;
    cd(dir_name);
    % delete NEV and CCF files
    file_name_1     = [file_name, '.nev'];
    file_name_2     = [file_name, '.ccf'];
    delete(file_name_1,file_name_2);
    % go back to where you were
    cd(cur_dir);
end