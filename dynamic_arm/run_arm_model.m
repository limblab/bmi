function run_arm_model(m_data_1,m_data_2,h,xpc)    
    cycle_counter = 0;    
    dt_hist = 0.01*ones(1,10);    
    F_x = 0;
    F_y = 0;
    encoder_theta = [0 0];
    forces = [F_x F_y];
    filtered_emg = [0 0 0 0];
    
    x0_default = [pi/4 3*pi/4 0 0]; 
    x0 = x0_default;   
    x0_b = [x0 x0];
    i = 0;
    options = odeset('RelTol',1e-2,'AbsTol',1e-2);
    arm_params_base = [];
    flag_reset = 0;
    EMG_data = zeros(size(m_data_1.Data.EMG_data));    
    temp_cocontraction = 0;
    cocontraction_display = 0;
    while ((m_data_1.Data.bmi_running)) % && i < 300)
        tic
        i = i+1;
        old_arm_params = arm_params_base;

        arm_params = evalin('base','arm_params');
        arm_params_base = arm_params;
        
        arm_params.dt = dt_hist(1);
        if ~isequal(old_arm_params,arm_params_base)
            save('temp_arm_params','arm_params');
            disp('Saved arm parameters')
        end        
        
        arm_params.cocontraction = temp_cocontraction;
        
        if ~(strcmp(arm_params.control_mode,'point_mass') || strcmp(arm_params.control_mode,'emg_cartesian'))
            arm_params.x_gain = -2*arm_params.left_handed+1;
        else
            arm_params.x_gain = 1;
        end
        
        arm_params.theta = x0(1:2);  
        
        if ~(strcmp(arm_params.control_mode,'point_mass') || strcmp(arm_params.control_mode,'emg_cartesian'))
            arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x0(1)) arm_params.l(1)*sin(x0(1))];
            arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x0(2)) arm_params.l(2)*sin(x0(2))];   
        else
            arm_params.X_e = x0(1:2);
            arm_params.X_h = x0(1:2);   
        end
        
        cycle_counter = cycle_counter+1;
        old_EMG_data = EMG_data;
        if arm_params.online   
            EMG_data = m_data_1.Data.EMG_data;
            EMG_labels = m_data_1.Data.EMG_labels;
            EMG_labels = EMG_label_conversion(EMG_labels);
            
            EMG_idx = zeros(1,4);
            EMG_order = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'}; 
            EMG_order = {'AD','PD','BI','TRI'}; 
            for iEMG = 1:length(EMG_order)
                temp = find(~cellfun(@isempty,strfind(EMG_labels,EMG_order{iEMG})));
                if ~isempty(temp)
                    EMG_idx(iEMG) = temp;
                end
            end            
            BRD_idx = find(~cellfun(@isempty,strfind(EMG_labels,'BRD')));
            if ~isempty(BRD_idx) && arm_params.use_brd
                EMG_idx(3) = BRD_idx;
            end
            temp_emg = zeros(1,4);
            for iEMG = 1:4
                if EMG_idx(iEMG)>0
                    temp_emg(iEMG) = EMG_data(EMG_idx(iEMG));
                end
            end
            EMG_data = temp_emg;  
%             if arm_params.emg_adaptation_rate>0
%                 arm_params.emg_max = max(arm_params.emg_max,EMG_data);
%                 arm_params.emg_max = arm_params.emg_max*exp(-dt_hist(1)/arm_params.emg_adaptation_rate);
%                 arm_params.emg_min = min(arm_params.emg_min,EMG_data);
%                 arm_params.emg_min = (arm_params.emg_min-arm_params.emg_max)*exp(-dt_hist(1)/arm_params.emg_adaptation_rate)+arm_params.emg_max;
%             end

            EMG_data = (EMG_data-arm_params.emg_min)./(arm_params.emg_max-arm_params.emg_min);            
            EMG_data(EMG_data<0) = 0;
            vel_data = m_data_1.Data.vel_predictions;
        else
            EMG_data = m_data_1.Data.EMG_data;
            EMG_labels = m_data_1.Data.EMG_labels;
            EMG_labels = EMG_label_conversion(EMG_labels);
            
            EMG_idx = zeros(1,4);
            EMG_order = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'}; 
            EMG_order = {'AD','PD','BI','TRI'}; 
            for iEMG = 1:length(EMG_order)
                temp = find(~cellfun(@isempty,strfind(EMG_labels,EMG_order{iEMG})));
                if ~isempty(temp)
                    EMG_idx(iEMG) = temp;
                end
            end            
            BRD_idx = find(~cellfun(@isempty,strfind(EMG_labels,'BRD')));
            if ~isempty(BRD_idx) && arm_params.use_brd
                EMG_idx(3) = BRD_idx;
            end
            temp_emg = zeros(1,4);
            for iEMG = 1:4
                if EMG_idx(iEMG)>0
                    temp_emg(iEMG) = EMG_data(EMG_idx(iEMG));
                end
            end
            EMG_data = temp_emg;  
