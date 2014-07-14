function params = adapt_params(ave_fr)

params = bmi_params_defaults;

% fixed:
params.adapt = true;
params.cursor_assist = true;
params.output ='none';
params.online = false;

% to be updated daily:
params.ave_fr = ave_fr;
% params.save_dir =  'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation';
params.save_dir =  'E:\Data-lab1\8I1-Jaco\CerebusData\Adaptation';
params.save_name = 'Jaco_WF_Adapt';
params.neuron_decoder = 'new_zeros';
% params.neuron_decoder = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\2014_03_18\Adapted_decoder_2014_03_18_172452_End.mat';
params.emg_decoder = 'E:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_2014-03-17_001_E2F_Decoder.mat';