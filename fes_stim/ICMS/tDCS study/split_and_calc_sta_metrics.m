% This  function loads all the files of the same type (baseline, tDCS or
% post-tDCS), splits them into windows of as many responses as specified in
% 'resp_per_win' and gives the resultant STA_METRICS  
%
%   sta_metrics_array = split_and_calc_sta_metrics( file_names, nbr_responses, varargin ) 
%
%   'file_names'            : the name of the files
%   'nbr_responses'         : nbr. of EMG responses in each of the windows
%                               in which each file will be split
%   'varargin'              : the number of files; if not passed it will be
%                               calculated by the function
%
%


function sta_metrics_array = split_and_calc_sta_metrics( file_names, nbr_responses, varargin ) 


% See if we need to compute the number of trials
if nargin == 3
    nbr_files               = varargin{1};
else
    if iscell(file_names)
        nbr_files           = numel(file_names);
    else
        nbr_files           = 1;
    end               
end


% Initalize calculate_sta_metrics_params
stamp                       = calculate_sta_metrics_defaults;
stamp.plot_yn               = false; % do not plot the responses for each epoch


% For the baseline trials (or the ICMS only trials)
bsln_epoch_ctr              = 1;

for i = 1:nbr_files

    if nbr_files > 1, 
        load( file_names{i} );
    else
        load( file_names );
    end
    sta_params.plot_yn      = false; % do not plot the responses for each epoch
    
    % 1. Get rid of the empty elements in the EMG responses
    zero_emg_rows           = all(emg.evoked_emg==0,1);
    zero_emg_rows           = squeeze(zero_emg_rows(1,1,:));    % array of logic variables that tell if that row is == 0
    emg.evoked_emg(:,:,zero_emg_rows)   = [];
    emg.nbr_evoked_resp     = size(emg.evoked_emg,3);
    
    % 2. Split the trial in epochs of the length specified in nbr_responses 
    nbr_epochs_this_trial   = floor( emg.nbr_evoked_resp / nbr_responses );
    
    % 3. Calculate the STA metrics for each of the data epochs in which the
    % trial file was divided
    for ii = 1:nbr_epochs_this_trial
    
        stamp.first_evoked_resp     = (ii - 1) * floor(emg.nbr_evoked_resp / nbr_epochs_this_trial) + 1;
        stamp.last_evoked_resp      = stamp.first_evoked_resp + nbr_responses - 1;
        
        sta_metrics_array(bsln_epoch_ctr)   = calculate_sta_metrics( emg, sta_params, stamp );
        
        % Add the sampling frequency
        sta_metrics_array(bsln_epoch_ctr).emg.fs            = emg.fs;
        sta_metrics_array(bsln_epoch_ctr).emg.t_before   = sta_params.t_before;
        sta_metrics_array(bsln_epoch_ctr).emg.t_after    = sta_params.t_after;
        
        bsln_epoch_ctr              = bsln_epoch_ctr + 1;
    end    
end

end
