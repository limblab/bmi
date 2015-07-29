function adapt_params = adapt_params_defaults(varargin)
%   'type'          : either 'normal', 'tvp', 'N2F' or 'supervised'
%   'LR'            : Learning Rate
%   'batch_length'  : Adapt to last n trials
%   'lambda'        : Factor for the L2 regularization (0 = none)
%   'delay'         : time between target onset and beginning of adaptation
%   'duration'      : time window during which to adapt after delay
%   'adapt_time'    : duration of adaptation period in seconds (default: Inf)
%   'fixed_time'    : duration of fixed periods in seconds. (def:0)
%   'adapt_freeze'  : flag indicating whether the decoders are fixed after 'adapt_time' has elapsed
%   'emg_patterns'  : 9x numemgs array of expected EMG values for each targets
try
    adapt_params_defaults = struct(...
        'type'          ,'normal',...
        'LR'            ,5e-7,...
        'batch_length'  ,1,...
        'lambda'        ,0,...
        'delay'         ,0.6,...
        'duration'      ,inf,...
        'adapt_time'    ,inf,...
        'fixed_time'    ,0*60,...
        'adapt_freeze'  ,false,...
        'emg_patterns'  ,get_optim_emg_patterns(E2F_deRugy_PD(15),[0 1])...
    );
catch
    adapt_params_defaults.Chris_you_broke_my_code_I_ll_miss_you_Ricky = [];
    adapt_params_defaults.batch_length = 0;
end

%     'emg_patterns'  ,time_varying_emg_pattern_default...

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