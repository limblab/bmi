function rt_str = stim_param_to_string(elecs, train_length, freq, ...
    duration, amp, delay, pol, fs_elecs, fs_value)
% stim_param_to_string produces stimulation string for xippmex's stim
% command which produce symmetric biphasic pulses.
%
%   str = stim_param_to_string(elecs, train_length, freq, duration, 
%                              amp, delay, pol, [fs_elecs, fs_value])
%
%   The first five variables contain arrays of parameters wanted for
%   stimulation organized by electrode.  For example stimulation parameters
%   for the first electrode will be elecs(1), train_length(1), etc.
%   
%   Arguments 1-7 are required and must be arrays of equal length.
%   
%   elecs - one indexed list of wanted electrodes - must be integers
%   train_length - length of pulse train (ms)
%   freq - frequency of pulse train (Hz)
%   duration - duration of single phase (ms)
%   amp - height of single phase's current (headstage steps - [0, 127]
%   delay - delay for interleaving (ms)
%   pol - polarity.  For bipolar stimulation.  1 - cathodic first, 
%     0 - anodic first
%   fs_elecs - list of electrodes to be used for fast settle
%   fs_value - length of time to fast settle (ms)

% If we are doing any fast settle, let's make sure that all the frequencies
% and the train length's are the same, otherwise this interface needs to be  
% significantly more complex.
if ~isempty(fs_elecs)
    if length(unique(freq)) ~= 1
        error('invalid stim parameters for fast settle.  need unique frequencies');
    end
    % set the fs frequencies (for unique fast settle electrodes) to be
    % whatever is the longest train length.
    fs_tl = max(train_length);
end

if length(unique([length(elecs), length(train_length), length(freq), ...
        length(duration), length(amp), length(delay)])) ~= 1
    error('invalid stim parameters, check array lengths');
end

param_length = length(elecs);

elect_str = 'Elect=';
tl_str = 'TL=';
freq_str = 'Freq=';
dur_str = 'Dur=';
amp_str = 'Amp=';
delay_str = 'TD=';
fs_str = 'FS=';
pol_str = 'PL=';

% fold fast settle electrodes into the parameter list
% first create the full list of electrodes
total_elecs = sort(unique([elecs, fs_elecs]));
% param_length = length(total_elecs);

% create a space for fast settle data for all electrodes
fs_times = zeros(1, length(total_elecs));
for elec_index=1:length(total_elecs)
    elec = total_elecs(elec_index);
    % check that this is a fast settle electrode
    if find(elec==fs_elecs)
        % check that this electrode is in our original electrode list
        fs_times(elec_index) = fs_value;
        if find(elecs==elec)
        % if the this is not in our current list of electrodes, we'll need
        % to insert (in the correct order) zero values for all the stim
        % parameters.
        else
            % create vectors with an extra element, NaN is used to know
            % where we haven't inserted a new element.
            new_tl = zeros(1, param_length+1) + NaN;
            new_freq = zeros(1, param_length+1) + NaN;
            new_dur = zeros(1, param_length+1) + NaN;
            new_amp = zeros(1, param_length+1) + NaN;
            new_delay = zeros(1, param_length+1) + NaN;
            new_pol = zeros(1, param_length+1) + NaN;
            
            param_length = param_length + 1;
            
            % insert the new values
            % we've set the fs train length above, the longest tl.
            new_tl(elec_index) = fs_tl;
            % if we got this far we should only be 1 unique frequency.
            new_freq(elec_index) = freq(1);
            % the rest may as well be zero.
            new_dur(elec_index) = 0;
            new_amp(elec_index) = 0;
            new_delay(elec_index) = 0;
            new_pol(elec_index) = 1;
            
            % now fold the original vectors back in
            new_tl(isnan(new_tl)) = train_length;
            new_freq(isnan(new_freq)) = freq;
            new_dur(isnan(new_dur)) = duration;
            new_amp(isnan(new_amp)) = amp;
            new_delay(isnan(new_delay)) = delay;
            new_pol(isnan(new_pol)) = pol;
            % finally, make this the original vectors
            train_length = new_tl;
            freq = new_freq;
            duration = new_dur;
            amp = new_amp;
            delay = new_delay;
            pol = new_pol;
        end
    end
end
elect_str = strcat(elect_str, sprintf('%d,', total_elecs));
tl_str = strcat(tl_str, sprintf('%.3f,', train_length));
freq_str = strcat(freq_str, sprintf('%.0f,', freq));
dur_str = strcat(dur_str, sprintf('%.3f,', duration));
amp_str = strcat(amp_str, sprintf('%d,', amp));
delay_str = strcat(delay_str, sprintf('%.3f,', delay));
fs_str = strcat(fs_str, sprintf('%.2f,', fs_times));
pol_str = strcat(pol_str, sprintf('%d,', pol));

rt_str = strcat(elect_str, ';', tl_str, ';', freq_str, ';',...
    dur_str, ';', amp_str, ';', delay_str, ';', fs_str, ';', pol_str, ';');
