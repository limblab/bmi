function data = get_default_data

data = struct('spikes'      , zeros(10,params.n_neurons),...
              'analog'      , [],...
              'ave_fr'      , 0.0,...
              'words'       , [],...
              'db_buf'      , [],...
              'emgs'        , zeros( params.n_lag_emg, params.n_emgs),...
              'adapt_trial' , false,...
              'adapt_bin'   , false,...
              'tgt_on'      , false,...
              'tgt_bin'     , NaN,...
              'tgt_ts'      , NaN,...
              'tgt_id'      , NaN,...
              'tgt_pos'     , [NaN NaN],...
              'tgt_size'    , [NaN NaN],...
              'pending_tgt_pos' ,[NaN NaN],...
              'pending_tgt_size',[NaN NaN],...
              'sys_time'    , 0.0,...
              'fix_decoder' , false,...
              'effort_flag' , false,...
              'traj_pct'    , 0 );