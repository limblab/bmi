%
% Stimulate to obtain the relationship between stimulation pulse width and
% joing force  
%
%   force = GET_PW_TO_FORCE( get_pw_f_params )
%
%
% Notes:
%   - So far, the code assumes that all the electrodes will be stimulated
%   at the same time; ToDo: implement a version to randomly go through a
%   list as in train_trig_avg
%
% ToDo's:
%   - add the informtaion about stimulaed channels, pw, etc once not every
%   time in read_cbmex_stta_data
%

function force = get_pw_to_force( varargin ) 



%------------------------------------
% read parameters. If no argument is passed load defaults
if nargin > 1   
    error('ERROR: The function only takes one argument of type get_pw_to_f_params');
elseif nargin == 1
    pwfp                = varargin{1};
    % fill missing params, if any
    pwfp                = get_pw_to_force_params_defaults(pwfp);
elseif nargin == 0
    pwfp                = get_pw_to_force_params_defaults();
end


%------------------------------------
% Stuff for data storage

% create folder name
hw.data_dir             = [pwfp.data_dir, filesep, 'PW_to_f_data_', datestr(now,'yyyy_mm_dd')];
% make the folder, if it doesn't already exist
if ~isdir(hw.data_dir), mkdir(hw.data_dir); end
% store current date and time, for the file name
hw.start_t              = datestr(now,'yyyymmdd_HHMMSS');

% --> Struct 'hw' will contain hardware handles, info to store data...


%--------------------------------------------------------------------------
%% connect with Central, start and configure data storage, and other checks
[hw, force]             = init_cbmex_for_stta( hw, pwfp, 'force' );



%--------------------------------------------------------------------------
%% Set up the stimulator

% connect to the stimulator
hw                      = connect_to_stim( hw, pwfp );

% configure stimulation parameters (except the PW that is updated in the
% loop below) 
hw                      = init_stimulator( pwfp, hw );



%% Initalize other things

% compute desired PWs, and randomize order (nbr PWs x nbr reps)
pwfp.pw_order           = linspace(pwfp.pw_rng(1),pwfp.pw_rng(2),pwfp.pw_steps);
pwfp.pw_order           = repmat(pwfp.pw_order,1,pwfp.nbr_reps);
hw.nbr_total_stims      = numel(pwfp.pw_order);
pwfp.pw_order           = pwfp.pw_order( randperm(hw.nbr_total_stims) );

% the total time to wait after recordings in central have started -for each
% stimulus. Plus 100 ms extra to avoid sync issues. Converted to s
hw.stim_wait_t          = ( pwfp.t_before + pwfp.train_dur + pwfp.t_after + 100 ) / 1000;


% Message box to stop the stimulation and exit, saving the data
hw.keep_running        	= msgbox('Click ''ok'' to stop the stimulation','FES');
set(hw.keep_running,'Position',[200 700 125 52]);
drawnow;
% Progress bar 
hw.prog_bar           	= waitbar(0, sprintf('Stimulation progress'));


% Add time varying stim parameter in force
force.stim_pws          = pwfp.pw_order;

%--------------------------------------------------------------------------
%% where the stimulation happens

% initialize stim ctr
hw.ctr_stim_nbr         = 1;

