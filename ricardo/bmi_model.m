function [xdot,out_var] = bmi_model(t,theta,arm_params)

%parameters
g = 0;
m = arm_params.m;
l = arm_params.l;
% lc = arm_params.lc;
% i = arm_params.i;
lc = arm_params.l/2; %distance from center
i = [arm_params.m(1)*arm_params.l(1)^2/3, arm_params.m(2)*arm_params.l(2)^2/3]; %moments of inertia i1, i2, need to validate coef's
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

J = [-l(1)*sin(theta(1))-l(2)*sin(theta(2)) -l(2)*sin(theta(2));...
    l(1)*cos(theta(1))+l(2)*cos(theta(2)) l(2)*cos(theta(2))];

% commanded_rot_vel = J\arm_params.commanded_vel(:);
arm_params.commanded_vel(1) = arm_params.commanded_vel(1)*(-1)^(-arm_params.left_handed+2);
commanded_rot_vel = J'*arm_params.commanded_vel(:);

motor_torque = arm_params.P_gain*(commanded_rot_vel - [theta(3);theta(4)-theta(3)]);
motor_torque(motor_torque>arm_params.max_torque) = arm_params.max_torque;
motor_torque(motor_torque<-arm_params.max_torque) = -arm_params.max_torque;

angle_diff = [theta(1)-arm_params.null_angles(1);theta(2)-(theta(1)+diff(arm_params.null_angles))];
constraint_torque = -sign(angle_diff).*exp(30*(abs(angle_diff))/(pi/2)-27);

 %matrix equations 
M = [m(2)*lc(1)^2+m(2)*l(1)^2+i(1), m(2)*l(1)*lc(2)^2*cos(theta(1)-theta(2));
 m(2)*l(1)*lc(2)*cos(theta(1)-theta(2)),+m(2)*lc(2)^2+i(2)]; 

C = [-m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(4)^2;
 -m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(3)^2];

Fg = [(m(1)*lc(1)+m(2)*l(1))*g*cos_theta_1;
 m(2)*g*lc(2)*cos_theta_2];

T_endpoint = J'*F_end(:);
% T_endpoint = [-(l(1)*sin_theta_1+l(2)*sin_theta_2) * F_end(1) + (l(1)*cos_theta_1-l(2)*cos_theta_2) * F_end(2);
%     -l(2)*sin_theta_2 * F_end(1) + l(2)*cos_theta_2 * F_end(2)];

tau_c = [-theta(3)*c(1);-(theta(4)-theta(3))*c(2)]; % viscosity
tau = T(:) + tau_c;
xdot(1:2,1)=theta(3:4);
xdot(3:4,1)= M\(T_endpoint + tau-Fg-C + motor_torque + constraint_torque);

out_var = [motor_torque(:);nan;nan;F_end(:)]';
% out_var = [motor_torque(:);T_endpoint;F_end(:)]';

end