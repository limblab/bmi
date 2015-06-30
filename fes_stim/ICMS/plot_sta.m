% 
% Plots the STA for a channel, as well as some of the metrics calculated in
% 'calculate_sta_metrics.m' 
%
%       function plot_sta( emg, varargin )
%
%
% Syntax:
%       PLOT_STA( EMG, STA_PARAMS, STA_METRICS )
%       PLOT_STA( EMG, FORCE, STA_PARAMS, STA_METRICS )
%
% Input parameters
%       'emg'               : structure that contains the evoked EMG
%                               response (per stim) and other EMG
%                               information  
%       'force'             : structure that contains the evoked Force
%                               response (per stim) and other Force
%                               information  
%       'sta_params'        : structure that contains general information
%                               on the experiment 
%       'sta_metrics'       : metrics that characterize PSF: 1) Fetz' and
%       Cheney's MPSF; 2) Polyakov and Schiebert's statistics  
%                                   Schiebert's statistics    
%
%
%
%                           Last modified by Juan Gallego 6/17/2015



function plot_sta2( emg, varargin )



% read parameters

if nargin == 3
    sta_params              = varargin{1};
    sta_metrics             = varargin{2};
elseif nargin == 4
    force                   = varargin{1};
    sta_params              = varargin{2};
    sta_metrics             = varargin{3};
elseif nargin < 3 || nargin > 4
    error('ERROR: The function only takes 3 or 4 parameters');
end



%--------------------------------------------------------------------------
% EMG plot

t_emg                       = -sta_params.t_before:1/emg.fs*1000:sta_params.t_after;       % in ms


figure('units','normalized','outerposition',[0 0 1 1],'Name',['Electrode #' sta_params.bank num2str(sta_params.stim_elec) ' - n = ' num2str(sta_metrics.emg.nbr_stims)]);

for i = 1:emg.nbr_emgs
    
    if emg.nbr_emgs <= 4
        
        subplot(1,emg.nbr_emgs,i), hold on,
        disp('ToDo')
        pause;
        
    elseif emg.nbr_emgs == 6
        
        subplot(2,3,ii), hold on,
        disp('ToDo')
        pause;
        
    elseif emg.nbr_emgs <= 8
        
        subplot(2,4,i), hold on, plot(t_emg, sta_metrics.emg.mean_emg(:,i)), xlim([0 1]), title(['EMG ch #' num2str(i)], 'FontSize', 14);
        disp('ToDo')
        pause;
        
    elseif emg.nbr_emgs <= 12
        
        subplot(3,4,i), hold on,
        if sta_metrics.emg.MPSF(i) > 0 
            plot(t_emg, sta_metrics.emg.mean_emg(:,i),'r','linewidth',2)
        else
            plot(t_emg, sta_metrics.emg.mean_emg(:,i),'k','linewidth',2)
        end
        set(gca,'FontSize',16), xlim([t_emg(1) t_emg(end)]), ylabel(emg.labels{i}(5:end),'FontSize',16);
        set(gca,'TickDir','out')
        plot(t_emg,(sta_metrics.emg.mean_baseline_emg(i) + 2*sta_metrics.emg.std_baseline_emg(i))*ones(emg.length_evoked_emg,1),'-.k')
        %plot(t_emg,(mean_mean_baseline_emg(i) - 2*std_mean_baseline_emg(i))*ones(length_evoked_emg,1),'k')
        
        if i > 8 
           xlabel('time (ms)') 
        end
        
        if  sta_metrics.emg.MPSF(i) > 0 && sta_metrics.emg.P_Ztest(i) < 0.05
            title(['MPSF = ' num2str(sta_metrics.emg.MPSF(i),3) ', P = ' num2str(sta_metrics.emg.P_Ztest(i),3)],'color','r');
        elseif sta_metrics.emg.MPSF(i) > 0 && sta_metrics.emg.P_Ztest(i) > 0.05
            title(['MPSF = ' num2str(sta_metrics.emg.MPSF(i),3) ', P = ' num2str(sta_metrics.emg.P_Ztest(i),3)],'color','g');
        elseif  sta_metrics.emg.MPSF(i) == 0 && sta_metrics.emg.P_Ztest(i) < 0.05
            title(['MPSF = ' num2str(sta_metrics.emg.MPSF(i),3) ', P = ' num2str(sta_metrics.emg.P_Ztest(i),3)],'color','b');
        else
            title(['P = ' num2str(sta_metrics.emg.P_Ztest(i),3)]);
        end
    end
end




%--------------------------------------------------------------------------
% Force plot

if nargin == 4

    t_force                     = -sta_params.t_before:1/force.fs*1000:sta_params.t_after;       % in ms
    
    figure('units','normalized','outerposition',[0 0 1 1],'Name',['Electrode #' sta_params.bank num2str(sta_params.stim_elec) ' - n = ' num2str(sta_metrics.emg.nbr_stims)]);
    
    % ToDo: code for plotting the forces
    if force.nbr_forces == 2
        subplot(221),plot(t_force, sta_metrics.force.mean_detrended_force(:,1),'b','linewidth',2), ylabel('detrended force X')
        subplot(222),plot(t_force, sta_metrics.force.mean_detrended_force(:,2),'k','linewidth',2), ylabel('detrended force Y')
        subplot(223),plot(t_force, sta_metrics.force.mean_force(:,1),'c','linewidth',2), ylabel('force X'), xlabel('times (ms)')
        subplot(224),plot(t_force, sta_metrics.force.mean_force(:,1),'color',[0.5 0.5 0.5],'linewidth',2), ylabel('force Y'), xlabel('times (ms)')
    end
end