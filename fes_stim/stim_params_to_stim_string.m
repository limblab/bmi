function stim_str = stim_params_to_stim_string(stim_params)
%
%
% [stim_str] = stim_params_to_stim_string(stim_params)
%
% stim_param_to_string produces stimulation string for xippmex's stim
% command which produce symmetric biphasic pulses.
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
%   'delay'     : Delay for interleaving (ms)
%   'pol'       : Polarity. 1 - cathodic first, 0 - anodic first
%   'fs'        : length of time to fast settle (ms)
%   'stim_res'  : stimulator resolution (in mA/step)
%
%   Other than chan_list, which contains N electrode numbers, and stim_res,
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


elect_str = 'Elect=';
tl_str = 'TL=';
freq_str = 'Freq=';
dur_str = 'Dur=';
amp_str = 'Amp=';
delay_str = 'TD=';
fs_str = 'FS=';
pol_str = 'PL=';


num_elect = length(stim_params.elect_list);

% convert amplitude from mA to num_steps
stim_params.amp = round(stim_params.amp/stim_params.stim_res);
if any(stim_params.amp > 127)
    stim_params.amp(stim_params.amp>127) = 127;
    warning(['Specified current amplitude exceeds stimulator capacity.\n'...
             'Current capped at 127 stimulator steps (%.3f mA)'],127*stim_params.stim_res);
end

% ToDo: check that each element doesn't contain more params than the number
% of electrode? Right now if N electrodes are listed, and N+X values are
% provided for pw for example, only the first N pw values will be used.

for e = 1:num_elect
    
    elect_str = [elect_str num2str(stim_params.elect_list(e)) ',']; %#ok<*AGROW>
    
    % duplicate parameters for every electrodes if only one value is
    % provided
    if length(stim_params.tl)==1
        stim_params.tl = repmat(stim_params.tl,1,num_elect);
    end
    if length(stim_params.freq)==1
        stim_params.freq = repmat(stim_params.freq,1,num_elect);
    end
    if length(stim_params.pw)==1
        stim_params.pw = repmat(stim_params.pw,1,num_elect);
    end
    if length(stim_params.amp)==1
        stim_params.amp = repmat(stim_params.amp,1,num_elect);
    end
    if length(stim_params.delay)==1
        stim_params.delay = repmat(stim_params.delay,1,num_elect);
    end
    if length(stim_params.pol)==1
        stim_params.pol = repmat(stim_params.pol,1,num_elect);
    end    
    if length(stim_params.fs)==1
        stim_params.fs = repmat(stim_params.fs,1,num_elect);
    end
    
    tl_str    = [tl_str    num2str(stim_params.tl(e))    ','];
    freq_str  = [freq_str  num2str(stim_params.freq(e))  ','];
    dur_str   = [dur_str   num2str(stim_params.pw(e))    ','];
    amp_str   = [amp_str   num2str(stim_params.amp(e))   ','];
    delay_str = [delay_str num2str(stim_params.delay(e)) ','];
    pol_str   = [pol_str   num2str(stim_params.pol(e))   ','];
    fs_str    = [fs_str    num2str(stim_params.fs(e))    ','];
    
end

elect_str = [elect_str ';'];
tl_str    = [tl_str    ';'];
freq_str  = [freq_str  ';'];
dur_str   = [dur_str   ';'];
amp_str   = [amp_str   ';'];
delay_str = [delay_str ';'];
fs_str    = [fs_str    ';'];
pol_str   = [pol_str   ';'];

stim_str = [elect_str tl_str freq_str dur_str amp_str delay_str fs_str pol_str];