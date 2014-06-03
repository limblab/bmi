% run_dynamic_arm_bmi
clear params
params.monkey_name = 'Mini';
params.save_dir = ['E:\' params.monkey_name];
params.mode = 'EMG'; % EMG | N2E | Vel(not implemented yet)
params.task_name = ['DCO_' params.mode];
params.neuron_decoder = '\\citadel\data\Mini_7H1\Ricardo\Mini_2014-05-27_decoders\Mini_2014-05-27_frankendecoder.mat';
params.N2E = '';
params.output = 'xpc';

if exist('params','var')
    params = bmi_params_defaults(params);
else
    params = bmi_params_defaults;
end

decoder_test(params)