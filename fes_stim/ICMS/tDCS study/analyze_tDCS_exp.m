% Function that loads all the files of an ICMS experiment (with or without
% tDCS), and plots a series of metrics that summarize the experiment
%
%   function tDCS_results = analyze_tDCS_exp( tDCS_exp )
%


function tDCS_results = analyze_tDCS_exp( tDCS_exp )


% If it's a tDCS experiment
if ~isempty( tDCS_exp.baseline_files )
    
    % Define the number of trials of each type, and store that in the
    % trial_type variable, that will be used for the analysis and the plots
    if iscell(tDCS_exp.baseline_files)
        nbr_bsln_trials     = numel(tDCS_exp.baseline_files);
    elseif tDCS_exp.baseline_files ~= 0
        nbr_bsln_trials     = 1;
    else
        nbr_bsln_trials     = 0;
    end
    
    if iscell(tDCS_exp.tDCS_files)
        nbr_tDCS_trials     = numel(tDCS_exp.tDCS_files);
    elseif tDCS_exp.tDCS_files ~= 0
        nbr_tDCS_trials     = 1;
    else
        nbr_tDCS_trials     = 0;
    end
    
    if iscell(tDCS_exp.post_tDCS_files)
        nbr_post_trials     = numel(tDCS_exp.post_tDCS_files);
    elseif tDCS_exp.post_tDCS_files ~= 0
        nbr_post_trials     = 1;
    else
        nbr_post_trials     = 0;
    end
    
    nbr_trials              = nbr_bsln_trials + nbr_tDCS_trials + nbr_post_trials;
    
    % Fill the 'trial_type' variable
    trial_type              = cell(1,nbr_trials);
    
    for i = 1:nbr_bsln_trials
        trial_type{i}       = 'bsln';
    end
    for i = 1:nbr_tDCS_trials
        trial_type{i+nbr_bsln_trials}                   = 'tDCS';
    end
    for i = 1:nbr_post_trials
        trial_type{i+nbr_bsln_trials+nbr_tDCS_trials}   = 'post';
    end    
    
                            
% For an ICMS-only experiment, define all the trials as 'baseline'
else
    
    bsln                    = what( tDCS_exp.exp_folder );
    tDCS_exp.baseline_files = bsln.mat;
    clear bsln;
    
    nbr_trials              = numel(tDCS_exp.baseline_files);
    nbr_bsln_trials         = nbr_trials; % For consistency
    [nbr_tDCS_trials nbr_post_trials]   = deal(0); % For consistency
    trial_type              = cell(1,nbr_trials);
    for i = 1:nbr_trials
        trial_type{i}       = 'bsln';
    end
end



% -------------------------------------------------------------------------
% Retrieve each trial and calculate STA_metrics

% time_axis                   = [];


% For the baseline trials
if nbr_bsln_trials > 0
    sta_metrics_bsln        = split_and_calc_sta_metrics( tDCS_exp.baseline_files, ...
                                tDCS_exp.resp_per_win, nbr_bsln_trials );
end


% For the tDCS trials
if nbr_tDCS_trials > 0
    sta_metrics_tDCS        = split_and_calc_sta_metrics( tDCS_exp.tDCS_files, ...
                                tDCS_exp.resp_per_win, nbr_tDCS_trials );
end

% For the post-tDCS trials
if nbr_post_trials > 0
    sta_metrics_post        = split_and_calc_sta_metrics( tDCS_exp.post_tDCS_files, ...
                                tDCS_exp.resp_per_win, nbr_post_trials );
end



% -------------------------------------------------------------------------
% Look at the data you want


% Look for the specified muscles, if any. Otherwise, initialize a 'dummy'
% array of muscles positions in 'sta_metrics_XXXX'
if ~isempty(tDCS_exp.muscles)
    
    nbr_muscles             = numel(tDCS_exp.muscles);
    pos_muscles             = zeros(1,nbr_muscles);
    for i = 1:numel(pos_muscles)
        sta_vars            = whos('sta_metrics*');
        pos_muscles(i)      = find( strncmp( eval([sta_vars(1).name '(1).emg.labels']), ...
                                tDCS_exp.muscles{i}, length(tDCS_exp.muscles{i}) ) );
        clear sta_vars;
    end
else
    pos_muscles             = 1:numel(sta_metrics_bsln(1).emg.labels);
    nbr_muscles             = numel(pos_muscles);
end


% -------------------------------------------------------------------------
% 1. Plot the MPSF for the specified muscles (or all of them)

% See how many MPSF 'points' (epochs) we have

if nbr_bsln_trials > 0
    nbr_points_bsln         = numel(sta_metrics_bsln);
else
    nbr_points_bsln         = 0;
end
if nbr_tDCS_trials > 0
    nbr_points_tDCS         = numel(sta_metrics_tDCS);
else
    nbr_points_tDCS         = 0;
end
if nbr_post_trials > 0
    nbr_points_post         = numel(sta_metrics_post);
else
    nbr_points_post         = 0;
end

nbr_MPSF_points             = nbr_points_bsln + nbr_points_tDCS + nbr_points_post;


% Fill the MPSF array
MPSF_array                  = zeros(nbr_MPSF_points,nbr_muscles);
if nbr_points_bsln > 0
    for i = 1:numel(pos_muscles)
        MPSF_array(1:nbr_points_bsln,i)     = arrayfun( @(x) x.emg.MPSF(pos_muscles(i)), sta_metrics_bsln )';
    end
