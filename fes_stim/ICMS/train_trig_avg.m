% 
% Function to do Stimulus Triggered Averaging of an intracortical electrode
% using the Grapevine. 
%
%       function varargout   = train_trig_avg( varargin )
%
%
% Syntax:
%       EMG                                     = TRAIN_TRIG_AVG( VARAGIN )
%       [EMG, ttap]                       = TRAIN_TRIG_AVG( VARAGIN )
%       FORCE                                   = TRAIN_TRIG_AVG( VARAGIN )
%       [FORCE, ttap]                     = TRAIN_TRIG_AVG( VARAGIN )
%       [EMG, FORCE, ttap]                = TRAIN_TRIG_AVG( VARAGIN ),
%               if ttap.record_force_yn = true
%       [EMG, ttap, STA_METRICS]          = TRAIN_TRIG_AVG( VARAGIN ),
%               if ttap.record_force_yn = false and ttap.plot_yn = true
%       [FORCE, ttap, STA_METRICS]        = TRAIN_TRIG_AVG( VARAGIN ),
%               if ttap.record_emg_yn = false and ttap.plot_yn = true
%       [EMG, FORCE, ttap, STA_METRICS]   = TRAIN_TRIG_AVG( VARAGIN )
%
%
% Input parameters: 
%       'ttap'        : stimulation settings. If not passed, read
%                               from train_trig_avg_default 
% Outputs: 
%       'emg'               : EMG evoked by each simulus, and some
%                               related information
%       'force'             : Force evoked by each stimulus, similar to
%                               the emg field. This is the second para
%       'ttap'        : stimulation parameters
%       'sta_metrics'       : StTA metrics computed with the
%       'calculate_sta_metrics' function  
%
%
%
%                           Last modified by Juan Gallego 6/17/2015




% %%%%%%%%%%%%
%   ToDo: 
%       - When the first threshold crossing is missed, read the rest of the
%       data
%       - Read the channel number of the sync signal, and the 
%   Some known issues:
%       - The resistor used in the analog input is hard-coded (100 Ohm)





function varargout = train_trig_avg( varargin )


close all;


% read parameters

if nargin > 1   
    error('ERROR: The function only takes one argument of type ttap');
elseif nargin == 1
    ttap                  = varargin{1};
elseif nargin == 0
    ttap                  = train_trig_avg_defaults();
end

if nargout > 4
    disp('ERROR: The function only returns up to three variables, of type emg, force and ttap');
end



%--------------------------------------------------------------------------
%% connect with Central 

% connect to central; if connection fails, return error message and quit
if ~cbmex('open', 1)
    
    echoudp('off');
%    close(handles.keep_running);
    error('ERROR: Connection to Central Failed');
end



% If we want to save the data ...

% Note structure 'hw' will have all the cerebus and grapevine stuff
if ttap.save_data_yn
   
    % create file name
    hw.data_dir                 = [ttap.data_dir filesep 'TTA_data_' datestr(now,'yyyy_mm_dd')];
    if ~isdir(hw.data_dir)
        mkdir(hw.data_dir);
    end
    hw.start_t                  = datestr(now,'yyyymmdd_HHMMSS');
    hw.cb.full_file_name        = fullfile( hw.data_dir, [ttap.monkey '_' ttap.bank '_' num2str(ttap.stim_elec) '_' hw.start_t '_' ttap.task '_STA' ]);

    % start 'file storage' app, or stop ongoing recordings
    cbmex('fileconfig', fullfile( hw.data_dir, hw.cb.full_file_name ), '', 0 );  
    drawnow;                        % wait till the app opens
    pause(1);
    drawnow;                        % wait some more to be sure. If app was closed, it did not always start recording otherwise

    % start cerebus file recording
    cbmex('fileconfig', hw.cb.full_file_name, '', 1);
end



% check if we want to record EMG, Force, or both. If none of them is
% specified
if ~ttap.record_emg_yn && ~ttap.record_force_yn
    cbmex('close');
    error('ERROR: It is necessary to record EMG, force or both');
