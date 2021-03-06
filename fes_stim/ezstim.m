%
% Stimulate with the Grapevine. Parameters are set in a structure following
% stim_params_defaults. A second argument can be passed to make the
% stimulation continuous.
%
%       function ezstim( varargin )
%
%
% Input parameters
%       1) 'stim_params'        : structure with the stimulation
%               parameters, see stim_params_defaults.m
%       2) 'continuous'         : if set to 1, it will stimulate
%               continuously. A message box appears to stop stimulation.
%
% Notes:
%       -- bipolar stim not yet implemented for the wireless stimulator
%

function ezstim(varargin)

% retrieve parameters
stim_params             = struct; 
continuous              = false;

if nargin == 1   
    stim_params         = varargin{1}; 
elseif nargin>1 
    stim_params         = varargin{1};
    continuous          = varargin{2}; 
end

% fill the rest of the parameters, or load defaults
stim_params             = stim_params_defaults( stim_params );
monbi = size(stim_params.elect_list,1); % for dividing up commands; two if bipolar, 1 if mono

% -------------------------------------------------------------------------
% start communication with the stimulator
if strcmp(stim_params.stimulator,'gv')
    xippmex('open');
    drawnow;
elseif strcmp(stim_params.stimulator,'ws')
    ws               = wireless_stim(stim_params); % connect to the stimulator
    % try/catch helps avoid left-open serial port handles and leaving
    % the Atmel wireless modules' firmware in a bad state
    try
        % go to the folder with calibration data
        cd(stim_params.path_cal_ws);
        ws.init(); % reset FPGA stim controller
    catch ME
        ws.delete();
        disp(datestr(datetime(),'HH:MM:ss:FFF'));
        rethrow(ME);
    end
    
    pause(1);
end


% -------------------------------------------------------------------------
% convert stimulation paramters to stimulation command

if strcmp(stim_params.stimulator,'gv')
    stim_string         = stim_params_to_stim_string( stim_params );
elseif strcmp(stim_params.stimulator,'ws')
    
    [stim_cmd, ch_list] = stim_params_to_stim_cmd_ws( stim_params );
%     % channels to stimulate
%     ch_list             = reshape(stim_params.elect_list,1,numel(stim_params.elect_list));
    % the stim_cmd is brokendown into a seris of commands because of
    % limitations in single command size 
    if length(ch_list) == 1
        for i = 1:length(stim_cmd)
            ws.set_stim(stim_cmd(i),ch_list{1});
        end
    else
        for i = 1:length(ch_list) 
            for ii = 1:length(stim_cmd)/monbi
                ws.set_stim(stim_cmd(ii+(i-1)*length(stim_cmd)/monbi),ch_list{i});
            end
        end
    end
    
    % set to run once
    for i = 1:length(ch_list)
        ws.set_Run(ws.run_once,ch_list{i})
    end
end

% -------------------------------------------------------------------------
% stimulate
if strcmp(stim_params.stimulator,'gv')
    xippmex('stim',stim_string);
elseif strcmp(stim_params.stimulator,'ws')
	%ws.set_stim(stim_cmd, stim_params.elect_list);
    ws.set_Run(ws.run_once_go,stim_params.elect_list)
end
disp('stimulating!')
drawnow;


% -------------------------------------------------------------------------
% if continuous stimulation was chosen, stimulate until the user closes the
% stimulation message box
if continuous
    global_tmr = tic;
    tmr = tic;
    stim_ctrl = msgbox('Click to Stop the Stimulation','Continuous Stimulation');
    drawnow;
    
    % set wireless stim to run continuously
    ws.set_Run(ws.run_cont,ch_list);
    
    while ishandle(stim_ctrl)
        elapsed_t = toc(tmr);
        global_t  = toc(global_tmr);
        if elapsed_t > max(stim_params.tl)/1000
            tmr = tic;
            if strcmp(stim_params.stimulator,'gv')
                xippmex('stim',stim_string);
            end                
        end
        if mod(global_t,60)<0.001
            fprintf('\n->stimulating');
            pause(0.002);
        elseif mod(global_t,5)<0.001
            fprintf('.');
            pause(0.002);
        end
        drawnow;
    end
    % stop wireless stim 
    ws.set_Run(ws.run_stop,ch_list);
   
    fprintf('\n');
end

% -------------------------------------------------------------------------
% close communication 

if strcmp(stim_params.stimulator,'gv')
    xippmex('close');
elseif strcmp(stim_params.stimulator,'ws')
    pause(1);
    delete(ws);
end