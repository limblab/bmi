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
%
%

function ezstim(varargin)

% retrieve parameters
stim_params = struct; continuous = false;
if nargin,   stim_params = varargin{1}; end
if nargin>1, continuous  = varargin{2}; end

% fill the rest of the parameters, or load defaults
stim_params = stim_params_defaults(stim_params);

% -------------------------------------------------------------------------
% convert stimulation paramters to stimulation string for the grapevine
stim_string = stim_params_to_stim_string(stim_params);

% open communication with Grapevine
xippmex('open');
drawnow;

% stimulate
xippmex('stim',stim_string);
drawnow;

% -------------------------------------------------------------------------
% if continuous stimulation was chosen, stimulate until the user closes the
% stimulation message box
if continuous
    global_tmr = tic;
    tmr = tic;
    stim_ctrl = msgbox('Click to Stop the Stimulation','Continuous Stimulation');
    drawnow;
    
    while ishandle(stim_ctrl)
        elapsed_t = toc(tmr);
        global_t  = toc(global_tmr);
        if elapsed_t > max(stim_params.tl)/1000
            tmr = tic;
            xippmex('stim',stim_string);
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
    fprintf('\n');
end

% -------------------------------------------------------------------------
% close communication with Grapevine
xippmex('close');
