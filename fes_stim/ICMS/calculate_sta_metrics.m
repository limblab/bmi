%
% Function to calculate the StTA metrics from data recorded with the
% 'stim_trig_avg' function 
%
%       function varargout = calculate_sta_metrics( varargin )
%
%
% Syntax:
%       STA_METRICS         = CALCULATE_STA_METRICS( EMG, STA_PARAMS )
%       STA_METRICS         = CALCULATE_STA_METRICS( FORCE, STA_PARAMS )
%       STA_METRICS         = CALCULATE_STA_METRICS( EMG, FORCE, STA_PARAMS )
%       STA_METRICS         = CALCULATE_STA_METRICS( EMG, STA_PARAMS, STA_METRICS_PARAMS ), 
%               if sta_params.record_force_yn = false 
%       STA_METRICS         = CALCULATE_STA_METRICS( FORCE, STA_PARAMS, STA_METRICS_PARAMS ), 
%               if sta_params.record_emg_yn = false 
%       STA_METRICS         = CALCULATE_STA_METRICS( EMG, FORCE, STA_PARAMS, STA_METRICS_PARAMS )
%       
%
% Input parameters:
%       'emg'                   : structure that contains the evoked EMG
%                                   response (per stim) and other EMG
%                                   information    
%       'force'                 : structure that contains the evoked Force
%                                   response (per stim) and other Force
%                                   information    
%       'sta_params'            : structure that contains the parameters
%                                   for the experiment 
%       'sta_metrics_params'    : structure that contains the parameters to
%                                   calculate the metrics
%
% Outputs:
%       'sta_metrics'           : metrics that characterize PSF: 1) Fetz'
%                                   and Cheney's MPSF; 2) Polyakov and
%                                   Schiebert's statistics    
%
%
%
%                           Last modified by Juan Gallego 6/17/2015


%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%       % ToDos:
%       - Calculate MPSI, analogously to MPSF
%       - Rectify the force?
%       - Resample all EMGs to 4 kHz? (or at least downsample form 10 kHz
%       to 4 kHz)
%



function varargout = calculate_sta_metrics( varargin )



% read parameters

switch nargin 
    case 1,
        error('the function needs at least two parameters');
    case 2,
        sta_params              = varargin{2};
        if ~isfield(varargin{1},'record_emg_yn')
            emg                 = varargin{1};
            sta_params.record_emg_yn    = true;     % to fix inconsistencies among versions
            sta_params.record_force_yn  = false;     % to fix inconsistencies among versions
        else
            if sta_params.record_emg_yn
                emg             = varargin{1};
            else
                force           = varargin{1};
            end
        end
        sta_metrics_params      = calculate_sta_metrics_defaults();
    case 3,
        if isfield(varargin{2},'record_force_yn')
            sta_params          = varargin{2};
            sta_metrics_params  = varargin{3};
            if ~isfield(sta_params,'record_emg_yn')
                emg             = varargin{1};
                sta_params.record_emg_yn    = true;     % to fix inconsistencies among versions
            elseif sta_params.record_emg_yn
                emg             = varargin{1};
            else
                force           = varargin{1};
            end
        else
            emg                 = varargin{1};
            force               = varargin{2};
            sta_params          = varargin{3};
            sta_metrics_params  = calculate_sta_metrics_defaults();
        end
    case 4,
        emg                     = varargin{1};
        force                   = varargin{2};
        sta_params              = varargin{3};
        sta_metrics_params      = varargin{4};
    otherwise,
        error('the function only takes up to 4 parameters');
end


if nargout > 1
    error('the function only returns one variable of type sta_metrics');
end


% override the plot option of sta_metrics_params, if specified in
% sta_params.plot_yn
if sta_params.plot_yn && ~sta_metrics_params.plot_yn
    sta_metrics_params.plot_yn  = true;
end



%-------------------------------------------------------------------------- 
% If we have recorded EMG...

if sta_params.record_emg_yn


