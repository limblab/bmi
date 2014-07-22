function params = train_offline_decoder(varargin)

if nargin
    params.neuronIDs = varargin{1};
end

params.adapt        = true ;
params.online       = false;
params.realtime     = false;
params.save_data    = false;
params.display_plots= false;
params.cursor_assist= false;
params.output       ='none';

%Jaco:

    %Data files
    params.offline_data   = 'F:\Data-lab1\8I1-Jaco\BinnedData\2014-07-20\Jaco_WF_20140720_HC_001_bin.mat';
    params.save_name      = 'Jaco_WF_Offline_Adapt_';
    params.save_dir       = 'F:\Data-lab1\8I1-Jaco\SavedFilters';
    
    %Neuron Decoder
    params.neuron_decoder = 'new_zeros';
    params.n_neurons      = size(params.neuronIDs,1);

    %EMG Decoder
    params.emg_decoder    = 'F:\Data-lab1\8I1-Jaco\SavedFilters\Jaco_WF_20140720_HC_001_E2F_Decoder.mat';
    params.n_emgs         = 6;
    
    %Adaptation Parameters
    params.lambda = 0;
    params.LR = 1e-8;
 
% %Jango:
% 
%     %Data files
%     params.offline_data   = 'F:\Data-lab1\12A1-Jango\BinnedData\2014-07-15\Jango_WF_20140715_HC_001_bin.mat';
%     params.save_name      = 'Jango_WF_Offline_Adapt_';
% 
%     %Neuron Decoder
%     params.neuron_decoder = 'new_zeros';
%     params.n_neurons      = size(params.neuronIDs,1);
% 
%     %EMG Decoder
%     params.emg_decoder    = 'F:\Data-lab1\12A1-Jango\SavedFilters\Jango_WF_20140715_HC_001_E2F_Decoder.mat';
%     params.n_emgs         = 10;
%     
%     %Adaptation Parameters
%     params.lambda = 0.0015;
% %     params.lambda = 0;
%     params.LR = 1e-9;
    
%-------------------
run_decoder(params);
%-------------------