end



% configure acquisition with Blackrock NSP
cbmex('trialconfig', 1);            % start data collection
drawnow;

pause(1);                           % give it some time...

[ts_cell_array, ~, analog_data] = cbmex('trialdata',1);
analog_data(:,1)                = ts_cell_array([analog_data{:,1}]',1); % ToDo: replace channel numbers with names


% look for the 'sync out' signal ('Stim_trig')
hw.cb.sync_signal_ch_nbr        =  find(strncmpi(ts_cell_array(:,1),'Stim',4));
if isempty(hw.cb.sync_signal_ch_nbr)
    error('ERROR: Sync signal not found in Cerebus. The channel has to be named Stim_trig');
else
    disp('Sync signal found');
    
    % ToDo: store the channel of the sync signal
    hw.cb.sync_signal_fs        = cell2mat(analog_data(find(strncmp(analog_data(:,1), 'Stim', 4),1),2));
    hw.cb.sync_out_resistor     = 100;  % define resistor to record sync pulse
end



% If chosen to record EMG

if ttap.record_emg_yn 

    % figure out how many EMG channels there are
    emg.labels                  = analog_data( strncmpi(analog_data(:,1), 'EMG', 3), 1 );
    emg.nbr_emgs                = numel(emg.labels); disp(['Nbr EMGs: ' num2str(emg.nbr_emgs)]);
    
    emg.fs                      = cell2mat(analog_data(find(strncmp(analog_data(:,1), 'EMG', 3),1),2));

    % EMG data will be stored in the 'emg' data structure 'emg.evoked_emg'
    % has dimensions EMG response -by- EMG channel- by- stimulus nbr- by
    % stimulation electrode
    emg.length_evoked_emg       = ( ttap.t_before + ttap.t_after ) * emg.fs/1000 + 1;
    emg.evoked_emg              = zeros( emg.length_evoked_emg, emg.nbr_emgs, ttap.nbr_stims_ch, numel(ttap.stim_elec) ); 
end


% If chosen to record force

if ttap.record_force_yn
   
    % figure out how many EMG sensors there are
    force.labels            = analog_data( strncmpi(analog_data(:,1), 'Force', 5), 1 );
    force.nbr_forces        = numel(force.labels); disp(['Nbr Force Sensors: ' num2str(force.nbr_forces)]);
    
    force.fs                = cell2mat(analog_data(find(strncmp(analog_data(:,1), 'Force', 5),1),2));
    
    % Force data will be stored in the 'emg' data structure
    % 'force.evoked_force' has dimensions Force response -by- Force sensor
    % - by- stimulus nbr -by stimulation electrode
    force.length_evoked_force   = ( ttap.t_before + ttap.t_after ) * force.fs/1000 + 1;
    force.evoked_force      = zeros( force.length_evoked_force, force.nbr_forces, ttap.nbr_stims_ch, numel(ttap.stim_elec) );
end


clear analog_data ts_cell_array;
cbmex('trialconfig', 0);        % stop data collection until the stim starts



%--------------------------------------------------------------------------
%% connect with Grapevine

% initialize xippmex
hw.gv.connection            = xippmex;

if hw.gv.connection ~= 1
    cbmex('close');
    error('ERROR: Xippmex did not initialize');
end


% check if the sync out channel has been mistakenly chosen for stimulation
if ~isempty(find(ttap.stim_elec == ttap.sync_out_elec,1))
    cbmex('close');
    error('ERROR: sync out channel chosen for ICMS!');
end


% find all Micro+Stim channels (stimulation electrodes). Quit if no
% stimulator is found 
hw.gv.stim_ch               = xippmex('elec','stim');

if isempty(hw.gv.stim_ch)
    cbmex('close');
    error('ERROR: no stimulator found!');
end


% quit if the specified channels (in 'ttap.stim_elec') do not exist,
% or if the sync_out channel does not exist  

if numel(find(ismember(hw.gv.stim_ch,ttap.stim_elec))) ~= numel(ttap.stim_elec)
    cbmex('close');
    error('ERROR: stimulation channel not found!');
elseif isempty(find(hw.gv.stim_ch==ttap.sync_out_elec,1))
    cbmex('close');
    error('ERROR: sync out channel not found!');
end


% SAFETY! check that the stimulation amplitude is not too large ( > 90 uA
% or > 1 ms) 
if ttap.stim_ampl > 0.090
    cbmex('close');
    error('ERROR: stimulation amplitude is too large (> 90uA) !');    
elseif ttap.stim_pw > 1
    cbmex('close');
    error('ERROR: stimulation pulse width is too large (> 1ms) !');    
end
   


%--------------------------------------------------------------------------
%% some preliminary stuff


% this variable counts the number of times all of the electrodes have been
% stimulated
hw.curr_stim_nbr            = 1;
% the total number of electrodes 
hw.nbr_elecs                = numel(ttap.stim_elec);
% the total time to wait after recordings in central have started -for each
% stimulus. Plus 100 ms extra to avoid sync issues. Converted to s
hw.stim_wait_t              = ( ttap.t_before + ttap.train_duration + ttap.t_after + 100 ) / 1000;
% ptr to know where to store the evoked EMG/Force in the data matrices
hw.ind_ev_resp            = ones(1,hw.nbr_elecs);    


% Message box to stop the stimulation and exit, saving the data
hw.keep_running             = msgbox('Click ''ok'' to stop the stimulation','ICMS');
set(hw.keep_running,'Position',[200 700 125 52]);
drawnow;


%--------------------------------------------------------------------------
%% stimulate to get TTAs


while hw.curr_stim_nbr < ttap.nbr_stims_ch

    % define a vector with the order in which the different electrodes will
    % be stimulated
    hw.elec_order           = ttap.stim_elec( randperm(numel(ttap.stim_elec)) );
    
    
    %---------------------------------------------------------------------
    % stimulate each channel
    for i = 1:hw.nbr_elecs
        
        % Wait for 'min_time_btw_trains' ms --to avoid delivering a bunch of trains
        % in a row
        t_wait              = tic;
        elapsed_t           = toc(t_wait);
        while elapsed_t < ttap.min_time_btw_trains/1000
            elapsed_t       = toc(t_wait);
        end

        
        %------------------------------------------------------------------
        % Define the stimulation string and start data collection
        % Note that TD adds a delay that is the time before the stimulation for
        % the TTA (defined in ttap.t_before) + 100 ms, to avoid
        % synchronization issues

        stim_string     = [ 'Elect = ' num2str( hw.elec_order(i) ) ',' num2str(ttap.sync_out_elec) ',;' ...
                            'TL = ' num2str(ttap.train_duration) ',' num2str(ceil(1000/ttap.stim_freq)) ',; ' ...
                            'Freq = ' num2str(ttap.stim_freq) ',' num2str(ttap.stim_freq) ',; ' ...
                            'Dur = ' num2str(ttap.stim_pw) ',' num2str(ttap.stim_pw) ',; ' ...
                            'Amp = ' num2str(ttap.stim_ampl/ttap.stimulator_resolut) ',' num2str(127) ',; ' ...
                            'TD = ' num2str((ttap.t_before)/1000+0.1) ',' num2str((ttap.t_before)/1000+0.1) ',; ' ...
                            'FS = 0,0,; ' ...
                            'PL = 1,1,;'];

        
        %-----------------------------------------------------------------
        % See if it is time to stimulate
        
        if strncmp(ttap.control_mode,'keyboard',8)
            % if stim is controlled manually
            disp('Press any key to stimulate')
            pause;
        elseif strncmp(ttap.control_mode,'word',4)
            % ToDo: Read the words from central
            % read_words()
        
            % see if we got the word we want....
        end
                        
        % start data collection
        cbmex('trialconfig', 1);
        drawnow;
        drawnow;
        drawnow;

        t_start             = tic;
        drawnow;

        % send stimulation command
        xippmex('stim',stim_string);
        drawnow;
        drawnow;
        drawnow;


        % wait to record for t_before t_train_duration + t_after
        t_stop              = toc(t_start);
        while t_stop < hw.stim_wait_t
            t_stop          = toc(t_start);
        end

        
        %------------------------------------------------------------------
        % read EMG (and Force) data and sync pulses

        % read the data from central (flush the data cache)
        [ts_cell_array, ~, analog_data] = cbmex('trialdata',1);
        cbmex('trialconfig', 0);
        drawnow;

        % Check if the sync pulse got lost. If it did, don't record the
        % data
        nbr_sync_pulses     = numel( cell2mat(ts_cell_array(hw.cb.sync_signal_ch_nbr,2)) );
        if nbr_sync_pulses ~= 1
            disp(' ');
            warning('sync pulse got lost somewhere!!!');
        else
            disp('sync pulse detected');
        
            %------------------------------------------------------------------
            % retrieve EMG, Force, or both, as well as the stimulation time stamp (from the sync pulse) 

            ts_sync_pulse                   = double( cell2mat(ts_cell_array(hw.cb.sync_signal_ch_nbr,2)) );

            analog_data(:,1)                = ts_cell_array([analog_data{:,1}]',1);

            % Get EMGs
            if ttap.record_emg_yn
                aux                         = analog_data( strncmp(analog_data(:,1), 'EMG', 3), 3 );
                for ii = 1:emg.nbr_emgs
                    emg.data(:,ii)          = double(aux{ii,1}); 
                end
                clear aux
            end

            % Get Forces
            if ttap.record_force_yn
                aux2                        = analog_data( strncmp(analog_data(:,1), 'Force', 5), 3 ); % ToDo: double check this line
                for ii = 1:force.nbr_forces
                    force.data(:,ii)        = double(aux2{ii,1});
                end
                clear aux2
            end


            % RESOLVE ISSUES RELATED TO THE SYNCHRONIZATION BETWEEN TIME STAMPS AND
            % ANALOG SIGNALS WHEN READING FROM CENTRAL. THIS HAS BEEN FIXED IN
            % CBMEX v6.3, ALTHOUGH IT SOMETIMES MISSES THE FIRST THRESHOLD CROSSING 
            % IN THE TRIAL     

            ts_sync_pulse_analog_freq  = ts_sync_pulse / 30000 * hw.cb.sync_signal_fs;    
            analog_sync_signal          = double( analog_data{ strncmp(analog_data(:,1), 'Stim', 4), 3 } );

            % find the first threshold crossing in the analog signal. Note that the
            % -(mean + 2SD) threshold is totally arbitrary, but it works
            ts_first_sync_pulse_analog_signal   = find( (analog_sync_signal - mean(analog_sync_signal)) < -2*std(analog_sync_signal), 1);

            % check if the misalignment between the time stamps and the analog signal is > 1 ms 
            misalign_btw_ts_analog      = ts_first_sync_pulse_analog_signal - ts_sync_pulse_analog_freq;

            if abs( misalign_btw_ts_analog ) > hw.cb.sync_signal_fs/1000
                if misalign_btw_ts_analog < 0
                    disp('Warning: Central has skipped the first threshold crossing of the sync signal!!!');
                    disp(['the delay btw analog/thr crossing is: ' num2str( misalign_btw_ts_analog / hw.cb.sync_signal_fs * 1000 )])
                else
                    disp('Warning: The delay between the time stamps and the analog signal is > 1 ms!!!');
                    disp(['it is: ' num2str( misalign_btw_ts_analog / hw.cb.sync_signal_fs * 1000 )])
                end
            else
                % this line can be commented
                disp('The delay between the time stamps and the analog signal is < 1 ms');
            end

        %   % this plot compares the time stamps of the threshold crossings and the analog signals    
        %     figure,plot(analog_sync_signal), hold on, xlim([0 10000]), xlabel(['sample numer at EMG fs = ' num2str(emg.fs) ' (Hz)']), 
        %     stem(ts_sync_pulses_emg_freq,ones(length(ts_sync_pulses),1)*-5000,'marker','none','color','r'), legend('analog signal','time stamps')



            %------------------------------------------------------------------  
            % Retrieve the data and store it in their corresponding structure(s)

            
            % check if we have recorded data before the stimulus for long
            % enough
            if ts_sync_pulse/30000 < ttap.t_before/1000
                ts_sync_pulse   = [];
            end

            
            % Data will be stored only if: 1) the mismatch between the
            % threshold crossing in the analog signal and the spikes (of
            % the sync signal) is < 1 s; and 2) we have not recorded for
            % long enough before the syn pulse  

            if ( abs( misalign_btw_ts_analog ) <  hw.cb.sync_signal_fs/1000 ) && ~isempty(ts_sync_pulse)

                ptr_stim_elec   = find(ttap.stim_elec==hw.elec_order(i));
                