% If we want to high pass filter the EMG

    if sta_metrics_params.hp_filter_EMG_yn

        % design the filter
        order                   = 1;
        W_n                     = sta_metrics_params.fc_hp_filter_EMG/(emg.fs/2);
        [a, b]                  = butter(order,W_n,'high');

        % filter all the EMG channels
        for i = 1:emg.nbr_emgs

            emg.evoked_emg_filt(:,i,:)  = filtfilt( a, b, squeeze(emg.evoked_emg(:,i,:)) );
        end

        % The hihg-pass filtered EMG will replace 'emg.evoked_emg'. The raw EMG
        % will be stored in new field 'evoked_EMG_raw'
            emg.evoked_emg_raw  = emg.evoked_emg;
            emg.evoked_emg      = emg.evoked_emg_filt;
    end



    %--------------------------------------------------------------------------
    %-------------------------------------------------------------------------- 
    % Some preliminary stuff

    % get rid of the EMG data epochs that are zero (because of a misalignment
    % of the sync pulse in the time stamps and analog data that are read from
    % central)

    zero_emg_rows               = all(emg.evoked_emg==0,1);
    zero_emg_rows               = squeeze(zero_emg_rows(1,1,:));    % array of logic variables that tell if that row is == 0
    emg.evoked_emg(:,:,zero_emg_rows)   = [];


    % check, if the 'last_evoked_resp' ~= 0 (last sample), if the specified
    % value is within limits
    [~,~,nbr_evoked_emg_responses]  = size(emg.evoked_emg);
    if ( sta_metrics_params.last_evoked_resp == 0 ) || ( sta_metrics_params.last_evoked_resp > nbr_evoked_emg_responses )
        sta_metrics_params.last_evoked_resp  = nbr_evoked_emg_responses;
    end



    %-------------------------------------------------------------------------- 
    % Compute the StTAs of the EMGs
    % Calculate mean (and SD) rectified EMG -> The mean is used to compute the STA

    mean_emg                    = mean( abs(emg.evoked_emg(:,:,sta_metrics_params.first_evoked_resp:sta_metrics_params.last_evoked_resp)),3 );
    %std_emg                     = std(abs(emg.evoked_emg(:,:,first_evoked_emg:last_evoked_emg)),0,3);
end


%--------------------------------------------------------------------------
%-------------------------------------------------------------------------- 
% Calculate the StTAs of the Force, if it is passed to the function

if exist('force','var')
    
    % get rid of the Force data epochs that are zero (because of a
    % misalignment of the sync pulse in the time stamps and analog data
    % that are read from central)  
    zero_force_rows             = all(force.evoked_force==0,1);
    zero_force_rows             = squeeze(zero_force_rows(1,1,:));    % array of logic variables that tell if that row is == 0
    force.evoked_force(:,:,zero_force_rows)   = [];

    % check, if the 'last_evoked_resp' ~= 0 (last sample), if the specified
    % value is within limits
    [~,~,nbr_evoked_force_responses]    = size(force.evoked_force);
    if ( sta_metrics_params.last_evoked_resp == 0 ) || ( sta_metrics_params.last_evoked_resp > nbr_evoked_force_responses )
        sta_metrics_params.last_evoked_resp  = nbr_evoked_force_responses;
    end
    
    % detrend the evoked force
    for i = 1:force.nbr_forces
        force.detrend_evoked_force(:,i,:)  = detrend(squeeze(force.evoked_force(:,i,:)));
    end
    
    % Calculate the mean force response, for each force sensor
    mean_force                  = mean(force.evoked_force(:,:,sta_metrics_params.first_evoked_resp:sta_metrics_params.last_evoked_resp),3);
    mean_detrended_force        = mean(force.detrend_evoked_force(:,:,sta_metrics_params.first_evoked_resp:sta_metrics_params.last_evoked_resp),3);
end
    




%--------------------------------------------------------------------------
%-------------------------------------------------------------------------- 
% EMG Metrics

