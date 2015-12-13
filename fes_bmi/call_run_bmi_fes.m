clear all; close all; clc;


%% Some definitions

% Who is in the lab?
monkey                  = 'Jango'; % 'Kevin'

% List of muscles for the decoder
% emg_list_4_dec          = {'FCU', 'FDP', 'PL', 'ECU', 'ECRl', 'EDCr'};  %{'FCR', 'FCU', 'EDC2'}; % {'FCU', 'PL', 'FCR'};
emg_list_4_dec          = {'FDP', 'PL'};  %{'FCR', 'FCU', 'EDC2'}; % {'FCU', 'PL', 'FCR'};

% Mapping of EMGs in the decoder to Electrodes in the Monkey
% sp.EMG_to_stim_map      = [{'FCR', 'FCU', 'EDC2'}; ...
%                             {'FCR', 'FCU', 'EDCu'}];
sp.EMG_to_stim_map      = [{'FDP', 'PL'}; ...
                            {'FDP', 'PL'}];

% Monopolar or bipolar stimulation
stim_mode               = 'bipolar'; % 'bipolar'; 'monopolar'

% Grapevine or wireless stimulator
params.output           = 'wireless_stim'; % 'stimulator'; 'wireless_stim';


% Run the code without the stimulator
stimulator_plugged_in   = true;

% Save the data
params.save_data        = true;

% file name
params.save_name        = 'Jango_WF_MUblock_';
% and folder name
if ispc
	params.save_dir     = 'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES';
elseif ismac
    params.save_dir     = '/Users/juangallego/Desktop';
end


% ------------------------------------------------------------------------
%% Build the neuron-to-EMG decoder

% % Raw data file for the decoder
% if ismac
%     file4decoder        = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/CerebusData/Plasticity/20150320_Jango_WF_001.nev';
% elseif ispc
% %     file4decoder        = 'E:\Data-lab1\12A1-Jango\CerebusData\BMIFES\20151117\Jango_20151118_isoWF_001.nev';
%     file4decoder        = 'E:\Data-lab1\12A1-Jango\CerebusData\BMIFES\20151117\Jango_20151125_isoWF_003.nev';
% end
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
% 
% clear train_data binnedData dec_opts



% ------------------------------------------------------------------------
%% If you want to use an existing decoder
if ismac
    dec_file            = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/Decoders/20150320_Jango_WF_001_binned_Decoder.mat';
elseif ispc
%     dec_file            = 'Z:\Jango_12a1\Plasticity\Behavior\data_2015_03_20\20150320_Jango_WF_001_binned_Decoder.mat';
%    dec_file            = 'E:\Data-lab1\12A1-Jango\CerebusData\BMIFES\20151117\Jango_20151118_isoWF_binned_Decoder.mat';
%    dec_file            = 'E:\Data-lab1\12A1-Jango\CerebusData\BMIFES\20151125\Jango_20151125_isoWF_003_binned_Decoder.mat';
    dec_file            = 'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES\20151211\Jango_20151211_isoWF_001_BDF_binned_Decoder.mat';
end

% If N2E is a file, this will load it 
if ~isstruct(dec_file)
    N2E                 = LoadDataStruct(dec_file);
    
    % Get rid of the muscles we don't care about (i.e. not included in emg_list_4_dec)
    if isfield(N2E, 'H')
        emg_pos_in_dec  = zeros(1,numel(emg_list_4_dec));
        for i = 1:length(emg_pos_in_dec)
            emg_pos_in_dec(i)   = find( strncmp(N2E.outnames,emg_list_4_dec(i),length(emg_list_4_dec{i})) );
        end
        
        N2E.H           = N2E.H(:,emg_pos_in_dec);
        N2E.outnames    = emg_list_4_dec;
    else
        error('Invalid neuron-to-emg decoder');
    end
end


% ------------------------------------------------------------------------
%% If you want to use offline data instead of online recordings from the monkey

% if ismac
%     params.offline_data = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/BinnedData/behavior plasticity/20150320_Jango_WF_001_binned.mat';
% elseif ispc
%     params.offline_data = 'Z:\Jango_12a1\Plasticity\Behavior\data_2015_03_20\20150320_Jango_WF_002_bin.mat';
% end


% ------------------------------------------------------------------------
%% Define some BMI parameters


% Neuron-to-EMG decoder file
params.neuron_decoder   = N2E;
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
        
        switch params.output
            case 'stimulator' % for the grapevine
                sp.muscles          = {'FDP', 'PL', 'FCU'};
%               sp.anode_map        = [{ [], [2 4 6], [], [], [], [], [], [14 16 18], [20 22 24] }; ...
%                                       { [], [1/3 1/3 1/3], [], [], [], [], [], [1/3 1/3 1/3], [1/3 1/3 1/3] }];
                sp.anode_map        = [{ [14 16 18], [8 10 12], [7 9 11] }; ...
                                        { [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3] }];
                        
                if strcmp(stim_mode,'bipolar')
                    sp.cathode_map  = [{ [14 16 18], [2 4 6], [], [8 10 12], [], [], [], [], [] }; ...
                                        { [1/3 1/3 1/3], [1/3 1/3 1/3], [], [1/3 1/3 1/3], [], [], [], [], [] }];
                elseif strcmp(stim_mode,'monopolar')
                    sp.cathode_map  = {{ }};
                end
                
            case 'wireless_stim'
                sp.muscles          = {'FDP','PL'};
%               sp.anode_map        = [{ [], [2 4 6], [], [], [], [], [], [14 16 18], [20 22 24] }; ...
%                                     { [], [1/3 1/3 1/3], [], [], [], [], [], [1/3 1/3 1/3], [1/3 1/3 1/3] }];
                sp.anode_map        = [{ 1, 3 }; ...
                                        { 1, 1 }];
                                
                if strcmp(stim_mode,'bipolar')
                    sp.cathode_map  = [{ 2, 4 }; ...
                                        { 1, 1 }];
                elseif strcmp(stim_mode,'monopolar')
                    sp.cathode_map  = {{ }};
                end
        end
        
    case 'Kevin'
        sp.muscles      = {'FCR1','FCR2','FCU1','FDPr','FDPu','FDS1','FDS2','PT','FCU2','ECU1','ECU2','ECR1','ECR2','EDCu'};        
        % sp.anode_map    
end

% In the wireless stimulator, the following 8 channels are functional:
%     channel       100 ohm load board
%     1              1
%     2              2
%     3              5
%     4              6
%     5              9
%     6              10
%     7              13
%     8              14


sp.EMG_min              = [0.0 0.0]; %repmat( 0.2, 1, numel(sp.muscles));
sp.EMG_max              = [0.6 0.6]; %repmat( 1, 1, numel(sp.muscles));
        
sp.PW_min               = repmat( 0.2, 1, numel(sp.muscles));
sp.PW_max               = repmat( 0.4, 1, numel(sp.muscles));

% even if we do PW-modulated FES, we initialize this for consistency of
% matrix size
sp.amplitude_min        = repmat( 2, 1, numel(sp.muscles));
sp.amplitude_max        = repmat( 6, 1, numel(sp.muscles));  % this is the amplitude for PW-modulated FES

sp.return               = stim_mode;

% port of the serial-usb interface for communicating with the wireless
% stimulator
sp.port_wireless        = 'COM3';


params.bmi_fes_stim_params  = sp;



% get rid of some variables
clear monkey sp emg_pos_in_dec i;



% ------------------------------------------------------------------------
%% Do it!

run_decoder(params);
