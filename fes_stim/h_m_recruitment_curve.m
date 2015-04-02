%
% Function to obtain H-reflex and M-wave recruitment curves
%
%   function varargout = h_m_recruitment_curve( varargin )
%
%
%   The function takes 1 or 0 arguments of type 'h_m_params'. When no
%   arguments are passed, it loads the parameters defined in
%   'h_m_recruitment_curve_default.m'
%
%   The function can return one variable of type 'emg'. 'emg' is a
%   structure that comprises: 1) the evoked EMG activity in all the
%   electrodes for each stimulus, 2) the estimated H-reflex and M-wave for
%   each stimulus in the chosen electrode, and 3) the amplitude of the
%   stimuli delivered  
%



% %%%%%%%%%%%%
%   Some known issues:
%       - The resolution of the stimulator, 250 uA/step, is hardcoded. The
%       same for the EMG sampling freq, to 2 kHz
%       - The stimulation time is obtained by looking for the stimulus
%       artefact not by reading a sync out
%
%
%   Last edited by Juan Gallego, 01/25/15
%


function varargout = h_m_recruitment_curve( varargin )


% read parameters

% If the function is called without input paramters 

if nargin > 1
    
    disp('ERROR: The function only takes one argument of type h_m_params');
    return;
elseif nargin == 1
   
    h_m_params              = varargin{1};
elseif nargin == 0
    
    h_m_params              = h_m_recruitment_curve_default();
end



%--------------------------------------------------------------------------
% some preliminary calculations

% create vector with stimulation amplitudes, randomly ordered
% Note 'hw' will have all the cerebus and grapevine stuff
hw.gv.stim_amps             = repmat(linspace(h_m_params.min_stim_ampl,h_m_params.max_stim_ampl,h_m_params.nbr_steps),1,h_m_params.nbr_reps);
hw.gv.stim_amps             = datasample(hw.gv.stim_amps,length(hw.gv.stim_amps),'Replace',false);



%--------------------------------------------------------------------------
%% connect with Central 

% connect to central; if connection fails, return error message and quit
if ~cbmex('open', 1)
    
    echoudp('off');
%    close(handles.keep_running);
    error('ERROR: Connection to Central Failed');
end


% if want to save the data...
if h_m_params.save_data_yn
    
    % create file name
    hw.data_dir             = [h_m_params.data_dir filesep 'h-reflex_data_' datestr(now,'yyyy_mm_dd')];
    if ~isdir(hw.data_dir)
        mkdir(hw.data_dir)
    end
    hw.start_t              = datestr(now,'yyyymmdd_HHMMSS');
    hw.cb.full_file_name    = fullfile( hw.data_dir, [h_m_params.monkey '_' hw.start_t '_' s_f_params.task '_h-reflex' ]);
    
    % start 'file storage' app, or stop ongoing recordings
    cbmex('fileconfig', fullfile( hw.data_dir, hw.cb.full_file_name ), '', 0 );  
    drawnow;                        % wait till the app opens
    pause(1);
    drawnow;                        % wait some more to be sure. If app was closed, it did not always start recording otherwise

    % start cerebus file recording
    cbmex('fileconfig', hw.cb.full_file_name, '', 1);
end    




% flush central's buffer - ToDo: Why?????
cbmex('trialconfig', 1);
drawnow;

pause(1);                       % ToDo: see if it's necessary


% Figure out how many EMG and force channels there are, and preallocate
% matrices accordingly

[ts_cell_array, ~, analog_data]     = cbmex('trialdata',1);

