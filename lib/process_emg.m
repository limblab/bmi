function [EMG_data,EMG_raw,strings_to_match] = process_emg(params,data,predictions)
% function [EMG_data,EMG_max,EMG_min,EMG_raw,strings_to_match] = process_emg(data,EMG_max,EMG_min)

strings_to_match = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'}; 

if strcmpi(params.mode,'emg')
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
elseif strcmpi(params.mode,'n2e') || strcmpi(params.mode,'n2e_cartesian')
%     emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
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

%     emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
%     emg_labels = data.labels(emg_channels);
%     for iString = 1:length(strings_to_match)
%         idx(iString) = find(strcmp(emg_labels,strings_to_match(iString)));
%     end
%     [~,chan_idx,~] = intersect(data.analog_channels,emg_channels);
%     EMG_data = data.analog(:,chan_idx);
%     % EMG_data(:,1:2) = 0;
%     EMG_raw = abs(EMG_data);
%     EMG_data = mean(EMG_raw);
% 
%     if size(EMG_data,2) == max(idx)
%         EMG_data = EMG_data(:,idx);
%     else
%         EMG_data = zeros(1,max(idx));
%         EMG_raw = zeros(10,max(idx));
%     end
%     
% %     % High force
% %     mixing_matrix = [   -.0421  -.1389	0.2059 -.103;...
% %                         -.036   -.013	-.1459  .239;...
% %                         -.095   .4111	0.061   0.0612;...
% %                         .4395   .0479   0.2099  -.1093]; 
%     
%     % Low force
%     mixing_matrix = [   -0.163  -0.0212  0.0805 -0.0558;...
%                         0.0429  0.0031  -0.0526 0.0748;...
%                         -.0636  0.1925  0.0216  0.0280;...
%                         0.0741  0.0009  0.0889  0.0127];
%     
%     EMG_data = EMG_data*mixing_matrix;
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