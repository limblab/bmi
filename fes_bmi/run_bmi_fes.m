clear all; close all; clc;


%% Some definitions

% Who is in the lab?
monkey                  = 'Jango'; % 'Kevin'

% List of muscles for the decoder
emg_list                = {'FCU', 'PL', 'FCR'};

% This flag allows you to run the code without the stimulator
stimulator_plugged_in   = false;

% Whether you want to save the data
params.save_data        = true;


% ------------------------------------------------------------------------
%% Build the neuron-to-EMG decoder

% Raw data file for the decoder
file4decoder            = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/CerebusData/Plasticity/20150320_Jango_WF_001.nev';


% Bin the data 
% --> Do not forget to normalize EMG and Force !!! <--
binnedData              = convert2BDF2Binned( file4decoder );


% Parameters for the decoder: EMG predictions; filter length = 500 ms; bin
% size = 50 ms; no static non-linearity
dec_opts.PredEMGs       = 1;


% Look for the muscles specified in 'emg_list'
emg_pos_in_binnedData   = zeros(1,numel(emg_list));
for i = 1:length(emg_pos_in_binnedData)
    emg_pos_in_binnedData(i) = find( strncmp(binnedData.emgguide,emg_list(i),length(emg_list{i})) );
end

train_data              = binnedData;
train_data.emgguide     = emg_list;
train_data.emgdatabin   = binnedData.emgdatabin(:,emg_pos_in_binnedData);

% Build the neuron-to-EMG decoder
N2E                     = BuildModel( train_data, dec_opts );



% ------------------------------------------------------------------------
%% Define some BMI parameters


% Neuron-to-EMG decoder file
params.neuron_decoder   = N2E;



params.output           = 'stimulator';
params.mode             = 'emg_only';


params.n_emgs           = numel(emg_list);  % this is the number of EMGs in the decoder


params.display_plots    = false;


if stimulator_plugged_in
    params.online       = true;
else
    params.online       = false;
end


% ------------------------------------------------------------------------
%% Define sitmulation parameters


switch monkey
    case 'Jango'
        sp.muscles      = {'EDCu','FCU','EDCr','ECU','ECRb','PL','ECRl','FDP','FCR'};
        sp.anode_map    = [{ [], [2 4 6], [], [], [], [], [], [14 16 18], [20 22 24] }; ...
                            { [], [1/3 1/3 1/3], [], [], [], [], [], [1/3 1/3 1/3], [1/3 1/3 1/3] }];
    case 'Kevin'
        sp.muscles      = {'FCR1','FCR2','FCU1','FDPr','FDPu','FDS1','FDS2','PT','FCU2','ECU1','ECU2','ECR1','ECR2','EDCu'};        
        % sp.anode_map    
end

sp.cathode_map          = {{ }};

sp.EMG_min              = repmat( 0.15, 1,numel(sp.muscles));
sp.EMG_max              = repmat( 1, 1,numel(sp.muscles));
        
sp.PW_min               = repmat( 0.02, 1,numel(sp.muscles));
sp.PW_max               = repmat( 0.4, 1,numel(sp.muscles));

% even if we do PW-modulated FES, we initialize this for consistency of
% matrix size
sp.amplitude_min        = repmat( 2, 1,numel(sp.muscles));
sp.amplitude_max        = repmat( 6, 1,numel(sp.muscles));  % this is the amplitude for PW-modulated FES


params.bmi_fes_stim_params  = sp;


% get rid of some variables
clear monkey sp;



% ------------------------------------------------------------------------
%% Do it!

run_decoder(params);
