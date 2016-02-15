function words = read_words()
% get words from cerebus stream using cbmex
%
% Inputs:
%   None
%
% Outputs:
%   words: nx2 array of words, where n is the number of received words
%
% Note: compare words against the values in w = Words;

% define max and min value to check if word is valid
min_db_val = hex2dec('F0');
max_db_val = hex2dec('FF');

% read and flush data buffer
[ts_cell_array, ~, analog_data] = cbmex('trialdata', 1);

% get timestamps and words from cell array
[ts,words] = ts_cell_array{151,2:3};

% check if any timestamps exist
if ~isempty(words)
    %The WORD is on the high byte (bits
    % 15-8) and the ENCODER is on the
    % low byte (bits 8-1).
    all_words = [ts, uint32(bitshift(bitand(hex2dec('FF00'),words),-8))];
    all_words = all_words(logical(all_words(:,2)),:);
    
    % behavior words:
    words = double(all_words( all_words(:,2) < min_db_val, :));
    
    % For debugging: prints word to screen when it finds one
    %     if ~isempty(words)
    %         words
    %     end
end

