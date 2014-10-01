function stim_params = stim_params_defaults(varargin)
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

stim_params_defaults = struct( ...   
    'EMG_min', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],...
    'EMG_max',[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], ...
    'freq', 30,...
    'mode',1,...
    'PW_max',[0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2],...
    'current_min',[0,0,0,0,0,0,0,0,0,0,0,0],...
    'current_max', [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2],...
    'duration_command',[6,6,6,6,6,6,6,6,6,6,6,6],...
    'anode_map', {{1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23; 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1;}},...
    'cathode_map',  {{2 4 6 8 10 12 14 16 18 20 22 24; 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1;}}...
 );

% fill default options missing from input argument
if nargin
    stim_params = varargin{1};
else
    stim_params = [];
end

all_param_names = fieldnames(stim_params_defaults);
for i=1:numel(all_param_names)
    if ~isfield(bmi_params,all_param_names(i))
        stim_params.(all_param_names{i}) = stim_params_defaults.(all_param_names{i});
    end
end
