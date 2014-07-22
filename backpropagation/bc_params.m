function params = bc_params(varargin)
% varargin = {ave_fr,neuronIDs}

params = bmi_params_defaults;

% fixed:
params.adapt         = false;
params.cursor_assist = false;

for i = 1:nargin
    if isscalar(varargin{i})
        params.ave_fr = varargin{i};
    else
        params.neuronIDs = varargin{i};
    end
end

%Jaco:
    params.save_name      = 'Jaco_WF_BC_';
    params.save_dir       = 'F:\Data-lab1\8I1-Jaco\CerebusData\Adaptation';

    %Neuron Decoder
    params.neuron_decoder = 'F:\Data-lab1\8I1-Jaco\SavedFilters\2014_07_21\Adapted_decoder_2014_07_21_180540_End.mat';
    params.n_neurons      = size(params.neuronIDs,1);

    %EMG Decoder
    params.emg_decoder    = 'F:\Data-lab1\8I1-Jaco\SavedFilters\Jaco_WF_20140720_HC_001_E2F_Decoder.mat';
    params.n_emgs         = 6;
    
% 
% %Jango:
%     params.save_name      = 'Jango_WF_BC_';
%     params.save_dir       = 'F:\Data-lab1\12A1-Jango\CerebusData\Adaptation';
% 
%     % Neuron decoder
% %     params.neuron_decoder = 'new_zeros';
%     params.neuron_decoder = 'F:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_20140715_HC_001_N2E_Decoder.mat';
%     params.n_neurons = size(params.neuronIDs,1);
% 
%     % EMG decoder
%     params.emg_decoder = 'F:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_20140715_HC_001_E2F_Decoder.mat';
%     params.n_emgs      = 10;
