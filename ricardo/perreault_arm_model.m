function [xdot,out_var] = perreault_arm_model(t,theta,arm_params)

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

xdot = zeros(8,1);
theta = reshape(theta,[],1);

sin_theta_1 = sin(theta(1));
sin_theta_2 = sin(theta(2));
cos_theta_1 = cos(theta(1));
cos_theta_2 = cos(theta(2));

sin_theta_1_b = sin(theta(5));
sin_theta_2_b = sin(theta(6));
cos_theta_1_b = cos(theta(5));
cos_theta_2_b = cos(theta(6));

% F = [1;-1];

% theta = [45;135]*pi/180;
% 
% J = [-l(1)*sin(theta(1))-l(2)*sin(theta(2)) -l(2)*sin(theta(2));...
%     l(1)*cos(theta(1))+l(2)*cos(theta(2)) l(2)*cos(theta(2))];
% 
% T = -pinv(J)*F;

emg_diff = [arm_params.musc_act(1)-arm_params.musc_act(2);...
    arm_params.musc_act(3)-arm_params.musc_act(4)];

muscle_torque = arm_params.emg_to_torque_gain.*emg_diff;

emg_coactivation = [min(arm_params.musc_act(1),arm_params.musc_act(2));...
    min(arm_params.musc_act(3),arm_params.musc_act(4))];
joint_error = [theta(5)-theta(1);theta(6)-theta(2)];
joint_stiffness = emg_coactivation.*(arm_params.joint_stiffness_max(:)-arm_params.joint_stiffness_min(:))+...
    arm_params.joint_stiffness_min(:);
muscle_stiffness_torque = joint_stiffness.*joint_error;

constraint_angle_diff = [theta(1)-arm_params.null_angles(1);theta(2)-(theta(1)+diff(arm_params.null_angles))];
constraint_torque = -sign(constraint_angle_diff).*exp(30*(abs(constraint_angle_diff))/(pi/2)-27);

 %matrix equations 
M = [m(2)*lc(1)^2+m(2)*l(1)^2+i(1), m(2)*l(1)*lc(2)^2*cos(theta(1)-theta(2));
 m(2)*l(1)*lc(2)*cos(theta(1)-theta(2)),+m(2)*lc(2)^2+i(2)]; 

M_b = [m(2)*lc(1)^2+m(2)*l(1)^2+i(1), m(2)*l(1)*lc(2)^2*cos(theta(5)-theta(6));
 m(2)*l(1)*lc(2)*cos(theta(5)-theta(6)),+m(2)*lc(2)^2+i(2)]; 

C = [-m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(4)^2;
 -m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(3)^2];

C_b = [-m(2)*l(1)*lc(2)*sin(theta(5)-theta(6))*theta(8)^2;
 -m(2)*l(1)*lc(2)*sin(theta(5)-theta(6))*theta(7)^2];

T_endpoint = [-(l(1)*sin_theta_1+l(2)*sin_theta_2) * F_end(1) + (l(1)*cos_theta_1-l(2)*cos_theta_2) * F_end(2);
    -l(2)*sin_theta_2 * F_end(1) + l(2)*cos_theta_2 * F_end(2)];

tau_c = [-theta(3)*c(1);-(theta(4)-theta(3))*c(2)]; % viscosity
tau = T(:) + tau_c;
xdot(1:2,1)=theta(3:4);
xdot(3:4,1)= M\(T_endpoint + tau - C + muscle_torque + muscle_stiffness_torque + constraint_torque);

tau_c_b = [-theta(7)*c(1);-(theta(8)-theta(7))*c(2)]; % viscosity
tau_b = tau_c_b;
xdot(5:6,1)=theta(7:8);
xdot(7:8,1)= M_b\(tau_b-C_b + muscle_torque + muscle_stiffness_torque + constraint_torque);

out_var = [muscle_torque(:);muscle_stiffness_torque(:);F_end(:);xdot(:)]';

end