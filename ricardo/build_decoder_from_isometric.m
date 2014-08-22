data_location = 'D:\Data\Chewie_8I2\Chewie_2014-08-21_DCO_iso_bmi';
bdf_file = [data_location filesep 'Output_Data\bdf.mat'];
param_file = dir([data_location filesep '*params*']);
param_file = [data_location filesep param_file(1).name];
decoder_type = 'cartesian';
load(bdf_file);
load(param_file);

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