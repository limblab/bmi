function [xdot,out_var] = hu_arm_model(t,theta,arm_params)

%parameters
g = 0;
m = arm_params.m;
l = arm_params.l;
lc = arm_params.l/2; %distance from center
i = [arm_params.m(1)*arm_params.l(1)^2/3, arm_params.m(2)*arm_params.l(2)^2/3]; %moments of inertia i1, i2, need to validate coef's
c = arm_params.c;
T = arm_params.T;
F_end = arm_params.F_end;
if numel(F_end)>2
    [~,idx] = min(abs(F_end(1,:)-t));
    F_end = F_end(2:3,idx);
end

xdot = zeros(8,1);
theta = reshape(theta,[],1);

[~, X_h_b] = get_elbow_hand(arm_params,theta(5:6)); 

F_end_b = [0;0];
if arm_params.walls
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
end

J = arm_jacobian(l,theta(1:2));
J_reference = arm_jacobian(l,theta(5:6));

T_endpoint = J'*F_end(:);
T_endpoint_reference = J_reference'*F_end_b(:);

emg_diff = [arm_params.musc_act(1)-arm_params.musc_act(2)...
    arm_params.musc_act(3)-arm_params.musc_act(4)];

muscle_torque = (arm_params.emg_to_torque_gain.*emg_diff)';

% emg_coactivation = [arm_params.musc_act(1)+arm_params.musc_act(2);...
%     arm_params.musc_act(3)+arm_params.musc_act(4)];

emg_coactivation = [arm_params.musc_act(1)+arm_params.musc_act(2);...
    arm_params.cocontraction];

joint_error = [theta(5)-theta(1);(theta(6)-theta(5))-(theta(2)-theta(1))];
joint_stiffness = emg_coactivation.*(arm_params.joint_stiffness_max(:)-arm_params.joint_stiffness_min(:))+...
    arm_params.joint_stiffness_min(:);
    
damping_coefficient = emg_coactivation.*(arm_params.joint_damping_max(:)-arm_params.joint_damping_min(:))+...
    arm_params.joint_damping_min(:);
joint_damping = -damping_coefficient.*[theta(3);theta(4)-theta(3)];
muscle_stiffness_torque = joint_stiffness.*joint_error + joint_damping;

joint_damping_b = -damping_coefficient.*[theta(7);theta(8)-theta(7)];
muscle_damping_torque_b = + joint_damping_b;

constraint_angle_diff = [theta(1)-arm_params.null_angles(1);theta(2)-(theta(1)+diff(arm_params.null_angles))];
constraint_torque = -sign(constraint_angle_diff).*exp(30*(abs(constraint_angle_diff))/(pi/2)-27);

constraint_angle_diff_b = [theta(5)-arm_params.null_angles(1);theta(6)-(theta(5)+diff(arm_params.null_angles))];
constraint_torque_b = -sign(constraint_angle_diff_b).*exp(30*(abs(constraint_angle_diff_b))/(pi/2)-27);

% Inertia matrix
M = arm_inertia_matrix(arm_params,theta(1:2));
M_b = arm_inertia_matrix(arm_params,theta(5:6));

% Coriolis torques
C = coriolis_torques(arm_params,theta(1:4));
C_b = coriolis_torques(arm_params,theta(5:8));
  
motor_torque = muscle_torque + muscle_stiffness_torque;
motor_torque(motor_torque>arm_params.max_torque) = arm_params.max_torque;
motor_torque(motor_torque<-arm_params.max_torque) = -arm_params.max_torque;

tau = [-theta(3)*c(1);-(theta(4)-theta(3))*c(2)]; % viscosity
xdot(1:2,1)=theta(3:4);
xdot(3:4,1)= M\(T(:) + T_endpoint + tau - C + motor_torque + constraint_torque);

tau_b = [-theta(7)*c(1);-(theta(8)-theta(7))*c(2)]; % viscosity
xdot(5:6,1)=theta(7:8);
xdot(7:8,1)= M_b\(T(:) + T_endpoint_reference + tau_b - C_b + muscle_torque + constraint_torque_b + muscle_damping_torque_b);

if arm_params.block_shoulder
    xdot([1 5]) = 0;
    xdot([3 7]) = 0;
end
out_var = [muscle_torque(:);muscle_stiffness_torque(:);F_end(:);xdot(:)]';

end