%             if arm_params.emg_adaptation_rate>0
%                 arm_params.emg_max = max(arm_params.emg_max,EMG_data);
%                 arm_params.emg_max = arm_params.emg_max*exp(-dt_hist(1)/arm_params.emg_adaptation_rate);
%                 arm_params.emg_min = min(arm_params.emg_min,EMG_data);
%                 arm_params.emg_min = (arm_params.emg_min-arm_params.emg_max)*exp(-dt_hist(1)/arm_params.emg_adaptation_rate)+arm_params.emg_max;
%             end

            EMG_data = (EMG_data-arm_params.emg_min)./(arm_params.emg_max-arm_params.emg_min);            
            EMG_data(EMG_data<0) = 0;
            vel_data = m_data_1.Data.vel_predictions;
                        
            forces = m_data_1.Data.forces;            
            F_x = 5*forces(1);
            F_y = 5*forces(2);
%             temp_t = [.05*cycle_counter .05*cycle_counter .05*cycle_counter .05*cycle_counter];
%             EMG_data = 500+500*[cos(temp_t(1)) cos(temp_t(2)+pi/2) cos(temp_t(3)+pi/4) cos(temp_t(4)+3*pi/4)];
%             EMG_data = (EMG_data-arm_params.emg_min)./(arm_params.emg_max-arm_params.emg_min);        
%             EMG_data = EMG_data.^2;
%             EMG_labels = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'};            
%             vel_data = 1*[cos(.1*temp_t(1)) cos(.3*temp_t(2)+pi/2)];
        end        
               
        EMG_data(isnan(EMG_data)) = 0;
        
        EMG_data = (1-arm_params.EMG_filter)*EMG_data + arm_params.EMG_filter*old_EMG_data;
        
        EMG_data = min(EMG_data,1);
        EMG_data = max(EMG_data,0);
        
        if isnan(F_x) || isnan(F_y)
            F_x = 0;
            F_y = 0;
        end
        
        if isobject(xpc)
            if mod(i,1) == 0
                fopen(xpc);
                xpc_data = fread(xpc);
                fclose(xpc);
            end

            if length(xpc_data)>=72
                F_x = typecast(uint8(xpc_data(41:48)),'double');
                F_y = typecast(uint8(xpc_data(49:56)),'double');
                encoder_theta = [typecast(uint8(xpc_data(57:64)),'double') typecast(uint8(xpc_data(65:72)),'double')];
            else
                disp('No udp data read')
            end
        end
        arm_params.F_end = [F_x F_y];

        if arm_params.walls
            if arm_params.X_h(1) < -.12
                arm_params.F_end(1) = -(arm_params.X_h(1)-(-.12))*arm_params.x_gain*500;
            end
            if arm_params.X_h(1) > .12
                arm_params.F_end(1) = -(arm_params.X_h(1)-(.12))*arm_params.x_gain*500;
            end
            if arm_params.X_h(2) < -.1
                arm_params.F_end(2) = -(arm_params.X_h(2)-(-.1))*500;
            end
            if arm_params.X_h(2) > .1
                arm_params.F_end(2) = -(arm_params.X_h(2)-(.1))*500;
            end
        end       
        
        arm_params.musc_act = EMG_data;
        arm_params.musc_l0 = sqrt(2*arm_params.m_ins.^2)+...
                        0*sqrt(2*arm_params.m_ins.^2)/5.*...
                        (rand(1,length(arm_params.m_ins))-.5);
        arm_params.commanded_vel = vel_data;

        t_temp = [0 mean(dt_hist)];
        
        old_X_h = arm_params.X_h;
        
        arm_params.F_end(1) = arm_params.x_gain*arm_params.F_end(1);
        arm_params.T = arm_params.x_gain*arm_params.T;
        
        switch(arm_params.control_mode)
            case 'hill'
                [t,x] = ode15s(@(t,x0) sandercock_model(t,x0(1:4),arm_params),t_temp,x0(1:4),options);
                [~,out_var] = sandercock_model(t,x(end,:),arm_params);
            case 'prosthesis'
                [t,x] = ode15s(@(t,x0) prosthetic_arm_model(t,x0(1:4),arm_params),t_temp,x0(1:4),options);
                [~,out_var] = prosthetic_arm_model(t,x(end,:),arm_params);
            case 'hu'
                if arm_params.block_shoulder
                    EMG_data(1:2) = 0;
                    arm_params.musc_act(1:2) = 0;
                    temp = min((.00001+arm_params.musc_act(3))/(.00001+arm_params.musc_act(4)),...
                        (.00001+arm_params.musc_act(4))/(.00001+arm_params.musc_act(3)));
