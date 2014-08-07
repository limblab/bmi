function arm_params = get_default_arm_params(arm_params_in)

%parameters
% arm_params_default.g = 0;

% Monkey
arm_params_default.m = [.5, .5];
arm_params_default.l = [.2, .2]; %segment lengths l1, l2
arm_params_default.F_max = [1000 1000 1000 1000];
arm_params_default.X_sh = [.05 -.3];
arm_params_default.c = [5, 5];
arm_params_default.emg_min = zeros(1,4);
arm_params_default.emg_max = 1000*ones(1,4);
arm_params_default.emg_adaptation_rate = -1;
arm_params_default.walls = 1;
arm_params_default.block_shoulder = 0;

% % Human
% arm_params_default.m = [1, 1];
% arm_params_default.l = [.5, .5]; %segment lengths l1, l2
% arm_params_default.c = [30, 30];
% arm_params_default.X_sh = [0 -.7];
% arm_params_default.F_max = [1000 1000 1000 1000];

arm_params_default.m_ins = [.02 .02 .02 .02];
arm_params_default.lc = arm_params_default.l/2; %distance from center
arm_params_default.i = [arm_params_default.m(1)*arm_params_default.l(1)^2/3, arm_params_default.m(2)*arm_params_default.l(2)^2/3]; %moments of inertia i1, i2, need to validate coef's

% arm_params_default.Ksh = 3;
% arm_params_default.Kl = .8;
arm_params_default.Ksh = 60; 
arm_params_default.Kl = 1;
%     musc_length = 0:.001:.04;
%     figure;
%     plot(musc_length,arm_params_default.F_max(1).*exp(arm_params_default.Ksh*(musc_length-arm_params_default.Kl*2*arm_params_default.m_ins(1))./(arm_params_default.Kl*2*arm_params_default.m_ins(1))));
%     ylim([0 500])
%     xlim([0 .04])

arm_params_default.null_angles = [pi/4 3*pi/4];
% arm_params_default.Kl = 1;
arm_params_default.k_gain = 23;

arm_params_default.T = 0*[2;-.2];
arm_params_default.dt = 0.05;
% arm_params_default.t = 0:arm_params_default.dt:50;
% arm_params_default.dt = diff(arm_params_default.t(1:2));

arm_params_default.left_handed = 1;
% arm_params_default.monkey_offset = [(-2*arm_params_default.left_handed+1)*.08 -sqrt(sum(arm_params_default.l.^2))]; 

% Prosthetic arm
arm_params_default.P_gain = 5;
arm_params_default.Vmax = 10;
arm_params_default.emg_thres = .1;
arm_params_default.max_torque = 10;

% Hu/Perreault arm
arm_params_default.emg_to_torque_gain = [5 5];
arm_params_default.joint_stiffness_min = [1 1];
arm_params_default.joint_stiffness_max = [5 5];
arm_params_default.joint_damping_coefficient = [.5 .5];

% Ruiz arm
arm_params_default.emg_to_force_gain = [5 5];
arm_params_default.endpoint_stiffness_min = 3;
arm_params_default.endpoint_stiffness_max = 10;
arm_params_default.endpoint_damping_coefficient = 5;

% Control mode
arm_params_default.control_mode = 'ruiz';

arm_param_fields = fields(arm_params_default);
for iField = 1:numel(arm_param_fields)
    if ~isfield(arm_params_in,arm_param_fields{iField})
        arm_params_in.(arm_param_fields{iField}) = arm_params_default.(arm_param_fields{iField});
    end
end

arm_params = arm_params_in;
