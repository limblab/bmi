% 
% Convert stimulation parameters into a stimulation command for the
% wireless stimulator
%
%   [stim_cmd, ch_list] = stim_params_to_stim_string(stim_params)
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

function [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params )

    
nbr_elects                  = numel(stim_params.elect_list);

% To ensure that the stimulation waveform will have the expect shape, we
% have to allow for a TD > 50. 
stim_params.delay           = ones(1,nbr_elects)*50;
% The pulses will also be staggered for each channel (or pairs of channels
% if doing bipolar stim)
[sorted_elects, sort_indx]  = sort(stim_params.elect_list(1,:));
nbr_anodes                  = size(stim_params.elect_list,2);
for i = 1:nbr_anodes
    stim_params.delay(i)    = stim_params.delay(i) + i*stim_params.staggering;
end
% if doing bipolar stim, stagger the pulses of the return electrodes as
% done for the "active" electrodes
if size(stim_params.elect_list,1) == 2
    % sort the return electrodes as done for the "active" electrodes
    sorted_elects(2,:)      = stim_params.elect_list(2,sort_indx);
    for i = 1:nbr_anodes
        stim_params.delay(i+nbr_anodes) = stim_params.delay(i+nbr_anodes) + ...
            i*stim_params.staggering;
    end    
end

% store sorted elects for sending adequate stim commands
ch_list                     = sorted_elects;

% Resort stim amplitude, frequency, PW and TL parameters if they are arrays
if ~isscalar(stim_params.amp)
    stim_params.amp         = stim_params.amp(sort_indx);
end
if ~isscalar(stim_params.freq)
    stim_params.freq        = stim_params.freq(sort_indx);
end
if ~isscalar(stim_params.pw)
    stim_params.pw          = stim_params.pw(sort_indx);
end
if ~isscalar(stim_params.tl)
    stim_params.tl          = stim_params.tl(sort_indx);
end

% struct arrays with param settings
% -- to avoid communcation problems, and since introducing a delay is not
% critical, the commands are sent for groups of 8 channels
if nbr_elects < 8
    stim_cmd{1}         	= struct(   'TL',      stim_params.tl );
    stim_cmd{2}             = struct(   'Freq',    stim_params.freq );
    stim_cmd{3}             = struct(   'CathAmp', 32768+stim_params.amp*1000 );
    stim_cmd{4}             = struct(   'AnodAmp', 32768-stim_params.amp*1000 );
    stim_cmd{5}             = struct(   'CathDur', stim_params.pw*1000 );
    stim_cmd{6}             = struct(   'AnodDur', stim_params.pw*1000 );
    stim_cmd{7}             = struct(   'TD',      stim_params.delay );
