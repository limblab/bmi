function adapt_params = adapt_params_defaults(varargin)
%   'mode'          : either 'direct' or 'emg_cascade' or 'adapt'
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
%   'cursor_assist' : moves the cursor
%   'delay'         : time between target onset and beginning of adaptation
%   'duration'      : time window during which to adapt after delay
%   'save_dir'      : path in which to save updated decoder
%   'db_size'       : expected size of databurst

dec_path = 'Z:\Jango_12a1\SavedFilters\';

N2F = [dec_path 'Jango_2014-01-03_WF_001_N2F950_Decoder.mat'];
N2E = [dec_path 'Jango_2014-01-03_WF_001_N2E500_Decoder.mat'];
E2F = [dec_path 'Jango_2014-01-03_WF_001_E2F500_Decoder.mat'];
% Ehat2F= [dec_path 'Jango_2013-12-11_WF_002_Ehat2F_Decoder.mat'];

adapt_params_defaults = struct( ...
    'mode'          ,'direct',...
    'online'        ,true,...    
    'LR'            ,1e-9,...
    ...
    'neuron_decoder',N2F,...
    'emg_decoder'   ,E2F,...
    ...
    'n_neurons'     ,96,...    
    'n_lag'         ,19,...
    'n_emgs'        ,6,...
    'n_lag_emg'     ,10,...
    ...
    'n_forces'      ,2,...
    'display_plots' ,true,...
    'batch_length'  ,8,...
    'simulate'      ,false,...
    'realtime'      ,1,...
    'adapt_time'    ,10*60,...
    'fixed_time'    ,2*60,...
    'show_progress' ,false,...
    'cursor_assist' ,true,...
    'delay'         ,0.1,...
    'duration'      ,0.3,...
    'binsize'       ,0.05,... 
    'db_size'       ,34,...
    'save_dir'      ,['E:\Data-lab1\AdaptationFiles\' date],...
    'offlineData'   ,'Z:\Jango_12a1\BinnedData\EMGCascade\2013-12-11_decoder_training\Jango_2013-12-11_WF_002.mat'...
);




% fill default options missing from input argument
if nargin
    adapt_params = varargin{1};
else
    adapt_params = [];
end

all_param_names = fieldnames(adapt_params_defaults);
for i=1:numel(all_param_names)
    if ~isfield(adapt_params,all_param_names(i))
        adapt_params.(all_param_names{i}) = adapt_params_defaults.(all_param_names{i});
    end
end

% 'neuron_decoder','E:\Data-lab1\AdaptationFiles\06-Dec-2013\Adapt_decoder_06-Dec-2013-123834_End.mat',...
% N2E_dec       = 'new_rand';
% N2E_dec       = 'new_zeros';
% N2E_dec       = [savedir '/previous_trials_05-Nov-2013 17:32:39.mat'];
% 'N2E_dec'       ,'E:\Data-lab1\AdaptationFiles\05-Dec-2013\Adapt_decoder_05-Dec-2013-191950_End.mat',...
% load EMG-to-force decoder
% EMG2F_w = randn(n_emg, n_force); % fake EMG-to-force decoder
% EMG2F_w = randn(1+ n_emg*n_lag, n_force); % fake EMG-to-force decoder, including lag
% EMG2F_w = load('/home/limblab/Desktop/SpikeDataLocal/SavedFilters/EMG2F/Spike_2013-09-23_500ms10binsEMG2F.mat');
% EMG2F_w = EMG2F_w.H;
% EMG2F_w2 = [];
% for lag = 1:10
%     EMG2F_w2 = [EMG2F_w2;
%         EMG2F_w(t:10:end, :)];
% end
% EMG2F_w = EMG2F_w2;
% H        = [ 0     0
%               1     0;
%             0.7   0.7;
%            -1     0;
%            -0.7   0.7;
%            -0.7  -0.7;
%             0.7  -0.7;
%             0     1;
%             0    -1];
%     'EMG2F_w'       ,[1     0;
%             0.7   0.7;
%            -1     0;
%            -0.7   0.7;
%            -0.7  -0.7;
%             0.7  -0.7;
%             0     1;
%             0    -1]