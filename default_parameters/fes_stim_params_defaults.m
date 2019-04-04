<<<<<<< Updated upstream
function fes_stim_params = fes_stim_params_defaults(varargin)
%
% function bmi_fes_stim_params = bmi_fes_stim_params_defaults(varargin)
%
%   'muscles'           : muscle electrodes in the animal
%   'EMG_to_stim_map'   : map between predicted EMGs (1st row )and
%                           stimulated muscles (2nd row)
%   'EMG_min'           : minimum value of the EMG predictions
%   'EMG_max'           : maxumum value of the EMG predictions
%   'freq'              : stimulation frequency (Hz)
%   'mode'              : stim mode; 'PW_modulation' or 'amplitude_modulation'
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

serialPorts = instrhwinfo('serial');
fes_stim_params_defaults = struct( ...
    'muscles',      {({'EDC', 'EDC2', 'ADL', 'ECU', 'FDP', 'ECR', 'Brad', 'PT', 'FCU', 'FDS', 'FCR', 'FDS2'})}, ...
    'EMG_to_stim_map',  {[{'EDC', 'EDC2', 'ADL', 'ECU', 'FDP', 'ECR', 'Brad', 'PT', 'FCU', 'FDS', 'FCR', 'FDS2'}; ...
                        {'EDC', 'EDC2', 'ADL', 'ECU', 'FDP', 'ECR', 'Brad', 'PT', 'FCU', 'FDS', 'FCR', 'FDS2'}]}, ...
    'EMG_min',      repmat(0.15,1,12), ...
    'EMG_max',      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], ...
    'freq',         30, ...
    'mode',         'PW_modulation', ... % amplitude_modulation or PW_modulation
    'PW_max',       [0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4],...
    'PW_min',       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],...
    'amplitude_min',[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],...
    'amplitude_max',[2, 0, 1, 4, 4, 0, 0, 2, 2, 1, 1, 0],...
    'anode_map',    {[{ [1 2 3], [4 5 6], [7 8 9], [10 11 12], [13 14 15], [16 17 18], [19 20 21], [22 23 24], [25 26 27], [28 29 30], [], [] }; ...
                        {[1/3 1/3 1/3], [1/4 1/4 1/2], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3] }]},...
    'cathode_map',  {{ }},...
    'stim_resolut', 0.018, ...
    'inter_ph_int', 33.3e-6, ...
    'serial_string', serialPorts.SerialPorts{end}, ...      % usually it will be the last plugged in
    'path_cal_ws',  '.', ...    
    'return',       'monopolar', ... % monopolar or bipolar
    'perc_catch_trials', 0 ...
);
=======

% Default stimulation parameters for grapevine stimulator or ripple's
% wireless stimulator for use in EZstim or ICMS code.
%   
% Use with 'stim_params_to_string.m' function to generate stim_string for
% the grapevine, or with 'stim_params_to_stim_cmd_ws.m' to generate 
% stim_cmd to generate stim_cmd for Ripple's wireless stimulator.
%
%   function stim_params = stim_params_defaults(varargin)
%
% stim_params_defaults generates the fields:
%   'elect_list'    : one indexed list of stimulation electrodes. If it is
%                       a 1-by-N array, all the electrodes will be treated
%                       as anodes and a common eletrode will be used as
%                       return; if it is a 2-by-N array, the first row of 
%                       electrodes will be the anodes,and the corresponding 
%                       electrodes in the second row the cathodes.
%   'tl'            : length of pulse train (ms)
%   'freq'          : frequency of pulse train (Hz)
%   'pw'            : duration of single phase ('TD' in ripple) (ms)
%   'amp'           : amplitude of single phase's current (mA)
%   'delay'         : Delay for interleaving (ms)
%   'pol'           : Polarity. 1 - cathodic first, 0 - anodic first
%   'fs'            : length of time to fast settle (ms)
%   'stim_res'      : stimulator resolution (in mA/step)
%   'staggering'    : staggering between channels for the wireless
%                       stimulator (us)
%   'stimulator'    : 'ws' (for the wireless stimulator), or 'gv' for the
%                       grapevine
%   'serial_ws'     : COM port to which the wireless stim is connected
%   'path_cal_ws'   : path of the calibration file for the wireless stim
%
% Other than chan_list, which contains N electrode numbers, all the other
% fields may contain either a single value or a vector of N values. If
% only one value is provided, it will be used for all the stimulation
% channels listed in chan_list.
%
% A parameter structure with some of the same field names can be provided
% as an input argument. The fields provided as input will not be
% overwritten. This function will instead fill up the inputed structure
% with the default values for the missing fields.


function stim_params = fes_stim_params_defaults(varargin)


serialPorts = instrhwinfo('serial');
stim_params_defaults = struct( ...
    'elect_list'        ,[1 3 5 7 9 11 13 15;2 4 6 8 10 12 14 16],... 
    'amp'               ,repmat(5,1,8),...
    'freq'              ,30,...
    'pw'                ,.5,...
    'tl'            	,2000,...
    'delay'             ,0,...
    'pol'               ,1,...
    'fs'                ,0.0,...
    'stim_res'          ,0.018,...
    'staggering'        ,0,...
    'stimulator'        ,'ws',...
    'serial_string'     ,serialPorts.SerialPorts{end},... % typically it's the last USB plugged in -- this way it might work for every computer
    'path_cal_ws'       ,'E:\Data-lab1\Wireless_Stimulator',... 
    'dbg_lvl'           ,1,...
    'comm_timeout_ms'   ,1000,...
    'blocking'          ,false,...
    'zb_ch_page'        ,2);
>>>>>>> Stashed changes


% fill default options missing from input argument
if nargin
<<<<<<< Updated upstream
    fes_stim_params = varargin{1};
else
    fes_stim_params = [];
end

all_param_names = fieldnames(fes_stim_params_defaults);
for i=1:numel(all_param_names)
    if ~isfield(fes_stim_params,all_param_names(i))
        fes_stim_params.(all_param_names{i}) = fes_stim_params_defaults.(all_param_names{i});
=======
    stim_params         = varargin{1};
    input_param_names   = fieldnames(stim_params);
else
    stim_params         = [];
    input_param_names   = [];
end

all_param_names         = fieldnames(stim_params_defaults);

for i = 1:numel(input_param_names)
    if ~any(strcmp(input_param_names{i},all_param_names))
        errordlg(sprintf('Invalid stim parameter\n"%s"',input_param_names{i}),'Need coffee??');
        return;
    end
end
        
for i = 1:numel(all_param_names)
    if ~isfield(stim_params,all_param_names(i))
        stim_params.(all_param_names{i}) = stim_params_defaults.(all_param_names{i});
>>>>>>> Stashed changes
    end
end
