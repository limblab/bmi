function [EMG_data,EMG_max,EMG_min,EMG_raw,strings_to_match] = process_emg(data,EMG_max,EMG_min)

emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
emg_labels = data.labels(emg_channels);
strings_to_match = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'};    
for iLabel = 1:length(strings_to_match)
    idx(iLabel) = find(strcmp(emg_labels,strings_to_match(iLabel)));
end

[~,chan_idx,~] = intersect(data.analog_channels,emg_channels);
EMG_data = data.analog(:,chan_idx);

if size(EMG_data,2) == max(idx)
    EMG_data = EMG_data(:,idx);
else
    EMG_data = zeros(1,max(idx));
end

% EMG_data(:,1:2) = 0;
EMG_raw = abs(EMG_data);
EMG_data = mean(EMG_raw);
% EMG_data = min(EMG_data,2000);
% EMG_data(:,1:2) = 0;

% if ~isfield(data,'EMG_max')
%     EMG_max = ones(size(EMG_data));
% end
EMG_max = max(.99*EMG_max,1*EMG_data);
EMG_min = min(1.01*EMG_min,EMG_data+.1);
% EMG_data = min(EMG_data,2000);
% EMG_max(1:end) = 1000;
% EMG_data = (EMG_data-EMG_min)./(EMG_max-EMG_min);
% EMG_data = EMG_data./EMG_max;
EMG_data = EMG_data./[4000 4000 2000 2000];
disp(num2str(EMG_data))
disp(num2str(EMG_min))
disp(num2str(EMG_max))