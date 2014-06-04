function [xdot,out_var] = prosthetic_arm_model(t,theta,arm_params)

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
x_gain = -2*arm_params.left_handed+1;

xdot = zeros(4,1);
theta = reshape(theta,[],1);

sin_theta_1 = sin(theta(1));
sin_theta_2 = sin(theta(2));
cos_theta_1 = cos(theta(1));
cos_theta_2 = cos(theta(2));

X_e = [x_gain*l(1)*cos_theta_1 l(1)*sin_theta_1];

%     emg = 0:.001:1;
%     thres = .2;
%     Vmax = 10;
%     Kv = sqrt(Vmax)/(1-thres);
%     vel = (Kv*(emg-thres)).^2;
%     vel(emg<thres) = 0;
%     figure;
%     plot(emg,vel)
%     P_gain = 1;
    
emg_diff = x_gain*[arm_params.musc_act(1)-arm_params.musc_act(2);...
    arm_params.musc_act(3)-arm_params.musc_act(4)];

Kv = sqrt(arm_params.Vmax)/(1-arm_params.emg_thres);
emg_to_vel = sign(emg_diff).*(Kv*(emg_diff-arm_params.emg_thres)).^2;
emg_to_vel(abs(emg_diff)<arm_params.emg_thres) = 0;

controller_torque = arm_params.P_gain*(emg_to_vel - [theta(3);theta(4)-theta(3)]);
controller_torque(abs(controller_torque)>arm_params.max_torque) =...
    sign(controller_torque(abs(controller_torque)>arm_params.max_torque))*arm_params.max_torque;

constraint_torque = -sign([theta(1);theta(2)]-arm_params.null_angles').*...
    exp(30*(abs([theta(1);theta(2)]-arm_params.null_angles'))/(pi/2)-27);
constraint_torque = 0*constraint_torque;

 %matrix equations 
M = [m(2)*lc(1)^2+m(2)*l(1)^2+i(1), m(2)*l(1)*lc(2)^2*cos(theta(1)-theta(2));
 m(2)*l(1)*lc(2)*cos(theta(1)-theta(2)),+m(2)*lc(2)^2+i(2)]; 

C = [-m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(4)^2;
 -m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(3)^2];

Fg = [(m(1)*lc(1)+m(2)*l(1))*g*cos_theta_1;
 m(2)*g*lc(2)*cos_theta_2];

T_endpoint = [-(l(1)*sin_theta_1+l(2)*sin_theta_2) * F_end(1) + (l(1)*cos_theta_1-l(2)*cos_theta_2) * F_end(2);
    -l(2)*sin_theta_2 * F_end(1) + l(2)*cos_theta_2 * F_end(2)];

tau_c = [-theta(3)*c(1);-(theta(4)-theta(3))*c(2)]; % viscosity
tau = T(:) + tau_c;
xdot(1:2,1)=theta(3:4);
xdot(3:4,1)= M\(T_endpoint + tau-Fg-C + controller_torque + constraint_torque);

out_var = [controller_torque(:);nan;nan;F_end(:)]';

end