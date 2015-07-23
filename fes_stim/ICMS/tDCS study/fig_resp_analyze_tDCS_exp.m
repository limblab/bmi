%
% Function to plot the evoke response figures for analyze_tDCS_exp
%
% function fig_resp_analyze_tDCS_exp( sta_metrics_bsln, sta_metrics_tDCS, ...
%           sta_metrics_post, t_axis_evoked_resp, pos_muscles, resp_per_win, fig_title )
%       To plot the MPSF (normalized or not)
%           varargin{1}:        mean_MPSF_bsln
%           varargin{2}:        std_MPSF_bsln
%


function fig_resp_analyze_tDCS_exp( sta_metrics_bsln, sta_metrics_tDCS, sta_metrics_post, ...
                                t_axis_evoked_resp, pos_muscles, resp_per_win, fig_title )


nbr_muscles     = numel(pos_muscles);
                            
for i = 1:nbr_muscles
    
    % 1. Figure that plots the 'raw' evoked responses
    figure, hold on;
    if ~isempty(sta_metrics_bsln)
        h_r1    = arrayfun( @(x) plot( t_axis_evoked_resp, x.emg.mean_emg(:,pos_muscles(i)), ...
                    'LineWidth', 1, 'color', 'k' ), sta_metrics_bsln );
    end
    if ~isempty(sta_metrics_tDCS)
        h_r2    = arrayfun( @(x) plot( t_axis_evoked_resp, x.emg.mean_emg(:,pos_muscles(i)), ...
                    'LineWidth', 1, 'color', 'r' ), sta_metrics_tDCS );
    end
    if ~isempty(sta_metrics_post)
        h_r3    = arrayfun( @(x) plot( t_axis_evoked_resp, x.emg.mean_emg(:,pos_muscles(i)), ...
                    'LineWidth', 1, 'color', 'b' ), sta_metrics_post );
    end

    % the crazy code for the legend
    if ~isempty(sta_metrics_bsln)
        if ~isempty(sta_metrics_tDCS)
            if ~isempty(sta_metrics_post)
                legend([h_r1(1) h_r2(1) h_r3(1)],'baseline','tDCS on','tDCS off','Location','northeast')
            else
                legend([h_r1(1) h_r2(1)],'baseline','tDCS on','Location','northeast')
            end
        else
            if ~isempty(sta_metrics_post)
                legend([h_r1(1) h_r3(1)],'baseline','tDCS off','Location','northeast')
            end
        end
    else
        if isempty(sta_metrics_tDCS)
            legend(h_r3(1),'tDCS off','Location','northeast')
        else
            legend([h_r2(1) h_r3(1)],'tDCS on','tDCS off','Location','northeast')
        end
    end
    
    % Set title, axes and format    
    xlim([t_axis_evoked_resp(1) t_axis_evoked_resp(end)])
    xlabel('time (ms)','Fontsize',14), ylabel('evoked response (mV)','Fontsize',14)
    set(gca,'FontSize',14), set(gca,'TickDir','out')
    title([fig_title ' - n = ' num2str(resp_per_win) ' resp/epoch'],'Interpreter', 'none')
    
    
    % 2. Figure that plots the detrended evoked responses
    figure, hold on;
    
    if ~isempty(sta_metrics_bsln)
        h_rd1   = arrayfun( @(x) plot( t_axis_evoked_resp, detrend( x.emg.mean_emg(:,pos_muscles(i)) ), ...
                    'LineWidth', 1, 'color', 'k' ), sta_metrics_bsln );
    end
    if ~isempty(sta_metrics_tDCS)
        h_rd2   = arrayfun( @(x) plot( t_axis_evoked_resp, detrend( x.emg.mean_emg(:,pos_muscles(i)) ), ...
                    'LineWidth', 1, 'color', 'r' ), sta_metrics_tDCS );
    end
    if ~isempty(sta_metrics_post)
        h_rd3   = arrayfun( @(x) plot( t_axis_evoked_resp, detrend( x.emg.mean_emg(:,pos_muscles(i)) ), ...
                    'LineWidth', 1, 'color', 'b' ), sta_metrics_post );
    end
        
    % Set title, axes and format
    xlim([t_axis_evoked_resp(1) t_axis_evoked_resp(end)])
    xlabel('time (ms)','Fontsize',14), ylabel('detrended evoked response (mV)','Fontsize',14)
    set(gca,'FontSize',14), set(gca,'TickDir','out') 
    title([fig_title ' - n = ' num2str(resp_per_win) ' resp/epoch'],'Interpreter', 'none')

    % the crazy code for the legend
    if ~isempty(sta_metrics_bsln)
        if ~isempty(sta_metrics_tDCS)
            if ~isempty(sta_metrics_post)
                legend([h_rd1(1) h_rd2(1) h_rd3(1)],'baseline','tDCS on','tDCS off','Location','northeast')
            else
                legend([h_rd1(1) h_rd2(1)],'baseline','tDCS on','Location','northeast')
            end
        else
            if ~isempty(sta_metrics_post)
                legend([h_rd1(1) h_rd3(1)],'baseline','tDCS off','Location','northeast')
            end
        end
    else
        if isempty(sta_metrics_tDCS)
            legend(h_rd3(1),'tDCS off','Location','northeast')
        else
            legend([h_rd2(1) h_rd3(1)],'tDCS on','tDCS off','Location','northeast')
        end
    end

end
