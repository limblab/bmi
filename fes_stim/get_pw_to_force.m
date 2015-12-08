%
% Stimulate to obtain the relationship between stimulation pulse width and
% joing force  
%
%   GET_PW_TO_FORCE( pw_f_params )
%
%
% Notes:
%   - In this version, all the data are pulled from Central in one stream,
%   rather than reading little chunks before and after each stimulus
%

function get_pw_to_force( varargin ) 



%------------------------------------
% read parameters. If no argument is passed load defaults
if nargin > 1   
    error('ERROR: The function only takes one argument of type pw_to_f_params');
elseif nargin == 1
    pwfp                = varargin{1};
    % fill missing params, if any
    pwfp                = pw_to_force_params_defaults(pwfp);
elseif nargin == 0
    pwfp                = pw_to_force_params_defaults();
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

% connect to central; if connection fails, return error message and quit
if ~cbmex('open', 1)   
    echoudp('off'); error('ERROR: Connection to Central Failed');
end

%------------------------------------
% For file storage in Central

% create file name
hw.cb_file_name         = [pwfp.monkey '_' hw.start_t '_' pwfp.task '_' pwfp.muscle '_pw_to_f'];

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
    error('ERROR: Sync signal not found in Cerebus. The channel has to be named Stim_trig');
else
    disp('Sync signal found');
    % store sync signal fs
    hw.cb_sync.fs       = cell2mat( analog_data(find(strncmp(analog_data(:,1), 'Stim', 4),1),2) );
end


% look for force sensors and store info about them
force.labels            = analog_data( strncmpi(analog_data(:,1), 'Force', 5), 1 );
force.nbr_forces        = numel(force.labels);
disp(['Nbr Force Sensors: ' num2str(force.nbr_forces)]);

force.fs                = cell2mat(analog_data(find(strncmp(analog_data(:,1), 'Force', 5),1),2));


%--------------------------------------------------------------------------
%% Setting up the stimulator

%------------------------------------
% if using the Grapevine, connect to it, and do some checks
if strncmp(pwfp.stimulator,'gv',2)

    % connect to Grapevine. If there's a comm error, close communication with
    % Central and exit 
    if xippmex ~= 1
        cbmex('close'); error('ERROR: Xippmex did not initialize');
    end
    
    % check that the sync out channel has not been mistakenly chosen for stim
    if ~isempty(find(pwfp.elec == pwfp.sync_ch,1))
        cbmex('close'); error('ERROR: sync out channel chosen for ICMS!');
    end
    
    % find all Micro+Stim channels (stimulation electrodes). Quit if no
    % stimulator is found 
    hw.gv.stim_ch       = xippmex('elec','stim');
    if isempty(hw.gv.stim_ch)
        cbmex('close'); error('ERROR: no stimulator found!');
    end
    
    % quit if the stim channels are not present, or if the sync ch is not present
    if numel( find(ismember(hw.gv.stim_ch,pwfp.elec)) ) ~= numel(pwfp.elec)
        cbmex('close'); error('ERROR: some stimulation channels were not found!');
    elseif isempty( find(hw.gv.stim_ch == pwfp.sync_ch,1) )
        cbmex('close'); error('ERROR: sync out channel not found!');
    end

%------------------------------------
% if it's the wireless stimulator, ...    
elseif strncmp(pwfp.stimulator,'ws',2)
   disp('ToDo'); 
end


%--------------------------------------------------------------------------
%% some preliminary stuff

% compute desired PWs, and randomize order (nbr PWs x nbr reps)
hw.stim_pws             = linspace(pwfp.pw_rng(1),pwfp.pw_rng(2),pwfp.pw_steps);
hw.pw_order             = repmat(hw.stim_pws,1,pwfp.nbr_reps);
hw.nbr_total_stims      = numel(hw.pw_order);
hw.pw_order             = hw.pw_order( randperm(hw.nbr_total_stims) );

% initialize stim ctr
hw.ctr_stim_nbr         = 1;

