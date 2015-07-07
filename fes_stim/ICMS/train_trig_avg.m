% 
% Function to do Stimulus Triggered Averaging of an intracortical electrode
% using the Grapevine. 
%
%       function varargout   = stim_trig_avg( varargin )
%
%
% Syntax:
%       EMG                                     = STIM_TRIG_AVG( VARAGIN )
%       [EMG, tta_params]                       = STIM_TRIG_AVG( VARAGIN )
%       FORCE                                   = STIM_TRIG_AVG( VARAGIN )
%       [FORCE, tta_params]                     = STIM_TRIG_AVG( VARAGIN )
%       [EMG, FORCE, tta_params]                = STIM_TRIG_AVG( VARAGIN ),
%               if tta_params.record_force_yn = true
%       [EMG, tta_params, STA_METRICS]          = STIM_TRIG_AVG( VARAGIN ),
%               if tta_params.record_force_yn = false and tta_params.plot_yn = true
%       [FORCE, tta_params, STA_METRICS]        = STIM_TRIG_AVG( VARAGIN ),
%               if tta_params.record_emg_yn = false and tta_params.plot_yn = true
%       [EMG, FORCE, tta_params, STA_METRICS]   = STIM_TRIG_AVG( VARAGIN )
%
%
% Input parameters: 
%       'tta_params'        : stimulation settings. If not passed, read
%                               from stim_trig_avg_default 
% Outputs: 
%       'emg'               : EMG evoked by each simulus, and some
%                               related information
%       'force'             : Force evoked by each stimulus, similar to
%                               the emg field. This is the second para
%       'tta_params'        : stimulation parameters
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
    error('ERROR: The function only takes one argument of type TTA_params');
elseif nargin == 1
    tta_params                  = varargin{1};
elseif nargin == 0
    tta_params                  = train_trig_avg_defaults();
end

if nargout > 4
    disp('ERROR: The function only returns up to three variables, of type emg, force and tta_params');
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
if tta_params.save_data_yn
   
    % create file name
    hw.data_dir                 = [tta_params.data_dir filesep 'STA_data_' datestr(now,'yyyy_mm_dd')];
    if ~isdir(hw.data_dir)
        mkdir(hw.data_dir);
    end
    hw.start_t                  = datestr(now,'yyyymmdd_HHMMSS');
    hw.cb.full_file_name        = fullfile( hw.data_dir, [tta_params.monkey '_' tta_params.bank '_' num2str(tta_params.stim_elec) '_' hw.start_t '_' tta_params.task '_STA' ]);

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
if ~tta_params.record_emg_yn && ~tta_params.record_force_yn
    cbmex('close');
    error('ERROR: It is necessary to record EMG, force or both');
end



% configure acquisition with Blackrock NSP
cbmex('trialconfig', 1);            % start data collection
drawnow;

pause(1);                           % ToDo: see if it's necessary

