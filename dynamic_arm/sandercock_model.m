function [xdot,out_var] = sandercock_model(t,theta,arm_params)

%parameters
% g = arm_params.g;
g = 0;
m = arm_params.m;
l = arm_params.l;
% lc = arm_params.lc;
% i = arm_params.i;
lc = arm_params.l/2; %distance from center
i = [arm_params.m(1)*arm_params.l(1)^2/3, arm_params.m(2)*arm_params.l(2)^2/3]; %moments of inertia i1, i2, need to validate coef's
c = arm_params.c;... * (.2+.8*max(arm_params.musc_act));
T = arm_params.T;
F_end = arm_params.F_end;
if numel(F_end)>2
    [~,idx] = min(abs(F_end(1,:)-t));
    F_end = F_end(2:3,idx);
end

xdot = zeros(4,1);

sin_theta_1 = sin(theta(1));
sin_theta_2 = sin(theta(2));
cos_theta_1 = cos(theta(1));
cos_theta_2 = cos(theta(2));

X_e = [l(1)*cos_theta_1 l(1)*sin_theta_1];

musc_end_1 = [arm_params.m_ins(1)*cos(arm_params.null_angles(1)+pi/2)...
    arm_params.m_ins(1)*cos(arm_params.null_angles(1)-pi/2)...
    X_e(1)-arm_params.m_ins(3)*cos_theta_1...
    X_e(1)+arm_params.m_ins(4)*cos_theta_1;...
    arm_params.m_ins(1)*sin(arm_params.null_angles(1)+pi/2)...
    arm_params.m_ins(2)*sin(arm_params.null_angles(1)-pi/2)...
    X_e(2)-arm_params.m_ins(3)*sin_theta_1...
    X_e(2)+arm_params.m_ins(4)*sin_theta_1];
musc_end_2 = [arm_params.m_ins(1)*cos_theta_1...
    arm_params.m_ins(2)*cos_theta_1...
    X_e(1)+arm_params.m_ins(3)*cos_theta_2...
    X_e(1)+arm_params.m_ins(4)*cos_theta_2;...
    arm_params.m_ins(1)*sin_theta_1...
    arm_params.m_ins(2)*sin_theta_1...
    X_e(2)+arm_params.m_ins(3)*sin_theta_2...
    X_e(2)+arm_params.m_ins(4)*sin_theta_2];

musc_vel = [arm_params.m_ins(1)*theta(3) arm_params.m_ins(2)*theta(3)...
    arm_params.m_ins(3)*theta(4) arm_params.m_ins(4)*theta(4);...
    arm_params.m_ins(1)*theta(3) arm_params.m_ins(2)*theta(3)...
    arm_params.m_ins(3)*theta(4) arm_params.m_ins(4)*theta(4)];

musc_vel = musc_vel.*[-sin_theta_1 -sin_theta_1...
                        -sin_theta_2 -sin_theta_2;...
                        cos_theta_1 cos_theta_1...
                        cos_theta_2 cos_theta_2];

% musc_vel = [arm_params.m_ins(1)*theta(3)*-sin_theta_1 arm_params.m_ins(2)*theta(3)*-sin_theta_1...
%     arm_params.m_ins(3)*theta(4)*-sin_theta_2 arm_params.m_ins(4)*theta(4)*-sin_theta_2;...
%     arm_params.m_ins(1)*theta(3)*cos_theta_1 arm_params.m_ins(2)*theta(3)*cos_theta_1...
%     arm_params.m_ins(3)*theta(4)*cos_theta_2 arm_params.m_ins(4)*theta(4)*cos_theta_2];
% musc_vel = sqrt(sum(musc_vel.^2))./arm_params.musc_l0;
musc_vel = sqrt(sum(musc_vel.^2));

% Negative musc_vel is muscle shortening.
musc_vel(1) = -sign(theta(3))*musc_vel(1);
musc_vel(2) = sign(theta(3))*musc_vel(2);
musc_vel(3) = -sign(theta(4))*musc_vel(3);
musc_vel(4) = sign(theta(4))*musc_vel(4);

