function [xdot,out_var] = miller_arm_model(t,theta,arm_params)

%parameters
g = 0;
m = arm_params.m;
l = arm_params.l;
lc = arm_params.lc;
i = arm_params.i;
c = arm_params.c;
T = arm_params.T;
F_end = arm_params.F_end;
if numel(F_end)>2
    [~,idx] = min(abs(F_end(1,:)-t));
    F_end = F_end(2:3,idx);
end

xdot = zeros(4,1);
theta = reshape(theta,[],1);

sin_theta_1 = sin(theta(1));
sin_theta_2 = sin(theta(2));
cos_theta_1 = cos(theta(1));
cos_theta_2 = cos(theta(2));

% F = [1;-1];

% theta = [45;135]*pi/180;
% 
% J = [-l(1)*sin(theta(1))-l(2)*sin(theta(2)) -l(2)*sin(theta(2));...
%     l(1)*cos(theta(1))+l(2)*cos(theta(2)) l(2)*cos(theta(2))];
% 
% T = -pinv(J)*F;

J_Muscle2Theta = [0.0336 -0.0381 0       0
                  0      0       0.0875 -0.0194]';
              
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

musc_length = sqrt(sum((musc_end_1 - musc_end_2).^2));

if isempty(arm_params.musc_length_old)
    arm_params.musc_length_old = musc_length;
end    

musc_length_diff = abs(arm_params.musc_length_old - musc_length);

% From Cui et al, 2008
musc_stiffness = 23.4*arm_params.musc_act.*arm_params.F_max*502E6*2E-6./...
    (23.4*arm_params.musc_act.*arm_params.F_max*.05 +...
    502E6*2E-6*.05);
musc_force_stiffness = sign(arm_params.musc_length_old - musc_length).*musc_stiffness.*musc_length_diff;

% musc_vel = [arm_params.m_ins(1)*theta(3) arm_params.m_ins(2)*theta(3)...
%     arm_params.m_ins(3)*theta(4) arm_params.m_ins(4)*theta(4);...
%     arm_params.m_ins(1)*theta(3) arm_params.m_ins(2)*theta(3)...
%     arm_params.m_ins(3)*theta(4) arm_params.m_ins(4)*theta(4)];
% 
% musc_vel = musc_vel.*[-sin_theta_1 -sin_theta_1...
%                         -sin_theta_2 -sin_theta_2;...
%                         cos_theta_1 cos_theta_1...
%                         cos_theta_2 cos_theta_2];

muscle_force = arm_params.F_max.*arm_params.musc_act + musc_force_stiffness;
muscle_torque = J_Muscle2Theta'*muscle_force';
muscle_torque(muscle_torque>arm_params.max_torque) = arm_params.max_torque;
muscle_torque(muscle_torque<-arm_params.max_torque) = -arm_params.max_torque;

constraint_angle_diff = [theta(1)-arm_params.null_angles(1);theta(2)-(theta(1)+diff(arm_params.null_angles))];
constraint_torque = -sign(constraint_angle_diff).*exp(30*(abs(constraint_angle_diff))/(pi/2)-27);

 %matrix equations 
M = [m(2)*lc(1)^2+m(2)*l(1)^2+i(1), m(2)*l(1)*lc(2)^2*cos(theta(1)-theta(2));
 m(2)*l(1)*lc(2)*cos(theta(1)-theta(2)),+m(2)*lc(2)^2+i(2)]; 

C = [-m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(4)^2;
 -m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(3)^2];

J = [-l(1)*sin(theta(1))-l(2)*sin(theta(2)) -l(2)*sin(theta(2));...
    l(1)*cos(theta(1))+l(2)*cos(theta(2)) l(2)*cos(theta(2))];

T_endpoint = J'*F_end(:);

% T_endpoint = [-(l(1)*sin_theta_1+l(2)*sin_theta_2) * F_end(1) + (l(1)*cos_theta_1-l(2)*cos_theta_2) * F_end(2);
%     -l(2)*sin_theta_2 * F_end(1) + l(2)*cos_theta_2 * F_end(2)];

tau_c = [-theta(3)*c(1);-(theta(4)-theta(3))*c(2)]; % viscosity
tau = T(:) + tau_c;
xdot(1:2,1)=theta(3:4);
xdot(3:4,1)= M\(T_endpoint + tau - C + muscle_torque + constraint_torque);

out_var = [muscle_torque(:);musc_force_stiffness(:);F_end(:);musc_length(:)]';

end