function [xdot,out_var] = point_mass_model(t,x,arm_params)

    m = arm_params.m_pm;    

    c = arm_params.c_pm;

    F_end = arm_params.F_end;
    if numel(F_end)>2
        [~,idx] = min(abs(F_end(1,:)-t));
        F_end = F_end(2:3,idx);
    end

    xdot = zeros(8,1);
    x = reshape(x,[],1);

    X_h = x(1:2);
    dX_h = x(3:4);
    X_h_b = x(5:6);
    dX_h_b = x(7:8);

    emg_diff = [arm_params.musc_act(1)-arm_params.musc_act(2)...
        arm_params.musc_act(3)-arm_params.musc_act(4)];

    muscle_force = (arm_params.emg_to_force_gain_pm.*emg_diff)';

    emg_coactivation = [arm_params.musc_act(1)+arm_params.musc_act(2);...
        arm_params.musc_act(3)+arm_params.musc_act(4)]/2;

    endpoint_error = X_h_b - X_h;
    endpoint_stiffness = emg_coactivation*(arm_params.endpoint_stiffness_max_pm(:)-arm_params.endpoint_stiffness_min_pm(:))+...
        arm_params.endpoint_stiffness_min_pm(:);

    damping_coefficient = emg_coactivation*(arm_params.endpoint_damping_max_pm(:)-arm_params.endpoint_damping_min_pm(:))+...
        arm_params.endpoint_damping_min_pm(:);

    endpoint_damping = damping_coefficient.*dX_h;
    muscle_stiffness_force = endpoint_stiffness.*endpoint_error - endpoint_damping;

    reference_damping = -damping_coefficient.*dX_h_b;
    reference_damping_force = reference_damping;

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

    tau = [-x(3)*c;-(x(4)-x(3))*c]; % viscosity
    xdot(1:2,1) = x(3:4);
    xdot(3:4,1) = m\(tau + muscle_force + muscle_stiffness_force + F_end(:));

    tau_b = [-x(7)*c;-(x(8)-x(7))*c]; % viscosity
    xdot(5:6,1) = x(7:8);
    xdot(7:8,1) = m\(tau_b + muscle_force + reference_damping_force + F_end_b(:));

    out_var = [muscle_force(:);muscle_stiffness_force(:);F_end(:);xdot(:)]';

end