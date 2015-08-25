%
% Function to plot the MPSF figures for analyze_tDCS_exp
%
% function fig_MPSF_analyze_tDCS_exp( MPSF_array, nbr_muscles, muscle_labels, ...
%           resp_per_win, nbr_points_bsln, nbr_points_tDCS, nbr_points_post, ...
%           fig_legend, varargin )
%
%       To plot the MPSF (normalized or not)
%           varargin{1}:        mean_MPSF_bsln
%           varargin{2}:        std_MPSF_bsln
%


function fig_MPSF_analyze_tDCS_exp( MPSF_array, nbr_muscles, muscle_labels, resp_per_win, ...
                                nbr_points_bsln, nbr_points_tDCS, nbr_points_post, fig_title, ...
                                varargin )

if nargin == 10
    mean_MPSF_bsln              = varargin{1};
    std_MPSF_bsln               = varargin{2};
elseif nargin > 10
    error('you have passed too many parameters!');
end


nbr_MPSF_points             = nbr_points_bsln + nbr_points_tDCS + nbr_points_post;


% This loop generates a plot for each muscle
for i = 1:nbr_muscles  
    
    figure;hold on;

    if ( nbr_MPSF_points ~= nbr_points_bsln ) && ( nbr_points_bsln > 0 )
        plot( MPSF_array(1:nbr_points_bsln+1,i),'k','linewidth',2,'markersize',12)
    else
        plot( MPSF_array(1:nbr_points_bsln,i),'k','linewidth',2,'markersize',12)
    end

    if nbr_MPSF_points ~= nbr_points_bsln

        % draw the lines
        if nbr_points_tDCS > 0
            if nbr_points_post > 0
                plot( nbr_points_bsln+1:nbr_points_bsln+nbr_points_tDCS+1, ...
                        MPSF_array(nbr_points_bsln+1:nbr_points_bsln+nbr_points_tDCS+1,i), 'r','linewidth',2 )
                plot( nbr_points_bsln+nbr_points_tDCS+1:size(MPSF_array,1), ...
                        MPSF_array(nbr_points_bsln+nbr_points_tDCS+1:end,i),'b','linewidth',2 )
            else
                plot( nbr_points_bsln+1:nbr_points_bsln+nbr_points_tDCS, ...
                        MPSF_array(nbr_points_bsln+1:nbr_points_bsln+nbr_points_tDCS,i), 'r','linewidth',2 )
            end
        elseif nbr_points_post > 0 
            plot( nbr_points_bsln+1:size(MPSF_array,1), MPSF_array(nbr_points_bsln+1:end,i),'b','linewidth',2 )
        end

        % draw the markers
        if nbr_points_tDCS > 0
            plot( nbr_points_bsln+1:nbr_points_bsln+nbr_points_tDCS, ...
                    MPSF_array(nbr_points_bsln+1:nbr_points_bsln+nbr_points_tDCS,i), ...
                            'or','linewidth',2,'markersize',12)
        end
        if nbr_points_post > 0
            plot( nbr_points_bsln+nbr_points_tDCS+1:size(MPSF_array,1), ...
                    MPSF_array(nbr_points_bsln+nbr_points_tDCS+1:end,i),...
                                        'ob','linewidth',2,'markersize',12)
        end
    end


    % draw the mean +/- SD of the baseline response, if recorded
    if nbr_points_bsln > 0
        plot( MPSF_array(1:nbr_points_bsln,i),'ok','linewidth',2,'markersize',12)

        plot( [0 size(MPSF_array,1)+1], ones(1,2).*mean_MPSF_bsln(i), '.-', 'color', ...
                [.5 .5 .5], 'linewidth', 2 )
        plot( [0 size(MPSF_array,1)+1], ones(1,2).*(std_MPSF_bsln(i)+mean_MPSF_bsln(i)),...
                ':', 'color', [.5 .5 .5], 'linewidth', 2 )
        plot( [0 size(MPSF_array,1)+1], ones(1,2).*(-std_MPSF_bsln(i)+mean_MPSF_bsln(i)),...
                ':', 'color', [.5 .5 .5], 'linewidth', 2 )
    end


    % Set title, axes and format
    set(gca,'FontSize',14), xlabel('epoch nbr.'), set(gca,'TickDir','out')
    if nargin == 10
        if unique(mean_MPSF_bsln) == 1
            ylabel(['Normalized MPSF ' muscle_labels{i}(5:end)],'FontSize',14)
        else
            ylabel(['MPSF ' muscle_labels{i}(5:end)],'FontSize',14)
        end
    else
        ylabel(['MPSF ' muscle_labels{i}(5:end)],'FontSize',14)
    end
    xlim([0 nbr_MPSF_points+1]), ylim([0 ceil(max(MPSF_array(:,i)))+1])
    title([fig_title ' - n = ' num2str(resp_per_win) ' resp/epoch'],'Interpreter', 'none')

    
    % all this... only to plot the right legend
    if nbr_MPSF_points ~= nbr_points_bsln
        if nbr_points_bsln > 0
            if nbr_points_tDCS > 0
                if nbr_points_post > 0
                    fig_legend  = {'baseline','tDCS on','tDCS off'}; 
                else
                    fig_legend  = {'baseline','tDCS on'};
                end
            elseif nbr_points_post > 0
                fig_legend      = {'baseline','tDCS off'};
            end
        else 
            if nbr_points_tDCS > 0
                if nbr_points_post > 0
                    fig_legend  = {'tDCS on','tDCS off'};
                else
                    fig_legend  = {'tDCS on'};
                end
            end
        end
        
        legend(fig_legend,'Location','southwest')
    end
    
end
