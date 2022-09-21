function PeriodicRecording(varargin)
% --- PeriodicRecording(varargin) ---
%   Sets up recordings for longs periods of time, starts recording into new
%   file every X minutes (default 15). Optional inputs should be put in as
%   name/value pairs. Hit "OK" to stop recording
%
%
% Optional Inputs [Default]:
%   RecLen      Length of each file, in minutes [15 minutes)
%   emgIP       IP address for DSPW recording system, if recording that
%   BaseFN      Filename. If not given, will open a series of recording
%               dialogues
%
%
%
% Example:
%   I want to record file "C:\Fake\AintReal\20170608_Pablo_InCage_xxx.nev"
%   for 2 hours in 10 minute segments.
%
%   PeriodicRecording('BaseFN','C:\Fake\AintReal\20170608_Pablo_InCage',...
%       'RecLen',10,'NumFile',12);
%
%
% KLB 2017
% updated 2022

%% Going to mandate the GUI at the moment
% % The following code would allow for you to run the function as a script,
% % but I think for the moment I'll just have everything passed by the GUI
%
%     % Set the defaults
%     RecLen = 15; % 15 min
%     emgIP = 0; % assume we're not recording EMGs
%     BaseFN = '';
%     gopro_flag = false; % do we need to sync gopro stuff?
%     ximea_flag = false; % do we need to sync ximea/imagesource stuff?
%     thirtyk = false; % recording at 30 khz?
%     
% 
%     % parse all the name-value optional inputs
%     for v = 1:2:nargin
%         switch varargin{v}
%             case 'RecLen'
%                 RecLen = varargin{v+1};
%             case 'NumFile'
%                 emgIP = varargin{v+1};
%             case 'BaseFN'
%                 BaseFN = varargin{v+1};
%             case 'XimeaFlag'
%                 ximea_flag = varargin{v+1};
%             case 'GoProFlag'
%                 gopro_flag = varargin{v+1};
%         end
%     end
% 
%     % set up the filename and recording location 
%     [file_dir,file_name,ext] = fileparts(BaseFN);
%     
%     % construct the file path if needed
%     if isempty(file_name)
%         file_name = SettingsDialog;
%     end
% 
%     % if no directory was specified or if the file doesn't exist...
%     if ~exist(file_dir,'dir')
%         file_dir = uigetdir('C:/','Recording Save Location');
%     end
%     
    UserData = SettingsDialog % load in default info
    file_dir = uigetdir('C:/','Recording Save Location');
    if file_dir == 0
        file_dir = pwd;
    end
    
    % And recompile it all into BaseFN
    UserData.filename = strjoin({file_dir, UserData.filename}, filesep);
    
    % filename suffix -- for each iteration
    UserData.I = 0;

    % set up the timer
    t = timer(...
            'Period',           UserData.RecLen,...
            'ExecutionMode',    'fixedrate',...
            'TimerFcn',         @PRTimerFcn,...
            'StartFcn',         @PRStartFcn,...
            'StopFcn',          @PRStopFcn,...
            'UserData',         UserData,...
            'StartDelay',       0);

    start(t)
    
    % messagebox -- let's get started
    h = msgbox('Press ''ok'' to stop recording');
    set(h,'DeleteFcn',{@PRMsgboxClose,t});
    
end

%%
% General Timer Function
%   close the previous file, start the next file, increment 
function PRTimerFcn(obj,event)


    % give everything a moment...
    pause(3)
    drawnow()
    
    % start the next recording
    recordingStartFunction(obj)

end


%%
% Timer Start Function
%   Connect to cerebus
function PRStartFcn(obj,event)

    % set up increment value in proper format
    cbmex('open') % open cbmex


end


%%
% Timer Ending Function
%   close the previous file, start the next file, increment 
function PRStopFcn(obj,event)

    % stop recording
    disp('Stopping recording and shutting down cbmex interface')
    recordingStopFunction(obj)
    
    delete(t)

end

%%
% msgbox close function
function PRMsgboxClose(obj,event,t)
    
    stop(t); % turn off the timer
end


