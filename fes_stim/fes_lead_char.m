% -- fes_lead_char --
% runs through a series of different amplitude and pulse widths for each
% channel of the ripple stimulator. Minimums values are saved by pressing a
% button in a msgbox. Outputs are saved in a local file

%% Set up the stimulator etc.
stim_params = stim_params_defaults;
stim_params.elect_list = [1 16];
stim_params.amp = 5;

ws = wireless_stim(stim_params);
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

ws.set_Run(ws.run_once_go,ch_list)   % run once

%% Set up cerebus to record everything
% we're not gonna bother with resetting all of config stuff cause it's a
% pain. just do it in central ya?
cbmex('open');
cbmex('trialconfig',0); % avoid buffering, since we're only gonna putting things in the files

FN = '';
cbmex('fileconfig',FN,[],1) % start recording a file named FN

%% Set up an excel file to record the values etc.
FNexcel = ''; % set this up in the same folder as the CBmex file
sheet = ''; % wiggity wiggity whaaaat?

xlrange = ['A1','B1','C1','D1','E1','F1','G1','H1','I1','J1','K1','L1','M1','N1',...
    'O1','P1','Q1','R1','S1','T1','U1','V1','W1','X1','Y1','Z1','AA1'];
xlrangei = 1;
xlswrite(FNexcel,{'Time' 'Pulse Width', 'Amplitude','Response'},sheet,xlrange(xlrangi));



%% set up a vector of all possible amplitudes and pulse widths
PW = [.1:.2:.9]; % list of pulse widths
amp = [2:2:6]; % list of amplitudes

[PW,amp] = meshgrid(PW,amp); % meshgrids
PW = PW(:); % turn back to vector
amp = amp(:); % same here

for j = 1:length(PW)
    xlrangi = xlrangi+1;
    stim_params.amp = amp(j); stim_params.pw = PW(j); % run through amps and PWs
    [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
    
    for i = 1:length(ch_list) 
        for ii = 1:length(stim_cmd)
            ws.set_stim(stim_cmd(ii),ch_list{i});
        end
    end
    
    
    % set to run once
    for i = 1:length(ch_list)
        ws.set_Run(ws.run_once,ch_list{i})
    end
    ws.set_Run(ws.run_once_go,ch_list);
    t = cbmex('time');
    drawnow;
    
    resp = input('Quality of response? [P(oor) G(ood) E(xcellent)]','s');
    xlswrite(FNexcel,{t,PW(j),amp(j),resp},sheet,xlrange(xlrangi));
    
    pause(1) % give us time for the next one
    
end

%% Close everything up

cbmex('close')
delete(ws)