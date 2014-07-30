function params = measure_force_offsets(params)
% function measure_force_offsets()
% Take a measurement of the force handle while it's being unused to get the
% offsets before a recording session, and save to
% '\\citadel\data\TestData\force_offset_cal.dat'
% Drawing from 'decoder_test.m', but with a hacked 'params' variable
current_location = mfilename('fullpath');
[current_folder,~,~] = fileparts(current_location);
cd(current_folder)
add_these = strfind(current_folder,'\');
add_these = current_folder(1:add_these(end)-1);
addpath(genpath(add_these))
clearxpc

calibration_pause = 2; % seconds to collect data across
%% Initialize 'params'
% Only initialize required values.
params_2.online = 1;
params_2.output = 'xpc';
params_2.display_plots = 0;
params_2.save_data = 0;

%% Initialize xPC connection
xpc = open_xpc_udp(params_2);
% handles = setup_display_plots(params_2);
% handles = get_new_filename(params_2,handles);
handles = [];
handles = start_cerebus_stream(params_2,handles,xpc);

%% Get data
A = cbmex('trialconfig',1);
% if ~A, disp('Not recording. Why?'); end
pause(calibration_pause); % Let data accumulate in buffer
[spike_data,~,continuous_data] = cbmex('trialdata',1);
cbmex('close');

%% Extract data
chanNames = spike_data(:,1);
continuous_data(:,1) = chanNames([continuous_data{:,1}]); % Replace chan numbers with names
dataColumn = 3; % Column in 'continuous_data' that contains data values (no need to keep chan names or sampling rates)
handleforce = continuous_data(strncmp(continuous_data(:,1),'ForceHandle',11),dataColumn); % Only take force data - 'ForceHandle[1-6]' - not EMGs
mean_forces = cellfun(@mean, handleforce, 'uni', 0); % Calculate mean value of each
mean_forces = cell2mat(mean_forces(:)'); % Convert cell to row vector

% Sanity check
force_diff = cellfun(@diff, handleforce, 'uni', 0);
mean_diff = cellfun(@mean, force_diff, 'uni', 0);
mean_diff = cell2mat(mean_diff(:)');
disp('Mean "diff" of calibration values:');
disp(mean_diff);

% Fx,Fy,scaleX,scaleY from ATI calibration file:
% \\citadel\limblab\Software\ATI FT - March2011\Calibration\FT7520.cal
% fhcal = [Fx;Fy]./[scaleX;scaleY]
% force_offsets acquired empirically by recording static
% handle.
params.fhcal = [-0.0129 0.0254 -0.1018 -6.2876 -0.1127 6.2163;...
         -0.2059 7.1801 -0.0804 -3.5910 0.0641 -3.6077]'./1000;
params.rotcal = [-1 0; 0 1];
params.force_offsets = mean_forces;
params.Fy_invert = 1;
    
clearxpc
