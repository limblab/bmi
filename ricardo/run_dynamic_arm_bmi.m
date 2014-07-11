% run_dynamic_arm_bmi
clear params
params.monkey_name = 'TestData';
params.save_dir = ['E:\' params.monkey_name];
params.mode = 'Iso'; % EMG | N2E | Vel (not implemented yet) | Iso
params.task_name = ['DCO_' params.mode];
params.neuron_decoder_name = '\\citadel\data\Mini_7H1\Ricardo\Mini_2014-05-27_decoders\Mini_2014-05-27_frankendecoder.mat';
params.map_file = '\\citadel\limblab\lab_folder\\Animal-Miscellany\Chewie 8I2\Blackrock implant surgery 6-14-10\1025-0394.cmp';
params.N2E = '';
params.output = 'xpc';
params.force_to_cursor_gain = .3;
params.save_firing_rates = 1;

if exist('params','var')
    params = bmi_params_defaults(params);
else
    params = bmi_params_defaults;
end
params.elec_map = read_cmp(params.map_file);

run_decoder(params)
