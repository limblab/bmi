%
% Characterize the PW to force relationship. Data should follow the force
% structure defined in get_pw_to_force
%
%   force = PW_TO_FORCE( force )
%   force = PW_TO_FORCE( force, pw_to_f_params )
%

function force = pw_to_force( force, varargin )

%------------------------------------
% read parameters. If no argument is passed load defaults
if nargin == 1
    params              = pw_to_force_params_defaults();
elseif nargin == 2
    params              = varargin{1};
end

%------------------------------------
% Preliminary stuff

% Preallocate a matrix to store evoke force. 
% Dimensions are: evoked force -by- force sensor -by- stimulus nbr -by- PW
aux.evoked_resp_length  = ( params.t_before + force.meta.stim_dur + params.t_after) ...
                            / 1000 * force.fs + 1; % in samples
aux.nbr_pws             = numel( force.meta.stim_pws );
force.evoked_force      = zeros( aux.evoked_resp_length, force.nbr_forces, ...
                            force.meta.nbr_stims, aux.nbr_pws );

                      
% -------------------------------------------------------------------------
% Check that the evoked responses fall within the recorded dataset, and
% fill the evoked responses matrix --à la STA

% calculate how many samples before and after the stimulus we need to look
% at for characterizing the evoked responses
aux.win_start           = - params.t_before / 1000 * force.fs;
aux.win_end             = (force.meta.stim_dur + params.t_after ) / 1000 * force.fs;

% check that neither the time before the first stimulus train, nor the time
% after the end of the last stimulus train, fall outside the recorded data
% window
if force.t_sync_pulses(1)*force.fs < abs(aux.win_start)
    warning('the first stimulus falls to early within the recorded data window; it will be discarded');
    force.t_sync_pulses(1) = [];
end
if ( force.t_sync_pulses(end)*force.fs + aux.win_end ) > ( force.data(end,1) * force.fs )
    warning('the last stimulus falls to late within the recorded data window; it will be discarded');
    force.t_sync_pulses(end) = [];
end

% Fill the 'evoked_force' matrix
% do for each PW
for i = 1:aux.nbr_pws
    
    % find which of the randomly ordered stimuli is at this PW
    aux.pos_stim        = find( force.stim_pw == force.meta.stim_pws(i) );
    
    for ii = 1:numel(aux.pos_stim)
       
        % find the sample when the current sync pulse occurs
       aux.sample_curr_sync = round( force.t_sync_pulses(aux.pos_stim(ii)) * force.fs );
       % and in which sample the window starts and ends
       aux.curr_win_start   = aux.win_start + aux.sample_curr_sync;
       aux.curr_win_end     = aux.win_end + aux.sample_curr_sync;
       
       % fill the matrix. Note that column 1 of force.data is the time
       force.evoked_force(:,:,ii,i) = force.data( aux.curr_win_start:aux.curr_win_end, ...
                                2:force.nbr_forces+1 ); 
    end
end

                        
% -------------------------------------------------------------------------
% The analysis itself

% 1. compute the mean and SD evoked response for each PW
% results will be stored in vectors with dimensions: 
%   time -by- force sensor -by- PW
force.analysis.mean     = zeros( aux.evoked_resp_length, force.nbr_forces, aux.nbr_pws );
force.analysis.std      = zeros( aux.evoked_resp_length, force.nbr_forces, aux.nbr_pws );

% do for each PW
for i= 1:aux.nbr_pws 
    force.analysis.mean(:,:,i) = mean(force.evoked_force(:,:,:,i),3);
    force.analysis.std(:,:,i) = std(force.evoked_force(:,:,:,i),0,3);
%     for ii = 1:force.nbr_forces
%         force.analysis.mean(:,ii,i) = mean(force.evoked_force(:,ii,:,i),1);
%     end 
end

% 2. Compute the peak evoked RECTIFIED force for each PW, as well as its
% mean and SD 
% preallocate matrices for data storage
force.analysis.peak     = zeros( force.meta.nbr_stims, force.nbr_forces, aux.nbr_pws );
force.analysis.mean_peak    = zeros( force.nbr_forces, aux.nbr_pws );
force.analysis.std_peak = zeros( force.nbr_forces, aux.nbr_pws );

