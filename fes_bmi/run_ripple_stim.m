function varargout = run_ripple_stim(varargin)
% Inputs: EMG files
% Outputs: ??
% 1. import EMG files (not sure how to do training here...)
% 2. read EMG files into variables that set up different muscles?
% 3. make EMG file into an envelope
% 4. make EMG envelope into a signal that we'll need to send
% 5. set up stimulation parameters that will stay the same (pw, interphase
% time)
% 6. send start signal - start running stimulation
% 7. read the signal from 4; as each pair of high/low is sent, check if the
% amplitude needs to be changed for the next pair. If so, send the updated
% amp to the stimulator. 

emg = struct; %read emgs into this struct formatted as: 'muscle'; [values over time]
[cols, headers] = xlsread('fake_emg.xlsx'); %muscles (headers) and cols (each emg is in a column)
muscles = strtrim(headers); %strip spaces from headers
%plot(cols(:,2))
hold on;
cols = abs(cols); 
plot(cols(:,2))
%disp(muscles(2))

for m=1:length(muscles)
    [emg.(muscles{m})] = cols(:,m); %get field name from column header, put column in as vector
end


[b, a] = butter(9,.0055,'high');
butterfilt = filtfilt(b, a, cols(:,2));
plot(butterfilt); 

hold off; 
%**MUST start at 0, end at 0 regardless of what the fit says


%okay, now send this signal that we just made
%????

