function [X_e, X_h] = get_elbow_hand(arm_params,theta)

X_e = arm_params.X_sh(:) + [arm_params.l(1)*cos(theta(1)); arm_params.l(1)*sin(theta(1))];
X_h = X_e + [arm_params.l(2)*cos(theta(2)); arm_params.l(2)*sin(theta(2))]; 