%                     temp = 1;
                    if arm_params.cocontraction_is_sum
                        cocontraction_new = (arm_params.musc_act(3) + arm_params.musc_act(4));
                    else
                        cocontraction_new = temp * (arm_params.musc_act(3) + arm_params.musc_act(4));
                    end
                    arm_params.cocontraction = (1-arm_params.cocontraction_filter)*cocontraction_new +...
                        arm_params.cocontraction_filter*arm_params.cocontraction;
                    temp_cocontraction = arm_params.cocontraction;
                    
                    if arm_params.display_cocontraction_index
                        cocontraction_display_new = temp * (arm_params.musc_act(3) + arm_params.musc_act(4));
                    else
                        cocontraction_display_new = cocontraction_new;
                    end
                    cocontraction_display = (1-arm_params.cocontraction_filter)*cocontraction_display_new +...
                        arm_params.cocontraction_filter*cocontraction_display;                    
                end
                [t,x] = ode15s(@(t,x0_b) hu_arm_model(t,x0_b,arm_params),t_temp,x0_b,options);
                [~,out_var] = hu_arm_model(t,x(end,:),arm_params);
                x0 = x0_b(1:4);
%                 x = x(:,1:4);
                if arm_params.block_shoulder
                    x(:,[1 5]) = arm_params.null_angles(1);
                    x(:,[3 7]) = 0;
                end
            case 'miller'
                if ~isfield(arm_params,'musc_length_old')
                    arm_params.musc_length_old = [];
                end
                [t,x] = ode15s(@(t,x0) miller_arm_model(t,x0(1:4),arm_params),t_temp,x0(1:4),options);
                [~,out_var] = miller_arm_model(t,x(end,:),arm_params);
                arm_params.musc_length_old = out_var(7:8);
            case 'perreault'
                [t,x] = ode15s(@(t,x0) perreault_arm_model(t,x0(1:4),arm_params),t_temp,x0(1:4),options);
                [~,out_var] = perreault_arm_model(t,x(end,:),arm_params);
            case 'ruiz'
                [t,x] = ode15s(@(t,x0_b) ruiz_arm_model(t,x0_b,arm_params),t_temp,x0_b,options);
                [~,out_var] = ruiz_arm_model(t,x(end,:),arm_params);                
                x0 = x0_b(1:4);                
            case 'bmi'
                [t,x] = ode15s(@(t,x0) bmi_model(t,x0(1:4),arm_params),t_temp,x0(1:4),options);
                [~,out_var] = bmi_model(t,x(end,:),arm_params);
            case 'point_mass'
                [t,x] = ode15s(@(t,x0_b) point_mass_model(t,x0_b,arm_params),t_temp,x0_b,options);
                [~,out_var] = point_mass_model(t,x(end,:),arm_params);                
                x0 = x0_b(1:4); 
            case 'emg_cartesian'                                                
                filtered_emg_new = arm_params.musc_act;
                filtered_emg = (1-arm_params.emg_filter)*filtered_emg_new +...
                    arm_params.emg_filter*filtered_emg;         
                x = arm_params.emg_to_cursor_gain*[filtered_emg(arm_params.emg_x_positive) filtered_emg(arm_params.emg_y_positive) 0 0];
                x0 = x0_b(1:4);
                out_var(1:4) = filtered_emg;
                out_var(5:6) = arm_params.F_end;
        end
        musc_force = out_var(1:4);
        F_end = out_var(5:6);
        F_end(1) = arm_params.x_gain*F_end(1);
        
        m_data_2.Data.musc_force = musc_force;
        m_data_2.Data.F_end = F_end;
        m_data_2.Data.theta = encoder_theta;
        m_data_2.Data.cocontraction = arm_params.cocontraction;
        m_data_2.Data.cocontraction_display = cocontraction_display;
        
        arm_params.theta = x(end,1:2);
        if (strcmp(arm_params.control_mode,'point_mass') || strcmp(arm_params.control_mode,'emg_cartesian'))
            arm_params.X_e = x(end,1:2);
            arm_params.X_h = x(end,1:2);               
        else
            arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x(end,1)) arm_params.l(1)*sin(x(end,1))];
            arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x(end,2)) arm_params.l(2)*sin(x(end,2))];
        end
                        
        % If model becomes unstable, restart
        if ~(strcmp(arm_params.control_mode,'point_mass') || strcmp(arm_params.control_mode,'emg_cartesian')) & (abs(arm_params.X_h(1:2)-old_X_h(1:2))>.1 | (abs(arm_params.X_h) > 0.2)) | any(isnan(arm_params.X_h))
            x0 = x0_default;
            [~,x] = ode45(@(t,x0) sandercock_model(t,x0,arm_params),t_temp,x0);
            arm_params.theta = x(end,1:2);
            arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x(end,1)) arm_params.l(1)*sin(x(end,1))];
            arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x(end,2)) arm_params.l(2)*sin(x(end,2))];   
            flag_reset = 1;
        elseif (strcmp(arm_params.control_mode,'point_mass') || strcmp(arm_params.control_mode,'emg_cartesian')) & (abs(arm_params.X_h(1:2)-old_X_h(1:2))>.1) | any(isnan(arm_params.X_h))
            x = zeros(size(x));
            arm_params.X_e = [0 0];
            arm_params.X_h = [0 0];   
            flag_reset = 1;
        end
        
        x0 = x(end,:);
        if (strcmp(arm_params.control_mode,'hu') || strcmp(arm_params.control_mode,'ruiz') || strcmp(arm_params.control_mode,'point_mass'))...
            && ~flag_reset
            x0_b = x(end,:);
        elseif strcmp(arm_params.control_mode,'point_mass')
            x0_b = x0;
            flag_reset = 0;
        else
            x0_b = [x0 x0];
            flag_reset = 0;
        end
        
        xH = 100*arm_params.X_h;
        xH(1) = arm_params.x_gain * xH(1);
        xE = 100*arm_params.X_e;
        xE(1) = arm_params.x_gain * xE(1);
        xS = 100*arm_params.X_sh;
        xS(1) = arm_params.x_gain * xS(1);
        
        if strcmp(arm_params.control_mode,'point_mass')
            xS = xH;
            xE = xH;
            xH2 = 100*x(end,5:6);
            xE2 = xH2;
            xS2 = xH2;
        elseif strcmp(arm_params.control_mode,'emg_cartesian')
            xS = xH;
            xE = xH;
            xH2 = xH;
            xE2 = xH2;
            xS2 = xH2;
        elseif numel(x0) > numel(x0_default)
            xE2 = arm_params.X_sh + [arm_params.l(1)*cos(x(end,5)) arm_params.l(1)*sin(x(end,5))];                
            xH2 = xE2 + [arm_params.l(2)*cos(x(end,6)) arm_params.l(2)*sin(x(end,6))]; 
            xE2(1) = arm_params.x_gain * xE2(1);
            xH2(1) = arm_params.x_gain * xH2(1);
            xE2 = 100 * xE2;
            xH2 = 100 * xH2;
            xS2 = xS;
        else
            xE2 = [arm_params.x_gain*100*arm_params.X_sh(1) 100*arm_params.X_sh(2)];
            xH2 = [arm_params.x_gain*100*arm_params.X_sh(1) 100*arm_params.X_sh(2)];            
            xS2 = xS;
        end
        
        m_data_2.Data.x_hand = xH;
        m_data_2.Data.elbow_pos = xE;
        m_data_2.Data.shoulder_pos = xS;

        dt_hist = circshift(dt_hist,[0 1]);
        dt_hist(1) = toc; 
        if mod(i,5)==0  
            if any(~cellfun(@isempty,strfind(EMG_labels,'EMG_BRD'))) && arm_params.use_brd
                temp_label = get(h.h_emg_axis,'XTickLabel');
                temp_label{3} = 'Brd(up)';
                set(h.h_emg_axis,'XTickLabel',temp_label);
            else                
                temp_label = get(h.h_emg_axis,'XTickLabel');
                temp_label{3} = 'Bi(up)';
                set(h.h_emg_axis,'XTickLabel',temp_label);
            end
            set(h.h_plot_force,'XData',[0 F_x],'YData',[0 F_y])
            set(h.h_plot_arm,'XData',[xS(1) xE(1) xH(1)],...
                'YData',[xS(2) xE(2) xH(2)])
            set(h.h_plot_arm_2,'XData',[xS(1) xE2(1) xH2(1)],...
                'YData',[xS(2) xE2(2) xH2(2)])
            set(h.h_emg_bar,'YData',[EMG_data arm_params.commanded_vel arm_params.cocontraction])
            drawnow                       
            set(h.h_plot_dt,'YData',dt_hist)
        end
    end   
    quit
end