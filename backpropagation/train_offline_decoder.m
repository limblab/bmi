function params = adapt_params(varargin)

% varargin = {num_best_neur}

params = bmi_params_defaults;

if nargin
    num_best_neur = varargin{1};
end

params.adapt        = true;
params.online       = false;
params.realtime     = false;
params.save_data    = false;

% % %Jaco:
% params.save_dir =  'E:\Data-lab1\8I1-Jaco\CerebusData\Adaptation';
% params.save_name = 'Jaco_WF_Adapt';
% 
% %params.neuron_decoder = 'new_zeros';
% params.neuron_decoder = 'E:\Data-lab1\8I1-Jaco\CerebusData\Adaptation\2014_05_29\Adapted_decoder_2014_05_29_150854_End.mat';
% params.emg_decoder = 'E:\Data-lab1\8I1-Jaco\SavedFilters\Jaco_WF_2014_05_08_HC_001_E2F_Decoder.mat';
% params.lambda = 0.015;
% params.n_emgs = 6;
% params.LR = 5e-10;

%Jango:

params.offline_data = 'F:\Data-lab1\12A1-Jango\BinnedData\20140714\Jango_WF_20140714_HC_001_bin.mat';
params.display_plots = false;

params.save_name = 'Jango_WF_Offline_Adapt_';
params.save_dir =  'F:\Data-lab1\12A1-Jango\CerebusData\Adaptation';
params.neuron_decoder = 'new_zeros';

% params.neuron_decoder = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\';
params.emg_decoder = 'F:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_20140714_HC_001_E2F_Decoder.mat';
% params.lambda = 0.0015;
params.lambda = 0;
params.n_emgs = 10;
params.LR = 1e-9;

params.neuronIDs = load('Z:\Jango_12a1\NeuronIDs\neuronIDs_sortedXCOVwEMG_20140707_b30.mat');
if isstruct(params.neuronIDs)
    fn = fieldnames(params.neuronIDs);
    params.neuronIDs = getfield(params.neuronIDs,fn{1});
end
params.neuronIDs = params.neuronIDs(1:num_best_neur,:);
params.n_neurons = size(params.neuronIDs,1);

run_decoder(params);