function bmi_params = bmi_params_defaults(varargin)
%   'mode'          : either 'direct' or 'emg_cascade'
%   'output'        : either 'stimulator' or 'xpc' or 'none'
%   'adapt'         : enable adaptation (emg_cascade mode only for now)
%   'LR'            : Learning Rate
%   'N2E_dec'       : Initial Neuron-to-EMG decoder: 'new_zeros',
%                     'new_rand', or string with decoder file name.
%   'n_lag'         : Number of lags to use (Default: 10)
%   'n_neurons'     : Number of neurons
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

% online decoders 03/04
% N2E = 'new_zeros';
% N2E = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\2014_02_26\Adapted_decoder_2014_02_26_175948_End.mat';
% N2E = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\2014_02_26\Adapted_decoder_2014_02_26_183740_End.mat';
% N2E = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\2014_02_27\Adapted_decoder_2014_02_27_144436_End.mat';
% N2E = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\2014_02_27\Adapted_decoder_2014_02_27_152235_End.mat';
% E2F = [dec_path 'Jango_2014-01-03_WF_001_E2F500_Decoder.mat'];
% E2F = [dec_path 'Jango_WF_2014-03-17_001_E2F_Decoder.mat'];
% E2F.H = zeros(61,2);

bmi_params_defaults = struct( ...
    'mode'          ,'emg',...
    'adapt'         ,false,...
    'cursor_assist' ,false,...
    'neuron_decoder','',...
    'emg_decoder'   ,'',...
    'output'        ,'xpc',...
    'online'        ,true,...
    'realtime'      ,0,...
    'offline_data'  ,'',...
    'cursor_traj'   ,'',...
    ...
    'n_neurons'     ,96,...    
    'n_lag'         ,10,...
    'n_emgs'        ,6,...
    'n_lag_emg'     ,10,...
    'n_forces'      ,2,...
    'binsize'       ,0.05,... 
    'db_size'       ,34,...
    'ave_fr'        ,10,...
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
    'save_dir'      ,'',...
    'save_name'     ,'',...
    'force_offset'  ,[0 0],...
    'stop_trial'    ,0, ...
    'stop_task_if_x_artifacts', 10, ...
    'stop_task_if_x_force',     0 ...
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
