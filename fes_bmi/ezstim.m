function ezstim(varargin)

stim_params = struct; continuous = false;
if nargin   stim_params = varargin{1}; end
if nargin>1 continuous  = varargin{2}; end

stim_params = stim_params_defaults(stim_params);
stim_string = stim_params_to_stim_string(stim_params);



xippmex('open');
drawnow;
xippmex('stim',stim_string);
drawnow;

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

xippmex('close');



