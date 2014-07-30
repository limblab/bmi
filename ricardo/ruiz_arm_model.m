function [xdot,out_var] = ruiz_arm_model(t,theta,arm_params)

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

X_e = arm_params.X_sh + [arm_params.l(1)*cos_theta_1 arm_params.l(1)*sin_theta_1];
X_h = X_e + [arm_params.l(2)*cos_theta_2 arm_params.l(2)*sin_theta_2]; 
X_e_b = arm_params.X_sh + [arm_params.l(1)*cos_theta_1_b arm_params.l(1)*sin_theta_1_b];
X_h_b = X_e_b + [arm_params.l(2)*cos_theta_2_b arm_params.l(2)*sin_theta_2_b]; 

% http://studywolf.wordpress.com/2013/09/02/robot-control-jacobians-velocity-and-force/
J = [-l(1)*sin(theta(1))-l(2)*sin(theta(2)) -l(2)*sin(theta(2));...
    l(1)*cos(theta(1))+l(2)*cos(theta(2)) l(2)*cos(theta(2))];

J_reference = [-l(1)*sin(theta(5))-l(2)*sin(theta(6)) -l(2)*sin(theta(6));...
    l(1)*cos(theta(5))+l(2)*cos(theta(6)) l(2)*cos(theta(6))];

if arm_params.left_handed
    arm_params.musc_act(1:2) = arm_params.musc_act(2:-1:1);
end
emg_diff = [arm_params.musc_act(1)-arm_params.musc_act(2)...
    arm_params.musc_act(3)-arm_params.musc_act(4)];

muscle_force = (arm_params.emg_to_force_gain.*emg_diff)';

emg_coactivation = [arm_params.musc_act(1)+arm_params.musc_act(2);...
    arm_params.musc_act(3)+arm_params.musc_act(4)];

endpoint_error = [X_h_b - X_h]';
endpoint_stiffness = emg_coactivation.*(arm_params.endpoint_stiffness_max(:)-arm_params.endpoint_stiffness_min(:))+...
    arm_params.endpoint_stiffness_min(:);
damping_coefficient = 2*sqrt(.01*m(:).*endpoint_stiffness);
dX_h = J*theta(3:4);
endpoint_damping = damping_coefficient.*dX_h/arm_params.dt;
muscle_stiffness_force = endpoint_stiffness.*endpoint_error - endpoint_damping;

% muscle_torque = inv(J)*muscle_force;
muscle_torque = J\muscle_force;
% muscle_stiffness_torque = inv(J)*muscle_stiffness_force;
muscle_stiffness_torque = J\muscle_stiffness_force;

% joint_error = [theta(5)-theta(1);(theta(6)-theta(5))-(theta(2)-theta(1))];
% joint_stiffness = emg_coactivation.*(arm_params.joint_stiffness_max(:)-arm_params.joint_stiffness_min(:))+...
%     arm_params.joint_stiffness_min(:);
% damping_coefficient = 2*sqrt(i(:).*joint_stiffness);
% joint_damping = damping_coefficient.*[theta(3);theta(4)-theta(3)]/arm_params.dt;

% muscle_stiffness_torque = joint_stiffness.*joint_error - joint_damping;

constraint_angle_diff = [theta(1)-arm_params.null_angles(1);theta(2)-(theta(1)+diff(arm_params.null_angles))];
constraint_torque = -sign(constraint_angle_diff).*exp(40*(abs(constraint_angle_diff))/(pi/2)-25);

constraint_angle_diff_b = [theta(5)-arm_params.null_angles(1);theta(6)-(theta(5)+diff(arm_params.null_angles))];
constraint_torque_b = -sign(constraint_angle_diff_b).*exp(40*(abs(constraint_angle_diff_b))/(pi/2)-25);

 %matrix equations 
M = [m(2)*lc(1)^2+m(2)*l(1)^2+i(1), m(2)*l(1)*lc(2)^2*cos(theta(1)-theta(2));
 m(2)*l(1)*lc(2)*cos(theta(1)-theta(2)),+m(2)*lc(2)^2+i(2)]; 

M_b = [m(2)*lc(1)^2+m(2)*l(1)^2+i(1), m(2)*l(1)*lc(2)^2*cos(theta(5)-theta(6));
 m(2)*l(1)*lc(2)*cos(theta(5)-theta(6)),+m(2)*lc(2)^2+i(2)]; 

C = [-m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(4)^2;
 -m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(3)^2];

C_b = [-m(2)*l(1)*lc(2)*sin(theta(5)-theta(6))*theta(8)^2;
 -m(2)*l(1)*lc(2)*sin(theta(5)-theta(6))*theta(7)^2];

    
F_end_b = [0;0];
if X_h_b(1) < -.12
    F_end_b(1) = -(X_h_b(1)-(-.12))*500;
end
if X_h_b(1) > .12
    F_end_b(1) = -(X_h_b(1)-(.12))*500;
end
if X_h_b(2) < -.1
    F_end_b(2) = -(X_h_b(2)-(-.1))*500;
end
if X_h_b(2) > .1
    F_end_b(2) = -(X_h_b(2)-(.1))*500;
end

% T_endpoint = [-(l(1)*sin_theta_1+l(2)*sin_theta_2) * F_end(1) + (l(1)*cos_theta_1+l(2)*cos_theta_2) * F_end(2);
%         -l(2)*sin_theta_2 * F_end(1) + l(2)*cos_theta_2 * F_end(2)];
% T_endpoint_reference = [-(l(1)*sin_theta_1_b+l(2)*sin_theta_2_b) * F_end_b(1) + (l(1)*cos_theta_1_b-l(2)*cos_theta_2_b) * F_end_b(2);
%     -l(2)*sin_theta_2_b * F_end_b(1) + l(2)*cos_theta_2_b * F_end_b(2)];

T_endpoint = J'*F_end(:);
T_endpoint_reference = J_reference'*F_end_b(:);
    
motor_torque = muscle_torque + muscle_stiffness_torque;
motor_torque(motor_torque>arm_params.max_torque) = arm_params.max_torque;
motor_torque(motor_torque<-arm_params.max_torque) = -arm_params.max_torque;

tau_c = [-theta(3)*c(1);-(theta(4)-theta(3))*c(2)]; % viscosity
tau = T(:) + tau_c;
xdot(1:2,1)=theta(3:4);
xdot(3:4,1)= M\(T_endpoint + tau - C + motor_torque + constraint_torque);

tau_c_b = [-theta(7)*c(1);-(theta(8)-theta(7))*c(2)]; % viscosity
tau_b = tau_c_b;
xdot(5:6,1)=theta(7:8);
xdot(7:8,1)= M_b\(T_endpoint_reference + tau_b - C_b + muscle_torque + constraint_torque_b);

out_var = [muscle_torque(:);muscle_stiffness_torque(:);F_end(:);xdot(:)]';

end