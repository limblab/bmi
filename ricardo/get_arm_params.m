function arm_params = get_arm_params()

arm_params.plot = 0;
arm_params.clear_all = 0;
arm_params.num_training_sets = 2000;

%parameters
arm_params.g = 0;

% Monkey
arm_params.m = [.2, .1];
arm_params.l = [.2, .18]; %segment lengths l1, l2
arm_params.F_max = [400 400 200 200];
arm_params.X_sh = [0 -.2];
arm_params.c = [1, 1];

% Human
arm_params.m = [1, 1];
arm_params.l = [.5, .5]; %segment lengths l1, l2
arm_params.c = [1, 1];
arm_params.X_sh = [0 -.7];
arm_params.F_max = [400 400 400 400];

arm_params.m_ins = [.02 .02 .02 .02];
arm_params.lc = arm_params.l/2; %distance from center
arm_params.i = [arm_params.m(1)*arm_params.l(1)^2/3, arm_params.m(2)*arm_params.l(2)^2/3]; %moments of inertia i1, i2, need to validate coef's

% arm_params.Ksh = 3;
% arm_params.Kl = .8;
arm_params.Ksh = 60; 
arm_params.Kl = 1;
%     musc_length = 0:.001:.04;
%     figure;
%     plot(musc_length,arm_params.F_max(1).*exp(arm_params.Ksh*(musc_length-arm_params.Kl*2*arm_params.m_ins(1))./(arm_params.Kl*2*arm_params.m_ins(1))));
%     ylim([0 500])
%     xlim([0 .04])

arm_params.null_angles = [3*pi/4 pi/2];
% arm_params.Kl = 1;
arm_params.k_gain = 23;

arm_params.T = 0*[2;-.2];
arm_params.dt = 0.05;
arm_params.t = 0:arm_params.dt:50;
% arm_params.dt = diff(arm_params.t(1:2));

arm_params.left_handed = 0;
arm_params.monkey_offset = [(-2*arm_params.left_handed+1)*.08 -sqrt(sum(arm_params.l.^2))]; 
