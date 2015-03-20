function params = adapt_params(varargin)
% varargin = {ave_fr,neuronIDs}

% fixed:
params.adapt = true;
params.cursor_assist = true;

for i = 1:nargin
    if isscalar(varargin{i})
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
params.save_name      = 'Jango_WF_Online_Adapt_';
params.save_dir       = 'F:\Data-lab1\12A1-Jango\CerebusData\Adaptation';
params.save_data      = true;

%Neuron Decoder
params.neuron_decoder = 'new_zeros';
params.n_neurons      = 96;

%EMG Decoder
params.emg_decoder    = 'F:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_20141014_HC_001_E2F1bin_Decoder.mat';
params.n_emgs         = 12;
params.n_lag_emg      = 1;





