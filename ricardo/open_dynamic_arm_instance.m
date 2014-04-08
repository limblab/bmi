function [m_data_1,m_data_2] = open_dynamic_arm_instance

    % Open new Matlab instance and create files for data transfer across instances
    delete('data_1.dat')
    delete('data_2.dat')

    EMG_data = zeros(1,4);
    bmi_running = 1;
    fid = fopen('data_1.dat','w');
    fwrite(fid, EMG_data, 'double');
    fwrite(fid, bmi_running, 'double');
    fclose(fid);

    model_running = 0;
    x_hand = zeros(1,2);
    musc_force = zeros(1,4);
    F_end = zeros(1,2);
    shoulder_pos = zeros(1,2);
    elbow_pos = zeros(1,2);
    fid = fopen('data_2.dat','w');
    fwrite(fid, model_running, 'double');
    fwrite(fid, x_hand, 'double');
    fwrite(fid, musc_force, 'double');
    fwrite(fid, F_end, 'double');
    fwrite(fid, shoulder_pos, 'double');
    fwrite(fid, elbow_pos, 'double');
    fclose(fid);

    m_data_1 = memmapfile('data_1.dat',...
    'Format',{'double',[1 4],'EMG_data';...
    'double',[1 1],'bmi_running'},'Writable',true);

    m_data_2 = memmapfile('data_2.dat',...
    'Format',{'double',[1 1],'model_running';...
    'double',[1 2],'x_hand';...
    'double',[1 4],'musc_force';...
    'double',[1 2],'F_end';...
    'double',[1 2],'shoulder_pos';...
    'double',[1 2],'elbow_pos'},'Writable',true);

    m_data_1.Data.bmi_running = 1;
    dos('start matlab -sd "C:\Users\system administrator\Desktop\bmi\ricardo" -r arm_model_container');

    disp('Opening dynamic arm Matlab instance, please wait')
    while(~m_data_2.Data.model_running)
        pause(.1)
    end
    disp('Finished opening dynamic arm Matlab instance, starting BMI')
end