% sitmulation loop
while hw.ctr_stim_nbr <= hw.nbr_total_stims
   
    %---------------------------------------------------------------------
    % Prepare to stimulate
    
    % update the stimulation string/command with the iteration-varying params
    %   (over)write PW command
    hw.sp.pw            = pwfp.pw_order( hw.ctr_stim_nbr );
    if strncmp(pwfp.stimulator,'gv',2)
        hw.stim_string  = stim_params_to_stim_string( hw.sp );
    elseif strncmp(pwfp.stimulator,'ws',2)
        hw.stim_cmd{1}  = struct(   'CathDur', hw.sp.pw*1000, ...
                                    'AnodDur', hw.sp.pw*1000, ...
                                    'Run', hw.ws.run_once_go); %run_once_go
    end
    
    %---------------------------------------------------------------------
    % See if it is time to stimulate (user pressed key or word), start
    % recording and stimulate
    
    % 1. time to stimulate?
    if strncmp(pwfp.ctrl_mode,'keyboard',8)
        % if stim is controlled manually
        disp('Press any key to stimulate')
        pause;
    elseif strncmp(pwfp.ctrl_mode,'word',4)
        % ToDo: Read the words from central
        % read_words()
        
        % see if we got the word we want....
    end

    % 2. start data collection
    cbmex('trialconfig', 1);
    % wait for a little bit until central starts recording
    pause(0.2);
    drawnow; drawnow; drawnow;
    % get current time, for recording
    hw.t_start          = tic;
    drawnow;
    
    % 3. send stimulation command
    if strncmp(pwfp.stimulator,'gv',2)
        % this command has the stimulator wait (baseline recording time,
        % specified in pwfp.t_before) already built in 
        xippmex('stim',hw.stim_string);
    elseif strncmp(pwfp.stimulator,'ws',2)
        % record baseline force during pwfp.t_before
        hw.t_before_wait = tic;
        while hw.t_before_wait < pwfp.t_before
            hw.t_before_wait = toc(hw.t_before_wait);
        end
        hw.ws.set_stim(hw.stim_cmd, hw.sp.elect_list);
    end
    drawnow; drawnow;
    
    % 4. wait to record for t_before t_train_duration + t_after
    hw.t_stop           = toc(hw.t_start);
    while hw.t_stop < hw.stim_wait_t
        hw.t_stop       = toc(hw.t_start);
    end
    
    %---------------------------------------------------------------------
    % read data from central and populate force struct with raw data and
    % evoked responses 
    [hw, force]         = read_cbmex_stta_data( force, pwfp, hw );
    
    %---------------------------------------------------------------------
    % Wait for 'min_time_btw_trains' ms --to avoid delivering a bunch of
    % trains in a row
    hw.t_wait           = tic;
    hw.elapsed_t        = toc(hw.t_wait);
    while hw.elapsed_t < pwfp.min_time_btw_trains/1000
        hw.elapsed_t    = toc(hw.t_wait);
    end
    
    
    %---------------------------------------------------------------------
    % update stim ctr, progress bar and check if user stopped stim
    
    % update ctr
    hw.ctr_stim_nbr     = hw.ctr_stim_nbr + 1;
    
    % update the progress bar, in 10% steps
    waitbar(hw.ctr_stim_nbr/hw.nbr_total_stims,hw.prog_bar)
    
    % if the message box is closed, stop recordings
    if ~ishandle(hw.keep_running)
        break; 
    end
end


%--------------------------------------------------------------------------
%% add metadata to force/emg data, and save everything

if ishandle(hw.keep_running )
    delete( hw.keep_running );
end
disp('Stimulation finished')
delete(hw.prog_bar);


% pause for 1 s to make sure we read the whole buffer
pause(1);
drawnow;


% add meta fields to force
force.meta.time         = hw.start_t;
force.meta.mokey        = pwfp.monkey;
force.meta.task         = pwfp.task;
force.meta.muscle       = pwfp.muscle;
force.meta.stim_amp     = pwfp.amp;
force.meta.stim_freq    = pwfp.freq;
force.meta.train_dur    = pwfp.train_dur;
force.meta.stim_pws     = linspace(pwfp.pw_rng(1),pwfp.pw_rng(2),pwfp.pw_steps);
force.meta.nbr_stims    = pwfp.nbr_reps;

% clear aux var
clear aux;


%--------------------------------------------------------------------------
%% stop communication with central
    
cbmex('fileconfig', hw.cb_file_name, '', 0);
cbmex('close');
drawnow;
drawnow;
disp('Communication with Central closed');


%--------------------------------------------------------------------------
%% stop communication with the wireless stimulator

if strcmp(pwfp.stimulator,'ws')
    delete(hw.ws);
end


% ------------------------------------------------------------------------
%% Characterize and plot the responses, and save the data

