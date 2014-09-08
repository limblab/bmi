function M = arm_inertia_matrix(arm_params,theta)
%% gribblelab.org/compeuro/5_Computational_Motor_Control_Dynamics.html

g = 0;
m = arm_params.m;
m_end = arm_params.m_end;
l = arm_params.l;
lc = arm_params.l/2; %distance from center
i = [m(1)*l(1)^2/3, m(2)*l(2)^2/3]; %moments of inertia i1, i2

% Inertial forces
M(1,1) = i(1) + i(2) + m(1)*lc(1)^2 + m(2)*(l(1)^2+lc(2)^2+2*l(1)*lc(2)*cos(theta(2)-theta(1))) +...
    m_end*(l(1)^2+l(2)^2+2*l(1)*l(2)*cos(theta(2)-theta(1)));
M(1,2) = i(2) + m(2)*(lc(2)^2+l(1)*lc(2)*cos(theta(2)-theta(1))) + m_end*(l(2)^2+l(1)*l(2)*cos(theta(2)-theta(1)));
M(2,1) = M(1,2);
M(2,2) = i(2) + m(2)*lc(2)^2 + m_end*l(2)^2;


