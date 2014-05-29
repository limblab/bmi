function [xdot,out_var] = sandercock_model(t,theta,arm_params)

%parameters
% g = arm_params.g;
g = 0;
m = arm_params.m;
l = arm_params.l;
lc = arm_params.lc;
i = arm_params.i;
c = arm_params.c;... * (.2+.8*max(arm_params.musc_act));
T = arm_params.T;
F_end = arm_params.F_end;
if numel(F_end)>2
    [~,idx] = min(abs(F_end(1,:)-t));
    F_end = F_end(2:3,idx);
end
x_gain = -2*arm_params.left_handed+1;

xdot = zeros(4,1);

sin_theta_1 = sin(theta(1));
sin_theta_2 = sin(theta(2));
cos_theta_1 = cos(theta(1));
cos_theta_2 = cos(theta(2));

X_e = [x_gain*l(1)*cos_theta_1 l(1)*sin_theta_1];

musc_end_1 = [arm_params.m_ins(1)*cos(arm_params.null_angles(1))...
    arm_params.m_ins(1)*cos(arm_params.null_angles(1)+pi)...
    X_e(1)-x_gain*arm_params.m_ins(3)*cos_theta_1...
    X_e(1)+x_gain*arm_params.m_ins(4)*cos_theta_1;...
    arm_params.m_ins(1)*sin(arm_params.null_angles(1))...
    arm_params.m_ins(2)*sin(arm_params.null_angles(1)+pi)...
    X_e(2)-arm_params.m_ins(3)*sin_theta_1...
    X_e(2)+arm_params.m_ins(4)*sin_theta_1];
musc_end_2 = [x_gain*arm_params.m_ins(1)*cos_theta_1...
    x_gain*arm_params.m_ins(2)*cos_theta_1...
    X_e(1)+x_gain*arm_params.m_ins(3)*cos_theta_2...
    X_e(1)+x_gain*arm_params.m_ins(4)*cos_theta_2;...
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
% musc_vel(abs(musc_vel)<.05) = 0;
% musc_vel

musc_length = sqrt(sum((musc_end_1 - musc_end_2).^2));

active_musc_force = arm_params.musc_act.*arm_params.F_max.*...
    (1-4*((musc_length-arm_params.musc_l0)./arm_params.musc_l0).^2) +...
    (musc_length-arm_params.musc_l0).*arm_params.musc_act.*arm_params.k_gain;
    
f = [.82 .5 .43 58]; % from Heliot2010
active_musc_force = active_musc_force.*(f(1) + f(2)*atan(f(3)+f(4)*musc_vel));
active_musc_force = max(0,active_musc_force);

passive_musc_force = arm_params.F_max.*exp(arm_params.Ksh*(musc_length-arm_params.Kl*2*arm_params.m_ins)./(arm_params.Kl*2*arm_params.m_ins));

   
%     musc_length = 0:.001:arm_params.musc_l0(1)*2;
%     arm_params.musc_l0 = sqrt(2*arm_params.m_ins.^2)+...
%         0*sqrt(2*arm_params.m_ins.^2)/5.*...
%         (rand(1,length(arm_params.m_ins))-.5);
%     
%     figure;
%     alpha = 1;
%     active_force_plot = alpha.*arm_params.F_max(1).*...
%         (1-4*((musc_length-arm_params.musc_l0(1))./arm_params.musc_l0(1)).^2) +...
%         (musc_length-arm_params.musc_l0(1)).*ones(size(arm_params.F_max(1))).*arm_params.k_gain;
%     active_force_plot(active_force_plot<0) = 0;
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
%     ylim([0 1000])

passive_musc_force = max(0,passive_musc_force);

musc_force = active_musc_force + passive_musc_force;
musc_force = max(0,musc_force);
musc_force = min(musc_force,arm_params.F_max);

musc_torque = [x_gain*(arm_params.m_ins(1)*musc_force(1) - arm_params.m_ins(2)*musc_force(2));...
    x_gain*(arm_params.m_ins(3)*musc_force(3) - arm_params.m_ins(4)*musc_force(4))];

 %matrix equations 
M = [m(2)*lc(1)^2+m(2)*l(1)^2+i(1), m(2)*l(1)*lc(2)^2*cos(theta(1)-theta(2));
 m(2)*l(1)*lc(2)*cos(theta(1)-theta(2)),+m(2)*lc(2)^2+i(2)]; 

C = [-m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(4)^2;
 -m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(3)^2];

Fg = [(m(1)*lc(1)+m(2)*l(1))*g*cos_theta_1;
 m(2)*g*lc(2)*cos_theta_2];

T_endpoint = [-(l(1)*sin_theta_1+l(2)*sin_theta_2) * F_end(1) + (l(1)*cos_theta_1-l(2)*cos_theta_2) * F_end(2);
    -l(2)*sin_theta_2 * F_end(1) + l(2)*cos_theta_2 * F_end(2)];

% tau =T+ [-theta(3)*c(1);-theta(4)*c(2)]; %input torques,
% tau =T+ [-sign(theta(3))*sqrt(abs(theta(3)))*c(1);-sign(theta(4))*sqrt(abs(theta(4)))*c(2)]; %input torques,
tau_c = [-theta(3)*c(1);-theta(4)*c(2)]; % viscosity
% tau_c = [ -min(max(theta(3),-1),1)*c(1) ; -min(max(theta(4),-1),1)*c(2)];
tau = T(:) + tau_c;
xdot(1:2,1)=theta(3:4);
xdot(3:4,1)= M\(T_endpoint + tau-Fg-C + musc_torque);

out_var = [musc_force(:);F_end(:)]';

end