musc_length = sqrt(sum((musc_end_1 - musc_end_2).^2));

active_musc_force = arm_params.musc_act.*arm_params.F_max.*...
    (1-4*((musc_length-arm_params.musc_l0)./arm_params.musc_l0).^2) +...
    (musc_length-arm_params.musc_l0).*arm_params.musc_act.*arm_params.k_gain;

% Make active force flat when muscle is longer than l0.
active_musc_force(musc_length>arm_params.musc_l0) = arm_params.musc_act(musc_length>arm_params.musc_l0).*...
    arm_params.F_max(musc_length>arm_params.musc_l0);
    
f = [.82 .5 .43 58]; % from Heliot2010
active_musc_force = active_musc_force.*(f(1) + f(2)*atan(f(3)+f(4)*musc_vel));
active_musc_force = max(0,active_musc_force);

passive_musc_force = arm_params.F_max.*exp(arm_params.Ksh*(musc_length-arm_params.Kl*2*arm_params.m_ins)./(arm_params.Kl*2*arm_params.m_ins));

% %%     Code for plotting force-length relationship:
%     arm_params = get_default_arm_params;    
%     arm_params.musc_l0 = sqrt(2*arm_params.m_ins.^2)+...
%         0*sqrt(2*arm_params.m_ins.^2)/5.*...
%         (rand(1,length(arm_params.m_ins))-.5);
%     musc_length = 0:.001:arm_params.musc_l0(1)*2;
%     
%     figure;
%     alpha = 1;
%     active_force_plot = alpha.*arm_params.F_max(1).*...
%         (1-4*((musc_length-arm_params.musc_l0(1))./arm_params.musc_l0(1)).^2) +...
%         (musc_length-arm_params.musc_l0(1)).*ones(size(arm_params.F_max(1))).*arm_params.k_gain;
%     active_force_plot(active_force_plot<0) = 0;
%     active_force_plot(musc_length>arm_params.musc_l0(1)) = alpha.*arm_params.F_max(1);
%     passive_force_plot = arm_params.F_max(1).*exp(arm_params.Ksh*...
%         (musc_length-arm_params.Kl*2*arm_params.m_ins(1))./(arm_params.Kl*2*arm_params.m_ins(1)));
%     passive_force_plot(passive_force_plot<0) = 0;
% 
%     plot(musc_length,active_force_plot,...
%         musc_length,passive_force_plot,...
%         musc_length,active_force_plot+passive_force_plot);
%     legend('Passive','Active','Passive + active')
%     xlabel('Muscle length (m)')
%     ylabel('Muscle force (N)')
%     ylim([0 1500])

%%
passive_musc_force = max(0,passive_musc_force);

musc_force = active_musc_force + passive_musc_force;
musc_force = max(0,musc_force);
musc_force = min(musc_force,arm_params.F_max);

musc_torque = [(arm_params.m_ins(1)*musc_force(1) - arm_params.m_ins(2)*musc_force(2));...
    (arm_params.m_ins(3)*musc_force(3) - arm_params.m_ins(4)*musc_force(4))];
musc_torque(musc_torque>arm_params.max_torque) = arm_params.max_torque;
musc_torque(musc_torque<-arm_params.max_torque) = -arm_params.max_torque;


%matrix equations 
M = arm_inertia_matrix(arm_params,theta(1:2));   

% Coriolis torques
C = coriolis_torques(arm_params,theta(1:4));

J = arm_jacobian(l,theta(1:2));

T_endpoint = J'*F_end(:);

tau = [-theta(3)*c(1);-(theta(4)-theta(3))*c(2)]; % viscosity

xdot(1:2,1)=theta(3:4);
xdot(3:4,1)= M\(T(:) + T_endpoint + tau - C + musc_torque);

out_var = [musc_force(:);F_end(:)]';

end