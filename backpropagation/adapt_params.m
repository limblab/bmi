function params = adapt_params(varargin)
% varargin = {ave_fr,neuronIDs}

params = bmi_params_defaults;

% fixed:
params.adapt = true;
params.cursor_assist = true;

for i = 1:nargin
    if iscalar(varargin{i})
        params.ave_fr = varargin{i};
    else
        params.neuronIDs = varargin{i};
    end
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
    params.save_name      = 'Jango_WF_Offline_Adapt_';
    params.save_dir       = 'F:\Data-lab1\12A1-Jango\CerebusData\Adaptation';

    % Neuron decoder
    params.neuron_decoder = 'new_zeros';
    % params.neuron_decoder = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\';
    params.n_neurons = size(params.neuronIDs,1);

    % EMG decoder
    params.emg_decoder = 'F:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_20140714_HC_001_E2F_Decoder.mat';
    params.n_emgs      = 10;

    % Adaptation parameters
    % params.lambda = 0.0015;
    params.lambda = 0;
    params.LR = 1e-9;
    

