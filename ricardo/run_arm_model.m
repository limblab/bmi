function [data,x0,xH] = run_arm_model(data,x0)

    emg_channels = find(~cellfun(@isempty,strfind(data.labels(:,1),'EMG')));
    emg_labels = data.labels(emg_channels);
    strings_to_match = {'EMG_AD';'EMG_PD';'EMG_BI';'EMG_TRI'};    
    for iLabel = 1:length(strings_to_match)
        idx(iLabel) = find(strcmp(emg_labels,strings_to_match(iLabel)));
    end
    
    [~,chan_idx,~] = intersect(data.analog_channels,emg_channels);
    EMG_data = data.analog(:,chan_idx);
    EMG_data = EMG_data(:,idx);
    
    EMG_data = mean(abs(EMG_data));
    
    if ~isfield(data,'EMG_max')
        data.EMG_max = zeros(size(EMG_data));
    end
    data.EMG_max = max(data.EMG_max,EMG_data);
    EMG_data = EMG_data./data.EMG_max;
    
    arm_params = get_arm_params();
    % hFig = create_arm_figure(arm_params);

    % script_filename = mfilename('fullpath');
    % [location,~,~] = fileparts(script_filename);

    if arm_params.left_handed
        file_suffix = 'left';
    else
        file_suffix = 'right';
    end

    arm_params.X_gain = -2*arm_params.left_handed+1;

%     x0 = [0 0 0 0];
    arm_params.F_end = [0 0];
    arm_params.musc_act = EMG_data;
    arm_params.musc_l0 = sqrt(2*arm_params.m_ins.^2)+...
                    0*sqrt(2*arm_params.m_ins.^2)/5.*...
                    (rand(1,length(arm_params.m_ins))-.5);
    arm_params.theta_ref = [3*pi/4 pi/2]; 
    arm_params.X_s = [0 0];

    t_temp = [0 arm_params.dt];
    [~,x] = ode45(@(t,x0) sandercock_model(t,x0,arm_params),t_temp,x0);
    arm_params.theta = x(end,1:2);
    arm_params.X_e = [arm_params.l(1)*cos(x(end,1)) arm_params.l(1)*sin(x(end,1))];
    arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x(end,2)) arm_params.l(2)*sin(x(end,2))];   
    x0 = x(end,:);
    xH = arm_params.X_h;
end