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