% save the data
save(fullfile(hw.data_dir,hw.cb_file_name),'force','pwfp');
disp(['Force data and Params saved in ' hw.cb_file_name '.mat']);

% call function that analyses and plots the data
force = pw_to_force( force, pwfp );





%%
%
% Function to initialize the grapevine/wireless stimulation parameters for
% doing PW or amplitude modulated FES
%
%   function [hw,varargout] = init_cbmex_for_stta( hw, stta_params, varargin )
%
% Inputs:
%   arguments 3 and 4 can be 'emg' or 'force' to define that we'll record
%   emg and/or force. 
%
% Outputs:
%   The order for the outputs is EMG and then Force if both are present
%


function [hw, varargout] = init_cbmex_for_stta( hw, stta_params, varargin )


% declare flags
read_emg = false; read_force = false;

% read input parameters
for i = 3:nargin
    if strncmpi(varargin{i-2},'force',5)
        read_force      = true;
    elseif strncmpi(varargin{i-2},'emg',3)
        read_emg        = true;
    end
end

% connect to central; if connection fails, return error message and quit
if ~cbmex('open', 1)   
    echoudp('off'); error('ERROR: Connection to Central Failed');
end

%------------------------------------
% For file storage in Central

% create file name
hw.cb_file_name         = [stta_params.monkey '_' hw.start_t '_' stta_params.task ...
                            '_' stta_params.muscle '_pw_to_f'];

% start Central's file storage app, assigning the filename
cbmex('fileconfig', fullfile(hw.data_dir,hw.cb_file_name), '', 1);
drawnow;

