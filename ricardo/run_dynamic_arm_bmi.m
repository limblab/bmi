% run_dynamic_arm_bmi
clear params
params.monkey_name = 'Mini';
params.save_dir = ['E:\' params.monkey_name];
params.task_name = 'DCO_BC';
params.mode = 'N2E'; % EMG | N2E
params.neuron_decoder = '\\citadel\data\Mini_7H1\Ricardo\Mini_2014-05-06_DCO\Output_Data\bdf-binned_Decoder.mat';
params.N2E = '';

decoder_test(params)