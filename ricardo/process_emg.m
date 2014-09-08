function [EMG_data,EMG_raw,strings_to_match] = process_emg(params,data,predictions)

strings_to_match = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'}; 

if strcmpi(params.mode,'emg')
    emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
    emg_labels = data.labels(emg_channels);
    for iString = 1:length(strings_to_match)
        idx(iString) = find(strcmp(emg_labels,strings_to_match(iString)));
    end
    [~,chan_idx,~] = intersect(data.analog_channels,emg_channels);
    EMG_data = data.analog(:,chan_idx);
    EMG_raw = abs(EMG_data);
    EMG_data = mean(EMG_raw);

    if size(EMG_data,2) == max(idx)
        EMG_data = EMG_data(:,idx);
    else
        EMG_data = zeros(1,max(idx));
        EMG_raw = zeros(10,max(idx));
    end
elseif strcmpi(params.mode,'n2e') || strcmpi(params.mode,'n2e_cartesian')
    temp = params.current_decoder.outnames;  
    for iLabel = 1:size(temp,1)
        emg_labels{iLabel} = ['EMG_' deblank(temp(iLabel,:))];        
    end
    for iString = 1:length(strings_to_match)
        idx(iString) = find(strcmp(emg_labels,strings_to_match(iString)));
    end
    EMG_raw = predictions(idx);
    EMG_data = predictions(idx);
elseif strcmpi(params.mode,'test')
    EMG_data = abs([min(data.handleforce(1),0) max(data.handleforce(1),0) min(data.handleforce(2),0) max(data.handleforce(2),0)]);
    EMG_raw = zeros(1,4);
else
    EMG_raw = zeros(1,4);
    EMG_data = zeros(1,4);
end