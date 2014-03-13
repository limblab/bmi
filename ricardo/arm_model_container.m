% function arm_model_container
    online = 1;
    if online
        XPC_IP = '192.168.0.1';
        XPC_PORT = 24998;
        xpc = udp(XPC_IP,XPC_PORT);
        set(xpc,'ByteOrder','littleEndian');
        set(xpc,'LocalHost','192.168.0.10');
        set(xpc,'LocalPort',24998);
        set(xpc,'Timeout',.1);
        set(xpc,'InputBufferSize',512);
        set(xpc,'InputDatagramPacketSize',512);

        m_data_1 = memmapfile('data_1.dat',...
        'Format',{'double',[1 4],'EMG_data';...
        'double',[1 1],'bmi_running'},'Writable',true);

        m_data_2 = memmapfile('data_2.dat',...
        'Format',{'double',[1 1],'model_running';...
        'double',[1 2],'x_hand';...
        'double',[1 4],'musc_force';...
        'double',[1 2],'F_end'},'Writable',true);
    else
        xpc = [];
        m_data_1.Data.EMG_data = zeros(1,4);
        m_data_1.Data.bmi_running = 2;
        m_data_2.Data.model_running = 0;
        m_data_2.Data.x_hand = [0 0];
        m_data_2.Data.musc_force = zeros(1,4);
        m_data_2.Data.F_end = zeros(1,2);
    end

    %% Let know other instance that we're ready
    m_data_2.Data.model_running = 1;
    
    h = [];
    
    close all
    h.h_fig = figure;
    subplot(221)
    h.h_plot_1 = plot(1:10,zeros(1,10),'-');    
    ylim([0 0.1])
    subplot(222)
    plot(0,0,'.k')
    h.h_plot_2 = plot([0 0],[0 0],'-r');
    xlim([-10 10])
    ylim([-10 10])    
    axis square
    subplot(223)    
    h.h_plot_3 = plot(0,0,'-k');    
    xlim([-1 1])
    ylim([-1 1]) 
    axis square
    drawnow
    
    run_arm_model(m_data_1,m_data_2,xpc,h)
    
% end