function [xdot,out_var] = ruiz_arm_model(t,theta,arm_params)

    %parameters
    g = 0;
    m = arm_params.m;
    l = arm_params.l;
    lc = arm_params.l/2; %distance from center
    i = [arm_params.m(1)*arm_params.l(1)^2/3, arm_params.m(2)*arm_params.l(2)^2/3]; %moments of inertia i1, i2

    c = arm_params.c;
    T = arm_params.T;
    F_end = arm_params.F_end;
    if numel(F_end)>2
        [~,idx] = min(abs(F_end(1,:)-t));
        F_end = F_end(2:3,idx);
    end

    xdot = zeros(8,1);
    theta = reshape(theta,[],1);

    [~, X_h] = get_elbow_hand(arm_params,theta(1:2));
    [~, X_h_b] = get_elbow_hand(arm_params,theta(5:6)); 

    J = arm_jacobian(l,theta(1:2));
    J_reference = arm_jacobian(l,theta(5:6));

    if arm_params.left_handed
        arm_params.musc_act(1:2) = arm_params.musc_act(2:-1:1);
    end
    emg_diff = [arm_params.musc_act(1)-arm_params.musc_act(2)...
        arm_params.musc_act(3)-arm_params.musc_act(4)];

    muscle_force = (arm_params.emg_to_force_gain.*emg_diff)';

    emg_coactivation = [arm_params.musc_act(1)+arm_params.musc_act(2);...
        arm_params.musc_act(3)+arm_params.musc_act(4)]/2;

    endpoint_error = X_h_b - X_h;
    endpoint_stiffness = emg_coactivation*(arm_params.endpoint_stiffness_max(:)-arm_params.endpoint_stiffness_min(:))+...
        arm_params.endpoint_stiffness_min(:);

    damping_coefficient = emg_coactivation*(arm_params.endpoint_damping_max(:)-arm_params.endpoint_damping_min(:))+...
        arm_params.endpoint_damping_min(:);

    dX_h = J*theta(3:4);
    endpoint_damping = damping_coefficient.*dX_h;
    muscle_stiffness_force = endpoint_stiffness.*endpoint_error - endpoint_damping;

    dX_h2 = J_reference*theta(7:8);
    reference_damping = -damping_coefficient.*dX_h2;
    reference_damping_torque = J_reference'*reference_damping;

    muscle_torque = J'*muscle_force;
    muscle_stiffness_torque = J'*muscle_stiffness_force;

    constraint_torque = get_constraint_torque(arm_params,theta(1:2));
    constraint_torque_b = get_constraint_torque(arm_params,theta(5:6));

    % Inertia matrix
    M = arm_inertia_matrix(arm_params,theta(1:2));
    M_b = arm_inertia_matrix(arm_params,theta(5:6));

    % Coriolis torques
    C = coriolis_torques(arm_params,theta(1:4));
    C_b = coriolis_torques(arm_params,theta(5:8));

    % Walls for reference arm
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

    T_endpoint = J'*F_end(:);
    T_endpoint_reference = J_reference'*F_end_b(:);

    motor_torque = muscle_torque + muscle_stiffness_torque;
    motor_torque(motor_torque>arm_params.max_torque) = arm_params.max_torque;
    motor_torque(motor_torque<-arm_params.max_torque) = -arm_params.max_torque;

    tau = [-theta(3)*c(1);-(theta(4)-theta(3))*c(2)]; % viscosity
    xdot(1:2,1) = theta(3:4);
    xdot(3:4,1) = M\(T(:) + T_endpoint + tau - C + motor_torque + constraint_torque);

    tau_b = [-theta(7)*c(1);-(theta(8)-theta(7))*c(2)]; % viscosity
    xdot(5:6,1) = theta(7:8);
    xdot(7:8,1) = M_b\(T_endpoint_reference + tau_b - C_b + muscle_torque + reference_damping_torque + constraint_torque_b);

    out_var = [muscle_torque(:);muscle_stiffness_torque(:);F_end(:);xdot(:)]';
%     out_var = [muscle_torque(:);muscle_stiffness_torque(:);F_end(:);xdot(:);T_endpoint(:)]';

end