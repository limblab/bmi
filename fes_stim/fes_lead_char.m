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
    curdir = pwd;
    cd(stim_params.path_cal_ws);
    ws.init();
    cd(curdir);
catch
    ws.delete();
    disp(datestr(datetime(),'HH:MM:SS:FFF'))
    error('Could not connect to stimulator')
    cd pwd;
end
% wait until it's set up...
drawnow();

% convert to proper stim commands, run it only once as an initial start
% [stim_cmd,ch_list] = stim_params_to_stim_cmd_ws(stim_params);
% for i = 1:length(ch_list)
%     for ii = 1:length(stim_cmd)
%         ws.set_stim(stim_cmd(ii),ch_list{i});
%     end
% end
% 
% for i = 1:length(ch_list)
%     ws.set_Run(ws.run_once,ch_list{i});
% end
% drawnow()
% 
% ws.set_Run(ws.run_once_go,ch_list)   % run once

%% Set up cerebus to record everything
% % we're not gonna bother with resetting all of config stuff cause it's a
% % pain. just do it in central ya?
% cbmex('open');
% cbmex('trialconfig',0); % avoid buffering, since we're only gonna putting things in the files
% 
% muscle = 'FPB2';
FN_base = 'E:\Data-lab1\12A1-Jango\CerebusData\EMG_stim\20170626\';
% FN = [FN_base, muscle];
% cbmex('fileconfig',FN,'',1) % start recording a file named FN

%% Set up an excel file to record the values etc.
FNexcel = [FN_base, 'Characterization_group1']; % set this up in the same folder as the CBmex file
% FNexcel = [FN_base, 'Classification_group2'];

if exist([FNexcel '.xlsx'],'file')
    error('Excel file already exists. Don''t write over that shiz')
end

% Jango 06202017 group 1
% electrode = {'FCR1_1', 'FCR1_2', 'FCR2_1', 'FCR2_2',...
%     'FCU1_1', 'FCU1_2', 'FCU2_1', 'FCU2_2', 'FDP1_1', 'FDP1_2',...
%     'FDP2_1', 'FDP2_2','FDS1_1', 'FDS1_2', 'FDS2_1', 'FDS2_2'};
% % Jango 06202017 group 2
electrode = {'PT_1', 'PT_2', 'PL_1', 'PL_2' ,...
    'APB_1', 'APB_2', 'FPB_1', 'FPB_2', 'FDS_1', 'FDS_2'};%,...
   % 'EPL_1', ',EPL_2', 'ECU1_1', 'ECU1_2', 'ECU2_1', 'ECU2_2'};



% xlrange = cell();
for i = 1:1000
    xlrange(i) = cellstr(sprintf('A%i',i));
end
xlrangei = 1;


%% find the desired current at 300 us pulse width
PW = .4;  % 400 us pulse width
amp = [1:8]; % 1-7 mA

stim_amps = zeros(16,1); % empty array for each electrode of the desired amps

% do this for each electrode
for i = 1:length(electrode)
    h_start = msgbox(['Start electrode ' electrode{i}]);
    while ishandle(h_start)
        pause(.01)
    end
    
    h_stim = msgbox('Hit ''ok'' when you feel the top');

    for a = 1:length(amp)
        if ishandle(h_stim)
            stim_params.amp = amp(a);
            stim_params.pw = PW; 
            stim_params.elect_list = i;
            stim_amps(i) = amp(a);

            fprintf('\n%.2f\n',amp(a));
        else
            break
        end
        
        [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
        for k = 1:length(stim_cmd)
            ws.set_stim(stim_cmd(k),ch_list{:});
        end
        
        for ii = 1:length(ch_list)
            ws.set_Run(ws.run_cont,ch_list{ii})
        end
        
        pause(2)

        
    end
    
    % reset everything to zeros
    stim_params.amp = 0;
    stim_params.pw = 0; 

    [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
    for k = 1:length(stim_cmd)
        ws.set_stim(stim_cmd(k),ch_list{1});
    end
    
    if ishandle(h_stim) % close it if we never felt the top, yo!
        close(h_stim)
    end
end 


stim_params.amp = 0;
stim_params.pw = 0; 
stim_params.elect_list = [1:2:15,2:2:16];

[stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
for k = 1:length(stim_cmd)
    for kk = 1:length(ch_list);
        ws.set_stim(stim_cmd(k),ch_list{kk});
    end
end

%% set up a vector of all possible amplitudes and pulse widths
PW = [0:.05:.4]; % list of pulse widths

SheetName = 'ThresholdV1_Group2';
xlswrite(FNexcel,{'Muscle','Threshold','Amplitude'},SheetName,xlrange{1});
for ii = 1:length(electrode)
    fprintf('%s\n',electrode{ii});
    stim_params.elect_list = ii;

    h_wait = msgbox(['Electrode for ' electrode{ii}]);
    while(ishandle(h_wait))
        drawnow()
    end
    
    h_low = msgbox('Can you feel it?');
    flg_end = false; % do we end the loop?
    
    for jj = 1:length(PW)
            th = PW(jj); % set the threshold anew

            stim_params.amp = stim_amps; % set current amplitude
            stim_params.pw = PW(jj); % set current pulse width
                        
            if ~ishandle(h_low)
                break;
            end
        
        [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
        fprintf('\n%.2f\n',PW(jj))
            

        for kk = 1:length(stim_cmd)
            ws.set_stim(stim_cmd(kk),ch_list{1});
        end

        % set to run
        ws.set_Run(ws.run_cont,ch_list{1})

        drawnow;

        pause(2) % give us time for the next one
 
    end
    
    stim_params.amp = 0;
    stim_params.pw = 0;
    [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands

    for k = 1:length(ch_list) 
        for kk = 1:length(stim_cmd)
            ws.set_stim(stim_cmd(kk),ch_list{k});
        end
    end
    for ch = 1:length(ch_list)
        ws.set_Run(ws.run_cont,ch_list{ch})
    end
    
    xlswrite(FNexcel,{electrode{ii},th,stim_amps(ii)},SheetName,xlrange{ii+1}); % write it to the excel sheet
    
    if ishandle(h_low) % did we ever click yes?
        close(h_low)
    end
    
end

% set everything to zero to clean up
stim_params.amp = 0;
stim_params.pw = 0; 
stim_params.elect_list = [1:2:15;2:2:16];

[stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
for k = 1:length(stim_cmd)
    for kk = 1:length(ch_list);
        ws.set_stim(stim_cmd(k),ch_list{kk});
    end
end

%% Close everything up
% cbmex('fileconfig',FN,'',0); % close  the file
% cbmex('close') %close cbmex
delete(ws) % close the wireless stimulator
fclose(instrfind)