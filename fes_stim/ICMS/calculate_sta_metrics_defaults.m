% 
% This function creates a structure that contains the default parameters
% for the function CALCULATE_STA_METRICS.M 
%
%
%       function sta_metrics_params = calculate_sta_metrics_defaults()
%
%
%       sta_metrics_params      : structure with fields
%           beg_bsln            : (ms) beginning of the baseline EMG
%                                   window. Measured wrt the beginning of
%                                   the evoked EMG for each stimulus.  
%           end_bsln            : (ms) end of the baseline EMG window.
%                                   Measured wrt the stimulus time
%                                   (positive means before stimulus time)
%           min_duration_PSF    : (ms) minimum duration for an increase in
%                                   EMG to be considered as an effect.
%           min_t_after_stim_for_PSF:   (ms) minimum time after the stimulus 
%                                   for an increase in EMG to be considered 
%                                   as an effect. 
%           first_evoked_resp   : first evoked response that will be
%                                   included in the StTAs (if you want to
%                                   consider a subset of the responses)    
%           last_evoked_resp    : last evoked response that will be
%                                   included in the StTAs (if you want to
%                                   consider a subset of the responses). If
%                                   == 0 => last   
%           hp_filter_EMG_yn    : if == 1 high-pass filter the EMG (1st
%                                   order Butterworth, zero-phase).
%           fc_hp_filter_EMG	: cut-off frequency of the high-pass filter
%                                   in Hz.
%           plot_yn             : plot the results using plot_sta().
%                                   Includes the metrics
%


function sta_metrics_params = calculate_sta_metrics_defaults()



sta_metrics_params  = struct(...
    'beg_bsln',                     0, ...
    'end_bsln',                     2, ...
    'min_duration_PSF',             1, ...
    'min_t_after_stim_for_PSF',     7, ...
    'first_evoked_resp',            1, ...
    'last_evoked_resp',             0, ...
    'hp_filter_EMG_yn',             0, ...
    'fc_hp_filter_EMG',             100, ...
    'plot_yn',                      true);