analog_data(:,1)        = ts_cell_array([analog_data{:,1}]',1); % replace channel numbers with names

emg.data                = analog_data( strncmp(analog_data(:,1), 'EMG', 3), 3 );

[emg.nbr_emgs, ~]       = size(emg.data);
disp(' '), disp(['Nbr EMG channels: ' num2str(emg.nbr_emgs)]);

emg.length_evoked_emg   = ( abs(h_m_params.beg_baseline_win) + h_m_params.end_h_reflex_win + h_m_params.extra_rec_time ) * 2000/1000;
emg.evoked_emg          = zeros( emg.length_evoked_emg, h_m_params.nbr_reps * h_m_params.nbr_steps, emg.nbr_emgs ); % ToDo: replace by read EMG sampling freq


if h_m_params.record_force_yn 
    force.data          = analog_data( strncmp(analog_data(:,1), 'Force', 5), 3 );
    [force.nbr_forces,~]= size(force.data);
    disp(['Nbr Force sensors: ' num2str(force.nbr_forces)]), disp(' ');
    force.evoked_force  = zeros( ( abs(h_m_params.beg_baseline_win) + h_m_params.end_h_reflex_win + h_m_params.extra_rec_time ) * 2000/1000, h_m_params.nbr_reps * h_m_params.nbr_steps, force.nbr_forces ); % ToDo: replace by read Force sampling freq
end

clear analog_data ts_cell_array;



%--------------------------------------------------------------------------
%% connect with Grapevine

% initialize xippmex
hw.gv.connection            = xippmex;

% if the connection fails, return error message and quite
if hw.gv.connection ~= 1
        cbmex('close');
        error('ERROR: Xippmex did not initialize');
end

% find all Micro+Stim channels (stimulation electrodes)
hw.gv.stim_ch               = xippmex('elec','stim');

if isempty(hw.gv.stim_ch)
    cbmex('close');
    error('ERROR: no stimulator found!');
end


%--------------------------------------------------------------------------
%% stimulate to get the curves!


% figure to plot the M-waves and H-reflex
emg_fig                     = struct(...
    'h',                        figure, ...
    't',                        h_m_params.beg_baseline_win:1000/2000:(h_m_params.end_h_reflex_win + h_m_params.extra_rec_time), ...
    'colors_plot',              colormap(autumn(length(hw.gv.stim_amps))),...
    'colors_plot_2',            colormap(winter(length(hw.gv.stim_amps))));

set(emg_fig.h, 'Name', 'Evoked EMG - Close this figure to stop');


% vars to store h-reflexes, m-wave, and baseline emg
emg.baseline                = zeros(1,length(hw.gv.stim_amps));
emg.h_reflex                = zeros(1,length(hw.gv.stim_amps));
emg.m_wave                  = zeros(1,length(hw.gv.stim_amps));

% a high pass filter for the EMG (from Dideriksen et al., J Appl Physiol, 2014)
[emg.online_filt.b, emg.online_filt.a]  = butter(5,120/(2000/2),'high');

drawnow;




for i = 1:length(hw.gv.stim_amps)
        
    
    %------------------------------------------------------------------
    % Define the stimulation string for the pair of channes. Note the
    % polarity (PL) is defined so as to one electrode is the anode and the
    % other the cathode
    
    % ToDo: check the definition of train lenght and stim frequency, now
    % 1-s and 1-Hz 
    stim_string             = [ 'Elect = ' num2str(h_m_params.stim_elecs(1)) ',' num2str(h_m_params.stim_elecs(2) + 1) ',; ' ...
                                'TL = 1000,1000,; ' ...    
                                'Freq = 1,1,; ' ...
                                'Dur = ' num2str(h_m_params.stim_pw) ',' num2str(h_m_params.stim_pw) ',; ' ...
                                'Amp = ' num2str(hw.gv.stim_amps(i)/.25) ',' num2str(hw.gv.stim_amps(i)/.25) ',; ' ...  % ToDo: define step as param
                                'TD = ' num2str(abs(h_m_params.beg_baseline_win)) ',' num2str(abs(h_m_params.beg_baseline_win)) ',; ' ...
                                'FS = 0,0,;' ...
                                'PL = 1,0,;'];
       
    % Flush the Central buffer before we start the stim
    cbmex('trialdata',1);

    % Store the current time. To control execution
    t_start                 = tic;
    
    % Send stimulation command
    xippmex('stim',stim_string);
    drawnow;

    
    %------------------------------------------------------------------ 
    % read and display EMG (and force) % ToDo: force
    % check if 1 s has been elapsed (for plotting and saving time) % ToDo: IMPROVE!!!
    paure(1);
    
    
    % read the data from central (flush the data cache)
    [ts_cell_array, ~, analog_data]   = cbmex('trialdata',1);
    
    % retrieve EMG data
    analog_data(:,1)        = ts_cell_array([analog_data{:,1}]',1); % replace channel numbers with names
   
    emg.data                = analog_data( strncmp(analog_data(:,1), 'EMG', 3), 3 );
    clear analog_data ts_cell_array;
    
    %------------------------------------------------------------------     
    % calculate H-reflex and M-wave; methods from (Dideriksen et al., 2014)
    
    % 1. high-pass filter the EMG
    filt_emg_h_m            = filtfilt( emg.online_filt.b, emg.online_filt.a, double(emg.data{h_m_params.emg_ch_for_plot+1}(1:length(emg_fig.t))));
    
    % 1b. Find the stimulation artefact. % ToDo: replace with the spike time!!!!
    [~, pos_min]            = min(filt_emg_h_m);
    [~, pos_max]            = max(filt_emg_h_m);
    stim_sample_nbr         = min([pos_min, pos_max]); 
    
    % 2. calculate the H-reflex (max peak-to-peak 12:22 ms after stim)
    emg.h_reflex(i)         = max( filt_emg_h_m( (stim_sample_nbr + 12*2000/1000):(stim_sample_nbr + 22*2000/1000) ) ) + ...
                                max( -filt_emg_h_m( (stim_sample_nbr + 12*2000/1000):(stim_sample_nbr + 22*2000/1000) ) );
                            
    % 2. calculate the M-wave (max peak-to-peak 2:12 ms after stim) % ToDo: DOUBLE CHECK !!!!
    emg.m_wave(i)           = max( filt_emg_h_m( (stim_sample_nbr + 2*2000/1000):(stim_sample_nbr + 12*2000/1000) ) ) + ...
                                max( -filt_emg_h_m( (stim_sample_nbr + 2*2000/1000):(stim_sample_nbr + 12*2000/1000) ) );
    
    
    % plot the data
    if ishandle(emg_fig.h)
       
        subplot(121), hold on, plot( emg_fig.t, emg.data{h_m_params.emg_ch_for_plot+1}(1:length(emg_fig.t)), ...
            'color', [.3 .3 .3]), 
        subplot(121), hold on, plot( emg_fig.t, filt_emg_h_m, 'linewidth', 2, 'color', emg_fig.colors_plot(i,:))
        title('evoked EMG'), xlabel('time (ms)'), ylabel('EMG (mV)'), xlim([emg_fig.t(1), emg_fig.t(end)]);
        
        subplot(122), hold on, plot( hw.gv.stim_amps(i), emg.h_reflex(i), 'marker', 'o', 'color', emg_fig.colors_plot(i,:))
        
        subplot(122), hold on, plot( hw.gv.stim_amps(i), emg.m_wave(i), 'marker', 'square', ...
            'color', emg_fig.colors_plot_2(i,:)), title('recruitment curves'), xlabel('stim amplitude (mA)'), ylabel('peak-to-peak EMG (mV)'),
            legend('h-reflex', 'm-wave'), xlim([(h_m_params.min_stim_ampl-0.5), (h_m_params.max_stim_ampl+0.5)])
    else
        disp('Execution stopped by the user');
        cbmex('close');
        break;
    end
    
    
    % store the raw EMG data
    for ii = 1:emg.nbr_emgs
        emg.evoked_emg( :, i, ii)   = double(emg.data{ii}(1:emg.length_evoked_emg));    % ToDo: check size does not change!
    end
    
    
    %------------------------------------------------------------------
    % Wait until this cycle is over
        
    if h_m_params.manual_stim_ctrl_yn ~= 1
    
        % check if the random time between stimuli is over (-1 s that we
        % waited for above). The random time is defined considering the max
        % and min ISI set in h_m_params
        t_elapsed           = toc(t_start);
    
        while t_elapsed < ( h_m_params.min_inter_stim_int + rand(1)*(h_m_params.max_inter_stim_int - h_m_params.min_inter_stim_int) - 1)
            t_elapsed       = toc(t_start);
        end
    else
        % wait for the user to send another stim command
        pause;
    end

    % ToDo - display a bunch of things before the next cycle
    disp(['Stim nbr: ' num2str(i) ' size evoked_emg: ' num2str(size(emg.evoked_emg))]);
end


%--------------------------------------------------------------------------
% Save data and stop cerebus recordings


% prepare variables for storage
emg.stim_amps               = hw.gv.stim_amps;
emg                         = rmfield(emg,'data');
emg                         = rmfield(emg,'online_filt');
    

% Return variables
if nargout == 1
    
    varargout{1}            = emg;
end



if h_m_params.save_data_yn
    
    % stop cerebus recordings
    cbmex('fileconfig', hw.cb.full_file_name, '', 0);
    cbmex('close');
    drawnow;
    disp('Communication with Central closed');

    % save matlab data. Note: the time in the faile name will be the same as in the cb file
    hw.matlab_full_file_name    = fullfile( hw.data_dir, [h_m_params.monkey '_' hw.start_t '_' s_f_params.task '_h-reflex' ]);
    
        
    disp(' ');
    save(hw.matlab_full_file_name,'emg');
    disp(['EMG, H-refex, M-wave and stim_amps saved in ' hw.matlab_full_file_name]);
end