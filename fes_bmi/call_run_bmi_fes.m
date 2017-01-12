clear all; close all; clc;


%% Some high level stuff

% Who is in the lab?
monkey                  = 'Jango'; % 'Kevin' 'Jango' 'Fish'
task                    = 'WF'; % 'MG_PT'; % 'MG_PG', 'WF', 'WM'   %This is the task you trained on

% List of muscles for the decoder
% emg_list_4_dec          = {'FCRr', 'FCRu', 'FCU1', 'FDPu', 'FDS2', 'PL', 'PT'}; % Fish grasping 
emg_list_4_dec          = {'FCRr', 'FCUu', 'FDPr', 'FDPu', 'FDSu', 'FDS', 'APB','PL'}; % Jango 12/11
% emg_list_4_dec          = {'FCRr', 'FCUu', 'FDPr', 'FDPu', 'FDSu', 'PL', 'FDS'}; 
% emg_list_4_dec          = {'FCRr', 'FDPr', 'FDPu', 'FDSu', 'PL', 'FDS'}; 

% Mapping of EMGs in the decoder to the electrodes that will be stimulated.
% First row lists which EMG, second row lists which muscle will be
% stimulated. The EMG prediction (1,n) will be used to control the
% stimulation of muscles in (2,n)
% sp.EMG_to_stim_map      = [{'FCRr', 'FCRu', 'FCU1', 'FDPu', 'FDS2', 'PL', 'PT'}; ...
%                             {'FCRr', 'FCRu', 'FCU1', 'FDPu', 'FDS2', 'PL', 'PT'}];
sp.EMG_to_stim_map      = [{'FCRr', 'FCUu', 'FDPr', 'FDPu', 'FDSu', 'FDS', 'APB','PL'}; ...
                            {'FCRr', 'FCUu', 'FDPr', 'FDPu', 'FDSu', 'FDS', 'APB','PL'}]; % Jango 12/11
% sp.EMG_to_stim_map      = [{'FCRr', 'FCUu', 'FDPr', 'FDPu', 'FDSu', 'FDS', 'PL'}; ...
%                             {'FCRr', 'FCUr', 'FDPr', 'FDPu', 'FDSu', 'FDSu', 'PL'}];
% sp.EMG_to_stim_map      = [{'FCRr', 'FDPr', 'FDPu', 'FDSu', 'FDS', 'PL'}; ...
%                             {'FCRr', 'FDPr', 'FDPu', 'FDSu', 'FDSu', 'PL'}];

                        
% Monopolar or bipolar stimulation
stim_mode               = 'monopolar'; % 'bipolar'; 'monopolar'

% Which stimulator we are using: the wireless stimulator ('wireless_stim')
% or the grapevine ('stimulator'). If you choose 'catch' it will do online
% predictions without stimulating; we don't need to have a stimulator
% conencted for this
params.output           = 'stimulator'; % 'wireless_stim'; 'catch'; 'stimulator';

% file name
params.save_name        = [monkey, '_' task '_MUblock_']; % can call it _MURblock_'
if strcmpi(params.output,'catch')
    params.save_name    = [params.save_name, 'catch_'];
end


% Run the code without the stimulator? 
% --if we are in 'catch' this field doesn't matter
stimulator_plugged_in   = true;

% True: use monkey's current neural activity, or False: read neural data from file 
params.online           = true;

% Percentage of catch trials
sp.perc_catch_trials    = 15;


% Save the data
params.save_data        = true;

% and folder name - change accordingly!
if ispc
	params.save_dir     = 'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES';
elseif ismac
    params.save_dir     = '/Users/juangallego/Desktop/Test';
end


%% ------------------------------------------------------------------------
% Build the neuron-to-EMG decoder

% Raw data file for the decoder
if ismac
    file4decoder        = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/CerebusData/Plasticity/20150320_Jango_WF_001.nev';
elseif ispc
    file4decoder        = 'E:\Data-lab1\12H2-Fish\Cerebus Data\CerebusData\InLab\07-25-2016\Fish-InLabWired-WF-KB-20160725001.ccf';
