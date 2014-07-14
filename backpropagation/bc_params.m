function params = bc_params(ave_fr)

params = bmi_params_defaults;

% fixed:
params.adapt = false;

params.cursor_assist = false;

% to be updated daily:
params.ave_fr = ave_fr;

% %Jaco:
% params.save_dir =  'E:\Data-lab1\8I1-Jaco\CerebusData\Adaptation';
% params.save_name = 'Jaco_WF_Adapt';
% 
% % params.neuron_decoder = 'E:\Data-lab1\8I1-Jaco\SavedFilters\Jaco_WF_2014_05_08_HC_001_N2E_Decoder.mat';
% params.neuron_decoder = 'E:\Data-lab1\8I1-Jaco\CerebusData\Adaptation\2014_05_29\Adapted_decoder_2014_05_29_150854_End.mat';
% params.emg_decoder = 'E:\Data-lab1\8I1-Jaco\SavedFilters\Jaco_WF_2014_05_08_HC_001_E2F_Decoder.mat';

% Jango:
params.save_name = 'Jango_WF_Adapt';
params.save_dir =  'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation';

% params.neuron_decoder = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\;
params.neuron_decoder = 'E:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_2014_05_29_HC_001_N2E_trainoffline_Decoder.mat';
params.emg_decoder = 'E:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_Adapt_2014_07_01_HC_001_bin_E2F_Decoder.mat';

