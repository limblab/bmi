
arm_params = get_arm_params();
hFig = create_arm_figure(arm_params);

script_filename = mfilename('fullpath');
[location,~,~] = fileparts(script_filename);

if arm_params.left_handed
    file_suffix = 'left';
else
    file_suffix = 'right';
end

arm_params.X_gain = -2*arm_params.left_handed+1;

x0 = [0 0 0 0];
arm_params.F_end = [0 0];
arm_params.musc_act = [0 0 0 0];
arm_params.musc_l0 = sqrt(2*arm_params.m_ins.^2)+...
                0*sqrt(2*arm_params.m_ins.^2)/5.*...
                (rand(1,length(arm_params.m_ins))-.5);
arm_params.theta_ref = [3*pi/4 pi/2]; 
arm_params.X_s = [0 0];
for i=1:length(arm_params.t)-1
    t_temp = [arm_params.t(i) arm_params.t(i+1)];
    [t,x] = ode45(@(t,x0) sandercock_model(t,x0,arm_params),t_temp,x0);
    arm_params.theta = x(end,1:2);
    arm_params.X_e = [arm_params.l(1)*cos(x(end,1)) arm_params.l(1)*sin(x(end,1))];
    arm_params.X_h = arm_params.X_e + [arm_params.l(2)*cos(x(end,2)) arm_params.l(2)*sin(x(end,2))];   
    x0 = x(end,:);
    arm_params.t_now = arm_params.t(i);
    update_arm_figure(hFig,arm_params)   
end