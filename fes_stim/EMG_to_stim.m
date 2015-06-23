function [duration_tracker,current_tracker] = EMG_to_stim(EMG_Pred, params)

%warning for EMG number mismatch
duration_tracker = zeros(1,length(EMG_Pred));
current_tracker = zeros(1,length(EMG_Pred));

if(params.mode == 1)
    
    for i = 1:length(params.cathode_map)
        
        if(EMG_Pred(i) < params.EMG_min(i))
            %               duration = params.PW_min(i);
            duration = 0;
            
        elseif((params.EMG_min(i) <= EMG_Pred(i))  && (EMG_Pred(i) < params.EMG_max(i)))
            duration = ( params.PW_max(i)/(params.EMG_max(i)-params.EMG_min(i)))*(EMG_Pred(i)-params.EMG_min(i));
            
        else
            duration = params.PW_max(i);
        end
        
        duration_tracker(i) = duration;
        
    end
    
else
    
    for i = 1:length(params.cathode_map)
        
        if(EMG_Pred(i) < params.EMG_min(i))
            %                current = params.current_min(i);
            current = 0;
            
        elseif((params.EMG_min(i) <= EMG_Pred(i))  && (EMG_Pred(i) < params.EMG_max(i)))
            current = ( params.current_max(i)/(params.EMG_max(i)-params.EMG_min(i)))*(EMG_Pred(i)-params.EMG_min(i));
            
        else
            current = params.current_max(i);
        end
        
        current_tracker(i) = current;
        
    end
    
    
end

end