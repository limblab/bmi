%
% Ripple wireless stimulator battery life test -- the function does
% PW-modulated stimulation of several channels (at 8 mA and the default
% stim freq) until it runs out of battery, with randomly generated PW
% values updated at 20 Hz. It returns the number of command updates and a
% matrix with the latency of each command update
%
%   function [nbr_stim_cycles, update_t] = test_ws_battery_life( serial_string, nbr_channels, varargin )
%
% Inputs (optional)     : [default]
%   serial_string       : serial USB port
%   nbr_channels        : nbr of channels that will be stimulated
%   (blocking)          : [false] true for synchronous communication, false
%                           for faster asynchronous comm
%   (zb_ch_page)        : [0] zigbee communication settings
%   (path_cal_ws)       : [E:\Data-lab1\Wireless_Stimulator] calibration
%                           file location
%   (save_path)         : ['E:\Data-lab1\TestData\wireless_stim_tests']
%
% Outputs:
%   nbr_stim_cycles     : nbr of stim cycles the stimulator could perform
%                           before communication broke or battery died
%   update_t            : time during which it was stimulating
%   battery_status      : matrix with stored battery status
%
%

function [nbr_stim_cycles, update_t, battery_status] = test_ws_battery_life( serial_string, ...
                                        nbr_channels, varargin )


% read optional input parameters, or set them to default values
if nargin >= 3
    blocking            = varargin{1};
else
    blocking            = false;
end
if nargin >= 4
    zb_ch_page          = varargin{2};
else 
    zb_ch_page          = 0;
end
if nargin >= 5
    % path to the stimulator's calibration file
    path_cal_ws         = varargin{3};
else
    path_cal_ws = 'E:\Data-lab1\Wireless_Stimulator';
end
if nargin == 6
    % path to file saving location
    save_path           = varargin{4};
else
    save_path           = 'E:\Data-lab1\TestData\wireless_stim_tests';
end
    


% some definitions -- could be defined as fcn params

% time between stimulation parameter update (s)
interstim_t             = 0.05;
% stimulation amplitude (uA)
amp                     = 8000; 
% max stim PW (us)
PW_max                  = 200;
% channels to stimulate
ch_list                 = 1:nbr_channels;

% go to the stimulator's calibration file directory
cur_dir                 = pwd;
cd(path_cal_ws);


% intialize stimulator
ws_struct               = struct(...
                            'serial_string', serial_string,...
                            'dbg_lvl', 1, ...
                            'comm_timeout_ms', -1, ...
                            'blocking', blocking, ...
                            'zb_ch_page', zb_ch_page ...
                            ); 

ws                      = wireless_stim(ws_struct);                        
                        
% try/catch helps avoid left-open serial port handles and leaving the Atmel
% wireless modules' firmware in a bad state 
try
    % ---------------------------------------------------------------------
    % initial config stimulator

    % reset FPGA stim controller
    ws.init();
    
    % print version info, call after init
    ws.version();      

    % get nbr of stimulator channels
    nbr_stim_chs        = ws.num_channels;
    
    % ---------------------------------------------------------------------
    % configure stimulator commands
    
    % configure train delay for each channel. Has to be > 50us because of
    % the electronics design. We stagger the stimuli by stagg_t to minimize
    % charge density at the return.
    %
    % Note: we're probably not going to do this with online FES, since this
    % extends the stimulation artifact, so we need to try without stagger
    % too.
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
    

    % configure some of the common parameters: train length, frequency,
    % polarity and amplitude
    cmd{1}              = struct('Freq', 30, ...         % Hz
                            'PL', 1 ...             % Cathodic first
                            );
    ws.set_stim(cmd, ch_list);
    
    cmd{1}              = struct('CathAmp', 32768+amp, ...  % 16-bit DAC setting
                            'AnodAmp', 32768-amp ...% 16-bit DAC setting
                            );                    
	ws.set_stim(cmd, ch_list);
    
    pause(1);


    % create msgbox to stop stimulation saving the data
    keep_running        = msgbox('Click ''ok'' to stop stimulating','Stim switch');
    set(keep_running,'Position',[200 700 125 52]);

    
    % ---------------------------------------------------------------------
    % loop that runs the test

    
    % counter to keep track of param updates
    ctr                 = 1;
    % empty array to store stimulus update time, to keep track of latency
    update_t            = [];
    battery_status = [];
    
    while ishandle(keep_running)
        % store current time
        cur_t           = tic;
        
        % generate random PW values
        PW              = round( rand(1,nbr_channels) * PW_max );
        % update anode and cathode PW
        ws.set_AnodDur( PW, ch_list);
        ws.set_CathDur( PW, ch_list);
        
        % wait until enough time has elapsed & store latency
        elapsed_t       = toc(cur_t);
        update_t(ctr)   = elapsed_t; %#ok<AGROW>
        while elapsed_t < interstim_t
            elapsed_t   = toc(cur_t);
        end
        
        % update cycle ctr
        ctr             = ctr + 1;
        drawnow;
        
        if ~mod(ctr,50)
            battery_status(ctr/50) = ws.check_battery; % battery low?
        end
        
    end

    nbr_stim_cycles = ctr;
            
    % save results
    file_name           = ['battery_tests_' datestr(now,'yymmdd_HHMMSS')];
    save([save_path, filesep, file_name], 'nbr_stim_cycles', 'update_t','blocking','zb_ch_page');
    disp(['saving data in E:\Data-lab1\TestData\wireless_stim_tests\battery_tests_' ...
        datestr(now,'yymmdd_HHMMSS')]);
    disp(' ')
    disp('stimulation stopped by the user');
    disp(['total time stim command updates at 20Hz: ' num2str(nbr_stim_cycles*interstim_t/60)]);
    disp(['mean command update latency: ' num2str(mean(update_t)) ' +/- ' num2str(std(update_t))]);
    
