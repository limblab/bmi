% This script allows you to setup everything to analyze a tDCS/ICMS-only
% experiment 


clear all; close all; clc

% 'ICMS_only' or 'tDCS_exp'
exp_type                = 'tDCS_exp';

% Choose the muscles to look at. If empty, the code will look at all of
% them
atp.muscles             = {'EMG_ECRl'}; % 'EMG_ECR1' 'EMG_ECRl'

% Folder with the data
atp.exp_folder          = '/Users/juangallego/Documents/NeuroPlast/Data/Jango/CerebusData/tDCS/STA_data_2015_07_23';

% The data in each of the files will be split in windows of size
% 'atp.resp_per_win' 
atp.resp_per_win        = 4500;


% -------------------------------------------------------------------------
% Fill the fields with the files

switch exp_type
    case 'ICMS_only'
        atp.baseline_files  = {};
    case 'tDCS_exp'
        % Get the baseline files
        atp.baseline_files  = uigetfile([atp.exp_folder '/*.mat'], 'Pick the Baseline / ICMS files', ...
                                'Multiselect', 'on' );
        % Get the tDCS files
        atp.tDCS_files      =  uigetfile([atp.exp_folder '/*.mat'], 'Pick the tDCS files', 'Multiselect', 'on' );
        % Get the post-tDCS files
        atp.post_tDCS_files =  uigetfile([atp.exp_folder '/*.mat'], 'Pick the post-tDCS files', 'Multiselect', 'on' );
    otherwise
        error('''exp_type'' has to be ''ICMS_only'' or ''tDCS_exp''');
end

% Get current folder, to come back
current_folder          = pwd;
cd(atp.exp_folder);

% -------------------------------------------------------------------------
% Call the function that analyzes and plost the data

tDCS_results            = analyze_tDCS_exp( atp );


% Go back to where you were
cd(current_folder);