%     file4decoder        = 'E:\Data-lab1\12H2-Fish\Cerebus Data\CerebusData\InLab\Jango_Treats_07272016_SN_002.nev';
end
 

% order of the static non-linearity
poly_order              = 2;

% Build decoder
N2E                     = build_emg_decoder_from_nev( file4decoder, task, emg_list_4_dec, poly_order );



% ------------------------------------------------------------------------
%% If want to use an existing decoder
if ismac
    dec_file            = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/Decoders/20150320_Jango_WF_001_binned_Decoder.mat';
elseif ispc
    dec_file            = 'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES\20160727\Jango_Treats_07272016_SN_002_N2E_Decoder.mat';
end

% If N2E is a file, this will load it
if ~isstruct(dec_file)
    N2E                 = LoadDataStruct(dec_file);
    
    % Find the muscles which EMGs we want to decode in the decoder file,
    % and get rid of the muscles we don't care about (i.e. not included in
    % emg_list_4_dec)
    if isfield(N2E, 'H')
        emg_pos_in_dec  = zeros(1,numel(emg_list_4_dec));
        for i = 1:length(emg_pos_in_dec)
            % don't look at EMGs with label length longer than the label
            % you are looking for because it can give an error (e.g., if
            % you are looking for the position of FCR and there is an FCRl
            % and an FCR matlab will try to return two values)
            indx_2_look = [];
            for ii = 1:length(N2E.outnames)
                if length(N2E.outnames{ii}) == length(emg_list_4_dec{i}) 
                    indx_2_look = [indx_2_look, ii];
                end
            end
            % find the index of the EMGs in the decoder
            emg_pos_in_dec(1,i) = indx_2_look( find( strncmp(N2E.outnames(indx_2_look),...
                                    emg_list_4_dec(i),length(emg_list_4_dec{i})) ));
        end
        % Get rid of the other muscles in the decoder
        N2E.H           = N2E.H(:,emg_pos_in_dec);
        N2E.outnames    = emg_list_4_dec;
    else
        error('Invalid neuron-to-emg decoder');
    end
end


% ------------------------------------------------------------------------
%% To use offline data instead of online recordings from the monkey

% load the file we will be replaying
if ~params.online
    if ismac
        params.offline_data = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/BinnedData/behavior plasticity/20150320_Jango_WF_001_binned.mat';
    elseif ispc
%        params.offline_data = 'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES\20160313\Jango_MG_PG_20160313_T3_001_bin.mat';
        params.offline_data = 'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES\20160221-recordings only\Jango_20160221_WF_R10T4_001_bin.mat';
    end
end

% by default, always save the data in an online experiment
if params.online && ~params.save_data
    warning('I assume you forgot to set the option save_data = true, since this is an online experiment, right? -- I have set it for you');
    params.save_data    = true;
end

% and don't save the offline ones
if ~params.online
    params.save_data    = false;
end


% ------------------------------------------------------------------------
%% Define some BMI parameters


% Assign the decoder we loaded
params.neuron_decoder   = N2E;
% decoder type is neurons-to-emg
params.mode             = 'emg_only';
% update the number of EMGs that will be predicted
params.n_emgs           = numel(emg_list_4_dec);
% for plotting
params.display_plots    = true;


% ------------------------------------------------------------------------
%% Define sitmulation parameters