catch ME
    delete(ws);
    if exist('ctr','var')
        nbr_stim_cycles = ctr;
    else
        nbr_stim_cycles = 0;
        update_t        = inf;
    end
    
    % save results
    file_name           = ['battery_tests_' datestr(now,'yymmdd_HHMMSS')];
    save([save_path, filesep, file_name], 'nbr_stim_cycles', 'update_t','blocking','zb_ch_page','battery_status');
    disp(['saving data in E:\Data-lab1\TestData\wireless_stim_tests\battery_tests_' ...
        datestr(now,'yymmdd_HHMMSS')]);
    disp(' ')
    disp(['total time stim command updates: ' num2str(nbr_stim_cycles*interstim_t/60)]);
    disp(['mean command update latency: ' num2str(mean(update_t))]);

    % plot a histogram with the latencies
    plot_latency_hist( update_t, save_path, file_name );
    
    % go back to where you were
    cd(cur_dir);
    
    if ishandle(keep_running)
        close(keep_running);
    end
    
    % return error
    rethrow(ME);
end


% plot a histogram with the latencies
plot_latency_hist( update_t, save_path, file_name );


% go back to where you were
cd(cur_dir);

% and wrap up
delete(ws);
nbr_stim_cycles = ctr;
if ishandle(keep_running)
    close(keep_running);
end

end



% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% function for plotting the histogram of the command update latency

function plot_latency_hist( update_t, save_path, file_name )

hst                     = histogram(update_t,0:0.001:0.15);
max_hst                 = max(hst.Values);
if max_hst > 10000
    y_mean              = ceil(max_hst/10000)*10000;
elseif max_hst > 1000
    y_mean              = ceil(max_hst/1000)*1000;
else
    y_mean              = ceil(max_hst/100)*100;
end
figure,hold on
histogram(update_t,0:0.001:0.15)
plot(mean(update_t),y_mean,'.','markersize',24,'color','k')
plot([mean(update_t)-std(update_t),mean(update_t)+std(update_t)],[y_mean,y_mean],...
    'k','linewidth',3)
set(gca,'FontSize',16,'TickDir','out')
ylim([0 1.1*y_mean])
xlabel('stim cmd update latency (s)'),ylabel('counts')
title(file_name,'Interpreter','none')
saveas(gcf,[save_path, filesep, file_name '.png'])

t_axis_latency      = update_t;
t_axis_latency(t_axis_latency<0.05) = 0.05;

figure
%plot(cumsum(update_t)/60,update_t)
plot(cumsum(t_axis_latency)/60,update_t)
xlabel('test time (min)')
ylabel('latency (s)')
set(gca,'FontSize',16,'TickDir','out')
ylim([0 0.15])
title(file_name,'Interpreter','none')
saveas(gcf,[save_path, filesep, file_name '_fcn_t.png'])


end