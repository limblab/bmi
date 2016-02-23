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
end
if nargin>1 
    continuous          = varargin{2}; 
end

% fill the rest of the parameters, or load defaults
stim_params             = stim_params_defaults( stim_params );

% -------------------------------------------------------------------------
% start communication with the stimulator
if strcmp(stim_params.stimulator,'gv')
    xippmex('open');
    drawnow;
elseif strcmp(stim_params.stimulator,'ws')
    ws               = wireless_stim(stim_params.serial_ws,0); % connect to the stimulator, no verbose
    % try/catch helps avoid left-open serial port handles and leaving
    % the Atmel wireless modules' firmware in a bad state
    try
        % go to the folder with calibration data
        cd(stim_params.path_cal_ws);
        ws.init(1, ws.comm_timeout_disable); % reset FPGA stim controller
    catch ME
        delete(ws);
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
    stim_cmd            = stim_params_to_stim_cmd_ws( stim_params );
    % channels to stimulate
    ch_list             = reshape(stim_params.elect_list,1,numel(stim_params.elect_list));
    % the stim_cmd is brokendown into a seris of commands because of
    % limitations in single command size 
    for i = 1:length(stim_cmd)
        ws.set_stim(stim_cmd(i),ch_list);
    end
    
    % check if we are doing monopolar or bipolar stimulation. Set polarity
    % accordingly
    % -- if stim_params.elect_list has to rows that means bipolar
    if size(stim_params.elect_list,1) == 2
        ws.set_PL( 1, ch_list(1:2:numel(ch_list)-1) );
        ws.set_PL( 0, ch_list(2:2:numel(ch_list)) );
    else
        ws.set_PL( 1, ch_list );
    end
    
    % set to run once
    ws.set_Run(ws.run_once,ch_list)
end

% -------------------------------------------------------------------------
% stimulate
if strcmp(stim_params.stimulator,'gv')
    xippmex('stim',stim_string);
    drawnow;
elseif strcmp(stim_params.stimulator,'ws')
	%ws.set_stim(stim_cmd, stim_params.elect_list);
    ws.set_Run(ws.run_once_go,stim_params.elect_list)
end


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
    delete(ws);
end

