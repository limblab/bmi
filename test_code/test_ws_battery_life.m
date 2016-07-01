%
% Ripple wireless stimulator battery life test -- the function does
% PW-modulated stimulation of several channels (at 8 mA and the default
% stim freq) until it runs out of battery, with randomly generated PW
% values updated at 20 Hz. It returns the number of command updates and a
% matrix with the latency of each command update
%
%   function [nbr_stim_cycles, update_t] = test_ws_battery_life( serial_string, nbr_channels )
%
%

function [nbr_stim_cycles, update_t] = test_ws_battery_life( serial_string, nbr_channels )


% some definitions -- could be defined as fcn params

% time between stimulation parameter update (s)
interstim_t             = 0.05;
% stimulation amplitude (uA)
amp                     = 8000; 
% max stim PW (us)
PW_max                  = 200;
% channels to stimulate
ch_list                 = 1:nbr_channels;
% path to the stimulator's calibration file
path_cal_ws             = 'E:\Data-lab1\Wireless_Stimulator';


% go to the stimulator's calibration file directory
cur_dir                 = pwd;
cd(path_cal_ws);


% intialize stimulator
ws                      = wireless_stim(serial_string, 0);


% try/catch helps avoid left-open serial port handles and leaving the Atmel
% wireless modules' firmware in a bad state 
try
    % ---------------------------------------------------------------------
    % initial config stimulator
    
    % comm_timeout specified in ms, or disable
    reset               = 1;
    % reset FPGA stim controller
    ws.init(reset, ws.comm_timeout_disable);
    
    % print version info, call after init
    ws.version();      

    % get nbr of stimulator channels
    nbr_stim_chs        = ws.num_channels;
    
    % ---------------------------------------------------------------------
    % configure stimulator commands
    
    % configure train delay for each channel. Has to be > 50us because of
    % the electronics design. We stagger the stimuli by stagg_t to minimize
    % charge density at the return
    stagg_t             = 500; % (s)
%     td                  = ones(1,16)*50;
    td(1:nbr_channels)  = 50 + stagg_t*(1:nbr_channels) - stagg_t;
    
    for i = 1:nbr_channels
        ws.set_TD(td(i), ch_list(i));
    end
%     cmd{1}              = struct('TD',td);
%     ws.set_stim(cmd,1:nbr_channels);

    % set the stimulator to run continously
    disp('starting stimulation sequence');
    ws.set_Run(ws.run_cont, 1:nbr_channels);
%     for i = 1:nbr_channels
%         ws.set_Run(ws.run_cont, i);
%     end
    

    % configure some of the common parameters
    cmd{1}              = struct('TL', 100, ...        % ms
                            'Freq', 30, ...        % Hz
                            'PL', 1 ...           % Cathodic first
                            );
    ws.set_stim(cmd, ch_list);
    cmd{1}              = struct('CathAmp', 32768+amp, ...  % 16-bit DAC setting
                            'AnodAmp', 32768-amp ...% 16-bit DAC setting
                            );                    
	ws.set_stim(cmd, ch_list);
    pause(1);


    % ---------------------------------------------------------------------
    % loop that runs the experiment

    
    % counter to keep track of param updates
    ctr                 = 1;
    % empty array to store stimulus update time, to keep track of latency
    update_t            = [];
    
    while(1)
        % store current time
        cur_t           = tic;
        
        % generate random PW values
        PW              = round( rand(1,nbr_channels) * PW_max );
        % update anode and cathode PW
        ws.set_AnodDur( PW, ch_list);
        ws.set_CathDur( PW, ch_list);
        
        % wait until enough time has elapsed & store latency
        elapsed_t       = toc(cur_t);
        update_t(ctr)   = elapsed_t;
        while elapsed_t < interstim_t
            elapsed_t   = toc(cur_t);
        end
        
        % update cycle ctr
        ctr             = ctr + 1;
    end
    
catch ME
    delete(ws);
    if exist('ctr','var')
        nbr_stim_cycles = ctr;
    else
        nbr_stim_cycles = 0;
        update_t        = inf;
    end
    save(['E:\Data-lab1\TestData\wireless_stim_tests\battery_tests_' ...
        datestr(now,'yymmdd_HHMMSS')], 'nbr_stim_cycles', 'update_t');
    disp(['saving data in E:\Data-lab1\TestData\wireless_stim_tests\battery_tests_' ...
        datestr(now,'yymmdd_HHMMSS')]);
    disp(' ')
    disp(['total time stim command updates: ' num2str(nbr_stim_cycles*interstim_t/60)]);
    disp(['mean command update latency: ' num2str(mean(update_t))]);
    rethrow(ME);
end


delete(ws);
nbr_stim_cycles = ctr;
