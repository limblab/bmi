function params = offline_adapt_params()

params = bmi_params_defaults;

% fixed:
params.adapt = true;
params.cursor_assist = true;
params.output = 'none';
params.online = false;
params.display_plots = false;
params.save_data = false;


% to be updated daily:
params.ave_fr = ave_fr;
params.save_dir =  'C:\Monkey\Jango\AdaptFiles\OfflineAdapt\';
params.save_name = 'Jango_Offline_Adapt';
params.neuron_decoder = 'new_zeros';
params.emg_decoder = '';