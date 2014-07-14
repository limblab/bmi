function bmi_params = bmi_params_defaults(varargin)
%   'mode'          : either 'direct' or 'emg_cascade'
%   'output'        : either 'stimulator' or 'xpc' or 'none'
%   'adapt'         : enable adaptation (emg_cascade mode only for now)
%   'LR'            : Learning Rate
%   'N2E_dec'       : Initial Neuron-to-EMG decoder: 'new_zeros',
%                     'new_rand', or string with decoder file name.
%   'n_lag'         : Number of lags to use (Default: 10)
%   'n_neurons'     : Number of neurons
%   'neuronIDs'     : Array of n_neurons x 2, containing [ch_id, unit_id];
%   'display_plots' : Plot adaptation procedure (Default: true)
%   'n_adapt_to_last':Adapt to last n sets of targets (look back for the
%                     last n instances in which the target appear and run
%                     gradient descent on them)
%   'simulate'      : Simulate four neurons each tuned to different halfs
%                     of the screen (vertical and horizontal)
%   'online'        : chose between Cerebus stream or BinnedData file
%   'realtime'      : # of times x real time (only for offline files)
%   'adaptation_time':duration of adaptation periods in seconds (default: Inf)
%   'fixed_time'    : duration of fixed periods in seconds. (def:0)
%   'adaptation_progress':display adaptation progress (Default: false)
%   'cursor_assist' : moves the cursor to a target and back, based on average firing rate and 'cursor_traj'
%   'cursor_traj'   : file path and name to a structure containing the fields 'mean_paths' and 'back_paths'
%   'delay'         : time between target onset and beginning of adaptation
%   'duration'      : time window during which to adapt after delay
%   'db_size'       : expected size of databurst
%   'save_dir'      : path in which to save updated decoder
%   'offline_data'  : binnedData file to be replayed (when 'online'=false)

N2E = 'new_zeros';
E2F.H = zeros(61,2);

bmi_params_defaults = struct( ...
    'mode'          ,'emg_cascade',...
    'adapt'         ,false,...
    'cursor_assist' ,false,...
    'neuron_decoder',N2E,...
    'emg_decoder'   ,E2F,...
    'output'        ,'xpc',...
    'online'        ,true,...
    'realtime'      ,false,...
    'offline_data'  ,'\\citadel\data\Jango_12a1\BinnedData\EMGCascade\2014-01-03_decoder_training\Jango_2014-01-03_WF_001.mat',...
    'cursor_traj'   ,'\\citadel\data\Jango_12a1\Mean_Paths\mean_paths_HC_Jango_WF_2014-01-03_R10.mat',...
    ...
    'n_neurons'     ,96,...
    'neuronIDs'     ,[(1:96)' zeros(96,1)],...
    'n_lag'         ,10,...
    'n_emgs'        ,6,...
    'n_lag_emg'     ,10,...
    'n_forces'      ,2,...
    'binsize'       ,0.05,... 
    'db_size'       ,34,...
    'ave_fr'        ,0,...
    ...
    'lambda'        ,0.0015,...
    'LR'            ,1e-9,...
    'batch_length'  ,1,...
    'delay'         ,0.1,...
    'duration'      ,1.0,...
    'adapt_time'    ,20*60,...
    'fixed_time'    ,0*60,...
    'adapt_freeze'  ,false,...
    'simulate'      ,false,...
    ...
    'display_plots' ,true,...
    'show_progress' ,false,...
    'save_data'     ,true,...
    'save_dir'      ,'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation',...
    'save_name'     ,'Jango_WF_Adapt'...
);


% fill default options missing from input argument
if nargin
    bmi_params = varargin{1};
else
    bmi_params = [];
end

all_param_names = fieldnames(bmi_params_defaults);
for i=1:numel(all_param_names)
    if ~isfield(bmi_params,all_param_names(i))
        bmi_params.(all_param_names{i}) = bmi_params_defaults.(all_param_names{i});
    end
end
