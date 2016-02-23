% 
% Convert stimulation parameters into a stimulation command for the
% wireless stimulator
%
%   stim_cmd = stim_params_to_stim_string(stim_params)
%
%   The input argument is a stim_params structure, as described in
%   stim_params_defaults.m
%   
%   It contains the fields:
%   'elect_list' : one indexed list of stimulation electrodes
%   'tl'        : length of pulse train (ms)
%   'freq'      : frequency of pulse train (Hz)
%   'pw'        : duration of single phase ('TD' in ripple) (ms)
%   'amp'       : amplitude of single phase's current (mA)
%   'pol'       : Polarity. 1 - cathodic first, 0 - anodic first
%
%   Other than elect_list, which contains N electrode numbers, and stim_res,
%   which is a scalar, all the other fields may contain either a single
%   value or a vector of N values. If only one value is provided, it will
%   be used for all the stimulation channels listed in chan_list.
%   
%   Example: the following will generate the appropriate stim_string to
%   stimulate the channels 1 through 4 at 30Hz with all the default
%   stimulation parameters
%
%   stim_params.chan_list = [1 2 3 4];
%   stim_params.Freq = 30;
%   stim_params = stim_params_defaults(stim_params); %fills up struct with default values
%   stim_string = stim_params_to_stim_string(stim_params);
%
%   see also: stim_params_defaults.m, ezstim.m
% 
% -------------------------------------------------------------------------
% NOTE !!!: the current version of the wireless stimulator firmware doesn't
% support setting the polarity as an array so this has to be habdled in 
%

function stim_cmd = stim_params_to_stim_cmd_ws( stim_params )

    
% To ensure that the stimulation waveform will have the expect shape, we
% have to allow for a TD > 50.
if stim_params.delay < 50
    stim_params.delay = 50;
end

% Single element struct array with param settings
stim_cmd{1}     = struct(   'TL',      stim_params.tl, ...
                            'Freq',    stim_params.freq, ...
                            'CathAmp', 32768+stim_params.amp*1000, ...
                            'AnodAmp', 32768-stim_params.amp*1000 );

stim_cmd{2}     = struct(   'CathDur', stim_params.pw*1000, ...
                            'AnodDur', stim_params.pw*1000, ...
                            'TD',      stim_params.delay );
