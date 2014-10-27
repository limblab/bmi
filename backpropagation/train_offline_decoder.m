function decoder = train_offline_decoder(varargin)
% varargin = {'Monkeyname' and/or neuronIDs}, in any order.

monkey = 'Jango';

for i=1:nargin
    if ischar(varargin{i})
        monkey = varargin{i};
    else
        params = varargin{i};
    end
end
params.adapt        = true;
params.online       = false;
params.realtime     = false;
params.save_data    = false;
params.display_plots= false;
params.cursor_assist= false;
params.output       ='none';
params.print_out    = false;

switch monkey

    case 'Jaco'
        
        %Data files
        params.offline_data   = '/Users/christianethier/Dropbox/Adaptation/temp_data/Jaco_WF_20140721_HC_0-18min.mat';
        params.save_name      = 'Jaco_WF_Offline_Adapt_';
        params.save_dir       = '/Users/christianethier/Dropbox/Adaptation/temp_data';
        
        %Neuron Decoder
        params.neuron_decoder = 'new_zeros';
        params.n_neurons      = size(params.neuronIDs,1);
        
        %EMG Decoder
        params.emg_decoder    = '/Volumes/data/Jaco_8I1/SavedFilters/2014_07_21/Jaco_WF_20140720_HC_001_E2F_Decoder.mat';
        params.n_emgs         = 6;
        
        %Adaptation Parameters
        % params.lambda = 0.015;
        params.lambda = 0;
        params.LR = 1e-9;
        
    case 'Jango'
        
        %Data files
%         params.offline_data   = 'F:\Data-lab1\12A1-Jango\BinnedData\20140714\Jango_WF_20140714_HC_001_bin.mat';
%         params.offline_data   = '/Users/christianethier/Dropbox/Adaptation/temp_data/TRAIN_2EMGs1F.mat';
%         params.offline_data   = '/Users/christianethier/Dropbox/Adaptation/temp_data/Jango_20140711_37m_TRAIN.mat';
        params.offline_data   = '/Users/christianethier/Dropbox/Adaptation/new_data/Jango_20140711_optimdata_20min.mat';
        params.save_name      = 'param_optim';
%         params.save_dir       = 'F:\Data-lab1\12A1-Jango\CerebusData\Adaptation';
        params.save_dir       = '/Users/christianethier/Dropbox/Adaptation/temp_data';
        
        %Neuron Decoder
        params.neuron_decoder = 'new_zeros';
        params.n_neurons      = 95;
%         params.n_neurons      = size(params.neuronIDs,1);
        
        %EMG Decoder
%         params.emg_decoder    = 'F:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_20140714_HC_001_E2F_Decoder.mat';
        params.emg_decoder    = '/Users/christianethier/Dropbox/Adaptation/new_data/Jango_20140707_E2F_Decoder1bin.mat';
%         params.emg_decoder    = '/Users/christianethier/Dropbox/Adaptation/temp_data/IRF_2E1F_Decoder.mat';
        params.n_emgs         = 9;
        params.n_lag_emg      = 1;
        
%         tmp_pat               = load('/Users/christianethier/Dropbox/Adaptation/new_data/Jango_20140707_EMGpatterns.mat');
%         params.emg_patterns   = tmp_pat.EMGpatterns; clear tmp_pat;
        
        %Adaptation Parameters
          %lambda: [L0 L1 L2 L3]:= weights for Force error, L1reg, L2reg and EMG templates respectively
         params.lambda = [1 0 4 0];
%         params.lambda = 10;
         params.LR = 1e-6;

end
%-------------------
decoder = run_decoder(params);
%-------------------
