% -- fes_lead_char --
% runs through a series of different amplitude and pulse widths for each
% channel of the ripple stimulator. Minimum values are saved by pressing a
% button in a msgbox. Outputs are saved in a local file


%% clear everything, parameters for this monkey
clear all; clc; close all;

% -- Greyson --
monkey = 'Greyson';
ccmid = '17L2';
% Greyson Muscle list
% first group of 16
% electrode = {'FDP2_1','FDP2_2','FCR2_1','FCR2_2','FCU1_1','FCU1_2','FCU2_1','FCU2_2',...
%     'FCR1_1','FCR1_2','FDP1_1','FDP1_2','FDS1_1','FDS1_2','FDS2_1','FDS2_2'};
% % second group of 16
electrode = {'FDS3_1','FDS3_2','PT_1','PT_2','APB_1','APB_2','FPB_1','FPB_2',...
  'Lum_1','Lum_2','fDI_1','fDI_2','EDC3_1','EDC3_2','SUP_1','SUP_2'}
% % Third group of 14
% electrode = {'ECU_1','ECU_2','ECU_3','ECR_1','ECR_2','ECR_3','EDC1_1','EDC1_2',...
%   'EDC2_1','EDC2_2','BI_1','BI_2','TRI_1','TRI_2'}


%% Set up the stimulator etc.
stim_params = stim_params_defaults;
stim_params.elect_list = [1:2:15;2:2:16];
stim_params.amp = 0;
stim_params.pw = 0;
% stim_params.comm_timeout_ms = -1;
% stim_params.pol = 1;

ws = wireless_stim(stim_params);
try 
    curdir = pwd;
    cd(stim_params.path_cal_ws);
    ws.init();
    cd(curdir);
catch
    ws.delete();
    fclose(instrfind)
    disp(datestr(datetime(),'HH:MM:SS:FFF'))
    error('Could not connect to stimulator')
    cd(curdir);
end
% wait until it's set up...
drawnow();


