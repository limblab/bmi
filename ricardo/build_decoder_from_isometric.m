bdf_file = 'D:\Data\Chewie_8I2\Chewie_2014-07-25_DCO_Iso\Output_Data\bdf.mat';
load(bdf_file);
arm_params = get_default_arm_params;
arm_params.left_handed = 1;

arm_params.X_sh = arm_params.l.*[-1 -1];

F = -bdf.force(:,2:3);
if 0
    estimated_emg = end_force_to_musc_act(arm_params,F);
else
    estimated_emg = end_force_to_cartesian_musc_act(arm_params,F);
end
estimated_emg = estimated_emg(:,[3 4 1 2]);
bdf.emg.data(:,2:5) = estimated_emg;
bdf.emg.rectified = true;

save(bdf_file,'bdf')