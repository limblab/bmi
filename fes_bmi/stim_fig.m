% Figure to plot the stimulation command (predicted EMG) for each muscle
% 
% function fig_handle = stim_fig( fig_handle , stim_PW, stim_amp, bmi_fes_stim_params, mode )
%
%   fig_handle          : handle structure (with figure and plot fields)
%   stim_PW             : desired stimulation PW vector
%   stim_amp            : desired stimulation amplitude vector
%   bmi_fes_stim_params : bmi_fes_stim_params structure in params structure
%   state               : 'init' / 'exec' to initialize the figure or during
%                           execution

function fig_handle = stim_fig( fig_handle , stim_PW, stim_amp, bmi_fes_stim_params, mode, stim_or_catch)


if strcmp(mode,'init')
    
    figure(fig_handle.fh);
    
    % label the muscles to use different colors
    fig_handle.ext_muscles  = strncmp(bmi_fes_stim_params.muscles,'E',1);
    fig_handle.flex_muscles = (strncmp(bmi_fes_stim_params.muscles,'F',1) | strncmp(bmi_fes_stim_params.muscles,'PL',2)) & ~strcmp(bmi_fes_stim_params.muscles,'FPB');
    
    fig_handle.hand_muscles = strncmp(bmi_fes_stim_params.muscles,'ADL',3);
    fig_handle.hand_muscles = fig_handle.hand_muscles | strncmp(bmi_fes_stim_params.muscles,'APB',3);
    fig_handle.hand_muscles = fig_handle.hand_muscles | strncmp(bmi_fes_stim_params.muscles,'APL',3);
    fig_handle.hand_muscles = fig_handle.hand_muscles | strncmp(bmi_fes_stim_params.muscles,'FPB',3);
    
    fig_handle.other_muscles = strncmp(bmi_fes_stim_params.muscles,'Brad',4);
    fig_handle.other_muscles = fig_handle.other_muscles | strncmp(bmi_fes_stim_params.muscles,'Sup',3);
    fig_handle.other_muscles = fig_handle.other_muscles | strncmp(bmi_fes_stim_params.muscles,'PT',2);

    
    % create plot
    fig_handle.ah           = axes('Parent',fig_handle.fh);
    hold on

    if ~isempty(find(fig_handle.ext_muscles,1))
        
        fig_handle.ph_ext   = plot( fig_handle.ah, find( fig_handle.ext_muscles ), ...
                                zeros( 1,sum(fig_handle.ext_muscles) ), ...
                                'b^', 'markersize', 18, 'linestyle', 'none' ); 
    end
    
    if ~isempty(find(fig_handle.flex_muscles,1))
        fig_handle.ph_flex  = plot( fig_handle.ah, find( fig_handle.flex_muscles), ...
                                zeros( 1,sum(fig_handle.flex_muscles) ), ...
                                'r^', 'markersize', 18, 'linestyle', 'none' ); 
    end
    
    if ~isempty(find(fig_handle.hand_muscles,1))
        fig_handle.ph_hand  = plot( fig_handle.ah, find( fig_handle.hand_muscles), ...
                                zeros( 1,sum(fig_handle.hand_muscles) ), ...
                                'k^', 'markersize', 18, 'linestyle', 'none' ); 
    end
    
    if ~isempty(find(fig_handle.other_muscles,1))
        fig_handle.ph_other = plot( fig_handle.ah, find( fig_handle.other_muscles), ...
                                zeros( 1,sum(fig_handle.other_muscles) ), ...
                                'g^', 'markersize', 18, 'linestyle', 'none' ); 
    end

    xlim([.5, numel(bmi_fes_stim_params.muscles)+.5]);

    
    fig_handle.ah.XTick     = 1:numel(bmi_fes_stim_params.muscles);
    fig_handle.ah.XTickLabel = bmi_fes_stim_params.muscles;
    fig_handle.ah.TickDir   = 'out';
    
    xlabel('muscle')
    ylabel('PW (us)')
    if strcmp(bmi_fes_stim_params.mode,'PW_modulation')
        fig_handle.ah.Title.String = 'PW stimulation values';
        ylim([0, max(bmi_fes_stim_params.PW_max)]);
    elseif strcmp(bmi_fes_stim_params.mode,'amplitude_modulation')
        fig_handle.ah.Title.String = 'Amplitude stimulation values';
        ylim([0, max(bmi_fes_stim_params.amplitude_max)]);
    end
    
elseif strcmp(mode,'exec')

    if strcmp(bmi_fes_stim_params.mode,'PW_modulation')
        
        % update PW plotting based on muscle type
        if ~isempty(fig_handle.ext_muscles)
            fig_handle.ph_ext.YData     = stim_PW(fig_handle.ext_muscles);
        end

        if ~isempty(fig_handle.flex_muscles)
            fig_handle.ph_flex.YData    = stim_PW(fig_handle.flex_muscles);
        end

        if ~isempty(fig_handle.hand_muscles)
            fig_handle.ph_hand.YData    = stim_PW(fig_handle.hand_muscles);
        end

        if ~isempty(fig_handle.other_muscles)
            fig_handle.ph_other.YData   = stim_PW(fig_handle.other_muscles);
        end
        
%         % Label on the title if this is a catch trial
%         if stim_or_catch && strcmp(fig_handle.ah.Title.String,'catch trial')
%             fig_handle.ah.Title.String = 'PW stimulation values';
%         elseif ~stim_or_catch && strcmp(fig_handle.ah.Title.String,'PW stimulation values')
%             fig_handle.ah.Title.String = 'catch trial';
%         end
       

    elseif strcmp(bmi_fes_stim_params.mode,'amplitude_modulation')
        
        % update PW plotting based on muscle type
        if ~isempty(fig_handle.ext_muscles)
            fig_handle.ph_ext.YData     = stim_amp(fig_handle.ext_muscles);
        end

        if ~isempty(fig_handle.flex_muscles)
            fig_handle.ph_flex.YData    = stim_amp(fig_handle.flex_muscles);
        end

        if ~isempty(fig_handle.hand_muscles)
            fig_handle.ph_hand.YData    = stim_amp(fig_handle.hand_muscles);
        end

        if ~isempty(fig_handle.other_muscles)
            fig_handle.ph_other.YData   = stim_amp(fig_handle.other_muscles);
        end
    end
end