%% Set up cerebus to record everything
% % we're not gonna bother with resetting all of config stuff cause it's a
% % pain. just do it in central ya?
% cbmex('open');
% cbmex('trialconfig',0); % avoid buffering, since we're only gonna putting things in the files
% 
% muscle = 'FPB2';
FN_base = ['E:\Data-lab1\',ccmid,'-',monkey,'\StimData\',datestr(today,'yyyymmdd')];
if ~exist(FN_base)
    mkdir(FN_base)
end

%% -------------------------------------------------------
% Everything in the next few sections is for monopolar. Keep that in
% mind...

%% Set up an excel file to record the values etc.
FNexcel = [FN_base, filesep, datestr(today,'yyyymmdd'),'_',monkey,'_Electrode_Characterization.xlsx']; % set this up in the same folder as the CBmex file
% FNexcel = [FN_base, 'Classification_group2'];

if exist(FNexcel,'file')
    warning('Excel file already exists. We''ll append the data in a new sheet')
end



% xlrange = cell();
for i = 1:1000
    xlrange(i) = cellstr(sprintf('A%i',i));
end
xlrangei = 1;



%% find the desired current at 400 us pulse width
PW = .4;  % 400 us pulse width
amp = [0:.5:6]; % .2:6 mA

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
            continue
        end
        
        [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
        for k = 1:length(stim_cmd)
            ws.set_stim(stim_cmd(k),ch_list{:});
        end
        
        for ii = 1:length(ch_list)
            ws.set_Run(ws.run_cont,ch_list{ii})
        end
        
        pause(.5)

        
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
PW = [0:.01:.4]; % list of pulse widths

SheetName = ['Monopolar_',datestr(now,'dd_mm_yyyy-hh_MM')];
xlswrite('E:\Data-lab1\17L2-Greyson\StimData\20181101\20181101_Greyson_Electrode_Characterization.xlsx',{'Muscle','Threshold','Amplitude'},SheetName,xlrange{1});
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

        stim_params.amp = stim_amps(ii); % set current amplitude
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

        pause(.5) % give us time for the next one
 
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
    

    
    if ishandle(h_low) % did we ever click yes?
        close(h_low)
        xlswrite(FNexcel,{electrode{ii},'N/A',stim_amps(ii)},SheetName,xlrange{ii+1}); % write it to the excel sheet
    else
        xlswrite(FNexcel,{electrode{ii},th,stim_amps(ii)},SheetName,xlrange{ii+1}); % write it to the excel sheet
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




%% ------------------------------------------------------------------
% Everything for the next couple of sections is for bipolar stim. Keep that
% in mind.

%% turn all the electrodes to run continuously setting

stim_params.amp = 0;
stim_params.pw = 0; 
stim_params.elect_list = [1:2:15;2:2:16];

[stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
for k = 1:length(stim_cmd)
    for kk = 1:length(ch_list);
        ws.set_stim(stim_cmd(k),ch_list{kk});
    end
end

ws.set_Run(ws.run_cont,ch_list{:})

%% find the desired current at 400 us pulse width
PW = .4;  % 400 us pulse width
amp = [0:.5:6]; % .2:1.8 mA
stim_params.elect_list = [1:2:15;2:2:16];

% do this for each electrode
for i = 1:length(electrode)
    h_start = msgbox(['Start electrode ' electrode{i}]);
    while ishandle(h_start)
        pause(.01)
    end
    
    h_stim = msgbox('Hit ''ok'' when you feel the top');

    for a = 1:length(amp)
        stim_params.amp = zeros(1,8);
        stim_params.pw = zeros(1,8);
        
        if ishandle(h_stim)
            stim_params.amp(i) = amp(a);
            stim_params.pw(i) = PW; 
            stim_amps(i) = amp(a);

            fprintf('\n%.2f mA\n',amp(a));
        else
            break
        end
        
        [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
        for kk = 1:length(ch_list)
            for k = 1:length(stim_cmd)/2
                ws.set_stim(stim_cmd(k+(kk-1)*length(stim_cmd)/2),ch_list{kk}); %first send the anodes, then the cathodes , capish?
            end
        end
        

        
        pause(.5)

        
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
stim_params.elect_list = [1:2:15;2:2:16];

[stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
for k = 1:length(stim_cmd)
    for kk = 1:length(ch_list);
        ws.set_stim(stim_cmd(k),ch_list{kk});
    end
end


%% set up a vector of all possible amplitudes and pulse widths
PW = [0:.01:.3]; % list of pulse widths

SheetName = ['Bipolar_',datestr(now)];
xlswrite(FNexcel,{'Muscle','Threshold','Amplitude'},SheetName,xlrange{1});
for ii = 1:length(electrode)
    fprintf('%s\n',electrode{ii});

    h_wait = msgbox(['Electrode for ' electrode{ii}]);
    while(ishandle(h_wait))
        drawnow()
    end
    
    h_low = msgbox('Can you feel it?');
    flg_end = false; % do we end the loop?
    
    for jj = 1:length(PW)
        th = PW(jj); % set the threshold anew

        stim_params.amp = zeros(1,8); % empty everything up
        stim_params.pw = zeros(1,8); % empty everything up
        stim_params.pw(ii) = PW(jj); % except for the desired channels
        stim_params.amp(ii) = stim_amps(ii); % load from 



        if ~ishandle(h_low)
            break;
        end
        
        fprintf('%.2f us',PW(jj)); 
        [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
        for kk = 1:length(ch_list)
            for k = 1:length(stim_cmd)/2
                ws.set_stim(stim_cmd(k+(kk-1)*length(stim_cmd)/2),ch_list{kk}); %first send the anodes, then the cathodes , capish?
            end
        end

        % set to run

        drawnow;

        pause(.5) % give us time for the next one
 
    end
    
    % set everything back to zero
    stim_params.amp = 0;
    stim_params.pw = 0;
    [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
    for kk = 1:length(ch_list)
        for k = 1:length(stim_cmd)/2
            ws.set_stim(stim_cmd(k+(kk-1)*length(stim_cmd)/2),ch_list{kk}); %first send the anodes, then the cathodes , capish?
        end
    end

    
    if ishandle(h_low) % did we ever click yes?
        close(h_low)
        xlswrite(FNexcel,{electrode{ii},'N/A',stim_amps(ii)},SheetName,xlrange{ii+1}); % write it to the excel sheet
    else
        xlswrite(FNexcel,{electrode{ii},th,stim_amps(ii)},SheetName,xlrange{ii+1}); % write it to the excel sheet
    end
    
end

% set everything to zero to clean up
stim_params.amp = 0;
stim_params.pw = 0; 
stim_params.elect_list = [1:2:15;2:2:16];

[stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params ); % convert to proper stimulation commands
for kk = 1:length(ch_list)
    for k = 1:length(stim_cmd)/2
        ws.set_stim(stim_cmd(k+(kk-1)*length(stim_cmd)/2),ch_list{kk}); %first send the anodes, then the cathodes , capish?
    end
end





%% Close everything up
% cbmex('fileconfig',FN,'',0); % close  the file
% cbmex('close') %close cbmex
delete(ws) % close the wireless stimulator
fclose(instrfind)