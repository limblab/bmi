function bmi_fes_stim_params = bmi_fes_stim_params_defaults(varargin)
%
% function bmi_fes_stim_params = bmi_fes_stim_params_defaults(varargin)
%
%   'muscles'           : muscle electrodes in the monkey
%   'EMG_to_stim_map'   : map between predicted EMGs (1st row )and
%                           stimulated muscles (2nd row)
%   'EMG_min'           : minimum value of the EMG predictions
%   'EMG_max'           : maxumum value of the EMG predictions
%   'freq'              : stimulation frequency (Hz)
%   'mode'              : stim. mode; 'PW_modulation' or 'amplitude_modulation'
%   'PW_max'            : maximum PW, in 'PW_modulation' mode. This PW
%                           would be used in amplitude-modulated FES
%   'PW_min'            : minimum PW, in 'PW_modulation' mode
%   'amplitude_min'     : minimum amplitude, in 'amplitude_modulation' mode
%   'amplitude_max'     : maximum amplitude, in 'amplitude_modulation'
%                           mode. This current amplitude is used in the
%                           'PW_modulation' mode to set the amplitude.   
%   'anode_map'         : electrodes that function as anodes for each
%                           muscle (first row), and how the current will be
%                           distributed among them (the sum for each muscle
%                           should = 1;    
%                       second row). 
%   'cathode_map'       : electrodes that function as cathodes for each
%                           muscle (first row), and how the current will
%                           be distributed among them (the sum for each
%                           muscle should = 1; second row). If blank, the
%                           stimulation is monopolar    
%   'stim_resolut'      : resolution of the stimulator (mA)
%   'inter_ph_int'      : inter-phase interval (us)
%   'port_wireless'     : COM port; for the wireless stimulator
%   'path_cal_ws'       : path calibration file wireless stimulator
%   'return'            : 'monopolar' or 'bipolar' stim
%   'perc_catch_trials'
%


bmi_fes_stim_params_defaults = struct( ...
    'muscles',      {({'FCRr','FCUr','FCUu','FDPr','FDPu','FDSr','FDSu','FDS'})}, ...
    'EMG_to_stim_map',  {[{'FCRr','FCUr','FCUu','FDPr','FDPu','FDSr','FDSu','FDS'}; ...
                        {'FCRr','FCUr','FCUu','FDPr','FDPu','FDSr','FDSu','FDS'}]}, ...
    'EMG_min',      repmat(0.15,1,8), ...
    'EMG_max',      repmat(1,1,8), ...
    'freq',         30, ...
    'mode',         'PW_modulation', ...
    'PW_max',       repmat(.5,1,8),...
    'PW_min',       zeros(1,8),...
    'amplitude_min',zeros(1,8),...
    'amplitude_max',repmat(5,1,8),...
    'anode_map',    {[{1:8}; ...
                        {ones(1,8)}]},...
    'cathode_map',  {{ }},...
    'stim_resolut', 0.018, ...
    'inter_ph_int', 33.3e-6, ...
    'port_wireless', 'COM5', ...
    'path_cal_ws',  'E:\Data-lab1\Wireless_Stimulator', ...    
    'return', 'monopolar', ...
    'perc_catch_trials', 0 ...
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
