function [EMG_data,EMG_raw,EMG_labels] = process_emg(params,data,predictions)

% EMG_labels = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'}; 

if strcmpi(params.mode,'emg')
    emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
    EMG_labels = data.labels(emg_channels)';
%     for iString = 1:length(strings_to_match)
%         idx(iString) = find(strcmp(emg_labels,strings_to_match(iString)));
%     end
    [~,chan_idx,~] = intersect(data.analog_channels,emg_channels);
    
    if isempty(chan_idx)
        EMG_data = zeros(1,length(emg_channels));
    else   
        EMG_data = data.analog(:,chan_idx);
    end
    
    EMG_raw = abs(EMG_data);
    EMG_demeaned = abs(EMG_data - repmat(mean(EMG_data),size(EMG_data,1),1));
    EMG_data = mean(EMG_demeaned,1);

%     if size(EMG_data,2) == max(idx)
%         EMG_data = EMG_data(:,idx);
%     else
%         EMG_data = zeros(1,max(idx));
%         EMG_raw = zeros(10,max(idx));
%     end
elseif strcmpi(params.mode,'n2e1') || strcmpi(params.mode,'n2e2') || strcmpi(params.mode,'n2e_cartesian')
    if iscell(params.current_decoder.outnames)
        EMG_labels = params.current_decoder.outnames;
        for iLabel = 1:numel(EMG_labels)
            EMG_labels{iLabel} = ['EMG_' EMG_labels{iLabel}];
        end
    else
        temp = params.current_decoder.outnames;  
        for iLabel = 1:size(temp,1)
            EMG_labels{iLabel} = ['EMG_' deblank(temp(iLabel,:))];        
        end
    end
    
    EMG_raw = predictions;
    EMG_data = predictions;
    
%     for iString = 1:length(EMG_labels)
%         temp = find(strcmp(EMG_labels,EMG_labels(iString)));
%         if ~isempty(temp)
%             EMG_raw(iString) = predictions(temp);
%             EMG_data(iString) = predictions(temp);
%         end
%     end

elseif strcmpi(params.mode,'test force') || strcmpi(params.mode,'test torque')
    EMG_labels = {'-X_force','X_force','-Y force','Y force'};
    EMG_data = abs([min(data.handleforce(1),0) max(data.handleforce(1),0) min(data.handleforce(2),0) max(data.handleforce(2),0)]);
    EMG_raw = zeros(1,4);
else
    EMG_labels = cell(1,4);
    EMG_raw = zeros(1,4);
    EMG_data = zeros(1,4);
end




