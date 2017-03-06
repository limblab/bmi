% -- fes_lead_char --
% runs through a series of different amplitude and pulse widths for each
% channel of the ripple stimulator. Minimums values are saved by pressing a
% button in a msgbox. Outputs are saved in a local file

%% Set up the stimulator etc.
params = stim_params_defaults;

ws = wireless_stim(params);
try 
    cd(stim_params.path_cal_ws);
    ws.init();
catch
    ws.delete();
    disp(datestr(datetime(),'HH:MM:SS:FFF'))
end
% wait until it's set up...
drawnow();

% convert to proper stim commands, run it only once as an initial start
[stim_cmd,ch_list] = stim_params_to_stim_cmd_ws(stim_params);
for i = 1:length(ch_lest)
    for ii = 1:length(stim_cmd)/2
        ws.set_stim(stim_cmd(ii+(i-1)*length(stim_cmd)/2),ch_list{i});
    end
end

for i = 1:length(ch_list)
    ws.set_Run(ws.run_once,ch_list{i});
end
drawnow()

ws.set_Run(ws.run_once_go,stim_params.elect_list)   % run once

% run through each channel one by one for 