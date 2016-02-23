%
% Characterize the PW to force relationship. Data should follow the force
% structure defined in get_pw_to_force
%
%   force = PW_TO_FORCE( force )
%   force = PW_TO_FORCE( force, pw_to_f_params )
%
%   Note: the default params struct needs to be fixed !!!!!
%   Note2: need to add calculations and plots of raw forces, now only
%   rectified

function force = pw_to_force( force, varargin )

%------------------------------------
% read parameters. If no argument is passed load defaults
if nargin == 1
    params              = pw_to_force_params_defaults();
elseif nargin == 2
    params              = varargin{1};
end


% define struct to store some stuff
aux                 = struct();
aux.nbr_pws         = length(force.meta.stim_pws);


% -------------------------------------------------------------------------
% The analysis itself

% 1. compute the mean and SD evoked response for each PW
% results will be stored in vectors with dimensions: 
%   time -by- force sensor -by- PW
force.analysis.mean         = zeros( force.length_evoked_force, force.nbr_forces, aux.nbr_pws );
force.analysis.std          = zeros( force.length_evoked_force, force.nbr_forces, aux.nbr_pws );

% do for each PW
for i= 1:aux.nbr_pws
    force.analysis.mean(:,:,i) = mean(force.evoked_force(:,:,force.stim_pws==force.meta.stim_pws(i)),3);
    force.analysis.std(:,:,i) = std(force.evoked_force(:,:,force.stim_pws==force.meta.stim_pws(i)),0,3);
%     for ii = 1:force.nbr_forces
%         force.analysis.mean(:,ii,i) = mean(force.evoked_force(:,ii,:,i),1);
%     end 
end


% 2. Compute the peak evoked RECTIFIED force for each PW, as well as its
% mean and SD

% preallocate matrices for data storage
force.analysis.peak_rect    = zeros( force.meta.nbr_stims, force.nbr_forces, aux.nbr_pws );
force.analysis.peak         = zeros( force.meta.nbr_stims, force.nbr_forces, aux.nbr_pws );
force.analysis.mean_peak_rect = zeros( force.nbr_forces, aux.nbr_pws );
force.analysis.std_peak_rect  = zeros( force.nbr_forces, aux.nbr_pws );

% get sample at which stimulation started 
indx_stim                   = params.t_before*force.fs/1000 + 1;
% get indexes baseline interval 
int_baseline                = 1:indx_stim-1; 

% calculate peak ABSOLUTE and RAW (signed) force evoked by each stimulus,
% by simply looking for the maximum of the evoked force in each direction 
for i = 1:aux.nbr_pws
    for ii = 1:force.nbr_forces
        indx_this_pw        = find(force.stim_pws==force.meta.stim_pws(i));
%        [aux_max, indx_max] = max(abs(force.evoked_force(indx_stim:end,ii,force.stim_pws==force.meta.stim_pws(i))));
        [aux_max, indx_max] = max(abs(force.evoked_force(indx_stim:end,ii,indx_this_pw)));
        force.analysis.peak_rect(:,ii,i) = squeeze(aux_max);
        indx_max            = squeeze(indx_max);
%         % ToDo
%         % peak raw (signed) force
%         for iii = 1:length(indx_max)
%             force.analysis.peak(:,ii,i) = force.evoked_force(indx_stim+indx_max(iii)-1,ii,indx_this_pw);
%         end
    end
end

% calculate baseline rectif force
% ToDo


% calculate mean and SD
for i = 1:aux.nbr_pws
    for ii = 1:force.nbr_forces
        force.analysis.mean_peak_rect(ii,i) = mean(force.analysis.peak_rect(:,ii,i),1);
        force.analysis.std_peak_rect(ii,i) = std(force.analysis.peak_rect(:,ii,i),0,1);
    end
end


% 2. Compute the 2D projection. This assumes the monkey is in the isometric
% box




% -------------------------------------------------------------------------
% Plots

% handle to maximized figure
figure('units','normalized','outerposition',[0 0 1 1]);
% create vector with colors per PW
aux.colors                  = jet(aux.nbr_pws);

%------------------------------------
% 1. evoked responses colored according to PW level

% create vector with time (ms)
aux.t_evoked_force          = - params.t_before : 1000/force.fs : ...
                                params.t_after+params.train_dur;
