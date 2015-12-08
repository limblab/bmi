%  
% Default parameters for pw_to_force
%
%   pw_to_f_params = PW_TO_FORCE_PARAMS_DEFAULTS(): returns structure with
%       default paramters
%   pw_to_f_params = PW_TO_FORCE_PARAMS_DEFAULTS( pw_to_f_params ): returns
%       structure with the specified parameters values, and the defaults in
%       the missing ones
%
%
%   pw_to_force_params_defaults has fields:
%       't_before'  : time before the stimulus, for STA (ms)
%       't_after'   : time after the stimulus, for STA (ms)
%       'rectify'   : rectify force or not (bool)
%       'detrend'   : detrend force or not (bool)
%
%

function pw_to_f_params = pw_to_force_params_defaults( varargin )

pw_to_f_params_def = struct( ...
    't_before',             20, ...
    't_after',              30, ...
    'rectify',              true, ...
    'detrend',              true ...
    );

% -------------------------------------------------------------------------
% Fill missing params if some of them have been passed
if nargin
    pw_to_f_params          = varargin{1};
    input_params_names      = fieldnames(pw_to_f_params);
else
    pw_to_f_params          = [];
    input_params_names      = [];
end

% Check that all the params that have been passed are named right
all_params_names        = fieldnames(pw_to_f_params_def);

for i = 1:numel(input_params_names)
   if ~any( strcmp(input_params_names{i},all_params_names ))
       errordlg(sprintf('Invalid parameter\n"%s"',input_params_names{i}));
       return;
   end
end

% Write defaults values to the missing fields (or to all of them, if no
% argument has been passed)  
for i = 1:numel(all_params_names)
    if ~isfield(pw_to_f_params, all_params_names(i))
        pw_to_f_params.(all_params_names{i}) = pw_to_f_params_def.(all_params_names{i});
    end
end