%%
% recording start function
function recordingStartFunction(obj)
    userData = obj.UserData

    % Starting everything for the next recording
    % ------------------------------------------
    % first step to starting the EMG recording
    if userData.emgIP
        urlread(userData.emgIP,'post',{'__SL_P_UDI','S0'}); % set bit 0
    end
    
    % Increment and start the cerebus recording
    userData.I = userData.I+1; % increment
    cbmex('Fileconfig',sprintf('%s_%03d',userData.filename, userData.I),['Recorded on ' date ' using PeriodicRecording.m'],1);
    disp(['Recording file ', sprintf('%s_%03d.nev',userData.filename, userData.I), '.nev']);

    % start the next EMG recording
    if userData.emgIP
        urlread(userData.emgIP,'post',{'__SL_P_UDI','S1'}); % set bit 1
    end
    
    if userData.ximea_flag || userData.gopro_flag
        cbmex('analogout',1,'sequence',[100 32767 900 0], 'repeats', 0);
    end
    
    obj.UserData = userData; % update the iterator etc.

end


%%
% recording stop function
function recordingStopFunction(obj)
    userData = obj.UserData; % make a copy
    
    % if we're running sync pulses...
    if userData.ximea_flag || userData.gopro_flag
        % turn off the sync pulse
        cbmex('analogout',1, 'sequence',[500,0,500,0], 'repeats',0);
    end
    
    % if we have an EMG, turn off the previous EMG file
    if userData.emgIP
        urlread(userData.ip_addr,'post',{'__SL_P_UDI','C1'}); % clear bit 1
    end
    
    % stop previous file
    cbmex('Fileconfig',sprintf('%s_%03d',userData.filename, userData.I),'',0);
    
    if userData.emgIP
        urlread(userData.ip_addr,'post',{'__SL_P_UDI','C0'}); % clear bit 0
    end


end


%% Input monkey name and task:
% so that this is usable for things besides the cage
function settings = SettingsDialog

    % set up the settings struct
    settings = struct();
    settings.filename=''; % default filename
    
    d = dialog('Position',[300 360 360 300],'Name','Recording Settings');


    monkey_txt = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[20 250 120 20],...
           'String','Monkey Name');

    monkey_popup = uicontrol('Parent',d,...
           'Style','popup',...
           'Position',[220 250 120 25],...
           'String',{'Pancake';'Pop';'Sherry';'Snap';'Tater';'Tot';'Waffle';'Yanny'});

    task_txt = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[20 220 120 20],...
           'String','Task Name');

    task_popup = uicontrol('Parent',d,...
           'Style','popup',...
           'Position',[220 220 120 25],...
           'String',{'Cage','MG','isoBox','isoHandle','WS','WM','FR'});

    RecLen_txt = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[20 170 120 20],...
           'String','Recording Length (sec)');

    RecLen_edit = uicontrol('Parent',d,...
           'Style','edit',...
           'Position',[140 170 200 25],...
           'String','900',...
           'Callback',@RecLen_callback); 

    EMG_txt = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[20 140 120 20],...
           'String','EMG IP');

    EMG_edit = uicontrol('Parent',d,...
           'Style','edit',...
           'Position',[140 140 200 25],...
           'String','0',...
           'Callback',@EMG_callback);

    Ximea_radio = uicontrol('Parent',d,...
           'Style','checkbox',...
           'Position',[90 90 180 20],...
           'String','Ximea or ImageSource Camera');

    GoPro_radio = uicontrol('Parent',d,...
           'Style','checkbox',...
           'Position',[130 70 100 20],...
           'String','GoPro Camera');

    btn = uicontrol('Parent',d,...
           'Position',[155 20 70 25],...
           'String','Apply Settings',...
           'Callback',@start_callback);


    % Wait for d to close before running to completion
    uiwait(d);

    % callback functions -- cleans up the settings
    function start_callback(popup,event)
        
        % filename stuff
        settings.monkey = char(monkey_popup.String(monkey_popup.Value,:));
        settings.task = char(task_popup.String(task_popup.Value,:));
        settings.filename = strjoin({datestr(now,'YYYYmmdd'),settings.monkey,settings.task},'_');
        
        % emg stuff
        if strcmp(EMG_edit.String(),'0')
            settings.emgIP = 0
        else
            settings.emgIP = EMG_edit.String();
        end
        
        % camera stuff
        settings.ximea_flag = Ximea_radio.Value;
        settings.gopro_flag = GoPro_radio.Value;
        
        
        % recording length 
        settings.RecLen = str2double(RecLen_edit.String());
        
        delete(gcf)
    end

    % make sure EMG IP is either a valid IP or 0
    function EMG_callback(popup,event)
        emg_split = strsplit(EMG_edit.String(),'.');
        
        if numel(emg_split)~=4
            EMG_edit.String = '0';
        end
    end

    % make sure recording length is a number
    function RecLen_callback(popup,event)
        if isnan(str2double(RecLen_edit.String()))
            RecLen_edit.String = '900';
        end
    end


end
