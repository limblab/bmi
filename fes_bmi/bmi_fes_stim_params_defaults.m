function bmi_fes_stim_params = bmi_fes_stim_params_defaults(varargin)
%
% function bmi_fes_stim_params = bmi_fes_stim_params_defaults(varargin)
%
%   'EMG_min'       : minimum value of the EMG predictions
%   'EMG_max'       : maxumum value of the EMG predictions
%   'freq'          : stimulation frequency (Hz)
%   'mode'          : stim. mode; 'PW_modulation' or 'amplitude_modulation'
%   'PW_max'        : maximum PW, in 'PW_modulation' mode
%   'PW_min'        : minimum PW, in 'PW_modulation' mode
%   'amplitude_min' : minimum amplitude, in 'amplitude_modulation' mode
%   'amplitude_max' : maximum amplitude, in 'amplitude_modulation' mode
%   'duration_command'  : ?????
%   'anode_map'     : electrodes that function as anodes for each muscle
%   'cathode_map'   : electrodes that function as cathodes for each muscle.
%                       If blank, the stimulation is monopolar
%


bmi_fes_stim_params_defaults = struct( ...   
    'EMG_min',      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], ...
    'EMG_max',      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], ...
    'freq',         30, ...
    'mode',         'PW_modulation', ...
    'PW_max',       [0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2],...
    'PW_min',       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],...
    'amplitude_min',[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],...
    'amplitude_max',[2, 0, 1, 4, 4, 0, 0, 2, 2, 1, 1, 0],...
    'duration_command', [6,6,6,6,6,6,6,6,6,6,6,6],...
    'anode_map',    {[{ [1 2 3], [4 5 6], [7 8 9], [10 11 12], [13 14 15], [16 17 18], [19 20 21], [22 23 24], [25 26 27], [28 29 30], [], [] }; ...
                        {[], [], [], [], [], [], [], [], [], [], [], [] }]},...
    'cathode_map',  {{ }}...
);


% fill default options missing from input argument
if nargin
    bmi_fes_stim_params = varargin{1};
else
    bmi_fes_stim_params = [];
end

all_param_names = fieldnames(stim_params_defaults);
for i=1:numel(all_param_names)
    if ~isfield(bmi_fes_stim_params,all_param_names(i))
        bmi_fes_stim_params.(all_param_names{i}) = bmi_fes_stim_params_defaults.(all_param_names{i});
    end
end
