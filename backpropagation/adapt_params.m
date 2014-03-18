function params = adapt_params()

params = bmi_params_defaults;

% fixed:
params.adapt = true;
params.cursor_assist = true;

% to be updated daily:
params.ave_fr = ave_fr;
params.save_dir =  'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation';
params.save_name = 'Jango_WF_Adapt';
params.neuron_decoder = 'new_zeros';
params.emg_decoder = '';