%------------------------------------
% Check signals (Central's hardware settings & connected stuff)

% read a 1-s stream of data. To know what is connected
cbmex('trialconfig', 1); 
drawnow; pause(1); 

[ts_cell_array, ~, analog_data] = cbmex('trialdata',1);
analog_data(:,1)      	= ts_cell_array([analog_data{:,1}]',1);


% look for the 'sync out' threshold crossing signal, called 'Stim_trig' in Central
hw.cb_sync.ch_nbr       = find(strncmpi(ts_cell_array(:,1),'Stim',4));
% if there is no sync signal (in Cenral's hardware settings), exit
if isempty(hw.cb_sync.ch_nbr)
    error('ERROR: Sync signal not found in Cerebus. The channel has to be named Stim_XXXX');
else
    disp('Sync signal found');
    % store sync signal fs
    hw.cb_sync.fs       = cell2mat( analog_data(find(strncmp(analog_data(:,1), 'Stim', 4),1),2) );
end


% look for force sensors and store info about them
if read_force
    force.labels            = analog_data( strncmpi(analog_data(:,1), 'Force', 5), 1 );
    force.nbr_forces        = numel(force.labels);
    disp(['Nbr Force Sensors: ' num2str(force.nbr_forces)]);

    force.fs                = cell2mat(analog_data(find(strncmp(analog_data(:,1), 'Force', 5),1),2));

    % Force data will be stored in the 'force' data structure
    % 'force.evoked_force' has dimensions Force response -by- Force sensor
    % - by- stimulus nbr -by stimulation electrode
    % force.stimulated_channels has info on which channels were stimulated
    % [stim time, stim electrode, boolean on if cbmex found sync pulse] 
    force.length_evoked_force   = ( stta_params.t_before + stta_params.train_dur + stta_params.t_after) * force.fs/1000 + 1;
    force.evoked_force          = zeros( force.length_evoked_force, force.nbr_forces, ...
                                    stta_params.pw_steps*stta_params.nbr_reps, numel(stta_params.elec) );
    %force.stimulated_channels   = zeros(stta_params.nbr_stims_ch*numel(ttap.stim_elec),3);
end

clear analog_data ts_cell_array;
cbmex('trialconfig', 0);        % stop data collection until the stim starts

if nargin==3
    if read_force
        varargout{1}        = force;
    elseif read_emg
        varargout{1}        = emg;
    end
elseif nargin
    varargout{1}            = emg;
    varargout{2}            = force;
end






%% 
%
% Connect to the stimulator

function hw = connect_to_stim( hw, sim_params )

%------------------------------------
% if using the Grapevine, connect to it, and do some checks
if strncmp(sim_params.stimulator,'gv',2)

    % connect to Grapevine. If there's a comm error, close communication with
    % Central and exit 
    if xippmex ~= 1
        cbmex('close'); error('ERROR: Xippmex did not initialize');
    end
    
    % check that the sync out channel has not been mistakenly chosen for stim
    if ~isempty(find(sim_params.elec == sim_params.sync_ch,1))
        cbmex('close'); error('ERROR: sync out channel chosen for FES!');
    end
    
    % find all Micro+Stim channels (stimulation electrodes). Quit if no
    % stimulator is found 
    hw.gv.stim_ch       = xippmex('elec','stim');
    if isempty(hw.gv.stim_ch)
        cbmex('close'); error('ERROR: no stimulator found!');
    end
    
    % quit if the stim channels are not present, or if the sync ch is not present
    if numel( find(ismember(hw.gv.stim_ch,sim_params.elec)) ) ~= numel(sim_params.elec)
        cbmex('close'); error('ERROR: some stimulation channels were not found!');
    elseif isempty( find(hw.gv.stim_ch == sim_params.sync_ch,1) )
        cbmex('close'); error('ERROR: sync out channel not found!');
    end
    
    % add the stimulator resolution field to sim_params
	sim_params.stim_res       = 0.018;

%------------------------------------
% if it's the wireless stimulator, ...    
elseif strncmp(sim_params.stimulator,'ws',2)
    
    % connect to the stimulator 
    dbg_lvl             = 0; % can be changed
    hw.ws               = wireless_stim(sim_params.serial_ws,dbg_lvl);
    
    % go to the calibration folder
    cur_dir             = pwd;
    cd(sim_params.path_cal_ws);
    
    % try/catch helps avoid left-open serial port handles and leaving
    % the Atmel wireless modules' firmware in a bad state
    try
        % comm_timeout specified in ms, or disable
        reset           = 1; % reset FPGA stim controller
        hw.ws.init(reset, hw.ws.comm_timeout_disable);
    catch ME
        delete(hw.ws);
        disp(datestr(datetime(),'HH:MM:ss:FFF'));
        rethrow(ME);
    end
    
    % go back to the original directory
    cd(cur_dir); clear cur_dir;
    
    % check that the sync out channel has not been mistakenly chosen for stim
    if ~isempty(find(sim_params.elec == sim_params.sync_ch,1))
        cbmex('close'); 
        delete(hw.ws);
        error('ERROR: sync out channel chosen for FES!');
    end
    
    % quit if the stim channels are not present, or if the sync ch is not present
    if numel( find(ismember(1:hw.ws.num_channels,sim_params.elec)) ) ~= numel(sim_params.elec)
        cbmex('close');         
        delete(hw.ws);
        error('ERROR: some stimulation channels were not found!');
    elseif isempty( find(1:hw.ws.num_channels == sim_params.sync_ch,1) )
        delete(hw.ws);
        cbmex('close'); 
        error('ERROR: sync out channel not found!');
    end
end


%%
%
% Function to initialize the grapevine/wireless stimulation parameters for
% doing PW or amplitude modulated FES
%
%   function hw = init_stimulator( stim_params, hw )


function hw = init_stimulator( stim_params, hw )

% - for the Grapevine
if strncmp(stim_params.stimulator,'gv',2)
 
    % for monopolar stim
    if size(stim_params.elec,1) == 1
    
    hw.sp.elect_list    = [stim_params.elec, stim_params.sync_ch];
    % create an amplitude vector, because it size has to be equal to the
    % number of electrodes since we want different amp for the stim
    % electrodes and the sync ch
    if length(stim_params.amp) == 1, hw.sp.amp = repmat(stim_params.amp,1,length(stim_params.elec)); end
    hw.sp.amp           = [hw.sp.amp/numel(stim_params.elec), stim_params.stim_res*127];
    hw.sp.freq          = stim_params.freq;
    hw.sp.pol           = stim_params.pol;
    hw.sp.pw            = stim_params.pw_rng(1); % this value will be overwritten every stim cycle
    % create a train length vector, because it size has to be equal to the
    % number of electrodes since we only want one sync pulse
    hw.sp.tl            = [repmat(stim_params.train_dur,1,length(stim_params.elec)) ceil(1000/stim_params.freq)];
    % Give a warning if stim dur > 1 s; the code needs to be fixed to
    % suport that
    if stim_params.train_dur > 1000, warning('Stimulus duration > 1000 ms'); end
    % add t_before stim as TD
    hw.sp.delay         = repmat(stim_params.t_before/1000,1,length(stim_params.elec)+1);
    hw.sp.stim_res      = 0.018; % the resolution of our grapevine (mA)
    % --> 'fs' and 'delay' are left set to their defaultsvalues
    hw.sp               = stim_params_defaults( hw.sp );
    elseif size(stim_params.elec,1) == 2
        cbmex('close');
        error('bipolar stimulation not implemented for the grapevine yet');
    end
% - for the wireless stimulator
elseif strncmp(stim_params.stimulator,'ws',2)
    
    hw.sp.stim_res      = 0.001; % the resolution of our wireless stim (mA)
    
    % for monopolar stimulation
    if size(stim_params.elec,1) == 1
        hw.sp.elect_list    = [stim_params.elec, stim_params.sync_ch];
        % setup a series of stimulation commands to intialize the stimulator
        % --we need to pass several command because there is a maximum package
        % size in zigbee 

        % calculate train length for stimulating electrodes and a single
        % pulse for the sync electrode 
        hw.ws.set_TL([repmat(stim_params.train_dur,1,length(stim_params.elec)) ...
                                ceil(1000/stim_params.freq)], hw.sp.elect_list);      
        % define common parameters, frequency, amplitude and running mode
        hw.stim_cmd{1}      = struct(   'Freq', stim_params.freq, ...
                                        'CathAmp', 32768+stim_params.amp*1000, ...
                                        'AnodAmp', 32768-stim_params.amp*1000, ...
                                        'TD', stim_params.train_dur, ...
                                        'PL', 1, ...
                                        'Run', hw.ws.run_once);
        hw.ws.set_stim( hw.stim_cmd, hw.sp.elect_list );
        
        % overwrite stimulus amplitude for the sync channel, so it's 4 mA
        hw.stim_cmd{1}      = struct(   'CathAmp', 32768+4*1000, ...
                                        'AnodAmp', 32768-4*1000);
        hw.ws.set_stim( hw.stim_cmd, stim_params.sync_ch );
        
        % train delay has to be > 50 us, to prevent weird waveform shapes
        hw.ws.set_TD( repmat(100,1,length(stim_params.elec)+1), ...
                        hw.sp.elect_list );
    
    % for bipolar stimulation
    elseif size(stim_params.elec,1) == 2
        hw.sp.elect_list    = [reshape(stim_params.elec,numel(stim_params.elec),1)', ...
                                stim_params.sync_ch];
        
        % setup a series of stimulation commands to intialize the stimulator
        % --we need to pass several command because there is a maximum package
        % size in zigbee 

        % define train length for stimulating electrodes and a single pulse for
        % the sync electrode
        hw.ws.set_TL([repmat(stim_params.train_dur,1,length(stim_params.elec)) ...
                                ceil(1000/stim_params.freq)], hw.sp.elect_list);      
        % define common parameters, frequency and amplitude
        hw.stim_cmd{1}      = struct(   'Freq', stim_params.freq, ...
                                        'TD', stim_params.train_dur, ...
                                        'CathAmp', 32768+stim_params.amp*1000, ...
                                        'AnodAmp', 32768-stim_params.amp*1000, ...
                                        'Run', hw.ws.run_once);
        hw.ws.set_stim( hw.stim_cmd, hw.sp.elect_list );
        
        % define polarity 
        hw.ws.set_PL( 1, hw.sp.elect_list(1:2:numel(hw.sp.elect_list)) );
        hw.ws.set_PL( 0, hw.sp.elect_list(2:2:numel(hw.sp.elect_list)-1) );
        
        % overwrite stimulus amplitude for the sync channel, so it's 4 mA
        hw.stim_cmd{1}      = struct(   'CathAmp', 32768+4*1000, ...
                                        'AnodAmp', 32768-4*1000);
        hw.ws.set_stim( hw.stim_cmd, stim_params.sync_ch );
        % train delay has to be > 50 us, to prevent weird waveform shapes
        hw.ws.set_TD( repmat(100,1,length(stim_params.elec)+1), ...
                        hw.sp.elect_list );
    end
end




%% -------------------------------------------------------------------------
%
% Function to read StTA data recorded with CBMEX
%
%   function [hw, varargout] = read_cbmex_stta_data( varargin )
%
% Inputs:
%   (force)         : force data struct
%   (emg)           : emg data struct
%   (stta_params)   : parameters to compute the StTA. Has to be passed as
%                       the second to last argument
%   (hw)            : struct containing hardware handles and params
%
% Outputs:
%   hw              : struct containing hardware handles and params
%   (force)         : force struct with populated raw data and evoked
%                       responses
%   (emg)           : emg struct with populated raw data and evoked
%                       responses
%

function [hw, varargout] = read_cbmex_stta_data( varargin )

% initialize flags to read whether we are looking at emg and/or force data
record_force = false; record_emg = false; 
% initialize flags to read whether we are looking at ICMS or force data. 
%   -- In ICMS an array with 'stimulated_channels' is passed; 
%   -- in FES an array with 'stim_pw' or 'stim_amp' is passed
is_icms = false; is_fes = false;

% read force and emg inputs
for i = 1:nargin-2
    if strcmpi(varargin{i}.labels{1}(1:5),'Force')
        record_force    = true;
        force           = varargin{i};
        if isfield(force,'stimulated_channels')
            is_icms     = true;
        elseif isfield(force,'stim_pws') || isfield(force,'stim_amsp')
            is_fes      = true;
        end
    elseif strcmpi(varargin{i}.labels{1}(1:3),'EMG')
        record_emg        = true;
        emg             = varargin{i};
        if isfield(emg,'stimulated_channels')
            is_icms     = true;
        elseif isfield(emg,'stim_pw') || isfield(force,'stim_amp')
            is_fes      = true;
        end
    end
end
% the last input argument has to be the StTA params
stta_params             = varargin{end-1};
% and the second to last the HW handle
hw                      = varargin{end};

% ------------------------------------------------------------------------
% read analog data and time stamps from central (flush the data cache)
[ts_cell_array, ~, analog_data] = cbmex('trialdata',1);
cbmex('trialconfig', 0);
drawnow;

% overwrite first column in analog_data cell array with variable names
analog_data(:,1)      	= ts_cell_array([analog_data{:,1}]',1);
  
% ------------------------------------------------------------------------
% 1. read force data
if record_force
    % read raw force data
    aux.force           = analog_data( strncmp(analog_data(:,1), 'Force', 5), 3 );
    
    % Add raw data to force struct
    for i = 1:force.nbr_forces
        force.raw{hw.ctr_stim_nbr}(:,i+1) = double(aux.force{i,1});
    end
    % add time vector in first column
    force.raw{hw.ctr_stim_nbr}(:,1) = 0:1/force.fs:1/force.fs*(length(force.raw{hw.ctr_stim_nbr}(:,2))-1);
end

% ------------------------------------------------------------------------
% 2. read EMG data
if record_emg
    warning('reading EMG not yet implemented')
end

% ------------------------------------------------------------------------
% 3. read sync pulses 

% read the threshold crossings
aux.ts_sync_pulses      = double( cell2mat(ts_cell_array(hw.cb_sync.ch_nbr,2)) );
% read the raw analog signal
analog_sync_signal      = double( analog_data{ strncmp(analog_data(:,1), 'Stim', 4), 3 } );

% NOTE: CBMEX has two bugs when detecting threshold crossings in analog
% channels: 1) it oftentimes misses the first sync pulse; 2) pretty rarely,
% there is a misalignment between the threshold crossings and the raw
% analog data [it seems that the raw data is the ground truth]. The
% following lines of code are implemented to circumvent these issues

% check if the threshold crossing has been missed
if isempty(aux.ts_sync_pulses), disp('Central has not detected the sync pulse'); end

% detrend analog signal -- ToDo: see if necessary
analog_sync_signal      = detrend(analog_sync_signal);
% compute threshold to detect the sync pulses
mean_analog_sync        = mean(analog_sync_signal);
std_analog_sync         = std(analog_sync_signal);
thr_analog_sync         = -(mean_analog_sync + 5*std_analog_sync);
% find sync pulses
sync_pulses_in_analog   = find( analog_sync_signal < thr_analog_sync );


% It seems that sometimes CBMEX starts recording late and misses the sync
% stimulus. If that happens, don't record anything and decrease the
% stimulation counter to do it again
if ~isempty(sync_pulses_in_analog)

    % Display what happened with the sync signals
    % check if the misalignment between the time stamps and the analog signal is > 1 ms
    t_first_sync_analog     = sync_pulses_in_analog(1)/hw.cb_sync.fs;

    if ~isempty(aux.ts_sync_pulses)
        misalign_btw_ts_analog = aux.ts_sync_pulses(1)/30000 - t_first_sync_analog;

        if misalign_btw_ts_analog > 1
            disp(['the delay btw analog/thr crossing is: ' num2str( misalign_btw_ts_analog )]);
        end
    end

    % ------------------------------------------------------------------------
    % 4. create array with evoked responses based on the specified intervals
    % for the force data
    if exist('force','var')
        % Find the sample that corresponds to the beginning of the baseline
        % window (the time of the sync pulse - t_before [baseline window
        % duration]) 
        trig_time_in_force_sample_nbr   = floor( t_first_sync_analog*force.fs ...
            - stta_params.t_before/1000*force.fs );
        % check if CBMEX didn't record the baseline period (it sometimes takes
        % very long to start recording. Give a warning
        if trig_time_in_force_sample_nbr < 0
            warning('Central did not record the baseline period. Stim response ignored');
        else
            % Record the evoked force
            force.evoked_force(:,:,hw.ctr_stim_nbr,1)   = force.raw{hw.ctr_stim_nbr}...
                ( trig_time_in_force_sample_nbr : ...
                (trig_time_in_force_sample_nbr + force.length_evoked_force - 1), 2:end );
        end
    end
    % for the EMG data
    if exist('emg','var')
        warning('storing EMG not yet implemented')
    end

    % ------------------------------------------------------------------------
    % Add additional information

    % % store sync pulses, and pulse width in 'force'
    if is_icms
        if exist('force','var')
            force.stimulated_channels   = stta_params.stimulated_channels;
        end
        if exist('emg','var')
            emg.stimulated_channels     = stta_params.stimulated_channels;
        end
    elseif is_fes
        if isfield(stta_params,'pw_order')
            if exist('force','var')
                force.stim_pw           = stta_params.pw_order;
            end
            if exist('emg','var')
                emg.stim_pw             = stta_params.pw_order;
            end
        elseif isfield(stta_params,'pw_order')
            if exist('force','var')
                force.stim_amp          = stta_params.amp_order;
            end
            if exist('emg','var')
                emg.stim_amp            = stta_params.amp_order;
            end
        end
    end
    
% if it has not detected the sync pulse, decrease stim counter by one
% to do it again
else
    warning('CBMEX has not recorded enough baseline data. This trial will be repeated');
    force.raw{hw.ctr_stim_nbr}      = [];
    hw.ctr_stim_nbr                 = hw.ctr_stim_nbr - 1;
end

% delete some variables
clear analog_data ts_cell_array;


% -----------------------------------------------------------------------
% return variables
if record_force && record_emg
    varargout{1}                    = emg;
    varargout{2}                    = force;
elseif record_force
    varargout{1}                    = force;
elseif record_emg
    varargout{1}                    = emg;
end