% function [EMG_data,EMG_raw,strings_to_match] = process_emg(params,data,predictions)
% % function [EMG_data,EMG_max,EMG_min,EMG_raw,strings_to_match] = process_emg(data,EMG_max,EMG_min)
% 
% strings_to_match = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'}; 
% 
% if strcmpi(params.mode,'emg') || strcmpi(params.mode,'iso')
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
% elseif strcmpi(params.mode,'n2e') || strcmpi(params.mode,'n2e_cartesian')
% %     emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
%     temp = params.current_decoder.outnames;  
%     for iLabel = 1:size(temp,1)
%         emg_labels{iLabel} = ['EMG_' deblank(temp(iLabel,:))];        
%     end
%     for iString = 1:length(strings_to_match)
%         idx(iString) = find(strcmp(emg_labels,strings_to_match(iString)));
%     end    
%     EMG_raw = predictions(idx);
%     EMG_data = predictions(idx);
% elseif strcmpi(params.mode,'test force')
%     emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
%     emg_labels = data.labels(emg_channels);
%     decoder_idx = find(~cellfun(@isempty,cellfun(@strfind,{params.decoders.decoder_type}',repmat({'emg2muscle_force'},length(params.decoders),1),'UniformOutput',false)));
%     decoder = params.decoders(decoder_idx);
%     for iRow = 1:size(decoder.outnames,1)
%         new_str_to_match{iRow} = deblank(decoder.outnames(iRow,:));
%     end
%     for iString = 1:length(strings_to_match)
%         idx(iString) = find(strcmp(emg_labels,new_str_to_match(iString)));
%     end
%     if isempty(data.emg_binned)
%         data.emg_binned = zeros(10,length(idx));
%     end
%     emg_binned = data.emg_binned(:,idx);    
%     
%     emg_predictions = [1 rowvec(emg_binned)']*decoder.H;
%     emg_predictions(emg_predictions<0) = 0;
%     for iP = 1:length(emg_predictions)
%         emg_predictions(iP) = polyval(decoder.P(:,iP),emg_predictions(iP));
%     end
%     EMG_data = emg_predictions;
%     EMG_raw = emg_predictions;
%     
%     
%     
% elseif strcmpi(params.mode,'test torque')
%     emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
%     emg_labels = data.labels(emg_channels);
%     decoder_idx = find(~cellfun(@isempty,cellfun(@strfind,{params.decoders.decoder_type}',repmat({'emg2muscle_torque'},length(params.decoders),1),'UniformOutput',false)));
%     decoder = params.decoders(decoder_idx);
%     for iRow = 1:size(decoder.outnames,1)
%         new_str_to_match{iRow} = deblank(decoder.outnames(iRow,:));
%     end
%     for iString = 1:length(strings_to_match)
%         idx(iString) = find(strcmp(emg_labels,new_str_to_match(iString)));
%     end
%     if isempty(data.emg_binned)
%         data.emg_binned = zeros(10,length(idx));
%     end
%     emg_binned = data.emg_binned(:,idx);    
%     
%     emg_predictions = [1 rowvec(emg_binned)']*decoder.H;
%     emg_predictions(emg_predictions<0) = 0;
%     for iP = 1:length(emg_predictions)
%         emg_predictions(iP) = polyval(decoder.P(:,iP),emg_predictions(iP));
%     end
%     EMG_data = emg_predictions;
%     EMG_raw = emg_predictions;
% else
%     EMG_data = zeros(1,4);
%     EMG_raw = zeros(1,4);
% end
% % elseif strcmpi(params.mode,'test')
% %     EMG_data = abs([min(data.handleforce(1),0) max(data.handleforce(1),0) min(data.handleforce(2),0) max(data.handleforce(2),0)]);
% %     EMG_raw = zeros(1,4);
% 
% 
% %     emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
% %     emg_labels = data.labels(emg_channels);
% %     for iString = 1:length(strings_to_match)
% %         idx(iString) = find(strcmp(emg_labels,strings_to_match(iString)));
% %     end
% %     [~,chan_idx,~] = intersect(data.analog_channels,emg_channels);
% %     EMG_data = data.analog(:,chan_idx);
% %     % EMG_data(:,1:2) = 0;
% %     EMG_raw = abs(EMG_data);
% %     EMG_data = mean(EMG_raw);
% % 
% %     if size(EMG_data,2) == max(idx)
% %         EMG_data = EMG_data(:,idx);
% %     else
% %         EMG_data = zeros(1,max(idx));
% %         EMG_raw = zeros(10,max(idx));
% %     end
% %     
% % %     % High force
% % %     mixing_matrix = [   -.0421  -.1389	0.2059 -.103;...
% % %                         -.036   -.013	-.1459  .239;...
% % %                         -.095   .4111	0.061   0.0612;...
% % %                         .4395   .0479   0.2099  -.1093]; 
% %     
% %     % Low force
% %     mixing_matrix = [   -0.163  -0.0212  0.0805 -0.0558;...
% %                         0.0429  0.0031  -0.0526 0.0748;...
% %                         -.0636  0.1925  0.0216  0.0280;...
% %                         0.0741  0.0009  0.0889  0.0127];
% %     
% %     EMG_data = EMG_data*mixing_matrix;
% 
%     
% 
% 
% % EMG_data = min(EMG_data,2000);
% % EMG_data(:,1:2) = 0;
% 
% % if ~isfield(data,'EMG_max')
% %     EMG_max = ones(size(EMG_data));
% % end
% % EMG_max = max(.99*EMG_max,1*EMG_data);
% % EMG_min = min(1.01*EMG_min,EMG_data+.1);
% % % EMG_data = min(EMG_data,2000);
% % EMG_max(1:end) = 5000;
% % % EMG_data = (EMG_data-EMG_min)./(EMG_max-EMG_min);
% % EMG_data = EMG_data./EMG_max;
% % % EMG_data = EMG_data./[4000 4000 2000 2000];
% % disp(num2str(EMG_data))
% % disp(num2str(EMG_min))
% % disp(num2str(EMG_max))