% PW axis, in us
aux.pw_axis                 = round(force.meta.stim_pws*1000); % round because sometimes linspace does weird things with the precision
% vector for storing handles to plots - for color legend
aux.colors                  = jet(aux.nbr_pws);
% create string for legend
for i = 1:aux.nbr_pws
    lgnd{i} = [num2str(force.meta.stim_pws(i)*1000) ' us'];
end
% 

% plot each evoked response
for i = 1:force.nbr_forces
    subplot(force.nbr_forces,2,1+2*(i-1)), hold on
    for ii = 1:aux.nbr_pws
        plot(aux.t_evoked_force,squeeze(force.evoked_force(:,i,force.stim_pws==force.meta.stim_pws(ii))),'color',aux.colors(ii,:));
        % plot mean response
        axl(ii) = plot(aux.t_evoked_force,force.analysis.mean(:,i,ii),'color',aux.colors(ii,:),'linewidth',3,'linestyle','-.');
    end
    xlim([aux.t_evoked_force(1) aux.t_evoked_force(end)])
    if i == force.nbr_forces
        xlabel('time (s)','FontSize',14)
    end
    ylabel(force.labels{i},'FontSize',14)
    set(gca,'FontSize',14),set(gca,'TickDir','out')
end
legend(axl,lgnd),%legend('boxoff')

% % add legends and axis labels
% for i = 1:force.nbr_forces
%     subplot(force.nbr_forces,2,1+2*(i-1))
%     ylabel(force.labels{i},'FontSize',16);
%     legend(squeeze(aux.color_h(i,1,:)),strread(num2str(force.meta.stim_pws),'%s'),'FontSize',16);
%     if i == force.nbr_forces
%        xlabel('time (ms)','FontSize',16) 
%     end
% end

%------------------------------------
% 2. force vs. PW

% plot the peak rectified force for each trial
for i = 1:force.nbr_forces
    subplot(force.nbr_forces,2,2*i), hold on
    for ii = 1:aux.nbr_pws
        plot(aux.pw_axis(ii),force.analysis.peak_rect(:,i,ii),'marker','o','markersize',12,'color',aux.colors(ii,:));
    end
    xlim([aux.pw_axis(1)-mean(diff(aux.pw_axis)), ...
        aux.pw_axis(end)+mean(diff(aux.pw_axis))]);
    % plot the mean +/- SD
    plot(aux.pw_axis,force.analysis.mean_peak_rect(i,:),'k','linewidth',2)
    plot(aux.pw_axis,force.analysis.mean_peak_rect(i,:) + ...
        force.analysis.std_peak_rect(i,:),'.-','color',[.5 .5 .5],'linewidth',1)
    plot(aux.pw_axis,force.analysis.mean_peak_rect(i,:) - ...
        force.analysis.std_peak_rect(i,:),'.-k','color',[.5 .5 .5],'linewidth',1)
    set(gca,'FontSize',14),set(gca,'TickDir','out')
    ylabel([force.labels{i} ' rectif'],'FontSize',14)
    if i == force.nbr_forces
        xlabel('pulse width (us)','FontSize',14)
    end
end

%------------------------------------
% 2. Polar plot with force vs. PW

% % plot the peak rectified force for each trial
% for i = 1:force.nbr_forces
%     subplot(force.nbr_forces,3,2*i), hold on
%     for ii = 1:aux.nbr_pws
%         plot(aux.pw_axis(ii),force.analysis.peak_rect(:,i,ii),'marker','o','markersize',12,'color',aux.colors(ii,:));
%     end
%     xlim([aux.pw_axis(1)-mean(diff(aux.pw_axis)), ...
%         aux.pw_axis(end)+mean(diff(aux.pw_axis))]);
%     % plot the mean +/- SD
%     plot(aux.pw_axis,force.analysis.mean_peak_rect(i,:),'k','linewidth',2)
%     plot(aux.pw_axis,force.analysis.mean_peak_rect(i,:) + ...
%         force.analysis.std_peak_rect(i,:),'.-','color',[.5 .5 .5],'linewidth',1)
%     plot(aux.pw_axis,force.analysis.mean_peak_rect(i,:) - ...
%         force.analysis.std_peak_rect(i,:),'.-k','color',[.5 .5 .5],'linewidth',1)
%     set(gca,'FontSize',14),set(gca,'TickDir','out')
% end
