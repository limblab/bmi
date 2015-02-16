function EMG_labels_new = EMG_label_conversion(EMG_labels)

if ~iscell(EMG_labels)    
    EMG_labels_temp = char(EMG_labels);
    EMG_labels_new = {};
    for iLabel = 1:size(EMG_labels_temp,1)
        if ~isempty(deblank(EMG_labels_temp(iLabel,:)))
            EMG_labels_new{iLabel} = deblank(EMG_labels_temp(iLabel,:));
        end
    end
else
    EMG_labels_new = 32*ones(10,10);
    for iLabel = 1:size(EMG_labels,2)
        EMG_labels_new(iLabel,:) = [uint8(EMG_labels{iLabel}) 32*ones(1,10-length(EMG_labels{iLabel}))];
    end
    EMG_labels_new = uint8(EMG_labels_new);    
end
