function C = coriolis_torques(arm_params,theta)

m = arm_params.m;
l = arm_params.l;
lc = arm_params.l/2; %distance from center


C = [-m(2)*l(1)*lc(2)*sin(theta(2)-theta(1))*theta(4)^2 - 2*m(2)*l(1)*lc(2)*sin(theta(2)-theta(1))*theta(3)*(theta(4)-theta(3));
 m(2)*l(1)*lc(2)*sin(theta(2)-theta(1))*theta(3)^2];