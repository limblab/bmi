function arm_params = get_default_arm_params(arm_params_in)

% Monkey
arm_params_default.GENERAL_PARAMETERS = 0;
arm_params_default.control_mode = 'hu';
arm_params_default.left_handed = 1;
arm_params_default.m = [.5, .5];
arm_params_default.m_end = 0;
arm_params_default.l = [.22, .25]; %segment lengths l1, l2
arm_params_default.null_angles = [pi/4 3*pi/4];
arm_params_default.X_sh = [.05 -.3];
arm_params_default.c = [0, 0];
arm_params_default.emg_min = zeros(1,4);
arm_params_default.emg_max = 1*ones(1,4);
arm_params_default.emg_adaptation_rate = -1;
arm_params_default.walls = 1;
arm_params_default.EMG_filter = 0;
arm_params_default.T = 0*[2;-.2];
arm_params_default.max_torque = 1000;
arm_params_default.online = 1;
arm_params_default.cocontraction_filter = 0.1;

% Hill arm
arm_params_default.HILL_MODEL_PARAMETERS = 0;
arm_params_default.F_max = [1000 1000 1000 1000];
arm_params_default.m_ins = [.02 .02 .02 .02];
arm_params_default.Ksh = 60; 
arm_params_default.Kl = 1;
arm_params_default.k_gain = 23;
%     musc_length = 0:.001:.04;
%     figure;
%     plot(musc_length,arm_params_default.F_max(1).*exp(arm_params_default.Ksh*(musc_length-arm_params_default.Kl*2*arm_params_default.m_ins(1))./(arm_params_default.Kl*2*arm_params_default.m_ins(1))));
%     ylim([0 500])
%     xlim([0 .04])

% Prosthetic arm
arm_params_default.PROSTHETIC_MODEL_PARAMETERS = 0;
arm_params_default.P_gain = 5;
arm_params_default.Vmax = 10;
arm_params_default.emg_thres = .1;

% Hu/Perreault arm
arm_params_default.HU_MODEL_PARAMETERS = 0;
arm_params_default.emg_to_torque_gain = [4 4];
arm_params_default.joint_stiffness_min = [0 0];
arm_params_default.joint_stiffness_max = [10 10];
arm_params_default.joint_damping_min = [.8 .8];
arm_params_default.joint_damping_max = [.8 .8];
arm_params_default.block_shoulder = 1;

% Ruiz arm
arm_params_default.RUIZ_MODEL_PARAMETERS = 0;
arm_params_default.emg_to_force_gain = [30 30];
arm_params_default.endpoint_stiffness_min = 3;
arm_params_default.endpoint_stiffness_max = 10;
arm_params_default.endpoint_damping_min = 2;
arm_params_default.endpoint_damping_max = 5;

% Point mass
arm_params_default.POINT_MASS_PARAMETERS = 0;
arm_params_default.m_pm = 1;
arm_params_default.c_pm = 100;
arm_params_default.emg_to_force_gain_pm = [10 10];
arm_params_default.endpoint_stiffness_min_pm = 0;
arm_params_default.endpoint_stiffness_max_pm = 0;
arm_params_default.endpoint_damping_min_pm = 0;
arm_params_default.endpoint_damping_max_pm = 0;

arm_params_default.NON_PARAMETERS = 0;
arm_params_default.cocontraction = 0;

arm_param_fields = fields(arm_params_default);
for iField = 1:numel(arm_param_fields)
    if isfield(arm_params_in,arm_param_fields{iField})
        arm_params.(arm_param_fields{iField}) = arm_params_in.(arm_param_fields{iField});
    else
        arm_params.(arm_param_fields{iField}) = arm_params_default.(arm_param_fields{iField});
    end
end