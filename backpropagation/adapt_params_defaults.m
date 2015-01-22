function adapt_params = adapt_params_defaults(varargin)
%   'LR'            : Learning Rate
%   'batch_length'  : Adapt to last n trials
%   'adapt_time'    : duration of adaptation period in seconds (default: Inf)
%   'fixed_time'    : duration of fixed periods in seconds. (def:0)
%   'adaptation_progress':display adaptation progress (Default: false)
%   'cursor_assist' : moves the cursor
%   'delay'         : time between target onset and beginning of adaptation
%   'duration'      : time window during which to adapt after delay

adapt_params_defaults = struct(...   
    'LR'            ,1e-9,...
    'batch_length'  ,1,...
    'delay'         ,0.1,...
    'duration'      ,1.0,...
    'adapt_time'    ,20*60,...
    'fixed_time'    ,0*60,...
    'adapt_freeze'  ,false,...
    'emg_patterns'  ,emg_pattern_default...
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