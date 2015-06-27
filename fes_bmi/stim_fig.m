% Figure to plot the stimulation command (predicted EMG) for each muscle

function stim_fig( fig_handle , stim_PW, stim_amp, bmi_fes_stim_params )


if strcmp(bmi_fes_stim_params.mode,'PW_modulation')

    figure(fig_handle)
    
    % label the muscles to use different colors
    
    
    bar(stim_PW,'r')
    set(gca,'XTickLabel',bmi_fes_stim_params.muscles)
    xlim([.5 length(stim_PW)+.5]), ylim([0 max(bmi_fes_stim_params.PW_max)])
    xlabel('muscle')
    ylabel('PW (us)')
else
    
end

%   set(gca,'XTickLabel',{'Group A','Group B','Group C'})
%   legend('Parameter 1','Parameter 2','Parameter 3','Parameter 4')
%   ylabel('Y Value')