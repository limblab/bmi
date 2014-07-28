% run_dynamic_arm_bmi
clear params
params.monkey_name = 'Chewie';
params.save_dir = ['E:\' params.monkey_name];
params.mode = 'N2E'; % EMG | N2E | Vel (not implemented yet) | Iso
params.task_name = ['DCO_' params.mode];
params.N2E_decoder.decoder_file = '\\citadel\data\Chewie_8I2\Ricardo\Chewie_2014-07-25_DCO_Iso\Output_Data\bdf-binned_Decoder.mat';
params.vel_decoder.decoder_file = '\\citadel\data\Chewie_8I2\Ricardo\Chewie_2014-07-25_DCO_Iso\Output_Data\bdf-binned_Decoder.mat';
params.map_file = '\\citadel\limblab\lab_folder\\Animal-Miscellany\Chewie 8I2\Blackrock implant surgery 6-14-10\1025-0394.cmp';
params.N2E = '';
params.output = 'xpc';
params.force_to_cursor_gain = .3;
params.save_firing_rates = 1;
params.display_plots = 0;
params.left_handed = 1;
params.debug = 0;

if exist('params','var')
    params = bmi_params_defaults(params);
else
    params = bmi_params_defaults;
end
params.elec_map = read_cmp(params.map_file);

run_decoder(params)
