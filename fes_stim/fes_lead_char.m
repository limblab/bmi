% -- fes_lead_char --
% runs through a series of different amplitude and pulse widths for each
% channel of the ripple stimulator. Minimums values are saved by pressing a
% button in a msgbox. Outputs are saved in a local file


%% clear everything to start clean
clear all; clc; close all;


%% Set up the stimulator etc.
stim_params = stim_params_defaults;
stim_params.elect_list = [1 16];
stim_params.amp = 5;
stim_params.PW = .1

ws = wireless_stim(stim_params);
try 
    cd(stim_params.path_cal_ws);
    ws.init();
catch
    ws.delete();
    disp(datestr(datetime(),'HH:MM:SS:FFF'))
    error('Could not connect to stimulator')
end
% wait until it's set up...
drawnow();

% convert to proper stim commands, run it only once as an initial start
[stim_cmd,ch_list] = stim_params_to_stim_cmd_ws(stim_params);
for i = 1:length(ch_list)
    for ii = 1:length(stim_cmd)
        ws.set_stim(stim_cmd(ii),ch_list{i});
    end
end

for i = 1:length(ch_list)
    ws.set_Run(ws.run_once,ch_list{i});
end
drawnow()

ws.set_Run(ws.run_once_go,ch_list)   % run once

%% Set up cerebus to record everything
% we're not gonna bother with resetting all of config stuff cause it's a
% pain. just do it in central ya?
cbmex('open');
cbmex('trialconfig',0); % avoid buffering, since we're only gonna putting things in the files

muscle = 'FDSu_2_again';
FN = ['E:\Data-lab1\Wireless_Stimulator\20170309_ElecClassify\', muscle];
cbmex('fileconfig',FN,'',1) % start recording a file named FN

%% Set up an excel file to record the values etc.
FNexcel = 'E:\Data-lab1\Wireless_Stimulator\20170309_ElecClassify\test'; % set this up in the same folder as the CBmex file
sheet = muscle; % wiggity wiggity whaaaat?

% xlrange = cell();
for i = 1:100
    xlrange(i) = cellstr(sprintf('A%i',i));
end
xlrangei = 1;
xlswrite(FNexcel,{'Time' 'Pulse Width', 'Amplitude','Response'},sheet,xlrange{xlrangei});



%% set up a vector of all possible amplitudes and pulse widths
PW = [0:.1:.4]; % list of pulse widths
amp = [2:2:6]; % list of amplitudes

[PW,amp] = meshgrid(PW,amp); % meshgrids
PW = PW(:); % turn back to vector
amp = amp(:); % same here
rn = (randperm(length(PW)));
PW = PW(rn);
amp = amp(rn);

for j = 1:length(PW)
    xlrangei = xlrangei+1;
    stim_params.amp = amp(j); stim_params.pw = PW(j); % run through amps and PWs
    [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
    
    for i = 1:length(ch_list) 
        for ii = 1:length(stim_cmd)
            ws.set_stim(stim_cmd(ii),ch_list{i});
        end
    end
    
%     only turn this on for debugging. We want to run blind to do a proper
%     psychometric curve
%     fprintf('PWM: %.2f amp: %.2f \n',PW(j),amp(j)); 
    
    % set to run once
    for i = 1:length(ch_list)
        ws.set_Run(ws.run_once,ch_list{i})
    end
    ws.set_Run(ws.run_once_go,ch_list);
    t = cbmex('time');
    drawnow;
    
    resp = input('Quality of response? [N(othing) P(oor) G(ood) E(xcellent)]','s');
    xlswrite(FNexcel,{t,PW(j),amp(j),resp},sheet,xlrange{xlrangei});
    
    pause(2) % give us time for the next one
    
end

%% Close everything up
cbmex('fileconfig',FN,'',0); % close  the file
cbmex('close') %close cbmex
delete(ws) % close the wireless stimulator