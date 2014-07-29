EMG = DCO.emg';
Fx_pos = bdf.force(:,2);
Fx_pos(Fx_pos<0) = 0;
Fx_neg = -bdf.force(:,2);
Fx_neg(Fx_neg<0) = 0;
Fy_pos = bdf.force(:,3);
Fy_pos(Fy_pos<0) = 0;
Fy_neg = -bdf.force(:,3);
Fy_neg(Fy_neg<0) = 0;

F = [Fx_pos Fx_neg Fy_pos Fy_neg];

mixing_matrix = EMG\F;
pseudo_force = EMG*mixing_matrix;


