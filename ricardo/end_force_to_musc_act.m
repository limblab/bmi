% Endpoint forces to muscle activations
function estimated_emg = end_force_to_musc_act(arm_params,F)

l = arm_params.l;

X_h = -arm_params.X_sh;

% Inverse kinematics
if arm_params.left_handed
    theta(2) = -2*atan(sqrt(((l(1)+l(2))^2-(X_h(1)^2+(X_h(2))^2))/...
        ((X_h(1)^2+X_h(2)^2)-(l(1)-l(2))^2)));
else
    theta(2) = 2*atan(sqrt(((l(1)+l(2))^2-(X_h(1)^2+(X_h(2))^2))/...
        ((X_h(1)^2+X_h(2)^2)-(l(1)-l(2))^2)));
end
phi = atan2(X_h(2),X_h(1));
psi = atan2(l(2)*sin(theta(2)),l(1)+l(2)*cos(theta(2)));
theta(1) = phi - psi;
% theta(2) = theta(1)+theta(2);

J = [-l(1)*sin(theta(1))-l(2)*sin(theta(2)) -l(2)*sin(theta(2));...
    l(1)*cos(theta(1))+l(2)*cos(theta(2)) l(2)*cos(theta(2))];

T = (-pinv(J)*F')';
min_99_prctile = min([prctile(T,90) prctile(-T,90)]);
mag_T = sqrt(T(:,1).^2+T(:,2).^2);
angle_T = atan2(T(:,2),T(:,1));
T(mag_T>min_99_prctile,:) = [min_99_prctile*cos(angle_T(mag_T>min_99_prctile))...
    min_99_prctile*sin(angle_T(mag_T>min_99_prctile))];

T_flexors = zeros(size(T,1),2);
T_extensors = zeros(size(T,1),2);

if arm_params.left_handed
    T_flexors(T<0) = abs(T(T<0));
    T_extensors(T>0) = abs(T(T>0));
else
    T_flexors(T>0) = abs(T(T>0));
    T_extensors(T<0) = abs(T(T<0));
end
    
T_flexors = T_flexors./repmat(max(T_flexors),size(T_flexors,1),1);
T_flexors(isnan(T_flexors)) = 0;
T_extensors = T_extensors./repmat(max(T_extensors),size(T_extensors,1),1);
T_extensors(isnan(T_extensors)) = 0;

% T_flexors = T_flexors./repmat(prctile(T_flexors',99)',1,size(T_flexors,2));
% T_flexors(T_flexors>1) = 1;
% T_flexors(isnan(T_flexors)) = 0;
% T_extensors = T_extensors./repmat(prctile(T_extensors',99)',1,size(T_extensors,2));
% T_extensors(T_extensors>1) = 1;
% T_extensors(isnan(T_extensors)) = 0;

estimated_emg = [T_flexors(:,1) T_extensors(:,1) T_flexors(:,2) T_extensors(:,2)];