% define the basic stimulation string
% for the Grapevine
if strncmp(pwfp.stimulator,'gv',2)
 
    hw.sp.elect_list    = [pwfp.elec, pwfp.sync_ch];
    % create an amplitude vector, because it size has to be equal to the
    % number of electrodes since we want different amp for the stim
    % electrodes and the sync ch
    if length(pwfp.amp) == 1, pwfp.amp = repmat(pwfp.amp,1,length(pwfp.elec)); end
    hw.sp.amp           = [pwfp.amp/numel(pwfp.elec), pwfp.stim_res*127];
    hw.sp.freq          = pwfp.freq;
    hw.sp.pw            = pwfp.pw_rng(1); % this value will be overwritten every stim cycle
    % create a train length vector, because it size has to be equal to the
    % number of electrodes since we only want one sync pulse
    hw.sp.tl            = [repmat(pwfp.stim_dur,1,length(pwfp.elec)) ceil(1000/pwfp.freq)];
    % Give a warning if stim dur > 1 s; the code needs to be fixed to
    % suport that
    if pwfp.stim_dur > 1000, warning('Stimulus duration > 1000 ms'); end
    hw.sp.pol           = pwfp.pol;
    hw.sp.stim_res      = pwfp.stim_res;
    % --> 'fs' and 'delay' are left set to their defaultsvalues
    hw.sp               = stim_params_defaults( hw.sp );
    
% for the wireless stimulator
elseif strncmp(pwfp.stimulator,'ws',2)
   disp('ToDo'); 
end


%--------------------------------------------------------------------------
%% where the stimulation happens


% start data collection
cbmex('trialconfig', 1); drawnow;

% sitmulation loop
while hw.ctr_stim_nbr < hw.nbr_total_stims
   
    %-----------------------------------------------------------------
    % Prepare to stimulate
    
    % update the stimulation string
    %   overwrite PW
    hw.sp.pw            = hw.pw_order( hw.ctr_stim_nbr );
    hw.stim_string      = stim_params_to_stim_string( hw.sp );
    
    %-----------------------------------------------------------------
    % See if it is time to stimulate... and stimulate!
    
    if strncmp(pwfp.ctrl_mode,'keyboard',8)
        % if stim is controlled manually
        disp('Press any key to stimulate')
        pause;
    elseif strncmp(pwfp.ctrl_mode,'word',4)
        % ToDo: Read the words from central
        % read_words()
        
        % see if we got the word we want....
    end
    
    % send stimulation command
    xippmex('stim',hw.stim_string);
    
    % Wait for 'min_time_btw_trains' ms --to avoid delivering a bunch of trains
    % in a row
    t_wait              = tic;
    elapsed_t           = toc(t_wait);
    while elapsed_t < pwfp.min_time_btw_trains/1000
        elapsed_t       = toc(t_wait);
    end
    
    % update ctr
    hw.ctr_stim_nbr     = hw.ctr_stim_nbr + 1;
end


%--------------------------------------------------------------------------
%% read force data and sync pulses

disp('Stimulation finished')

% pause for 1 s to make sure we read the whole buffer
pause(1)

% read data from central (flush the data cache)
[ts_cell_array, ~, analog_data] = cbmex('trialdata',1);
cbmex('trialconfig', 0);
drawnow;

% retrieve force data
analog_data(:,1)      	= ts_cell_array([analog_data{:,1}]',1);
aux.force               = analog_data( strncmp(analog_data(:,1), 'Force', 5), 3 );
% --> struct 'aux' will be used for temporary stuff and then cleared
for i = 1:force.nbr_forces
    force.data(:,i+1)   = double(aux.force{i,1});
end
% add time vector in first column
force.data(:,1)         = 0:1/force.fs:1/force.fs*(length(force.data)-1);


% find sync pulses
aux.ts_sync_pulses      = double( cell2mat(ts_cell_array(hw.cb_sync.ch_nbr,2)) );
% store sync pulses, and pulse width in 'force'
force.t_sync_pulses     = aux.ts_sync_pulses / 30000;
force.stim_pw           = hw.pw_order;


% add meta fields
force.meta.mokey        = pwfp.monkey;
force.meta.task         = pwfp.task;
force.meta.muscle       = pwfp.muscle;
force.meta.time         = hw.start_t;

% ------------------------------------------------------------------------
% compute STA