end

if nbr_points_tDCS > 0
     for i = 1:numel(pos_muscles)
        MPSF_array(nbr_points_bsln+1:nbr_points_bsln+nbr_points_tDCS,i)     = arrayfun( @(x) ...
                                            x.emg.MPSF(pos_muscles(i)), sta_metrics_tDCS )';
     end
end

if nbr_points_post > 0
    for i = 1:numel(pos_muscles)
        MPSF_array(nbr_points_bsln+nbr_points_tDCS+1:end,i)                 = arrayfun( @(x) ...
                                            x.emg.MPSF(pos_muscles(i)), sta_metrics_post )';
    end
end

% Normalize the MPSF to the mean during the baseline, and compute SD
if nbr_points_bsln > 0

    mean_MPSF_bsln          = mean(MPSF_array(1:nbr_points_bsln,:),1);
    std_MPSF_bsln           = std(MPSF_array(1:nbr_points_bsln,:),1);

    norm_MPSF_array         = MPSF_array / mean_MPSF_bsln;
    norm_std_MPSF_bsln      = std_MPSF_bsln / mean_MPSF_bsln;
end


% -> To Plot the MPSF

% Retrieve monkey, electrode and date information for figure title
if nbr_points_bsln > 0
    if iscell(tDCS_exp.baseline_files)
        file_name_4_metadata    = tDCS_exp.baseline_files{1};
    else
        file_name_4_metadata    = tDCS_exp.baseline_files;
    end
    muscle_labels               = sta_metrics_bsln(1).emg.labels(pos_muscles);
elseif nbr_points_tDCS > 0
    if iscell(tDCS_exp.tDCS_files)
        file_name_4_metadata    = tDCS_exp.tDCS_files{1};
        muscle_labels           = sta_metrics_tDCS(1).emg.labels(pos_muscles);
    else
        file_name_4_metadata    = tDCS_exp.tDCS_files;
        muscle_labels           = sta_metrics_post(1).emg.labels(pos_muscles);
    end
end

last_pos_title              = find( file_name_4_metadata =='_', 4 );
fig_title                   = file_name_4_metadata(1:last_pos_title(end)-1);
clear last_pos_title;


% Here come the plots !!!
% Plot the MPSF 
if nbr_points_bsln == 0
    fig_MPSF_analyze_tDCS_exp( MPSF_array, nbr_muscles, muscle_labels, tDCS_exp.resp_per_win, ...
                                nbr_points_bsln, nbr_points_tDCS, nbr_points_post, ...
                                fig_title );
else
    fig_MPSF_analyze_tDCS_exp( MPSF_array, nbr_muscles, muscle_labels, tDCS_exp.resp_per_win, ...
                                nbr_points_bsln, nbr_points_tDCS, nbr_points_post, ...
                                fig_title, mean_MPSF_bsln, std_MPSF_bsln );
end

% Plot the normalized MPSF
if nbr_points_bsln > 0
    fig_MPSF_analyze_tDCS_exp( norm_MPSF_array, nbr_muscles, muscle_labels, tDCS_exp.resp_per_win, ...
                                nbr_points_bsln, nbr_points_tDCS, nbr_points_post, ...
                                fig_title, ones(1,nbr_MPSF_points), norm_std_MPSF_bsln );
end


% -------------------------------------------------------------------------
% 2. Plot the Evoked responses

% create the time axis for the plot
if nbr_points_bsln > 0
    t_axis_evoked_resp      = -sta_metrics_bsln(1).emg.t_before : 1/sta_metrics_bsln(1).emg.fs*1000 ...
                                : sta_metrics_bsln(1).emg.t_after;
elseif nbr_points_tDCS > 0
    t_axis_evoked_resp      = -sta_metrics_tDCS(1).emg.t_before : 1/sta_metrics_tDCS(1).emg.fs*1000 ...
                                : sta_metrics_tDCS(1).emg.t_after;
else
    t_axis_evoked_resp      = -sta_metrics_post(1).emg.t_before : 1/sta_metrics_post(1).emg.fs*1000 ...
                                : sta_metrics_post(1).emg.t_after;
end

% this trick makes the code handle cases in which one or two of the
% sta_metrics is not present
[smb, smt, smp]             = deal([]);
if nbr_points_bsln > 0
    smb                     = sta_metrics_bsln;
end
if nbr_points_tDCS > 0
    smt                     = sta_metrics_tDCS;
end
if nbr_points_post > 0
    smp                     = sta_metrics_post;
end

% plot the 'raw' and detrended evoked EMG responses
fig_resp_analyze_tDCS_exp( smb, smt, smp, t_axis_evoked_resp, pos_muscles,  ...
                            tDCS_exp.resp_per_win, fig_title );


% -------------------------------------------------------------------------
% Return variables

if nbr_points_bsln > 0
    tDCS_results.baseline   = sta_metrics_bsln;
end
if nbr_points_tDCS > 0
    tDCS_results.tDCS       = sta_metrics_tDCS;
end
if nbr_points_post > 0
    tDCS_results.post       = sta_metrics_post;
end

% Add some meta information to the results
tDCS_results.meta.monkey    = fig_title(1:find(fig_title=='_',1)-1);
tDCS_results.meta.date      = [fig_title(end-7:end-4) '_' fig_title(end-3:end-2) '_' fig_title(end-1:end)];


end
