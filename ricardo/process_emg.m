function [EMG_data,EMG_raw,strings_to_match] = process_emg(params,data,predictions)
% function [EMG_data,EMG_max,EMG_min,EMG_raw,strings_to_match] = process_emg(data,EMG_max,EMG_min)

strings_to_match = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'}; 

if strcmp(params.mode,'EMG')
    emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
    emg_labels = data.labels(emg_channels);
    for iString = 1:length(strings_to_match)
        idx(iString) = find(strcmp(emg_labels,strings_to_match(iString)));
    end
    [~,chan_idx,~] = intersect(data.analog_channels,emg_channels);
    EMG_data = data.analog(:,chan_idx);
    % EMG_data(:,1:2) = 0;
    EMG_raw = abs(EMG_data);
    EMG_data = mean(EMG_raw);

    if size(EMG_data,2) == max(idx)
        EMG_data = EMG_data(:,idx);
    else
        EMG_data = zeros(1,max(idx));
        EMG_raw = zeros(10,max(idx));
    end
elseif strcmp(params.mode,'N2E')
%     emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
    temp = params.neuron_decoder.outnames;  
    for iLabel = 1:size(temp,1)
        emg_labels{iLabel} = ['EMG_' deblank(temp(iLabel,:))];        
    end
    for iString = 1:length(strings_to_match)
        idx(iString) = find(strcmp(emg_labels,strings_to_match(iString)));
    end    
    EMG_raw = predictions(idx);
    EMG_data = predictions(idx);    
else
    EMG_raw = zeros(1,4);
    EMG_data = zeros(1,4);
end
    


% EMG_data = min(EMG_data,2000);
% EMG_data(:,1:2) = 0;

% if ~isfield(data,'EMG_max')
%     EMG_max = ones(size(EMG_data));
% end
% EMG_max = max(.99*EMG_max,1*EMG_data);
% EMG_min = min(1.01*EMG_min,EMG_data+.1);
% % EMG_data = min(EMG_data,2000);
% EMG_max(1:end) = 5000;
% % EMG_data = (EMG_data-EMG_min)./(EMG_max-EMG_min);
% EMG_data = EMG_data./EMG_max;
% % EMG_data = EMG_data./[4000 4000 2000 2000];
% disp(num2str(EMG_data))
% disp(num2str(EMG_min))
% disp(num2str(EMG_max))