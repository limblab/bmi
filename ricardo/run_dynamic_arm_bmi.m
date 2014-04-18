% run_dynamic_arm_bmi
clear params
params.save_dir = 'E:\Kevin';
params.monkey_name = 'Kevin';
params.task_name = 'DCO_EMG';
params.task_description = '';
% params.save_name = 'Kevin_DCO_EMG';

decoder_test(params)