function params = offline_bc_params(varargin)
% varargin = {params}
if nargin params=varargin{1}; end

% fixed:
params.adapt         = false;
params.cursor_assist = false;
params.output        = 'none';
params.save_data     = false;
params.online        = false;
params.real_time     = true;

params.save_name      = 'Test_offline_BC_';
params.save_dir       = cd;
params.mode           = 'emg_cascade';

params.emg_convolve  = [0.5 0.75 1 0.75 0.5];
params.emg_convolve  = params.emg_convolve./sum(params.emg_convolve);
