% -- fes_lead_char --
% runs through a series of different amplitude and pulse widths for each
% channel of the ripple stimulator. Minimum values are saved by pressing a
% button in a msgbox. Outputs are saved in a local file


%% clear everything to start clean
clear all; clc; close all;


%% Set up the stimulator etc.
stim_params = stim_params_defaults;
stim_params.elect_list = [1:2:15;2:2:16];
stim_params.amp = 2.5;
stim_params.PW = .1;

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
% % we're not gonna bother with resetting all of config stuff cause it's a
% % pain. just do it in central ya?
% cbmex('open');
% cbmex('trialconfig',0); % avoid buffering, since we're only gonna putting things in the files
% 
% muscle = 'FPB2';
FN_base = 'Z:\data\Jango_12a1\ElectrodeCharacterization\20170320\';
% FN = [FN_base, muscle];
% cbmex('fileconfig',FN,'',1) % start recording a file named FN

%% Set up an excel file to record the values etc.
FNexcel = [FN_base, 'Classification']; % set this up in the same folder as the CBmex file
% sheet = muscle; % wiggity wiggity whaaaat?

electrode = {'FCRr_1', 'FCRr_2', 'FCUr_1', 'FCUr_2', 'FCUu_1', 'FCUu_2',...
    'FDPr_1', 'FDPr_2', 'FDSr_1', 'FDSr_2', 'FDSu_1', 'FDSu_2', 'PL_1', 'PL_2'...
    'FDS_1', 'APB_2'};

% xlrange = cell();
for i = 1:1000
    xlrange(i) = cellstr(sprintf('A%i',i));
end
xlrangei = 1;
% xlswrite(FNexcel,{'Time' 'Pulse Width', 'Amplitude','Response'},sheet,xlrange{xlrangei});



%% set up a vector of all possible amplitudes and pulse widths
PW = [0:.01:.3]; % list of pulse widths
amp = [4,6,8]; % list of amplitudes


[PW,amp] = meshgrid(PW,amp); % meshgrids
PW = PW(:); % turn back to vector
amp = amp(:); % same here
% rn = (randperm(length(PW)));
% PW = PW(rn);
% amp = amp(rn);

xlrangei = 1;
xlswrite(FNexcel,{'Muscle','Pulse Width', 'Amplitude'},'Low',xlrange{xlrangei});
xlswrite(FNexcel,{'Muscle','Pulse Width', 'Amplitude'},'High',xlrange{xlrangei});
for ii = 0:4*length(electrode)-1
    fprintf('%c',electrode{mod(ii,16)+1});
    h_low = msgbox('can you feel it?'); % set up a msgbox for the minimum
    stim_params.elect_list = mod(ii,16)+1;
    xlrangei = xlrangei+1;
    for j = 1:length(PW)
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

        % set to run
        for i = 1:length(ch_list)
            ws.set_Run(ws.run_cont,ch_list{i})
        end
%         ws.set_Run(ws.run_once_go,ch_list);
%         t = cbmex('time');
        drawnow;

        if ~exist(h_low)&&~exist(h_hi)
            h_hi = msgbox('I have seen the top!')
            xlswrite(FNexcel,{electrode{mod(ii,16)+1},PW(j),amp(j)},'Low',xlrange{xlrangei});
        elseif ~exist(h_hi)
            xlswrite(FNexcel,{electrode{mod(ii,16)+1},PW(j),amp(j)},'High',xlrange{xlrangei});
        end

        pause(1) % give us time for the next one
    end
end

%% Close everything up
% cbmex('fileconfig',FN,'',0); % close  the file
% cbmex('close') %close cbmex
delete(ws) % close the wireless stimulator