function M = arm_inertia_matrix(arm_params,theta)
g = 0;
m = arm_params.m;
l = arm_params.l;
lc = arm_params.l/2; %distance from center
i = [arm_params.m(1)*arm_params.l(1)^2/3, arm_params.m(2)*arm_params.l(2)^2/3]; %moments of inertia i1, i2

% Inertial forces
M(1,1) = i(1)+i(2)+m(1)*lc(1)^2+m(2)*(l(1)^2+lc(2)^2+2*l(1)*lc(2)*cos(theta(2)-theta(1)));
M(1,2) = i(2)+m(2)*(lc(2)^2+l(1)*lc(2)*cos(theta(2)-theta(1)));
M(2,1) = M(1,2);
M(2,2) = i(2)+m(2)*lc(2)^2;


