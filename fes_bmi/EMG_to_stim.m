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

function [stim_PW, stim_amp] = EMG_to_stim( EMG_pred, bmi_fes_stim_params)


nbr_emgs            = size(EMG_pred,2);

stim_PW             = zeros(1,nbr_emgs);
stim_amp            = zeros(1,nbr_emgs);


% This loop is the piecewise mapping of EMG predictions onto amplitude/PW
% commands
if strcmp(bmi_fes_stim_params.mode,'PW_modulation')
    
    for ii = 1:nbr_emgs
        
        if EMG_pred(ii) < bmi_fes_stim_params.EMG_min(ii)
            
            stim_PW(ii)  = 0;
            stim_amp(ii) = 0;
        elseif EMG_pred(ii) > bmi_fes_stim_params.EMG_max(ii)
            
            stim_PW(ii)  = bmi_fes_stim_params.PW_max(ii);
            stim_amp(ii) = bmi_fes_stim_params.amplitude_max(ii);
        else
            stim_PW(ii)  = ( EMG_pred(ii) - bmi_fes_stim_params.EMG_min(ii) )* ...
                ( bmi_fes_stim_params.PW_max(ii) - bmi_fes_stim_params.PW_min(ii) ) ...
                / ( bmi_fes_stim_params.EMG_max(ii) - bmi_fes_stim_params.EMG_min(ii) ) ...
                + bmi_fes_stim_params.PW_min(ii);
            
            stim_amp(ii) = bmi_fes_stim_params.amplitude_max(ii);
        end
    end
    
elseif strcmp(bmi_fes_stim_params,'amplitude_modulation')
    
    for ii = 1:nbr_emgs
        
        if EMG_pred(ii) < bmi_fes_stim_params.EMG_min(ii)
            stim_amp(ii) = 0;
            stim_PW(ii) = 0;
            
        elseif EMG_pred(ii) > bmi_fes_stim_params.EMG_max(ii)
            
            stim_amp(ii) = bmi_fes_stim_params.amplitude_max(ii);
            stim_PW(ii) = bmi_fes_stim_params.PW_max;
        else
            stim_PW(ii)  = ( EMG_pred(ii) - bmi_fes_stim_params.EMG_min(ii) )* ...
                ( bmi_fes_stim_params.amplitude_max(ii) - bmi_fes_stim_params.amplitude_min(ii) ) ...
                / ( bmi_fes_stim_params.EMG_max(ii) - bmi_fes_stim_params.EMG_min(ii) ) ...
                + bmi_fes_stim_params.amplitude_min(ii);        
        end
    end
end

end