else
    % If we are doing bipolar stim, the commans for the return electrodes
    % are the same as for the active electrodes
    if size(stim_params.elect_list,1) == 2 
        stim_cmd{1}         = struct(   'TL',      stim_params.tl );
        stim_cmd{9}         = struct(   'TL',      stim_params.tl );
        stim_cmd{2}         = struct(   'Freq',    stim_params.freq );
        stim_cmd{10}        = struct(   'Freq',    stim_params.freq );
        stim_cmd{3}         = struct(   'CathAmp', 32768+stim_params.amp*1000 );
        stim_cmd{11}        = struct(   'CathAmp', 32768+stim_params.amp*1000 );
        stim_cmd{4}         = struct(   'AnodAmp', 32768-stim_params.amp*1000 );
        stim_cmd{12}        = struct(   'AnodAmp', 32768-stim_params.amp*1000 );
        stim_cmd{5}         = struct(   'CathDur', stim_params.pw*1000 );
        stim_cmd{13}        = struct(   'CathDur', stim_params.pw*1000 );
        stim_cmd{6}         = struct(   'AnodDur', stim_params.pw*1000 );
        stim_cmd{14}        = struct(   'AnodDur', stim_params.pw*1000 );
        stim_cmd{7}         = struct(   'TD',      stim_params.delay(1:nbr_elects/2) );
        stim_cmd{15}        = struct(   'TD',      stim_params.delay(nbr_elects/2+1:end) );    
        stim_cmd{8}         = struct(   'PL',      ones(1,nbr_anodes) );
        stim_cmd{16}        = struct(   'PL',      zeros(1,nbr_anodes) );    
    % but if we are doing monopolar stim the commands can be different for
    % each electrode
    else
        if ~isscalar(stim_params.tl)
            stim_cmd{1}     = struct(   'TL',      stim_params.tl(1:8) );
            stim_cmd{9}  	= struct(   'TL',      stim_params.tl(9:nbr_elects) );
        else
            stim_cmd{1}     = struct(   'TL',      stim_params.tl );
            stim_cmd{9}  	= struct(   'TL',      stim_params.tl );
        end
        if ~isscalar(stim_params.freq)
            stim_cmd{2}     = struct(   'Freq',    stim_params.freq(1:8) );
            stim_cmd{10}    = struct(   'Freq',    stim_params.freq(9:nbr_elects) );
        else
            stim_cmd{2}     = struct(   'Freq',    stim_params.freq );
            stim_cmd{10}    = struct(   'Freq',    stim_params.freq );
        end
        if ~isscalar(stim_params.amp)
            stim_cmd{3}     = struct(   'CathAmp', 32768+stim_params.amp(1:8)*1000 );
            stim_cmd{11}    = struct(   'CathAmp', 32768+stim_params.amp(9:nbr_elects)*1000 );
            stim_cmd{4}     = struct(   'AnodAmp', 32768-stim_params.amp(1:8)*1000 );
            stim_cmd{12}    = struct(   'AnodAmp', 32768-stim_params.amp(9:nbr_elects)*1000 );
        else
            stim_cmd{3}     = struct(   'CathAmp', 32768+stim_params.amp*1000 );
            stim_cmd{11}    = struct(   'CathAmp', 32768+stim_params.amp*1000 );
            stim_cmd{4}     = struct(   'AnodAmp', 32768-stim_params.amp*1000 );
            stim_cmd{12}    = struct(   'AnodAmp', 32768-stim_params.amp*1000 );
        end
        if ~isscalar(stim_params.pw)
            stim_cmd{5}     = struct(   'CathDur', stim_params.pw(1:8)*1000 );
            stim_cmd{13}    = struct(   'CathDur', stim_params.pw(9:nbr_elects)*1000 );
            stim_cmd{6}     = struct(   'AnodDur', stim_params.pw(1:8)*1000 );
            stim_cmd{14}    = struct(   'AnodDur', stim_params.pw(9:nbr_elects)*1000 );
        else
            stim_cmd{5}     = struct(   'CathDur', stim_params.pw*1000 );
            stim_cmd{13}    = struct(   'CathDur', stim_params.pw*1000 );
            stim_cmd{6}     = struct(   'AnodDur', stim_params.pw*1000 );
            stim_cmd{14}    = struct(   'AnodDur', stim_params.pw*1000 );
        end
        stim_cmd{7}         = struct(   'TD',      stim_params.delay(1:8) );
        stim_cmd{15}        = struct(   'TD',      stim_params.delay(9:nbr_elects) );    
        stim_cmd{8}         = struct(   'PL',      ones(1,nbr_anodes/2) );
        stim_cmd{16}        = struct(   'PL',      ones(1,nbr_anodes/2) );
    end
end

% turn ch_list into a struct for sending the commands
if nbr_elects < 8
    ch_list_struct{1}       = ch_list(1);              
else
    if size(stim_params.elect_list,1) == 2 
        ch_list_struct{1}   = ch_list(1,:);              
        ch_list_struct{2}   = ch_list(2,:);
    else
        ch_list_struct{1}   = ch_list(1:8);              
        ch_list_struct{2}   = ch_list(9:nbr_elects);
    end
end
clear ch_list;
ch_list                     = ch_list_struct;
        