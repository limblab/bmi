load('temp_arm_params')
arm_params.online = 1;
if arm_params.online
    XPC_IP = '192.168.0.1';
    XPC_PORT = 24998;
    xpc = udp(XPC_IP,XPC_PORT);
    set(xpc,'ByteOrder','littleEndian');
    set(xpc,'LocalHost','192.168.0.10');
    set(xpc,'LocalPort',24998);
    set(xpc,'Timeout',.05);
    set(xpc,'InputBufferSize',100);
    set(xpc,'InputDatagramPacketSize',100);
    set(xpc, 'ReadAsyncMode', 'continuous');
%     fopen(xpc);

    m_data_1 = memmapfile('data_1.dat',...
    'Format',{'double',[1 4],'EMG_data';...
    'double',[1 1],'bmi_running';...
    'double',[1 2],'vel_predictions'},'Writable',true);

    m_data_2 = memmapfile('data_2.dat',...
    'Format',{'double',[1 1],'model_running';...
    'double',[1 2],'x_hand';...
    'double',[1 4],'musc_force';...
    'double',[1 2],'F_end';...
    'double',[1 2],'shoulder_pos';...
    'double',[1 2],'elbow_pos';...
    'double',[1 2],'theta'},'Writable',true);
else
    xpc = [];
    m_data_1.Data.EMG_data = zeros(1,4);
    m_data_1.Data.bmi_running = 2;
    m_data_1.Data.vel_predictions = zeros(1,2);
    m_data_2.Data.model_running = 0;    
%     m_data_2.Data.file_name = repmat(' ',1,200);
    m_data_2.Data.x_hand = [0 0];
    m_data_2.Data.musc_force = zeros(1,4);
    m_data_2.Data.F_end = zeros(1,2);
    m_data_2.Data.shoulder_pos = zeros(1,2);
    m_data_2.Data.elbow_pos = zeros(1,2);
    m_data_2.Data.theta = zeros(1,2);
end

% Let know other instance that we're ready
m_data_2.Data.model_running = 1;

h = create_arm_model_figure;

run_arm_model(m_data_1,m_data_2,h,xpc)

