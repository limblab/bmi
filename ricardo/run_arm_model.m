function run_arm_model(m_data_1,m_data_2,h,xpc)    
    cycle_counter = 0;    
    dt_hist = 0.01*ones(1,10);    
    F_x = 0;
    F_y = 0;
    encoder_theta = [0 0];
    forces = [F_x F_y];
    
    x0_default = [pi/4 3*pi/4 0 0];
    x0 = x0_default;   
    x0_b = [x0 x0];
    i = 0;
%     xpc_data = zeros(512,1);    
    options = odeset('RelTol',1e-2,'AbsTol',1e-2);
    arm_params_base = [];
    flag_reset = 0;
    EMG_data = zeros(size(m_data_1.Data.EMG_data));
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

        arm_params.x_gain = -2*arm_params.left_handed+1;
        arm_params.theta = x0(1:2);
        arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x0(1)) arm_params.l(1)*sin(x0(1))];
        arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x0(2)) arm_params.l(2)*sin(x0(2))];
    
        
        cycle_counter = cycle_counter+1;
        old_EMG_data = EMG_data;
        if arm_params.online   
            EMG_data = m_data_1.Data.EMG_data;
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
            temp_t = [.05*cycle_counter .05*cycle_counter .05*cycle_counter .05*cycle_counter];
            EMG_data = 500+500*[cos(temp_t(1)) cos(temp_t(2)+pi/2) cos(temp_t(3)+pi/4) cos(temp_t(4)+3*pi/4)];
            EMG_data = (EMG_data-arm_params.emg_min)./(arm_params.emg_max-arm_params.emg_min);        
            EMG_data = EMG_data.^2;
%             EMG_data(1:4) = 0;
            vel_data = 1*[cos(.1*temp_t(1)) cos(.3*temp_t(2)+pi/2)];
        end        
        
%         assignin('base','arm_params',arm_params);        
        EMG_data(isnan(EMG_data)) = 0;
        
        EMG_data = (1-arm_params.EMG_filter)*EMG_data + arm_params.EMG_filter*old_EMG_data;
        
        EMG_data = min(EMG_data,1);
        EMG_data = max(EMG_data,0);
%         EMG_data = min(EMG_data,1);
            
%         F_x = m_data_1.Data.force_xpc(1);
%         F_y = m_data_1.Data.force_xpc(2);
        
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
        else   
            forces = min(forces,1);
            forces = max(forces,-1);
            F_x = 5*forces(1);
            F_y = 5*forces(2);
        end
        
        arm_params.F_end = [F_x F_y];
%         clc
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
%         if arm_params.walls
%             if arm_params.X_h(1) < -.12
%                 arm_params.F_end(1) = arm_params.x_gain*5;
%             end
%             if arm_params.X_h(1) > .12
%                 arm_params.F_end(1) = -arm_params.x_gain*5;
%             end
%             if arm_params.X_h(2) < -.1
%                 arm_params.F_end(2) = 5;
%             end
%             if arm_params.X_h(2) > .1
%                 arm_params.F_end(2) = -5;
%             end
%         end
        
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
%                 out_var
        end
        musc_force = out_var(1:4);
        F_end = out_var(5:6);
        F_end(1) = arm_params.x_gain*F_end(1);
        
        m_data_2.Data.musc_force = musc_force;
        m_data_2.Data.F_end = F_end;
        m_data_2.Data.theta = encoder_theta;
        
        arm_params.theta = x(end,1:2);
        arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x(end,1)) arm_params.l(1)*sin(x(end,1))];
        arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x(end,2)) arm_params.l(2)*sin(x(end,2))];   
                        
        % If model becomes unstable, restart
        if (abs(arm_params.X_h(1:2)-old_X_h(1:2))>.1 | (abs(arm_params.X_h) > 0.2)) | any(isnan(arm_params.X_h))
            x0 = x0_default;
            [~,x] = ode45(@(t,x0) sandercock_model(t,x0,arm_params),t_temp,x0);
            arm_params.theta = x(end,1:2);
            arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x(end,1)) arm_params.l(1)*sin(x(end,1))];
            arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x(end,2)) arm_params.l(2)*sin(x(end,2))];   
            flag_reset = 1;
        end
        
        x0 = x(end,:);
        if (strcmp(arm_params.control_mode,'hu') || strcmp(arm_params.control_mode,'ruiz')) && ~flag_reset
            x0_b = x(end,:);
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
        
        if numel(x0) > numel(x0_default)
            xE2 = arm_params.X_sh + [arm_params.l(1)*cos(x(end,5)) arm_params.l(1)*sin(x(end,5))];                
            xH2 = xE2 + [arm_params.l(2)*cos(x(end,6)) arm_params.l(2)*sin(x(end,6))]; 
            xE2(1) = arm_params.x_gain * xE2(1);
            xH2(1) = arm_params.x_gain * xH2(1);
            xE2 = 100 * xE2;
            xH2 = 100 * xH2;
        else
            xE2 = [arm_params.x_gain*100*arm_params.X_sh(1) 100*arm_params.X_sh(2)];
            xH2 = [arm_params.x_gain*100*arm_params.X_sh(1) 100*arm_params.X_sh(2)];            
        end
        
        m_data_2.Data.x_hand = xH;
        m_data_2.Data.elbow_pos = xE;
        m_data_2.Data.shoulder_pos = xS;

        dt_hist = circshift(dt_hist,[0 1]);
        dt_hist(1) = toc; 
        if mod(i,5)==0           
            set(h.h_plot_force,'XData',[0 F_x],'YData',[0 F_y])
            set(h.h_plot_arm,'XData',[xS(1) xE(1) xH(1)],...
                'YData',[xS(2) xE(2) xH(2)])
            set(h.h_plot_arm_2,'XData',[xS(1) xE2(1) xH2(1)],...
                'YData',[xS(2) xE2(2) xH2(2)])
            set(h.h_emg_bar,'YData',[EMG_data arm_params.commanded_vel])
            drawnow                       
            set(h.h_plot_dt,'YData',dt_hist)
        end
    end   
    quit
end