%                 % remove sync pulses at the end, if the evoked response
%                 % (duration = ttap.t_after) falls outside the recorded data
%                 if ttap.record_emg_yn
% 
%                     last_ts_number_in_emg_window    = find( ts_sync_pulse/30000 > ( length(emg.data)/emg.fs - ttap.t_after/1000), 1 );
% 
%                     if ~isempty(last_ts_number_in_emg_window)
%                        ts_sync_pulse(last_ts_number_in_emg_window:end) = [];
%                        disp(['Warning: ' num2str(hw.cb.nbr_stims_this_epoch - last_ts_number_in_emg_window + 1) ' sync pulses were too late in the EMG data'])
%                     end
%                 end
% 
%                 if ttap.record_force_yn
% 
%                     last_ts_number_in_force_window  = find( ts_sync_pulse/30000 > ( length(force.data)/force.fs - ttap.t_after/1000), 1 );
% 
%                     if ~isempty(last_ts_number_in_force_window)
%                        ts_sync_pulse(last_ts_number_in_force_window:end) = [];
%                        disp(['Warning: ' num2str(hw.cb.nbr_stims_this_epoch - last_ts_number_in_force_window + 1) ' sync pulses were too late in the Force data'])
%                     end
%                 end


                %------------------------------------------------------------------
                % store the evoked EMG (interval around the stimulus defined by
                % t_before and t_after in params 

                if ttap.record_emg_yn

%                     for ii = 1:min(length(ts_sync_pulse),length(emg.evoked_emg))
% 
%                         trig_time_in_emg_sample_nbr     = floor( double(ts_sync_pulse(ii))/30000*emg.fs - ttap.t_before/1000*emg.fs );
% 
%                            emg.evoked_emg(:,:,ii+hw.ind_ev_resp)    = emg.data( trig_time_in_emg_sample_nbr : ...
%                                 (trig_time_in_emg_sample_nbr + emg.length_evoked_emg - 1), : );
%                     end
                    
                    trig_time_in_emg_sample_nbr     = floor( double(ts_sync_pulse)/30000*emg.fs - ttap.t_before/1000*emg.fs );

                    emg.evoked_emg(:,:,hw.ind_ev_resp(ptr_stim_elec),ptr_stim_elec)    = emg.data( trig_time_in_emg_sample_nbr : ...
                        (trig_time_in_emg_sample_nbr + emg.length_evoked_emg - 1), : );
                end

                %------------------------------------------------------------------
                % store the evoked Force (interval around the stimulus defined by
                % t_before and t_after in params

                if ttap.record_force_yn

                    trig_time_in_force_sample_nbr   = floor( double(ts_sync_pulse)/30000*force.fs - ttap.t_before/1000*force.fs );

                    force.evoked_force(:,:,hw.ind_ev_resp(ptr_stim_elec),ptr_stim_elec)   = force.data( trig_time_in_force_sample_nbr : ...
                        (trig_time_in_force_sample_nbr + force.length_evoked_force - 1), : );
                end
                
                % update ptr for data storage
                hw.ind_ev_resp(ptr_stim_elec)  = hw.ind_ev_resp(ptr_stim_elec) + 1;
            end
        end

        % delete some variables
        clear analog_data ts_cell_array; 
        
        if ttap.record_emg_yn
            if isfield(emg,'data')
                emg                 = rmfield(emg,'data');
            end
        end
        if ttap.record_force_yn
            if isfield(force,'data')
                force               = rmfield(force,'data');
            end
        end
    end
    
    
    % update cycle counter (nbr of times all electrodes will be stimulated)
    hw.curr_stim_nbr                = hw.curr_stim_nbr + 1;
    
    
    % If the message box is closed, stop recordings
    if ~ishandle(hw.keep_running)
        break; 
     end
end



%--------------------------------------------------------------------------
% Save data and stop cerebus recordings


if ishandle(hw.keep_running)
    disp(['Finished stimulating electrodes ' num2str(ttap.stim_elec)]);
    disp(' ');
    delete( hw.keep_running );
else
    disp(['Stimulation of electrodes ' num2str(ttap.stim_elec) ' stopped by the user']);
    disp(' ');
end


% Save the data, if specified in ttap
if ttap.save_data_yn
    
    % stop cerebus recordings
    cbmex('fileconfig', hw.cb.full_file_name, '', 0);
    cbmex('close');
    drawnow;
    drawnow;
    disp('Communication with Central closed');
    
%    xippmex('close');

    % save matlab data. Note: the time in the faile name will be the same as in the cb file
    hw.matlab_full_file_name    = fullfile( hw.data_dir, [ttap.monkey '_' ttap.bank '_' num2str(ttap.stim_elec) '_' hw.start_t '_' ttap.task '_TTA' ]);
    
    disp(' ');
    
    if ttap.record_force_yn == false
        save(hw.matlab_full_file_name,'emg','ttap');
        disp(['EMG data and Stim Params saved in ' hw.matlab_full_file_name]);
    else
        save(hw.matlab_full_file_name,'emg','force','ttap');
        disp(['EMG and Force data and Stim Params saved in ' hw.matlab_full_file_name]);
    end    
end

cbmex('close')


% Calculate the TTA metrics and plot, if specified in ttap
if ttap.plot_yn
   
    if ~ttap.record_force_yn
        tta_metrics             = calculate_sta_metrics( emg, ttap );
    elseif ~ttap.record_emg_yn
        tta_metrics             = calculate_sta_metrics( force, ttap );
    else
        tta_metrics             = calculate_sta_metrics( emg, force, ttap );
    end
end



%-------------------------------------------------------------------------- 
% Return variables
if nargout == 1
    if ttap.record_emg_yn
        varargout{1}        = emg;
    else
        varargout{1}        = force;
    end
elseif nargout == 2
    if ttap.record_emg_yn
        varargout{1}        = emg;
    else
        varargout{1}        = force;
    end
    varargout{2}            = ttap;
elseif nargout == 3
    if ttap.record_force_yn && ttap.record_emg_yn
        varargout{1}        = emg;
        varargout{2}        = force;
        varargout{3}        = ttap;
    elseif ttap.record_emg_yn
        varargout{1}        = emg;
        varargout{2}        = ttap;
        varargout{3}        = sta_metrics;        
    elseif ttap.record_force_yn     
        varargout{1}        = force;
        varargout{2}        = ttap;
        varargout{3}        = sta_metrics;
    end
elseif nargout == 4
    varargout{1}            = emg;
    varargout{2}            = force;
    varargout{3}            = ttap;
    varargout{4}            = sta_metrics;
end