[ts_cell_array, ~, analog_data] = cbmex('trialdata',1);
analog_data(:,1)                = ts_cell_array([analog_data{:,1}]',1); % ToDo: replace channel numbers with names


% look for the 'sync out' signal ('Stim_trig')
hw.cb.sync_signal_ch_nbr        =  find(strncmp(ts_cell_array(:,1),'Stim',4));
if isempty(hw.cb.sync_signal_ch_nbr)
    error('ERROR: Sync signal not found in Cerebus. The channel has to be named Stim_trig');
else
    disp('Sync signal found');
    
    % ToDo: store the channel of the sync signal
    hw.cb.sync_signal_fs        = cell2mat(analog_data(find(strncmp(analog_data(:,1), 'Stim', 4),1),2));
    hw.cb.sync_out_resistor     = 100;  % define resistor to record sync pulse
end



% If chosen to record EMG

if tta_params.record_emg_yn 

    % figure out how many EMG channels there are
    emg.labels                  = analog_data( strncmp(analog_data(:,1), 'EMG', 3), 1 );
    emg.nbr_emgs                = numel(emg.labels); disp(['Nbr EMGs: ' num2str(emg.nbr_emgs)]);
    
    emg.fs                      = cell2mat(analog_data(find(strncmp(analog_data(:,1), 'EMG', 3),1),2));

    % EMG data will be stored in the 'emg' data structure 'emg.evoked_emg'
    % has dimensions EMG response -by- EMG channel- by- stimulus nbr
    emg.length_evoked_emg       = ( tta_params.t_before + tta_params.t_after ) * emg.fs/1000 + 1;
    emg.evoked_emg              = zeros( emg.length_evoked_emg, emg.nbr_emgs, tta_params.nbr_stims_ch ); 
end


% If chosen to record force

if tta_params.record_force_yn
   
    % figure out how many EMG sensors there are
    force.labels            = analog_data( strncmp(analog_data(:,1), 'Force', 5), 1 );
    force.nbr_forces        = numel(force.labels); disp(['Nbr Force Sensors: ' num2str(force.nbr_forces)]);
    
    force.fs                = cell2mat(analog_data(find(strncmp(analog_data(:,1), 'Force', 5),1),2));
    
    % Force data will be stored in the 'emg' data structure
    % 'force.evoked_force' has dimensions Force response -by- Force sensor
    % - by- stimulus nbr
    force.length_evoked_force   = ( tta_params.t_before + tta_params.t_after ) * force.fs/1000 + 1;
    force.evoked_force      = zeros( force.length_evoked_force, force.nbr_forces, tta_params.nbr_stims_ch );
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
if ~isempty(find(tta_params.stim_elec == tta_params.sync_out_elec,1))
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


% quit if the specified channel (in 'tta_params.stim_elec') does not exist,
% or if the sync_out channel does not exist  

if isempty(find(hw.gv.stim_ch==tta_params.stim_elec,1))
    cbmex('close');
    error('ERROR: stimulation channel not found!');
elseif isempty(find(hw.gv.stim_ch==tta_params.sync_out_elec,1))
    cbmex('close');
    error('ERROR: sync out channel not found!');
end


% % SAFETY! check that the stimulation amplitude is not too large ( > 90 uA
% % or > 1 ms) 
% if tta_params.stim_ampl > 0.090
%     cbmex('close');
%     error('ERROR: stimulation amplitude is too large (> 90uA) !');    
% elseif tta_params.stim_pw > 1
%     cbmex('close');
%     error('ERROR: stimulation pulse width is too large (> 1ms) !');    
% end
   


%--------------------------------------------------------------------------
%% some preliminary stuff


% % this defines 'epochs' of continuous ICMS and cerebus recordings. To avoid
% % the need of reading a huge chunk of data from Central at once
% hw.cb.epoch_duration        = 10;   % epoch duration (in s)
% hw.cb.nbr_epochs            = ceil(tta_params.nbr_stims_ch/tta_params.stim_freq/hw.cb.epoch_duration);
% hw.cb.nbr_stims_this_epoch  = tta_params.stim_freq*hw.cb.epoch_duration;
% hw.cb.ind_ev_resp            = 0;    % ptr to know where to store the evoked EMG


drawnow;


%--------------------------------------------------------------------------
%% stimulate to get STAs



%------------------------------------------------------------------
% Define the stimulation string and start data collection
% Note that TD adds a delay that is the time before the stimulation for
% the StTA (defined in tta_params.t_before) + 10 ms, to avoid
% synchronization issues


stim_string             = [ 'Elect = ' num2str(tta_params.stim_elec) ',' num2str(tta_params.sync_out_elec) ',;' ...
                            'TL = ' num2str(tta_params.train_duration) ',' num2str(ceil(1000/tta_params.stim_freq)) ',; ' ...
                            'Freq = ' num2str(tta_params.stim_freq) ',' num2str(tta_params.stim_freq) ',; ' ...
                            'Dur = ' num2str(tta_params.stim_pw) ',' num2str(tta_params.stim_pw) ',; ' ...
                            'Amp = ' num2str(tta_params.stim_ampl/tta_params.stimulator_resolut) ',' num2str(ceil(3/hw.cb.sync_out_resistor/tta_params.stimulator_resolut*1000)) ',; ' ...
                            'TD = ' num2str((tta_params.t_before)/1000) ',' num2str((tta_params.t_before)/1000) ',; ' ...
                            'FS = 0,0,; ' ...
                            'PL = 1,1,;'];


for i = 1:tta_params.nbr_stims_ch

    
    disp('press any key to stimulate');
    pause;
    
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
    
    
    % wait for the inter-stimulus interfal (defined by stim freq)
    t_stop              = toc(t_start);
    while t_stop < (1/tta_params.stim_freq)
        t_stop          = toc(t_start);
    end
    
%     % record for some extra time to avoid loosing the last epoch ?it may
%     % happen some times 
%     if ii == hw.cb.nbr_stims_this_epoch
%         % ToDo: try increasing this number to avoid loosing sync pulses
%         % at the end
%         pause(0.01);
%     end


    %------------------------------------------------------------------
    % read EMG (and Force) data and sync pulses

    % read the data from central (flush the data cache)
    [ts_cell_array, ~, analog_data] = cbmex('trialdata',1);
    cbmex('trialconfig', 0);
    drawnow;

    % display if some of the stim pulses were lost
    lost_sync_pulses                = numel( cell2mat(ts_cell_array(hw.cb.sync_signal_ch_nbr,2)) ) - hw.cb.nbr_stims_this_epoch;
    if lost_sync_pulses ~= 0
        disp(' ');
        disp(['Warning: ' num2str(hw.cb.nbr_stims_this_epoch - numel(cell2mat(ts_cell_array(hw.cb.sync_signal_ch_nbr,2)))) ' sync pulses lost in this stim epoch!']);
    else
        disp(' ');
        disp('all sync pulses detected during this stim epoch');
    end

    
    %------------------------------------------------------------------
    % retrieve EMG, Force, or both, as well as the stimulation time stamps 

    ts_sync_pulses                  = double( cell2mat(ts_cell_array(hw.cb.sync_signal_ch_nbr,2)) );

    
    analog_data(:,1)                = ts_cell_array([analog_data{:,1}]',1);

    if tta_params.record_emg_yn
        aux                         = analog_data( strncmp(analog_data(:,1), 'EMG', 3), 3 );
        for ii = 1:emg.nbr_emgs
            emg.data(:,ii)          = double(aux{ii,1}); 
        end
        clear aux
    end
    
    if tta_params.record_force_yn
        aux2                        = analog_data( strncmp(analog_data(:,1), 'Force', 5), 3 ); % ToDo: double check this line
        for ii = 1:force.nbr_forces
            force.data(:,ii)        = double(aux2{ii,1});
        end
        clear aux2
    end
    
    
    %------------------------------------------------------------------  
    % RESOLVE ISSUES RELATED TO THE SYNCHRONIZATION BETWEEN TIME STAMPS AND
    % ANALOG SIGNALS WHEN READING FROM CENTRAL. THIS HAS BEEN FIXED IN
    % CBMEX v6.3, ALTHOUGH IT SOMETIMES MISSES THE FIRST THRESHOLD CROSSING 
    % IN THE TRIAL     
    
    % ToDo: check if these changes broke the code
    
    ts_sync_pulses_analog_freq  = ts_sync_pulses / 30000 * hw.cb.sync_signal_fs;    
    analog_sync_signal          = double( analog_data{ strncmp(analog_data(:,1), 'Stim', 4), 3 } );
    
    % find the first threshold crossing in the analog signal. Note that the
    % -(mean + 2SD) threshold is totally arbitrary, but it works
    ts_first_sync_pulse_analog_signal   = find( (analog_sync_signal - mean(analog_sync_signal)) < -2*std(analog_sync_signal), 1);


    % check if the misalignment between the time stamps and the analog signal is > 1 ms 
    misalign_btw_ts_analog      = ts_first_sync_pulse_analog_signal - ts_sync_pulses_analog_freq(1);
    
    if abs( misalign_btw_ts_analog ) > hw.cb.sync_signal_fs/1000
        if misalign_btw_ts_analog < 0
            disp('Warning: Central has skipped the first threshold crossing of the sync signal!!!');
            disp(['the delay btw analog/thr crossing is: ' num2str( misalign_btw_ts_analog / hw.cb.sync_signal_fs * 1000 )])
        else
            disp('Warning: The delay between the time stamps and the analog signal is > 1 ms!!!');
            disp(['it is: ' num2str( misalign_btw_ts_analog / hw.cb.sync_signal_fs * 1000 )])
        end
    else
        disp('The delay between the time stamps and the analog signal is < 1 ms');
    end

%   % this plot compares the time stamps of the threshold crossings and the analog signals    
%     figure,plot(analog_sync_signal), hold on, xlim([0 10000]), xlabel(['sample numer at EMG fs = ' num2str(emg.fs) ' (Hz)']), 
%     stem(ts_sync_pulses_emg_freq,ones(length(ts_sync_pulses),1)*-5000,'marker','none','color','r'), legend('analog signal','time stamps')



    %------------------------------------------------------------------  
    % Retrieve the data and store it in their corresponding structure(s)
    
    % When the time stamps and the analog data are not synchronized, they
    % won't be stored. A <1 ms difference in the analog data and the time
    % stamps is allowed, to compensate for rounding errors. Besides, if the
    % first sync pulse has been missed, the code stores the rest of the
    % epoch. This bug has been detected in the latest version of CBMex
    
    if abs( misalign_btw_ts_analog ) <  hw.cb.sync_signal_fs/1000


        %------------------------------------------------------------------
        % remove the time stamps of the sync pulses which responses would
        % fall outside the recorded EMG/Force data
        
        % remove the first sync pulse if the EMG/force baseline
        % (tta_params.t_before) falls outside the recorded data 
        if floor(ts_sync_pulses(1)/30000) < tta_params.t_before/1000
            ts_sync_pulses(1)   = [];
%         elseif (length(emg.data) - tta_params.t_after) < floor(ts_sync_pulses(end)/30000*emg.fs)
%             ts_sync_pulses(end) = [];
        end
                
        % remove sync pulses at the end, if the evoked response
        % (duration = tta_params.t_after) falls outside the recorded data
        if tta_params.record_emg_yn

            last_ts_number_in_emg_window    = find( ts_sync_pulses/30000 > ( length(emg.data)/emg.fs - tta_params.t_after/1000), 1 );
            
            if ~isempty(last_ts_number_in_emg_window)
               ts_sync_pulses(last_ts_number_in_emg_window:end) = [];
               disp(['Warning: ' num2str(hw.cb.nbr_stims_this_epoch - last_ts_number_in_emg_window + 1) ' sync pulses were too late in the EMG data'])
            end
        end
        
        if tta_params.record_force_yn

            last_ts_number_in_force_window  = find( ts_sync_pulses/30000 > ( length(force.data)/force.fs - tta_params.t_after/1000), 1 );
            
            if ~isempty(last_ts_number_in_force_window)
               ts_sync_pulses(last_ts_number_in_force_window:end) = [];
               disp(['Warning: ' num2str(hw.cb.nbr_stims_this_epoch - last_ts_number_in_force_window + 1) ' sync pulses were too late in the Force data'])
            end
        end
        

        %------------------------------------------------------------------
        % store the evoked EMG (interval around the stimulus defined by
        % t_before and t_after in params 

        if tta_params.record_emg_yn
        
            for ii = 1:min(length(ts_sync_pulses),length(emg.evoked_emg))
                
                trig_time_in_emg_sample_nbr     = floor( double(ts_sync_pulses(ii))/30000*emg.fs - tta_params.t_before/1000*emg.fs );

%                 % check if we haven't recorded EMG for long enough, during some of
%                 % the stimuli. If not, store the data
%                 if (trig_time_in_emg_sample_nbr + (tta_params.t_after + tta_params.t_before)*emg.fs/1000 ) < length(emg.data)
                    
                    emg.evoked_emg(:,:,ii+hw.cb.ind_ev_resp)    = emg.data( trig_time_in_emg_sample_nbr : ...
                        (trig_time_in_emg_sample_nbr + emg.length_evoked_emg - 1), : );
%                 else
%                     disp('one sync pulse in the EMG is far too late!');
%                     drawnow;
%                 end
            end
        end

        
        %------------------------------------------------------------------
        % store the evoked Force (interval around the stimulus defined by
        % t_before and t_after in params
        
        if tta_params.record_force_yn
            
            for ii = 1:min(length(ts_sync_pulses),length(force.evoked_force))
                
                trig_time_in_force_sample_nbr   = floor( double(ts_sync_pulses(ii))/30000*force.fs - tta_params.t_before/1000*force.fs );
                
%                 % check if we haven't recorded Force for long enough, during some
%                 % of the stimuli. If not, store the data
%                 if (trig_time_in_force_sample_nbr + (tta_params.t_after + tta_params.t_before)*force.fs/1000 ) < length(force.data)
                    
                    force.evoked_force(:,:,ii+hw.cb.ind_ev_resp)   = force.data( trig_time_in_force_sample_nbr : ...
                        (trig_time_in_force_sample_nbr + force.length_evoked_force - 1), : );
%                 else
%                     disp('one sync pulse in the Force is far too late!');
%                     drawnow;
%                 end
            end
        end
    end

    
    
%     % update ptr to index
%     hw.cb.ind_ev_resp           = length(ts_sync_pulses) + hw.cb.ind_ev_resp;


    % delete some variables
    clear analog_data ts_cell_array; 
    if tta_params.record_emg_yn
        emg                     = rmfield(emg,'data');
    end
    if tta_params.record_force_yn
        force                   = rmfield(force,'data');
    end
    
    % A 1-s pause to avoid stimulating 
end




%--------------------------------------------------------------------------
% Save data and stop cerebus recordings


disp(['Finished stimulating electrode ' num2str(tta_params.stim_elec)]);
disp(' ');


% Save the data, if specified in tta_params
if tta_params.save_data_yn
    
    % stop cerebus recordings
    cbmex('fileconfig', hw.cb.full_file_name, '', 0);
    cbmex('close');
    drawnow;
    drawnow;
    disp('Communication with Central closed');
    
%    xippmex('close');

    % save matlab data. Note: the time in the faile name will be the same as in the cb file
    hw.matlab_full_file_name    = fullfile( hw.data_dir, [tta_params.monkey '_' tta_params.bank '_' num2str(tta_params.stim_elec) '_' hw.start_t '_' tta_params.task '_STA' ]);
    
    disp(' ');
    
    if tta_params.record_force_yn == false
        save(hw.matlab_full_file_name,'emg','tta_params');
        disp(['EMG data and Stim Params saved in ' hw.matlab_full_file_name]);
    else
        save(hw.matlab_full_file_name,'emg','force','tta_params');
        disp(['EMG and Force data and Stim Params saved in ' hw.matlab_full_file_name]);
    end    
end

cbmex('close')


% Calculate the STA metrics and plot, if specified in tta_params
if tta_params.plot_yn
   
    if ~tta_params.record_force_yn
        sta_metrics             = calculate_sta_metrics( emg, tta_params );
    elseif ~tta_params.record_emg_yn
        sta_metrics             = calculate_sta_metrics( force, tta_params );
    else
        sta_metrics             = calculate_sta_metrics( emg, force, tta_params );
    end
end



%-------------------------------------------------------------------------- 
% Return variables
if nargout == 1
    if tta_params.record_emg_yn
        varargout{1}        = emg;
    else
        varargout{1}        = force;
    end
elseif nargout == 2
    if tta_params.record_emg_yn
        varargout{1}        = emg;
    else
        varargout{1}        = force;
    end
    varargout{2}            = tta_params;
elseif nargout == 3
    if tta_params.record_force_yn && tta_params.record_emg_yn
        varargout{1}        = emg;
        varargout{2}        = force;
        varargout{3}        = tta_params;
    elseif tta_params.record_emg_yn
        varargout{1}        = emg;
        varargout{2}        = tta_params;
        varargout{3}        = sta_metrics;        
    elseif tta_params.record_force_yn     
        varargout{1}        = force;
        varargout{2}        = tta_params;
        varargout{3}        = sta_metrics;
    end
elseif nargout == 4
    varargout{1}            = emg;
    varargout{2}            = force;
    varargout{3}            = tta_params;
    varargout{4}            = sta_metrics;
end


