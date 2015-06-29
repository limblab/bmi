% Figure to plot the stimulation command (predicted EMG) for each muscle

function stim_fig( fig_handle , stim_PW, stim_amp, bmi_fes_stim_params )


if strcmp(bmi_fes_stim_params.mode,'PW_modulation')

    figure(fig_handle)
    
    % label the muscles to use different colors
    ext_muscles             = strncmp(bmi_fes_stim_params.muscles,'E',1);
    flex_muscles            = strncmp(bmi_fes_stim_params.muscles,'F',1);
    
    hand_muscles            = strncmp(bmi_fes_stim_params.muscles,'ADL',3);
    hand_muscles            = hand_muscles | strncmp(bmi_fes_stim_params.muscles,'APB',3);
    hand_muscles            = hand_muscles | strncmp(bmi_fes_stim_params.muscles,'APL',3);
    
    other_muscles           = strncmp(bmi_fes_stim_params.muscles,'Brad',4);
    other_muscles           = other_muscles | strncmp(bmi_fes_stim_params.muscles,'Sup',3);
    other_muscles           = other_muscles | strncmp(bmi_fes_stim_params.muscles,'PT',2);

    
    bar(stim_PW)
    set(gca,'XTickLabel',bmi_fes_stim_params.muscles)
    hold on    
    bar(find(ext_muscles),stim_PW(ext_muscles),'b')
    bar(find(flex_muscles),stim_PW(flex_muscles),'r')
	bar(find(hand_muscles),stim_PW(hand_muscles),'k')
    bar(find(other_muscles),stim_PW(other_muscles),'g')
    xlim([.5 length(stim_PW)+.5]), ylim([0 max(bmi_fes_stim_params.PW_max)])
    xlabel('muscle')
    ylabel('PW (us)')
    hold off
else
    
end

%   set(gca,'XTickLabel',{'Group A','Group B','Group C'})
%   legend('Parameter 1','Parameter 2','Parameter 3','Parameter 4')
%   ylabel('Y Value')