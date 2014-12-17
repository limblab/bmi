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
        params.offline_data   = '/Users/christianethier/Dropbox/Adaptation/Data/Jango3/Jango_20141014_traindata.mat';
        params.save_dir       = '/Users/christianethier/Dropbox/Adaptation/temp_data';
        
        %Neuron Decoder
        params.neuron_decoder = 'new_zeros';
        params.n_neurons      = 96;
        %EMG Decoder
%         params.emg_decoder    = 'F:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_20140714_HC_001_E2F_Decoder.mat';
%         params.emg_decoder    = '/Users/christianethier/Dropbox/Adaptation/Data/GenericPD_4WristMuscles.mat';
        params.emg_decoder    = '/Users/christianethier/Dropbox/Adaptation/Data/Jango3/Jango_20141014_E2F_xcor_norm_scaled.mat';
        params.n_emgs         = 12;
        params.n_lag_emg      = 1;
        
%         tmp_pat               = load('/Users/christianethier/Dropbox/Adaptation/Data/Jango/Jango_WF_20141104_HC_001_EMGpatterns+PD.mat');
        tmp_pat               = load('/Users/christianethier/Dropbox/Adaptation/Data/Jango3/Jango_20141014_opt_emgpat_12EMGs.mat');
        params.emg_patterns   = tmp_pat.emg_patterns; clear tmp_pat;
        
        %Adaptation Parameters
%           %lambda: [L0 L1 L2 L3]:= weights for Force error, L1reg, L2reg and EMG templates respectively
%          params.lambda = [1 0 0.5 0];
% %          params.lambda = [1 0 1 1];
         params.LR = 2e-6;
         
    case 'Spike'
        %Data files
        params.offline_data   = '/Users/christianethier/Dropbox/Adaptation/Data/Spike/BinnedData/Spike_20120307_traindata.mat';
        params.save_dir       = '/Users/christianethier/Dropbox/Adaptation/temp_data';
        
        %Neuron Decoder
        params.neuron_decoder = 'new_zeros';

        %EMG Decoder
        params.emg_decoder    = '/Users/christianethier/Dropbox/Adaptation/Data/Spike/decoders/Spike_20120307_E2F_13EMGs.mat';
%         params.emg_decoder    = '/Users/christianethier/Dropbox/Adaptation/Data/GenericPD_4WristMuscles.mat';
        params.n_emgs         = 13;
        params.n_lag_emg      = 1;

        %EMG Patterns
        tmp_pat               = load('/Users/christianethier/Dropbox/Adaptation/Data/Spike/decoders/Spike_20120307_optpat_13EMGs.mat');
        params.emg_patterns   = tmp_pat.emg_patterns; clear tmp_pat;
        
        %Adaptation Parameters
%          params.lambda = [1 0 4 100];
         %params.lambda = [1 0 4 100];
         params.LR = 2e-6;                

end
%-------------------
decoder = run_decoder(params);
%-------------------