% here we tell the code which muscles are connected to which channels in
% the stimulator. We also define whether we do monopolar or bipolar
% stimulation
switch monkey
    
    % For Jango, this is for the switchboard that Ripple made for the
    % wireless stimulator
    case 'Jango'
        
       sp.muscles                  = {'FCRr', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDSu', 'PL', 'APB'};
%         sp.muscles                  = {'FCRr', 'FCUr', 'FDPr', 'FDPu', 'FDSu', 'FDSno', 'APB'};
%        sp.muscles                  = {'FCRr', 'FCUr', 'FDPr', 'FDPu', 'FDSu', 'FDSu', 'PL'};        
%         sp.muscles                  = {'FCRr', 'FDPr', 'FDPu', 'FDSu', 'FDSu', 'PL'};        
        switch params.output
            % for the grapevine
            case 'stimulator' 
                sp.anode_map        = [{ [3 5 7], [9 11 13], [15 17 19], [21 23 25], [27 29 31], ...
                                        [2 4 6], [8 10 12], [14 16 18] }; ...
                                        { [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], ...
                                        [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3] }];

                % define the cathodes; empty for bipolar
                if strcmp(stim_mode,'bipolar')
%                     sp.cathode_map  = [{ 2, 4, 6 }; ... 
%                                         { 1, 1, 1 }]; %bipolar not set
%                                                       up yet for 
%                                                       grapevine
                elseif strcmp(stim_mode,'monopolar')
                    sp.cathode_map  = {{ }};
                end
            % for the wireless stimulator
            case 'wireless_stim'
                sp.anode_map        = [{ 1, 2, 3, 4, 5, 6, 7, 8 }; ...
                                        { 1, 1, 1, 1, 1, 1, 1, 1 }];
%                 sp.anode_map        = [{ 1, 3, 5, 7, 9, 11, 13 }; ...
%                                         { 1, 1, 1, 1, 1, 1, 1 }];
%                 sp.anode_map        = [{ 1, 5, 7, 9, 11, 13 }; ...
%                                         { 1, 1, 1, 1, 1, 1 }];
                % define the cathodes; empty for bipolar
                if strcmp(stim_mode,'bipolar')
%                     sp.cathode_map  = [{ 2, 4, 6, 8, 10, 12, 14, 16 }; ...
%                                         { 1, 1, 1, 1, 1, 1, 1, 1 }];
%                     sp.cathode_map  = [{ 2, 4, 6, 8, 10, 12, 14 }; ...
%                                         { 1, 1, 1, 1, 1, 1, 1 }];
%                     sp.cathode_map  = [{ 2, 6, 8, 10, 12, 14 }; ...
%                                         { 1, 1, 1, 1, 1, 1 }];
                elseif strcmp(stim_mode,'monopolar')
                    sp.cathode_map  = {{ }};
                end
        end
    
       case 'Fish'
        
       sp.muscles                  = {'FCRr', 'FCRu', 'FCU2', 'FDPu', 'FDS2', 'PL', 'PT', 'SUP', 'EDC', 'Brad', 'ECUr', 'ECUu', 'ECRb', 'EDC'};
%         sp.muscles                  = {'FCRr', 'FCUr', 'FDPr', 'FDPu', 'FDSu', 'FDSno', 'APB'};
%        sp.muscles                  = {'FCRr', 'FCUr', 'FDPr', 'FDPu', 'FDSu', 'FDSu', 'PL'};        
%         sp.muscles                  = {'FCRr', 'FDPr', 'FDPu', 'FDSu', 'FDSu', 'PL'};        
        switch params.output
            % for the grapevine
            case 'stimulator' 
                sp.anode_map        = [{ [3 5 7], [9 11 13], [15 17 19], [21 23 25], [27 29 31], ...
                                        [2 4 6], [8 10 12], [14 16 18] }; ...
                                        { [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], ...
                                        [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3] }];

                % define the cathodes; empty for monopolar
                if strcmp(stim_mode,'bipolar')
                    sp.cathode_map  = [{ 2, 4, 6 }; ...
                                        { 1, 1, 1 }];
                elseif strcmp(stim_mode,'monopolar')
                    sp.cathode_map  = {{ }};
                end
            % for the wireless stimulator
            case 'wireless_stim'
                sp.anode_map        = [{ 1, 2, 3, 4, 5, 6, 7, 8 }; ...
                                        { 1, 1, 1, 1, 1, 1, 1, 1 }];
%                 sp.anode_map        = [{ 1, 3, 5, 7, 9, 11, 13 }; ...
%                                         { 1, 1, 1, 1, 1, 1, 1 }];
%                 sp.anode_map        = [{ 1, 5, 7, 9, 11, 13 }; ...
%                                         { 1, 1, 1, 1, 1, 1 }];
                % define the cathodes; empty for bipolar
                if strcmp(stim_mode,'bipolar')
%                     sp.cathode_map  = [{ 2, 4, 6, 8, 10, 12, 14, 16 }; ...
%                                         { 1, 1, 1, 1, 1, 1, 1, 1 }];
%                     sp.cathode_map  = [{ 2, 4, 6, 8, 10, 12, 14 }; ...
%                                         { 1, 1, 1, 1, 1, 1, 1 }];
%                     sp.cathode_map  = [{ 2, 6, 8, 10, 12, 14 }; ...
%                                         { 1, 1, 1, 1, 1, 1 }];
                elseif strcmp(stim_mode,'monopolar')
                    sp.cathode_map  = {{ }};
                end
        end
        
        
        
    case 'Kevin'
        sp.muscles      = {'FCR1','FCR2','FCU1','FDPr','FDPu','FDS1','FDS2','PT','FCU2','ECU1','ECU2','ECR1','ECR2','EDCu'};        
        % sp.anode_map    
end


% ------------------------------------------------------------------------
%% Define parameters for the controller

% The controller maps the EMG into PW or amplitude using a proportional law
% When doing PW-modulated FES, the stim amplitude is fixed to
% amplitude_max, and when doing amplitude-modulated FES, to PW_max
% sp.EMG_min              = [.1 .1 .1 .1 .1 .1 .1];
% sp.EMG_max              = [.9 .9 .9 .9 .9 .9 .9];
% sp.EMG_min              = [.1 .1 .1 .1 .1 .1 .1 .1];
% sp.EMG_min              = [.15 .15 .15 .15 .1 .1 .1 .15];
sp.EMG_min              = [.15 .2 .2 .2 .15 .15 .15 .2];
% sp.EMG_min              = [.3 .3 .3 .3 .3 .3 .3 .3];
% sp.EMG_max              = [.6 .6 .6 .6 .6 .6 .6 .6];
% sp.EMG_max              = [.7 .7 .7 .7 .7 .7 .7 .7];
% sp.EMG_max              = [.8 .8 .8 .8 .8 .8 .8 .8];
% sp.EMG_min              = [.1 .1 .1 .1 .1 .1];
sp.EMG_max              = [.9 .9 .9 .9 .9 .9 .9 .9];
        
sp.PW_min               = [0 .15 .05 .1 .05 .1 .05 .05]; % repmat( 0.05, 1, numel(sp.muscles));
sp.PW_max               = [0 .3 .3 .3 .3 .3 .3 .3];% repmat( 0.4, 1, numel(sp.muscles));
% sp.PW_max               = [0 .4 .4 .4 .4 .4 .4 .4];% repmat( 0.4, 1, numel(sp.muscles));
% sp.PW_min               = [.05 .15 .05 .05 .01 .01 .05]; % repmat( 0.05, 1, numel(sp.muscles));
% sp.PW_max               = [.4 .4 .4 .4 .4 .4 .4];% repmat( 0.4, 1, numel(sp.muscles));
% sp.PW_min               = [.05 .05 .05 .01 .01 .05]; % repmat( 0.05, 1, numel(sp.muscles));
% sp.PW_max               = [.4 .4 .4 .4 .4 .4];% repmat( 0.4, 1, numel(sp.muscles));

sp.amplitude_min        = repmat( 0, 1, numel(sp.muscles));
% sp.amplitude_max        = [0 4 4 4 4 4 4 2];  % this is the max amplitude for PW-modulated FES
sp.amplitude_max        = [0 6 6 4 6 4 6 4];  % this is the max amplitude for PW-modulated FES

% sp.amplitude_max        = [6 6 6 6 6 6];  % this is the max amplitude for PW-modulated FES

% set up the return mode
sp.return               = stim_mode;

% port of the serial-usb interface for communicating with the wireless
% stimulator
if strncmp(params.output,'wireless_stim',13)
    sp.port_wireless    = 'COM3';
end


% pass the stimulation parametesr to the params struct
params.bmi_fes_stim_params  = sp;

% ------------------------------------------------------------------------
%% Load settings from previous session
load('');   % Filename for settings

% ------------------------------------------------------------------------
%% Save settings for future usage
save('',params);  % fill in file name to save settings


% ------------------------------------------------------------------------
%% Do it!

run_bmi_fes(params);


