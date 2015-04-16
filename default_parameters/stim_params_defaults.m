function stim_params = stim_params_defaults(varargin)
%   Default stimulation parameters for grapevine stimulator
%   Use with 'stim_params_to_string.m' function to generate stim_string
%
%   stim_params_defaults generates the fields:
%   'chan_list' : one indexed list of stimulation electrodes
%   'tl'        : length of pulse train (ms)
%   'freq'      : frequency of pulse train (Hz)
%   'pw'        : duration of single phase ('TD' in ripple) (ms)
%   'amp'       : amplitude of single phase's current (mA)
%   'delay'     : Delay for interleaving (ms)
%   'pol'       : Polarity. 1 - cathodic first, 0 - anodic first
%   'fs'        : length of time to fast settle (ms)
%   'stim_res'  : stimulator resolution (in mA/step)
%
%   Other than chan_list, which contains N electrode numbers, all the other
%   fields may contain either a single value or a vector of N values. If
%   only one value is provided, it will be used for all the stimulation
%   channels listed in chan_list.
%
%   A parameter structure with some of the same field names can be provided
%   as an input argument. The fields provided as input will not be
%   overwritten. This function will instead fill up the inputed structure
%   with the default values for the missing fields.

stim_params_defaults = struct( ...
    'elect_list'     ,[3 5 7],...
    'amp'           ,2.286,...
    'freq'          ,30,...
    'pw'            ,0.2,...
    'tl'            ,1000,...
    'delay'         ,0,...
    'pol'           ,1,...
    'fs'            ,0.0,...
    'stim_res'      ,0.018...
    );

% fill default options missing from input argument
if nargin
    stim_params = varargin{1};
    input_param_names = fieldnames(stim_params);
else
    stim_params = [];
    input_param_names = [];
end

all_param_names   = fieldnames(stim_params_defaults);

for i = 1:numel(input_param_names)
    if ~any(strcmp(input_param_names{i},all_param_names))
        errordlg(sprintf('Invalid stim parameter\n"%s"',input_param_names{i}),'Need coffee??');
        return;
    end
end
        
for i=1:numel(all_param_names)
    if ~isfield(stim_params,all_param_names(i))
        stim_params.(all_param_names{i}) = stim_params_defaults.(all_param_names{i});
    end
end
