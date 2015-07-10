function params = bc_params(monkey,varargin)


if nargin > 1
    params = varargin{1};
end

% fixed:
params.adapt         = false;
params.cursor_assist = false;
params.output        = 'xpc';
params.save_data     = true;
params.online        = true;

if strncmpi(monkey,'jango',3)
    params.save_name = 'Jango_';
    params.save_dir  = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\';
elseif strncmpi(monkey,'kevin',3)
    params.save_name = 'Kevin_';
    params.save_dir  = 'E:\Data-lab1\12A2-Kevin\Adaptation\';
else
    warning('unknown monkey name, save_dir not set!');
end

%  params.neuron_decoder = 'Z:\Jango_12a1\SavedFilters\Adaptation\20150217\Jango_2015217_WFHC_002&003_N2F_Decoder.mat';

