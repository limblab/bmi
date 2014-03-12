function run_arm_model(m_data_1,m_data_2,xpc,h)    
    cycle_counter = 0;    
    dt_hist = 0.05*ones(1,10);
    F_x = 0;
    F_y = 0;
    
    x0_default = [pi/4 3*pi/4 0 0];
    x0 = x0_default;
    arm_params = get_arm_params();
    arm_params.theta = x0(1:2);
    arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x0(1)) arm_params.l(1)*sin(x0(1))];
    arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x0(2)) arm_params.l(2)*sin(x0(2))];   
    
    while (m_data_1.Data.bmi_running)
%     while true
        tic
        cycle_counter = cycle_counter+1;
%         m_data_1.Data.bmi_running
%         if mod(cycle_counter,100)==0
%             clc
%             disp(['Running arm model, cycle ' num2str(cycle_counter)])
%         end
           
        EMG_data = m_data_1.Data.EMG_data;
        EMG_data = min(EMG_data,1);        

        arm_params.X_gain = -2*arm_params.left_handed+1;

%         arm_params.F_end = [0 0];
         
%         xpc_data = 1;
%         i=0;
        fopen(xpc);
        xpc_data = fread(xpc);
        fclose(xpc);
%         while ~isempty(xpc_data)            
%             i = i+1;
%             flushinput(xpc)
%             xpc_data = fread(xpc);
%             [i size(xpc_data)]
%         end
        
        if length(xpc_data)>=72
            F_x = typecast(uint8(xpc_data(41:48)),'double');
            F_y = typecast(uint8(xpc_data(49:56)),'double');
%             F_x = typecast(uint8(xpc_data(57:64)),'double');
%             F_y = typecast(uint8(xpc_data(65:72)),'double');
        else
            disp('No udp data read')
        end
        arm_params.F_end = .1*[F_x F_y];
        clc

        arm_params.musc_act = EMG_data;
        arm_params.musc_l0 = sqrt(2*arm_params.m_ins.^2)+...
                        0*sqrt(2*arm_params.m_ins.^2)/5.*...
                        (rand(1,length(arm_params.m_ins))-.5);
        arm_params.theta_ref = [3*pi/4 pi/2]; 
        arm_params.X_s = [0 0];

%         t_temp = [0 mean(dt_hist)];
        t_temp = [0 dt_hist(1)];
        
        old_X_h = arm_params.X_h;
        [~,x] = ode45(@(t,x0) sandercock_model(t,x0,arm_params),t_temp,x0);
        
        arm_params.theta = x(end,1:2);
        arm_params.X_e = arm_params.X_sh + [arm_params.l(1)*cos(x(end,1)) arm_params.l(1)*sin(x(end,1))];
        arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x(end,2)) arm_params.l(2)*sin(x(end,2))];   
                
        % If model becomes unstable, restart
        if abs(arm_params.X_h(1:2)-old_X_h(1:2))>.1
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

        dt_hist = shift(dt_hist,1);
        dt_hist(1) = toc;
%         set(h.h_plot_1,'YData',dt_hist)
%         set(h.h_plot_2,'XData',[0 F_x],'YData',[0 F_y])
%         drawnow
    end
    if exist('xpc','var')
        fclose(xpc);
        delete(xpc);
        clear xpc;
        close all
        exit
    end
end