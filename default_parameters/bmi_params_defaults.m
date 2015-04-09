function bmi_params = bmi_params_defaults(varargin)
%   'mode'          : either 'direct' or 'emg_cascade'
%   'adapt'         : enable adaptation (emg_cascade mode only for now)
%   'cursor_assist' : moves the cursor to a target and back according to 'cursor_traj'
%   'cursor_traj'   : file path and name to a structure containing the fields 'mean_paths' and 'back_paths'
%   'decoders'      : structure containing decoder structure to store with fields 'decoder_file' and decoder_typeInitial Neuron-to-EMG decoder: 'new_zeros',
%                     'new_rand', or string with decoder file name.
%   'emg_decoder'   : file name or structure containing emg-to-force model
%   'sigmoid'       : flag to decide whether or not to apply a sigmoid to emg preds
%   'emg_convolve'  : [1*n_bins] vector filter to apply to EMG decoder to include force dynamics
%   'output'        : either 'stimulator' or 'xpc' or 'none'
%   'online'        : chose between Cerebus stream or BinnedData file
%   'realtime'      : # of times x real time (only for offline files)
%   'offline_data'  : binnedData file to be replayed (when 'online'=false)
%   'hp_rc'         : high-pass filter time constant in seconds (0 = no filtering of preds)
%   'stim_params'   : structure containing emg-to-stim parameters and electrode to muscle mapping
%   'pred_bounds'   : upper_bound for predictions
%
%   'n_neurons'     : Number of neurons
%   'neuronIDs'     : Array of n_neurons x 2, containing [ch_id, unit_id];
%   'n_lag'         : Number of lags to use (Default: 10)%
%   'n_emgs'        : Number of muscles in E2F model
%   'n_lag_emg'     : Number of lags for E2F model
%   'n_forces'      : Number of force signals to predict (unused?)
%   'binsize'       : Cycle time for decoder. Has to match binsize in decoders
%   'db_size'       : expected size of databurst
%   'ave_fr'        : scalar representing global average firing rate
%
%   'display_plots' : Plot adaptation procedure (Default: true)
%   'print_out'     : if true, gives warnings when processing a cycle takes longer than binsize
%   'save_data'     : whether or not to save predictions and other data streamed from cerebus
%   'save_dir'      : directory for saving data
%   'save_name'     : prefix for saving files names
%    
%   'force_offset'  :
%   'stop_trial'    :
%   'stop_task_if_x_artifacts' : 
%   'stop_task_if_x_force' :
%   'offset_time_constant' :

N2E = 'Jango_20141203_default_N2F_decoder.mat';
E2F = E2F_deRugy_PD(15);

bmi_params_defaults = struct( ...
    'decoders'      ,default_bmi_decoders,...
    'mode'          ,'direct',...
    'adapt'         ,false,...
    'cursor_assist' ,false,...
    'cursor_traj'   ,curs_traj_default,...
    'neuron_decoder',N2E,...
    'emg_decoder'   ,E2F,...
    'sigmoid'       ,false,...
    'emg_convolve'  ,[],...
    'output'        ,'xpc',...
    'online'        ,true,...
    'realtime'      ,true,...
    'offline_data'  ,'Jango_20141203_default_offline_data.mat',...
    'hp_rc'         ,0,...
    'stim_params'   ,stim_params_defaults,...
    'pred_bounds'   ,[inf inf],...
    ...
    'n_neurons'     ,96,...
    'neuronIDs'     ,[(1:96)' zeros(96,1)],...
    'n_lag'         ,10,...
    'n_emgs'        ,5,...
    'n_lag_emg'     ,1,...
    'n_forces'      ,2,...
    'binsize'       ,0.05,... 
    'db_size'       ,34,...
    'ave_fr'        ,0,...
    ...
    'adapt_params'  ,adapt_params_defaults,...
    ...
    'display_plots' ,true,...
    'print_out'     ,true,...
    'save_data'     ,true,...
    'save_dir'      ,cd,...
    'save_name'     ,'BMI_test',...
    ...
    'force_offset'  ,[0 0],...
    'stop_trial'    ,0, ...
    'stop_task_if_x_artifacts', 10, ...
    'stop_task_if_x_force',     0.02, ...
    'offset_time_constant',     10000000000000000000 ...
);


% fill default options missing from input argument
if nargin
    bmi_params = varargin{1};
    if isfield(bmi_params,'adapt_params')
        % fill up the adapt_params substructure if present.
        bmi_params.adapt_params = adapt_params_defaults(bmi_params.adapt_params);
    end
else
    bmi_params = [];
end

all_param_names = fieldnames(bmi_params_defaults);
for i=1:numel(all_param_names)
    if ~isfield(bmi_params,all_param_names(i))
        bmi_params.(all_param_names{i}) = bmi_params_defaults.(all_param_names{i});
    end
end
