function params = adapt_params(varargin)
% varargin = {ave_fr,num_best_neur}

params = bmi_params_defaults;

% fixed:
params.adapt = true;
params.cursor_assist = true;
% to be updated daily:
params.ave_fr = ave_fr;

if nargin
    params.ave_fr = varargin{1};
end
if nargin >1
    num_best_neur = varargin{2};
end

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
params.save_name = 'Jango_WF_Adapt';
params.save_dir =  'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation';

params.neuron_decoder = 'new_zeros';
% params.neuron_decoder = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\';
params.emg_decoder = 'E:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_2014_05_29_HC_001_E2F_Decoder.mat';
params.lambda = 0.0015;
params.n_emgs = 11;
params.LR = 1e-9;

params.neuronIDs = load('Z:\Jango_12a1\SavedFilters\neuronIDs_sortedXCOVwEMG_20140703.mat');
if isstruct(params.neuronIDs)
    fn = fieldnames(params.neuronIDs);
    params.neuronIDs = getfield(params.neuronIDs,fn{1});
end
params.neuronIDs = params.neuronIDs(1:num_best_neur,:);
    

