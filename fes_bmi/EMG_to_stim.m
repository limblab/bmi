%
% Function that computes the desired stimulation amplitude / PW based on
% the predicted EMG and some parameters. Currently it implementes a
% piecewise linear model defined by the minimum and maximum EMG levels and
% the minimum and maximum PW/amplitude values (defined in
% bmi_fes_stim_params)
%
% function [stim_PW, stim_amp] = EMG_to_stim( EMG_pred, bmi_fes_stim_params )
%
% Inputs:
%   EMG_pred            : array with EMG predictions for this bin
%   bmi_fse_stim_params : struct of type bmi_fes_stim_params
%
% Outputs:git 
%   stim_PW             : array with the stim PW for each channel
%   stim_amp            : array with the stim amplitude for each channel
%
%

function [stim_PW, stim_amp] = EMG_to_stim( EMG_pred, bmi_fes_stim_params )


nbr_emgs            = size(EMG_pred,2);

stim_PW             = zeros(1,nbr_emgs);
stim_amp            = zeros(1,nbr_emgs);


% This loop is the piecewise mapping of EMG predictions onto amplitude/PW
% commands
if strcmp(bmi_fes_stim_params.mode,'PW_modulation')
    
    for i = 1:nbr_emgs
        
        if EMG_pred(i) < bmi_fes_stim_params.EMG_min(i)
            
            stim_PW(i)  = 0;
            stim_amp(i) = 0;
        elseif EMG_pred(i) > bmi_fes_stim_params.EMG_max(i)
            
            stim_PW(i)  = bmi_fes_stim_params.PW_max(i);
            stim_amp(i) = bmi_fes_stim_params.amp_max(i);
        else
            stim_PW(i)  = ( EMG_pred(i) - bmi_fes_stim_params.EMG_min(i) )* ...
                ( bmi_fes_stim_params.PW_max(i) - bmi_fes_stim_params.PW_min(i) ) ...
                / ( bmi_fes_stim_params.EMG_max(i) - bmi_fes_stim_params.EMG_min(i) ) ...
                + bmi_fes_stim_params.PW_min(i);
            
            stim_amp(i) = bmi_fes_stim_params.amp_max(i);
        end
    end
    
elseif strcmp(bmi_fes_stim_params,'amplitude_modulation')
    
    for i = 1:nbr_emgs
        
        if EMG_pred(i) < bmi_fes_stim_params.EMG_min(i)
            
            stim_amp(i) = 0;
        elseif EMG_pred(i) > bmi_fes_stim_params.EMG_max(i)
            
            stim_amp(i) = bmi_fes_stim_params.amplitude_max(i);
        else
            stim_PW(i)  = ( EMG_pred(i) - bmi_fes_stim_params.EMG_min(i) )* ...
                ( bmi_fes_stim_params.amplitude_max(i) - bmi_fes_stim_params.amplitude_min(i) ) ...
                / ( bmi_fes_stim_params.EMG_max(i) - bmi_fes_stim_params.EMG_min(i) ) ...
                + bmi_fes_stim_params.amplitude_min(i);        
        end
    end
end

end