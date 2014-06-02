function run_arm_model(m_data_1,m_data_2,xpc,h)    
    cycle_counter = 0;    
    dt_hist = 0.01*ones(1,10);
    F_x = 0;
    F_y = 0;
    forces = [F_x F_y];
    
    x0_default = [pi/4 3*pi/4 0 0];
    x0 = x0_default;   
    i = 0;
    xpc_data = zeros(512,1);    
    options = odeset('RelTol',1e-2,'AbsTol',1e-2);
    arm_params_base = [];
    while ((m_data_1.Data.bmi_running)) % && i < 300)
        i = i+1;
        old_arm_params = arm_params_base;

        arm_params = evalin('base','arm_params');
        arm_params_base = arm_params;
        
        if ~isequal(old_arm_params,arm_params_base)
            save('temp_arm_params','arm_params');
            disp('Saved arm parameters')
        end        

        arm_params.theta = x0(1:2);
        arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x0(1)) arm_params.l(1)*sin(x0(1))];
        arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x0(2)) arm_params.l(2)*sin(x0(2))];   
    
        tic
        cycle_counter = cycle_counter+1;
           
        EMG_data = m_data_1.Data.EMG_data;
        EMG_data = (EMG_data-arm_params.emg_min)./(arm_params.emg_max-arm_params.emg_min);        
        EMG_data(isnan(EMG_data)) = 0;
        EMG_data = min(EMG_data,1);
        EMG_data = max(EMG_data,0);
%         EMG_data = min(EMG_data,1);

        arm_params.X_gain = -2*arm_params.left_handed+1;
            
        if isobject(xpc)
            if mod(i,1) == 0
                fopen(xpc);
                xpc_data = fread(xpc);
                fclose(xpc);
            end

            if length(xpc_data)>=72
                F_x = typecast(uint8(xpc_data(41:48)),'double');
                F_y = typecast(uint8(xpc_data(49:56)),'double');
            else
                disp('No udp data read')
            end
        else            
%             cycle_counter = 0
%             cycle_counter = cycle_counter+1;
%             m_data_1.Data.EMG_data = .9*m_data_1.Data.EMG_data +...
%                 .1*rand(size(m_data_1.Data.EMG_data)).*...
%                 (2*(cos(cycle_counter/10000+[0 pi/3 1.5*pi pi/4])>0)-1);
%             m_data_1.Data.EMG_data =... .9*m_data_1.Data.EMG_data +...
%                 1.*...
%                 (.5*(cos(cycle_counter/100+[0 pi/3 1.5*pi pi/4]))+.5);
%             m_data_1.Data.EMG_data = min(m_data_1.Data.EMG_data,1);
%             m_data_1.Data.EMG_data = max(m_data_1.Data.EMG_data,0);
%             m_data_1.Data.EMG_data = .5*ones(size(m_data_1.Data.EMG_data));
%             m_data_1.Data.EMG_data
                        
            if mod(cycle_counter,200)==0
                m_data_1.Data.EMG_data = rand(1,4);
%                 forces = .99*forces +...
%                     .01*rand(1,2).*...
%                     (2*(cos(2*pi*cycle_counter/1000+[pi/3 1.5*pi])>0)-1);
%                 forces = 2*rand(1,2)-1;
            end
            
            forces = min(forces,1);
            forces = max(forces,-1);
            F_x = 5*forces(1);
            F_y = 5*forces(2);
            
        end
        
        arm_params.F_end = [F_x F_y];
%         clc
%         if arm_params.X_h(1) < -.12
%             arm_params.F_end(1) = 10;
%         end
%         if arm_params.X_h(1) > .12
%             arm_params.F_end(1) = -10;
%         end
%         if arm_params.X_h(2) < -.1
%             arm_params.F_end(2) = 10;
%         end
%         if arm_params.X_h(2) > .1
%             arm_params.F_end(2) = -10;
%         end
        
        arm_params.musc_act = EMG_data;
        arm_params.musc_l0 = sqrt(2*arm_params.m_ins.^2)+...
                        0*sqrt(2*arm_params.m_ins.^2)/5.*...
                        (rand(1,length(arm_params.m_ins))-.5);
%         arm_params.theta_ref = [3*pi/4 pi/2]; 
%         arm_params.X_s = [0 0];

        t_temp = [0 mean(dt_hist)];
%         t_temp = [0 dt_hist(1)];
%         t_temp = [0 0.01];
        
        old_X_h = arm_params.X_h;
        
        switch(arm_params.control_mode)
            case 'dynamic'
                [t,x] = ode45(@(t,x0) sandercock_model(t,x0,arm_params),t_temp,x0,options);
                [~,out_var] = sandercock_model(t,x(end,:),arm_params);
            case 'prosthesis'
                [t,x] = ode45(@(t,x0) prosthetic_arm_model(t,x0,arm_params),t_temp,x0,options);
                [~,out_var] = prosthetic_arm_model(t,x(end,:),arm_params);
        end
        
        m_data_2.Data.musc_force = out_var(1:4);
        m_data_2.Data.F_end = out_var(5:6);
        
        arm_params.theta = x(end,1:2);
        arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x(end,1)) arm_params.l(1)*sin(x(end,1))];
        arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x(end,2)) arm_params.l(2)*sin(x(end,2))];   
                
        % If model becomes unstable, restart
        if (abs(arm_params.X_h(1:2)-old_X_h(1:2))>.1 | (abs(arm_params.X_h) > 0.2))
            x0 = x0_default;
            [~,x] = ode45(@(t,x0) sandercock_model(t,x0,arm_params),t_temp,x0);
            arm_params.theta = x(end,1:2);
            arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x(end,1)) arm_params.l(1)*sin(x(end,1))];
            arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x(end,2)) arm_params.l(2)*sin(x(end,2))];   
        end
        
        x0 = x(end,:);
        
        xH = arm_params.X_h;
        xH(1) = arm_params.X_gain * xH(1);
        
        m_data_2.Data.x_hand = xH;
        m_data_2.Data.elbow_pos = 100*arm_params.X_e;
        m_data_2.Data.shoulder_pos = 100*arm_params.X_sh;

        if mod(i,1)==0
            dt_hist = circshift(dt_hist,[0 1]);
            dt_hist(1) = toc;
            set(h.h_plot_1,'YData',dt_hist)
            set(h.h_plot_2,'XData',[0 F_x],'YData',[0 F_y])
            set(h.h_plot_3,'XData',[arm_params.X_sh(1) arm_params.X_e(1) xH(1)],...
                'YData',[arm_params.X_sh(2) arm_params.X_e(2) xH(2)])
            set(h.h_emg_bar,'YData',EMG_data)
            drawnow
        end
        
    end
    if ~isempty('xpc')
        fclose(xpc);
        delete(xpc);
        clear xpc;
        close all
        exit
    end
end