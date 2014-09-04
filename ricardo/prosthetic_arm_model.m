function [xdot,out_var] = prosthetic_arm_model(t,theta,arm_params)

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

J = arm_jacobian(l,theta(1:2));
    
emg_diff = [arm_params.musc_act(1)-arm_params.musc_act(2);...
    arm_params.musc_act(3)-arm_params.musc_act(4)];

Kv = sqrt(arm_params.Vmax)/(1-arm_params.emg_thres);
emg_to_vel = sign(emg_diff).*(Kv*(emg_diff-arm_params.emg_thres)).^2;
emg_to_vel(abs(emg_diff)<arm_params.emg_thres) = 0;

motor_torque = arm_params.P_gain*(emg_to_vel - [theta(3);theta(4)-theta(3)]);
motor_torque(motor_torque>arm_params.max_torque) = arm_params.max_torque;
motor_torque(motor_torque<-arm_params.max_torque) = -arm_params.max_torque;

angle_diff = [theta(1)-arm_params.null_angles(1);theta(2)-(theta(1)+diff(arm_params.null_angles))];
constraint_torque = -sign(angle_diff).*exp(30*(abs(angle_diff))/(pi/2)-27);

%matrix equations 
M = arm_inertia_matrix(arm_params,theta(1:2));   

% Coriolis torques
C = coriolis_torques(arm_params,theta(1:4));

T_endpoint = J'*F_end(:);

tau = [-theta(3)*c(1);-(theta(4)-theta(3))*c(2)]; % viscosity
xdot(1:2,1)=theta(3:4);
xdot(3:4,1)= M\(T(:) + T_endpoint + tau - C + motor_torque + constraint_torque);

out_var = [motor_torque(:);nan;nan;F_end(:)]';

end