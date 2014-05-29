% run_dynamic_arm_bmi
clear params
params.monkey_name = 'Mini';
params.save_dir = ['E:\' params.monkey_name];
params.mode = 'N2E'; % EMG | N2E
params.task_name = ['DCO_' params.mode];
params.neuron_decoder = '\\citadel\data\Mini_7H1\Ricardo\Mini_2014-05-27_decoders\Mini_2014-05-27_frankendecoder.mat';
params.N2E = '';

decoder_test(params)