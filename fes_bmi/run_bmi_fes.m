clear all; close all; clc;


%% Some definitions

% Who is in the lab?
monkey                  = 'Jango'; % 'Kevin'

% List of muscles for the decoder
emg_list_4_dec          = {'FCU', 'ECU', 'EDC2'}; % {'FCU', 'PL', 'FCR'};

% Mapping of EMGs in the decoder to Electrodes in the Monkey
sp.EMG_to_stim_map      = [{'FCU', 'ECU', 'EDC2'}; ...
                            {'FCU', 'ECU', 'EDCu'}];
                        
% Monopolar or bipolar stimulation
stim_mode               = 'bipolar'; % 'bipolar'; 'monopolar'


% This flag allows you to run the code without the stimulator
stimulator_plugged_in   = false;

% Whether you want to save the data
params.save_data        = false;


% ------------------------------------------------------------------------
%% Build the neuron-to-EMG decoder

% % Raw data file for the decoder
% file4decoder            = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/CerebusData/Plasticity/20150320_Jango_WF_001.nev';
% 
% 
% % Bin the data 
% % --> Do not forget to normalize EMG and Force !!! <--
% binnedData              = convert2BDF2Binned( file4decoder );
% 
% 
% % Parameters for the decoder: EMG predictions; filter length = 500 ms; bin
% % size = 50 ms; no static non-linearity
% dec_opts.PredEMGs       = 1;
% 
% 
% % Look for the muscles specified in 'emg_list_4_dec'
% emg_pos_in_binnedData   = zeros(1,numel(emg_list_4_dec));
% for i = 1:length(emg_pos_in_binnedData)
%     emg_pos_in_binnedData(i) = find( strncmp(binnedData.emgguide,emg_list_4_dec(i),length(emg_list_4_dec{i})) );
% end
% 
% train_data              = binnedData;
% train_data.emgguide     = emg_list_4_dec;
% train_data.emgdatabin   = binnedData.emgdatabin(:,emg_pos_in_binnedData);
% 
% % Build the neuron-to-EMG decoder
% N2E                     = BuildModel( train_data, dec_opts );



% ------------------------------------------------------------------------
%% If you want to use an existing decoder
dec_file                        = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/Decoders/20150320_Jango_WF_001_binned_Decoder.mat';


% If N2E is a file, this will load it 
if ~isstruct(dec_file)
    N2E                         = LoadDataStruct(dec_file);
    
    % Get rid of the muscles we don't care about (i.e. not included in emg_list_4_dec)
    if isfield(N2E, 'H')
        emg_pos_in_dec          = zeros(1,numel(emg_list_4_dec));
        for i = 1:length(emg_pos_in_dec)
            emg_pos_in_dec(i)   = find( strncmp(N2E.outnames,emg_list_4_dec(i),length(emg_list_4_dec{i})) );
        end
        
        N2E.H                   = N2E.H(:,emg_pos_in_dec);
        N2E.outnames            = emg_list_4_dec;
    else
        error('Invalid neuron-to-emg decoder');
    end
end


% ------------------------------------------------------------------------
%% If you want to use offline data instead of online recordings from the monkey

params.offline_data             = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/BinnedData/behavior plasticity/20150320_Jango_WF_001_binned.mat';


% ------------------------------------------------------------------------
%% Define some BMI parameters


% Neuron-to-EMG decoder file
params.neuron_decoder   = N2E;



params.output           = 'stimulator';
params.mode             = 'emg_only';


params.n_emgs           = numel(emg_list_4_dec);  % this is the number of EMGs in the decoder


params.display_plots    = false; % these plots are for other BMI stuff


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
%         sp.anode_map    = [{ [], [2 4 6], [], [], [], [], [], [14 16 18], [20 22 24] }; ...
%                             { [], [1/3 1/3 1/3], [], [], [], [], [], [1/3 1/3 1/3], [1/3 1/3 1/3] }];
        
        sp.anode_map    = [{ [14 16 18], [2 4 6], [], [8 10 12], [], [], [], [], [] }; ...
                            { [1/3 1/3 1/3], [1/3 1/3 1/3], [], [1/3 1/3 1/3], [], [], [], [], [] }];
                        
        if strcmp(stim_mode,'bipolar')
            sp.cathode_map  = [{ [1 3 5], [7 9 11], [], [13 15 17], [], [], [], [], [] }; ...
                                { [1/3 1/3 1/3], [1/3 1/3 1/3], [], [1/3 1/3 1/3], [], [], [], [], [] }];
        elseif strcmp(stim_mode,'monopolar')
            sp.cathode_map          = {{ }};
        end
        
    case 'Kevin'
        sp.muscles      = {'FCR1','FCR2','FCU1','FDPr','FDPu','FDS1','FDS2','PT','FCU2','ECU1','ECU2','ECR1','ECR2','EDCu'};        
        % sp.anode_map    
end


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
clear monkey sp emg_pos_in_dec i;



% ------------------------------------------------------------------------
%% Do it!

run_decoder(params);
