
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


function stim_params = stim_params_defaults(varargin)


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
    'serial_string'     ,serialPort.SerialPorts{end},... % typically it's the last USB plugged in -- this way it might work for every computer
    'path_cal_ws'       ,'E:\Data-lab1\Wireless_Stimulator',... 
    'dbg_lvl'           ,1,...
    'comm_timeout_ms'   ,1000,...
    'blocking'          ,false,...
    'zb_ch_page'        ,2);


% fill default options missing from input argument
if nargin
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
    end
end
