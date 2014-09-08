function J = arm_jacobian(l,theta)

% http://studywolf.wordpress.com/2013/09/02/robot-control-jacobians-velocity-and-force/
J = [-l(1)*sin(theta(1))-l(2)*sin(theta(2)) -l(2)*sin(theta(2));...
    l(1)*cos(theta(1))+l(2)*cos(theta(2)) l(2)*cos(theta(2))];
