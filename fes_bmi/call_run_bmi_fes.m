clear all; close all; clc;


%% Some high level stuff

% Who is in the lab?
monkey                  = 'Jango'; % 'Kevin'
task                    = 'MG_PG'; % 'MG_PG', 'WF', 'WM'

% List of muscles for the decoder
% emg_list_4_dec          = {'FCRu', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDS'};
emg_list_4_dec          = {'FCRu', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDS'};

% Mapping of EMGs in the decoder to Electrodes in the Monkey
% sp.EMG_to_stim_map      = [{'FCRu', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDS'}; ...
%                             {'FCRu', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDSu'}];
sp.EMG_to_stim_map      = [{'FCRu', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDS'}; ...
                            {'FCRu', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDSu'}];


% Monopolar or bipolar stimulation
stim_mode               = 'bipolar'; % 'bipolar'; 'monopolar'

% Grapevine or wireless stimulator
params.output           = 'wireless_stim'; % 'catch'; 'stimulator'; 'wireless_stim';

% file name
params.save_name        = [monkey, '_' task '_MUblock_'];
if strcmpi(params.output,'catch')
    params.save_name    = [params.save_name, 'catch_'];
end


% Run the code without the stimulator?
stimulator_plugged_in   = true;

% Do an online experiment, or read neural data from file
params.online           = true;

% Percentage of catch trials
sp.perc_catch_trials    = 10;


% Save the data
params.save_data        = true;

% and folder name
if ispc
	params.save_dir     = 'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES';
elseif ismac
    params.save_dir     = '/Users/juangallego/Desktop/Test';
end


% ------------------------------------------------------------------------
%% Build the neuron-to-EMG decoder

% % Raw data file for the decoder
% if ismac
%     file4decoder        = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/CerebusData/Plasticity/20150320_Jango_WF_001.nev';
% elseif ispc
% %     file4decoder        = 'E:\Data-lab1\12A1-Jango\CerebusData\BMIFES\20151117\Jango_20151118_isoWF_001.nev';
% %     file4decoder        = 'E:\Data-lab1\12A1-Jango\CerebusData\BMIFES\20151117\Jango_20151125_isoWF_003.nev';
% %     file4decoder        = 'E:\Data-lab1\TestData\_to_delete\datafile002.nev'
%     file4decoder        = 'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES\20160319\Jango_MG_PG_20160319_T3_001.nev';
% end
%  
% 
% % order of the static non-linearity
% poly_order              = 3;
% 
% % Build decoder
% N2E                     = build_emg_decoder_from_nev( file4decoder, task, emg_list_4_dec, poly_order );



% ------------------------------------------------------------------------
%% If you want to use an existing decoder
if ismac
    dec_file            = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/Decoders/20150320_Jango_WF_001_binned_Decoder.mat';
elseif ispc
%    dec_file            =
%    'E:\Data-lab1\12A1-Jango\CerebusData\BMIFES\20151125\Jango_20151125_isoWF_003_binned_Decoder.mat';
%    dec_file            =
%    'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES\20160313\Jango_MG_PG_20160313_T3_001_decoder.mat';
    dec_file            = 'E:\Data-lab1\12A1-Jango\CerebusData\BMI-FES\20160319\Jango_MG_PG_20160319_T3_001_bin_Decoder.mat';
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
        
%        sp.muscles                  = {'FCRu', 'FCUr', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDSu', 'APB'};
%        sp.muscles                  = {'FCRu', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDSu'};
        sp.muscles                  = {'FCRu', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDSu' };
        
        switch params.output
            % for the grapevine
            case 'stimulator' 
%               sp.anode_map        = [{ [], [2 4 6], [], [], [], [], [], [14 16 18], [20 22 24] }; ...
%                                       { [], [1/3 1/3 1/3], [], [], [], [], [], [1/3 1/3 1/3], [1/3 1/3 1/3] }];
                sp.anode_map        = [{ 1, 3, 5, }; ...
                                        { 1, 1, 1 }];

                % define the cathodes; empty for bipolar
                if strcmp(stim_mode,'bipolar')
%                     sp.cathode_map  = [{ 2, 4, 6, 8, 10, 12, 14, 16}; ...
%                                         { 1, 1, 1, 1, 1, 1, 1, 1 }];
                    sp.cathode_map  = [{ 2, 4, 6 }; ...
                                        { 1, 1, 1 }];
                elseif strcmp(stim_mode,'monopolar')
                    sp.cathode_map  = {{ }};
                end
            % for the wireless stimulator
            case 'wireless_stim'
%                 sp.anode_map        = [{ 1, 3, 5, 7, 9, 11, 13, 15 }; ...
%                                         { 1, 1, 1, 1, 1, 1, 1, 1 }];
%                 sp.anode_map        = [{ 1, 3, 7, 9, 11, 13 }; ...
%                                         { 1, 1, 1, 1, 1, 1 }];
                sp.anode_map        = [{ 1, 3, 5, 7, 9, 13 }; ...
                                        { 1, 1, 1, 1, 1, 1 }];
                % define the cathodes; empty for bipolar
                if strcmp(stim_mode,'bipolar')
%                     sp.cathode_map  = [{ 2, 4, 8, 10, 12, 14 }; ...
%                                         { 1, 1, 1, 1, 1, 1,  }];
                    sp.cathode_map  = [{ 2, 4, 6, 8, 10, 14 }; ...
                                        { 1, 1, 1, 1, 1, 1 }];
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
sp.EMG_min              = [.4 .2 .3 .3 .3 .3];
sp.EMG_max              = [1 .7 .9 .9 .9 .9];
        
sp.PW_min               = [.05 0 .05 .05 .05 .05]; % repmat( 0.05, 1, numel(sp.muscles));
sp.PW_max               = [.4 0 .4 .4 .4 .4];% repmat( 0.4, 1, numel(sp.muscles));

sp.amplitude_min        = repmat( 2, 1, numel(sp.muscles));
sp.amplitude_max        = repmat( 6, 1, numel(sp.muscles));  % this is the amplitude for PW-modulated FES

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
%% Do it!

run_bmi_fes(params);


