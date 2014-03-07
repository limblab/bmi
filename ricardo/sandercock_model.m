function xdot = sandercock_model(t,theta,arm_params)

%parameters
g = arm_params.g;
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

X_e = [x_gain*l(1)*cos(theta(1)) l(1)*sin(theta(1))];

musc_end_1 = [x_gain*arm_params.m_ins(1)*cos(arm_params.null_angles(1))...
    x_gain*arm_params.m_ins(1)*cos(arm_params.null_angles(1)+pi)...
    X_e(1)-x_gain*arm_params.m_ins(3)*cos(theta(1))...
    X_e(1)+x_gain*arm_params.m_ins(4)*cos(theta(1));...
    arm_params.m_ins(1)*sin(arm_params.null_angles(1))...
    arm_params.m_ins(2)*sin(arm_params.null_angles(1)+pi)...
    X_e(2)-arm_params.m_ins(3)*sin(theta(1))...
    X_e(2)+arm_params.m_ins(4)*sin(theta(1))];
musc_end_2 = [arm_params.m_ins(1)*cos(theta(1))...
    arm_params.m_ins(2)*cos(theta(1))...
    X_e(1)+x_gain*arm_params.m_ins(3)*cos(theta(2))...
    X_e(1)+x_gain*arm_params.m_ins(4)*cos(theta(2));...
    arm_params.m_ins(1)*sin(theta(1))...
    arm_params.m_ins(2)*sin(theta(1))...
    X_e(2)+arm_params.m_ins(3)*sin(theta(2))...
    X_e(2)+arm_params.m_ins(4)*sin(theta(2))];


musc_length = sqrt(sum((musc_end_1 - musc_end_2).^2));

active_musc_force = arm_params.musc_act.*arm_params.F_max.*...
    (1-4*((musc_length-arm_params.musc_l0)./arm_params.musc_l0).^2) +...
    (musc_length-arm_params.musc_l0).*arm_params.musc_act.*arm_params.k_gain;
active_musc_force = max(0,active_musc_force);

passive_musc_force = arm_params.F_max.*exp(arm_params.Ksh*(musc_length-arm_params.Kl*2*arm_params.m_ins)./(arm_params.Kl*2*arm_params.m_ins));
%     musc_length = 0:.001:.04;
%     figure;
%     plot(musc_length,arm_params.F_max(1).*exp(arm_params.Ksh*(musc_length-arm_params.Kl*2*arm_params.m_ins(1))./(arm_params.Kl*2*arm_params.m_ins(1))));
%     ylim([0 200])
passive_musc_force = max(0,passive_musc_force);

musc_force = active_musc_force + passive_musc_force;
musc_force = max(0,musc_force);
musc_force = min(musc_force,arm_params.F_max);

musc_torque = [x_gain*(arm_params.m_ins(1)*musc_force(1) - arm_params.m_ins(2)*musc_force(2));...
    x_gain*(arm_params.m_ins(3)*musc_force(3) - arm_params.m_ins(4)*musc_force(4))];

 %matrix equations 
M = [m(2)*lc(1)^2+m(2)*l(1)^2+i(1), m(2)*l(1)*lc(2)^2*cos(theta(1)-theta(2));
 m(2)*l(1)*lc(2)*cos(theta(1)-theta(2)),+m(2)*lc(2)^2+i(2)]; 

C = [-m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(4)^2;
 -m(2)*l(1)*lc(2)*sin(theta(1)-theta(2))*theta(3)^2];

Fg = [(m(1)*lc(1)+m(2)*l(1))*g*cos(theta(1));
 m(2)*g*lc(2)*cos(theta(2))];

T_endpoint = [-(l(1)*sin(theta(1))+l(2)*sin(theta(2))) * F_end(1) + (l(1)*cos(theta(1))-l(2)*cos(theta(2))) * F_end(2);
    -l(2)*sin(theta(2)) * F_end(1) + l(2)*cos(theta(2)) * F_end(2)];

tau =T+[-theta(3)*c(1);-theta(4)*c(2)]; %input torques,
xdot(1:2,1)=theta(3:4);
xdot(3:4,1)= M\(T_endpoint + tau-Fg-C + musc_torque);

end