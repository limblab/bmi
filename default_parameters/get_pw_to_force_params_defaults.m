%  
% Default parameters for get_pw_to_force
%
%   get_pw_to_f_params = GET_PW_TO_FORCE_PARAMS_DEFAULTS(): returns
%       structure with default paramters  
%   get_pw_to_f_params = GET_PW_TO_FORCE_PARAMS_DEFAULTS( pw_to_f_params ):
%       returns structure with the specified parameters values, and the
%       defaults in the missing ones 
%
%
%   get_pw_to_force_params_defaults has fields:
%       'elec'      : electrode or electrodes
%       'amp'       : amplitude of each phase (mA). Total for all elecs
%       'freq'      : stim frequency (Hz)
%       'pw_rng'    : min and max PW (s)
%       'pw_steps'  : nbr. of steps in which pw_rng will be divided
%       'nbr_reps'  : nbr. of stimuli at each PW
%       'stim_dur'  : duration of each stimulus (ms). 
%       'pol'       : polarity; 1 = cathodic first
%       'min_time_btw_trains' : wait time after each train (ms)
%       'ctrl_mode' : 'keyboard': stimulation will be delivered
%                                   when a key is pressed
%                               : 'word': stimulation will be delivered 
%                                   every time a specific word occurs 
%       'word'      : the word to be used in control_mode = word
%       'stimulator': 'gv' (Grapevine), or 'ws' (wireless)
%       'stim_res'  : stimulator resolution. For Grapevine only
%       'sync_ch'   : stimulator channel used for sync with Central
%       'data_dir'  : where the Matlab and Cerebus data will be stored
%       'monkey'    : name. For naming the files
%       'task'      : task the monkey is performing. For naming the files
%       'muscle'    : name of the stimulated muscle. For naming the files
%
%   NOTE: STIM_DUR currently limited to < 1000 s !!!

function get_pw_to_f_params = get_pw_to_force_params_defaults( varargin )

get_pw_to_f_params_defaults = struct( ...
    'elec',             [3 5 7], ...
    'amp',              2, ...
    'freq',             30, ...
    'pw_rng',           [0.05 0.3], ...
    'pw_steps',         6, ...
    'nbr_reps',         3, ...
    'stim_dur',         1000, ...
    'pol',              1, ...
    'min_time_btw_trains', 2000, ...
    'ctrl_mode',        'keyboard', ...
    'word',             32, ...
    'stimulator',       'gv', ...
    'stim_res',         0.018, ...
    'sync_ch',          32, ...
    'data_dir',         'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES', ...
    'monkey',           'Jango', ...
    'task',             'WF',...
    'muscle',           'ECR'...
    );


% -------------------------------------------------------------------------
% Fill missing params if some of them have been passed
if nargin
    get_pw_to_f_params  = varargin{1};
    input_params_names  = fieldnames(get_pw_to_f_params);
else
    get_pw_to_f_params  = [];
    input_params_names  = [];
end
    
% Check that all the params that have been passed are named right
all_params_names        = fieldnames(get_pw_to_f_params_defaults);

for i = 1:numel(input_params_names)
   if any( strcmp(input_params_names{i},all_params_names ))
       errordlg(sprintf('Invalid parameter\n"%s"',input_params_names{i}));
       return;
   end
end

% Write defaults values in the missing fields (all of them, if no argument
% has been passed) 
for i = 1:numel(all_params_names)
    if ~isfield(get_pw_to_f_params, all_params_names(i))
        get_pw_to_f_params.(all_params_names{i}) = get_pw_to_f_params_defaults.(all_params_names{i});
    end
end