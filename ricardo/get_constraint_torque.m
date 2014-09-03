function constraint_torque = get_constraint_torque(arm_params,theta)

constraint_angle_diff = [theta(1)-arm_params.null_angles(1);theta(2)-(theta(1)+diff(arm_params.null_angles))];
constraint_torque = -sign(constraint_angle_diff).*exp(40*(abs(constraint_angle_diff))/(pi/2)-25);