if ~isfield(varargin{1},'record_emg_yn') 

    %-------------------------------------------------------------------------- 
    % Calculate the "Mean percent facilitation" (Cheney & Fetz, 1985) - height
    % of the PSF peak above the mean baseline level, divided by the baseline
    % noise  


    % Calculate the mean and SD baseline EMG for each channel. 
    % Fetz & Cheney calculate the baseline -5:5 ms w.r.t to the spike. Since we
    % have stimulation artefacts I use -20:-2 ms as standard (more similarly to 
    % (Griffin et al., 2009) 

    mean_baseline_emg            	= mean(abs(emg.evoked_emg((sta_metrics_params.beg_bsln*emg.fs/1000+1):((sta_params.t_before - sta_metrics_params.end_bsln)*emg.fs/1000+1), ...
        :,sta_metrics_params.first_evoked_resp:sta_metrics_params.last_evoked_resp)),3);
    mean_mean_baseline_emg          = mean(mean_baseline_emg,1);
    std_mean_baseline_emg           = std(mean_baseline_emg,0,1);


    % Look for a threshold (mean + 2*SD) crossing that lasts > 1 ms (the time
    % specified in 'sta_metrics_params.min_duration_PSF'). The code start
    % several ms after the stimulus (sta_metrics_params.min_t_after_stim_for_PSF)
    % to avoid the effect of stimulation artefacts

    start_PSF_win               	= (sta_params.t_before + sta_metrics_params.min_t_after_stim_for_PSF)*emg.fs/1000 + 1;
    MPSF                            = zeros(emg.nbr_emgs,1);
    duration_PSF                    = zeros(emg.nbr_emgs,1);
    t_after_stim_start_PSF          = zeros(emg.nbr_emgs,1);

    t_emg                           = -sta_params.t_before:1/emg.fs*1000:sta_params.t_after;       % in ms



    for i = 1:emg.nbr_emgs


        % Look for the peak EMG activity 
        [~, aux_pos_max]            = max(mean_emg(start_PSF_win:end,i));
        pos_peak_PSF                = aux_pos_max + start_PSF_win - 1;      % this is the position of the peak wrt the beginnig 


        % See if the peak is above the baseline EMG (mean + 2*SD)
        aux_emg_without_bsln        = mean_emg(:,i) - ( mean_mean_baseline_emg(i) + 2*std_mean_baseline_emg(i) );

        if aux_emg_without_bsln(pos_peak_PSF) > 0

            start_PSF               = find(aux_emg_without_bsln(1:pos_peak_PSF-1) < 0, 1, 'last') + 1;
            end_PSF                 = find(aux_emg_without_bsln(pos_peak_PSF+1:end) < 0, 1) - 1 + pos_peak_PSF;

            if ( ~isempty(end_PSF) && ~isempty(start_PSF) ) && ( (end_PSF - start_PSF) > sta_metrics_params.min_duration_PSF*emg.fs/1000 )

                duration_PSF(i)     = (end_PSF - start_PSF)*1000/emg.fs;

                MPSF(i)             = ( mean(mean_emg(start_PSF:end_PSF,i)) - mean_mean_baseline_emg(i)) / mean_mean_baseline_emg(i) * 100;
                t_after_stim_start_PSF(i)   = t_emg(start_PSF );
            end
        end
    end



    %-------------------------------------------------------------------------- 
    % Calculate MPSI - similar to MPSF but for inhibition

    MPSI                            = zeros(emg.nbr_emgs,1);

    % TODO!!




    %-------------------------------------------------------------------------- 
    % Calculate "Multiple fragment statistical analysis," (Poliakov &
    % Schiebert, 1998)

    
    % This function will only be applied for stimulation with single pulses
    % not trains
    if isfield(sta_params,'stim_mode') && ~strncmp(sta_params.stim_mode,'trains',5) || ~isfield(sta_params,'stim_mode' )

        % Definitions for the intervals in which we will divide the data
        % for clarity, the values are first specified in ms and then transformed to
        % indexes in the vectors
        r_T_intvl                       = [8 18];
        r_c1_intvl                      = [-12 -2];
        r_c2_intvl                      = [18 28];

        r_T_intvl                       = (r_T_intvl + sta_params.t_before) * emg.fs /1000 + 1;
        r_c1_intvl                      = (r_c1_intvl + sta_params.t_before) * emg.fs /1000 + 1;
        r_c2_intvl                      = (r_c2_intvl + sta_params.t_before) * emg.fs /1000 + 1;

        % check that we are not outside margins
        if min(t_emg(r_c1_intvl)) < -sta_params.t_before
            disp('the r_c1 interval falls outside limits');
            return;
        end

        if max(t_emg(r_c2_intvl)) > sta_params.t_after
            disp('the r_c2 interval falls outside limits');
            return;
        end


        % 1. Divide the dataset into sqrt(nbr of stimuli) non-overlapping windows
        % (of size sqrt(nbr of spikes)) 

        nbr_non_overlap_wdws            = floor(sqrt(size(emg.evoked_emg,3)));
        Xj_MFSA                         = zeros( nbr_non_overlap_wdws, emg.nbr_emgs );
        r_T                             = zeros( nbr_non_overlap_wdws, emg.nbr_emgs );
        r_c1                            = zeros( nbr_non_overlap_wdws, emg.nbr_emgs );
        r_c2                            = zeros( nbr_non_overlap_wdws, emg.nbr_emgs );
        %Z_MFSA                          = zeros( nbr_non_overlap_wdws, emg.nbr_emgs );
        P_Z_test                        = zeros( 1, emg.nbr_emgs );


        % 2. Calculate the mean SpTA rEMG for each segment, 'mean_temp_STAs_MFSA'

        for i = 1:emg.nbr_emgs

            for ii = 1:nbr_non_overlap_wdws

                temp_start_indx         = 1+(ii-1)*nbr_non_overlap_wdws;
                temp_end_indx           = ii*nbr_non_overlap_wdws;

                % 'temp_StTAs_MFSA' is the mean rectified EMG for this 'fragment',
                % and muscle
                temp_StTAs_MFSA         = mean(abs(squeeze(emg.evoked_emg(:,i,temp_start_indx:temp_end_indx))),2);

                % 3. Calculate the test parameter X for each segment. 
                % 	X_j = mean(r_T - (r_c1 + r_C2)/2 (j = 1:nr_non_overlap_wdws)
                r_T(ii,i)               = mean(temp_StTAs_MFSA(r_T_intvl));
                r_c1(ii,i)              = mean(temp_StTAs_MFSA(r_c1_intvl));
                r_c2(ii,i)              = mean(temp_StTAs_MFSA(r_c2_intvl));

                Xj_MFSA(ii,i)           = r_T(ii,i) - (r_c1(ii,i) + r_c2(ii,i))/2;

            end

            % 4. Test the null hypothesis that the mean value of X was zero
            % with a two-tailed z-test.
            %   Take the mean and SD of the sample population and the
            %   standard (i.e. ~N(0,1)) normal distribution

            [~, P_Z_test(i)]             = ztest(Xj_MFSA(:,i),0,1);
        end
    end


    %-------------------------------------------------------------------------- 
    % Return metrics


    sta_metrics.emg.nbr_stims       = sta_metrics_params.last_evoked_resp - sta_metrics_params.first_evoked_resp + 1;
    sta_metrics.emg.mean_emg        = mean_emg;
    sta_metrics.emg.mean_baseline_emg       = mean_mean_baseline_emg;
    sta_metrics.emg.std_baseline_emg        = std_mean_baseline_emg;

    sta_metrics.emg.MPSF            = MPSF;
    sta_metrics.emg.t_after_stim_start_PSF  = t_after_stim_start_PSF;
    sta_metrics.emg.duration_MPSF   = duration_PSF;

    if ( isfield(sta_params,'stim_mode') && ~strncmp(sta_params.stim_mode,'trains',5) ) || ~isfield(sta_params,'stim_mode' )
        sta_metrics.emg.P_Ztest     = P_Z_test;
        sta_metrics.emg.Xj_Ztest    = Xj_MFSA;
    end
    
    sta_metrics.emg.labels          = emg.labels;
end


if exist('force','var')

    sta_metrics.force.nbr_stims     = sta_metrics_params.last_evoked_resp - sta_metrics_params.first_evoked_resp + 1;
    sta_metrics.force.mean_force    = mean_force;
    sta_metrics.force.mean_detrended_force    = mean_detrended_force;
    
    % ToDo: include the rest
end
    


if nargout == 1
   
    varargout{1}                = sta_metrics;
end



%--------------------------------------------------------------------------
% Plot, if specified in 'sta_metrics_params.plot_yn'
if sta_metrics_params.plot_yn
    
    if sta_params.record_emg_yn && sta_params.record_force_yn
        plot_sta( emg, force, sta_params, sta_metrics );
    elseif ~sta_params.record_force_yn
        plot_sta( emg, sta_params, sta_metrics );
    else
        plot_sta( force, sta_params, sta_metrics );
    end
end