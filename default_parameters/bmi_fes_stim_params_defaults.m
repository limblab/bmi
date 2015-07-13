function bmi_fes_stim_params = bmi_fes_stim_params_defaults(varargin)
%
% function bmi_fes_stim_params = bmi_fes_stim_params_defaults(varargin)
%
%   'muscles'       : muscle electrodes in the monkey
%   'EMG_to_stim_map'   : map between predicted EMGs (1st row )and
%                           stimulated muscles (2nd row)
%   'EMG_min'       : minimum value of the EMG predictions
%   'EMG_max'       : maxumum value of the EMG predictions
%   'freq'          : stimulation frequency (Hz)
%   'mode'          : stim. mode; 'PW_modulation' or 'amplitude_modulation'
%   'PW_max'        : maximum PW, in 'PW_modulation' mode
%   'PW_min'        : minimum PW, in 'PW_modulation' mode
%   'amplitude_min' : minimum amplitude, in 'amplitude_modulation' mode
%   'amplitude_max' : maximum amplitude, in 'amplitude_modulation' mode.
%                       This current amplitude is used in the
%                       'PW_modulation' mode to set the amplitude.
%   'anode_map'     : electrodes that function as anodes for each muscle
%                       (first row), and how the current will be distributed
%                       among them (the sum for each muscle should = 1;
%                       second row). 
%   'cathode_map'   : electrodes that function as cathodes for each muscle.
%                       (first row), and how the current will be distributed
%                       among them (the sum for each muscle should = 1;
%                       second row). If blank, the stimulation is monopolar
%   'stim_resolut'  : resolution of the stimulator (mA)
%   'inter_ph_int'  : inter-phase interval (us)
%


bmi_fes_stim_params_defaults = struct( ...
    'muscles',      {({'EDC', 'EDC2', 'ADL', 'ECU', 'FDP', 'ECR', 'Brad', 'PT', 'FCU', 'FDS', 'FCR', 'FDS2'})}, ...
    'EMG_to_stim_map',  {[{'EDC', 'EDC2', 'ADL', 'ECU', 'FDP', 'ECR', 'Brad', 'PT', 'FCU', 'FDS', 'FCR', 'FDS2'}; ...
                        {'EDC', 'EDC2', 'ADL', 'ECU', 'FDP', 'ECR', 'Brad', 'PT', 'FCU', 'FDS', 'FCR', 'FDS2'}]}, ...
    'EMG_min',      repmat(0.15,1,12), ...
    'EMG_max',      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], ...
    'freq',         30, ...
    'mode',         'PW_modulation', ...
    'PW_max',       [0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4],...
    'PW_min',       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],...
    'amplitude_min',[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],...
    'amplitude_max',[2, 0, 1, 4, 4, 0, 0, 2, 2, 1, 1, 0],...
    'anode_map',    {[{ [1 2 3], [4 5 6], [7 8 9], [10 11 12], [13 14 15], [16 17 18], [19 20 21], [22 23 24], [25 26 27], [28 29 30], [], [] }; ...
                        {[1/3 1/3 1/3], [1/4 1/4 1/2], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3] }]},...
    'cathode_map',  {{ }},...
    'stim_resolut', 0.018, ...
    'inter_ph_int', 33.3e-6 ...
);


% fill default options missing from input argument
if nargin
    bmi_fes_stim_params = varargin{1};
else
    bmi_fes_stim_params = [];
end

all_param_names = fieldnames(bmi_fes_stim_params_defaults);
for i=1:numel(all_param_names)
    if ~isfield(bmi_fes_stim_params,all_param_names(i))
        bmi_fes_stim_params.(all_param_names{i}) = bmi_fes_stim_params_defaults.(all_param_names{i});
    end
end
