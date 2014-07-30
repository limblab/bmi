
strings_to_match = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'}; 

emg_labels = bdf.emg.emgnames;
for iString = 1:length(strings_to_match)
    idx(iString) = find(strcmp(emg_labels,strings_to_match(iString)));
end

EMG = DCO.emg(idx,:)';
F = -bdf.force(:,2:3);
Fx_pos = F(:,1);
Fx_pos(Fx_pos<0) = 0;
Fx_neg = -F(:,1);
Fx_neg(Fx_neg<0) = 0;
Fy_pos = F(:,2);
Fy_pos(Fy_pos<0) = 0;
Fy_neg = -F(:,2);
Fy_neg(Fy_neg<0) = 0;

F = [Fx_pos Fx_neg Fy_pos Fy_neg];

mixing_matrix = EMG\F;
pseudo_force = EMG*mixing_matrix;


