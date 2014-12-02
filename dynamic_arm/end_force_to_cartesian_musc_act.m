% Endpoint forces to muscle activations
function [estimated_emg, normalization_val] = end_force_to_cartesian_musc_act(arm_params,F)

% min_99_prctile = min([prctile(F,99) prctile(-F,99)]);
mag_F = sqrt(F(:,1).^2+F(:,2).^2);
min_99_prctile = prctile(mag_F,99);
angle_F = atan2(F(:,2),F(:,1));
F(mag_F>min_99_prctile,:) = [min_99_prctile*cos(angle_F(mag_F>min_99_prctile))...
    min_99_prctile*sin(angle_F(mag_F>min_99_prctile))];

estimated_emg(:,1) = F(:,1);
estimated_emg(estimated_emg(:,1)<0,1) = 0;
estimated_emg(:,2) = -F(:,1);
estimated_emg(estimated_emg(:,2)<0,2) = 0;
estimated_emg(:,3) = F(:,2);
estimated_emg(estimated_emg(:,3)<0,3) = 0;
estimated_emg(:,4) = -F(:,2);
estimated_emg(estimated_emg(:,4)<0,4) = 0;

normalization_val = max(estimated_emg);
estimated_emg = estimated_emg./repmat(max(estimated_emg),size(estimated_emg,1),1);
