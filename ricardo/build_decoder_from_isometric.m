bdf_file = 'D:\Data\Chewie_8I2\Chewie_2014-08-04_DCO_iso_ruiz\Output_Data\bdf.mat';
decoder_type = 'cartesian';
load(bdf_file);
arm_params = get_default_arm_params;
arm_params.left_handed = 1;

F = -bdf.force(:,2:3);
if strcmp(decoder_type,'musc')
    estimated_emg = end_force_to_musc_act(arm_params,F);
elseif strcmp(decoder_type,'cartesian')
    estimated_emg = end_force_to_cartesian_musc_act(arm_params,F);
end
estimated_emg = estimated_emg(:,[3 4 1 2]);
bdf.emg.data(:,2:5) = estimated_emg;
bdf.emg.rectified = true;

[bdf_folder,bdf_filename,ext] = fileparts(bdf_file);
save([bdf_folder filesep bdf_filename '-' decoder_type],'bdf')