% function arm_model_container

    XPC_IP   = '192.168.0.1';
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
    'double',[1 2],'x_hand'},'Writable',true);

    %% Let know other instance that we're ready
    m_data_2.Data.model_running = 1;
    
%     close all
%     h.h_fig = figure;
%     subplot(411)
%     h.h_plot_1 = plot(1:10,zeros(1,10),'-');    
%     ylim([0 0.1])
%     subplot(412)
%     plot(0,0,'.k')
%     h.h_plot_2 = plot([0 0],[0 0],'-r');
%     xlim([-10 10])
%     ylim([-10 10])
%     axis square
%     drawnow
    h = [];
    run_arm_model(m_data_1,m_data_2,xpc,h)
    
% end