% calculate peak ABSOLUTE force evoked by each stimulus
for i = 1:aux.nbr_pws 
    for ii = 1:force.nbr_forces
        force.analysis.peak(:,ii,i) = max(abs(force.evoked_force(:,ii,:,i)));
    end
end

% calculate mean and SD
for i = 1:aux.nbr_pws  
    force.analysis.mean_peak(:,i) = mean(force.analysis.peak(:,:,i),1);
    force.analysis.std_peak(:,i) = std(force.analysis.peak(:,:,i),0,1);
end

% -------------------------------------------------------------------------
% Plots

% handle to maximized figure
figure('units','normalized','outerposition',[0 0 1 1]);
% create vector with colors per PW
aux.colors          = jet(aux.nbr_pws);

%------------------------------------
% 1. evoked responses colored according to PW level

% create vector with time (ms)
aux.t_evoked_force  = ( aux.win_start:aux.win_end ) * 1000 / force.fs;
% vector for storing handles to plots - for color legend
aux.color_h         = zeros(force.nbr_forces,force.meta.nbr_stims,aux.nbr_pws);

% plot each evoked response
for i = 1:force.nbr_forces
    subplot(force.nbr_forces,2,1+2*(i-1)), hold on
    for ii = 1:aux.nbr_pws
        aux.color_h(i,:,ii) = plot(aux.t_evoked_force,squeeze(force.evoked_force(:,i,:,ii)),'color',aux.colors(ii,:));
    end
    xlim([aux.t_evoked_force(1) aux.t_evoked_force(end)])
    set(gca,'FontSize',16)
end

% and the mean...
for i = 1:force.nbr_forces
    subplot(force.nbr_forces,2,1+2*(i-1)), hold on
    for ii = 1:aux.nbr_pws
        plot(aux.t_evoked_force,force.analysis.mean(:,i,ii),'color',aux.colors(ii,:),'linewidth',2);
    end
    xlim([aux.t_evoked_force(1) aux.t_evoked_force(end)])
    set(gca,'FontSize',16)
end

% add legends and axis labels
for i = 1:force.nbr_forces
    subplot(force.nbr_forces,2,1+2*(i-1))
    ylabel(force.labels{i},'FontSize',16);
    legend(squeeze(aux.color_h(i,1,:)),strread(num2str(force.meta.stim_pws),'%s'),'FontSize',16);
    if i == force.nbr_forces
       xlabel('time (ms)','FontSize',16) 
    end
end

%------------------------------------
% 2. force vs. PW

% PW axis, in us
aux.pw_axis             = round(force.meta.stim_pws*1000); % round because sometimes linspace does weird things with the precision

% plot the peak rectified force for each trial
for i = 1:force.nbr_forces
    subplot(force.nbr_forces,2,2*i), hold on
    for ii = 1:aux.nbr_pws
        plot(aux.pw_axis(ii),force.analysis.peak(:,i,ii),'marker','o','markersize',12,'color',aux.colors(ii,:));
    end
    xlim([aux.pw_axis(1)-mean(diff(aux.pw_axis)), ...
        aux.pw_axis(end)+mean(diff(aux.pw_axis))]);
    set(gca,'FontSize',16)
end

% and the mean force per PW
for i = 1:force.nbr_forces
    subplot(force.nbr_forces,2,2*i), hold on
    plot(aux.pw_axis,force.analysis.mean_peak(i,:),'k','linewidth',2)
    plot(aux.pw_axis,force.analysis.mean_peak(i,:) + ...
        force.analysis.std_peak(i,:),'.-k','linewidth',1)
    plot(aux.pw_axis,force.analysis.mean_peak(i,:) - ...
        force.analysis.std_peak(i,:),'.-k','linewidth',1)
end

% add legends and axis labels
for i = 1:force.nbr_forces
    subplot(force.nbr_forces,2,2*i),
    ylabel(force.labels{i},'FontSize',16);
    if i == force.nbr_forces
       xlabel('pulse width (us)','FontSize',16) 
    end
end
