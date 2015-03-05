function params = bc_params(varargin)
% varargin = {ave_fr,neuronIDs}

% fixed:
params.adapt         = false;
params.cursor_assist = false;
params.output        = 'xpc';
params.save_data     = true;
params.online        = true;

for i = 1:nargin
    if isscalar(varargin{i})
        params.ave_fr = varargin{i};
    else
        params.neuronIDs = varargin{i};
    end
end

%Jango:
    params.save_name      = 'Jango_IsoBox_BC_';
    params.save_dir       = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\';
    
%     % optimal N2F decoder:
%     params.mode           = 'direct';
%     params.neuron_decoder = 'E:\Data-lab1\12A1-Jango\SavedFilters\20150212\Jango_2015212_WFHC_001_50neur_N2F_Decoder.mat';
    
    % decoder trained with adapt_offline
    params.mode           = 'direct';
    params.neuron_decoder = 'Z:\Jango_12a1\SavedFilters\Adaptation\20150217\Jango_2015217_WFHC_002&003_N2F_Decoder.mat';
    
    
    % Neuron decoder
%     params.neuron_decoder = 'new_zeros';
%     params.neuron_decoder = 'Z:\Jango_12a1\SavedFilters\BCcontrol\20150115\Jango_IsoBox_HC_20150115_001_N2F_Decoder.mat';
%     params.neuron_decoder = 'Z:\Jango_12a1\SavedFilters\Adaptation\20150120\Jango_20150120_WFHC_003_N2E.mat';



    % EMG decoder
%     params.emg_decoder = 'Z:\Jango_12a1\SavedFilters\Jango_20150107_E2F_xcor_12EMGs.mat';
%     params.emg_decoder = 'Z:\Jango_12a1\SavedFilters\E2F_8generic_iso_muslces.mat';
%     params.n_emgs      = 8;
%     params.n_lag_emg   = 1;
