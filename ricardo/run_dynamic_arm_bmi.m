% run_dynamic_arm_bmi
clear params
params.monkey_name = 'Kevin';
params.save_dir = ['E:\' params.monkey_name];
params.task_name = 'DCO_EMG';
params.mode = 'EMG'; % EMG | N2E
params.N2E = '';

decoder_test(params)