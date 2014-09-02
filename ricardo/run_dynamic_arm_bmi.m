% run_dynamic_arm_bmi
clear params
params.monkey_name = 'Chewie';
params.save_dir = ['E:\' params.monkey_name];
params.mode = 'iso'; % emg | n2e | n2e_cartesian | vel | iso
params.arm_model = 'hu'; % hill | prosthesis | hu | miller | perreault | ruiz | bmi
params.task_name = ['DCO_' params.mode];
params.decoders(1).decoder_file = '\\citadel\data\Chewie_8I2\Ricardo\Chewie_2014-08-21_DCO_iso_bmi\Output_Data\bdf-musc_Binned_Decoder.mat';
params.decoders(1).decoder_type = 'n2e';
params.decoders(2).decoder_file = '\\citadel\data\Chewie_8I2\Ricardo\Chewie_2014-08-21_DCO_iso_bmi\Output_Data\bdf-cartesian_Binned_Decoder.mat';
params.decoders(2).decoder_type = 'n2e_cartesian';
params.decoders(3).decoder_file = '\\citadel\data\Chewie_8I2\Ricardo\Chewie_2014-08-20_RW\Chewie_2014-08-20_RW_001_Binned_Decoder.mat';
params.decoders(3).decoder_type = 'vel';
params.arm_params_file = 'E:\Chewie\Chewie_2014-08-19_DCO_iso_ruiz\Chewie_2014-08-19_DCO_iso_ruiz_001_params.mat';
% params.arm_params_file = [];
params.map_file = '\\citadel\limblab\lab_folder\\Animal-Miscellany\Chewie 8I2\Blackrock implant surgery 6-14-10\1025-0394.cmp';
params.output = 'xpc';
params.force_to_cursor_gain = .3;
params.save_firing_rates = 1;
params.display_plots = 0;
params.left_handed = 1;
params.debug = 0;
params.offset_time_constant = 60;
params.vel_offsets = [0 0];
params.artifact_removal = 0;
params.artifact_removal_window = 0.001;
params.artifact_removal_num_channels = 10;

if exist('params','var')
    params = bmi_params_defaults(params);
else
    params = bmi_params_defaults;
end
params.elec_map = read_cmp(params.map_file);

arm_params = [];
if ~isempty(params.arm_params_file)
    load(params.arm_params_file,'arm_params')       
end
arm_params = get_default_arm_params(arm_params);

save('temp_arm_params','arm_params')
clear arm_params

run_decoder(params)
