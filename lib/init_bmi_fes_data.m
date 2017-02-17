function [data,offline_data,params] = init_bmi_fes_data(params)

if ~strcmp(params.mode,'direct')
    spike_buf_size = params.n_lag + params.n_lag_emg - 1;
else
    spike_buf_size = params.n_lag;
end

if ~params.online
    if ~isstruct(params.offline_data)
        offline_data = LoadDataStruct(params.offline_data);
    else
        offline_data = params.offline_data;
    end
    params.n_neurons = size(offline_data.neuronIDs,1);
    params.neuronIDs = offline_data.neuronIDs;
    params.binsize   = offline_data.timeframe(2)-offline_data.timeframe(1);
    params.ave_fr    = mean(mean(offline_data.spikeratedata));
else
    offline_data = []; 
end

% old implementation of catch trial, changed -KLB
% % create an array with 1 and 0 symbolizing the fes and catch trials, in
% % blocks of 100
% catch_trials        = randi(50,round(params.bmi_fes_stim_params.perc_catch_trials/2),1)';
% catch_trials        = sort(catch_trials);

data = struct(  'spikes'      , zeros(spike_buf_size,params.n_neurons),...
                'analog'      , [],...
                'ave_fr'      , 0.0,...
                'words'       , [],...
                'db_buf'      , [],...
                'emgs'        , zeros( params.n_lag_emg, params.n_emgs),...
                'curs_pred'   , [NaN NaN],...
                'curs_act'    , [NaN NaN],...
                'stim_PW'     , zeros(1,params.n_emgs),...
                'stim_amp'    , zeros(1,params.n_emgs),...
                'fes_or_catch', 1, ... % flag for doing or not doing FES
                % old catch trial implementation method. changed.
%                 'catch_trial_indx', catch_trials, ...     % trial numbers that will be catch
%                 'trial_ctr'   , 0, ... % for the catch vs FES trials
                'tgt_on'      , false,...
                'tgt_bin'     , NaN,...
                'tgt_ts'      , NaN,...
                'tgt_id'      , NaN,...
                'tgt_pos'     , [NaN NaN],...
                'tgt_size'    , [NaN NaN],...
                'pending_tgt_pos' ,[NaN NaN],...
                'pending_tgt_size',[NaN NaN],...
                'sys_time'    , 0.0,...
                'traj_pct'    , 0,...
                'artifact_found', 0,...
                'trial_count', 0);
            
% data = struct(  'spikes'      , zeros(spike_buf_size,params.n_neurons),...
%                 'analog'      , [],...
%                 'ave_fr'      , 0.0,...
%                 'words'       , [],...
%                 'db_buf'      , [],...
%                 'emgs'        , zeros( params.n_lag_emg, params.n_emgs),...
%                 'curs_pred'   , [NaN NaN],...
%                 'curs_act'    , [NaN NaN],...
%                 'stim_PW'     , zeros(1,params.n_emgs),...
%                 'stim_amp'    , zeros(1,params.n_emgs),...
%                 'adapt_trial' , false,...
%                 'adapt_bin'   , false,...
%                 'adapt_flag'  , false,...
%                 'tgt_on'      , false,...
%                 'tgt_bin'     , NaN,...
%                 'tgt_ts'      , NaN,...
%                 'tgt_id'      , NaN,...
%                 'tgt_pos'     , [NaN NaN],...
%                 'tgt_size'    , [NaN NaN],...
%                 'pending_tgt_pos' ,[NaN NaN],...
%                 'pending_tgt_size',[NaN NaN],...
%                 'sys_time'    , 0.0,...
%                 'fix_decoder' , false,...
%                 'effort_flag' , false,...
%                 'traj_pct'    , 0,...
%                 'emg_binned'  , zeros( 10, 4),...
%                 'artifact_found', 0,...
%                 'trial_count', 0);

if params.online
    cbmex('open',1);
    data.labels = cbmex('chanlabel',1:156);
    cbmex('close')
else
    
    
end
