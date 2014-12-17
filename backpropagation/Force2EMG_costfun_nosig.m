function [cost_out, cost_grad] = Force2EMG_costfun_nosig(EMG, F, w, lambda, expected_emg)
    % EMG is predicted EMG
    % F is expected force
    % w are the EMG-to-Force vectors (MxN), M = num_muscle, N = num_force
    % lambda is the regularization factor to minimize predicted EMG.
    % expected_emg correspond to the expected EMG pattern
    
    n_F = size(w,2);
    n_E = size(EMG,2);
    
    Fpred  = EMG*w;

    cost_out  =  sum(   lambda(1)*sum((F-Fpred).*(F-Fpred),2)/n_F  + ... %minimize Fpred error
                        lambda(2)*sum(EMG,2)/n_E       + ... %minimize EMG (L1)
                        lambda(3)*sum(EMG.^2,2)/n_E    + ... %minimize EMG square(L2)
                        lambda(4)*sum((EMG-expected_emg).*(EMG-expected_emg),2)/n_E ); %minimize diff with emg_patterns
                    

    cost_grad =     lambda(1)*2*(-F*w' + EMG*(w*w') )/n_F + ...
                    lambda(2)/n_E       + ...
                    lambda(3)*2*EMG/n_E + ...
                    lambda(4)*2*(EMG-expected_emg)/n_E;
                
%%
% 
%     n_F = size(w,2);
%     [n_bins,n_E] = size(EMG);
%     
%     Fpred  = EMG*w;
%     
%     cost_out  =  sum(   lambda(1)*sum((F-Fpred).*(F-Fpred),2)/n_F  + ... %minimize Fpred error
%                         lambda(2)*sum(EMG,2)/n_E       + ... %minimize EMG (L1)
%                         lambda(3)*sum(EMG.^2,2)/n_E    + ... %minimize EMG square(L2)
%                         lambda(4)*sum((EMG-expected_emg).*(EMG-expected_emg),2)/n_E ); %minimize diff with emg_patterns
%     
%     cost_grad = zeros(size(EMG));                
%     for f = 1:n_F
%         cost_grad =  cost_grad + ...
%                         lambda(1)*(-2*w'*diag(F(:,f)-Fpred(:,f)))' +...
%                         lambda(2)/n_E       + ...
%                         lambda(3)*2*EMG/n_E + ...
%                         lambda(4)*2*(EMG-expected_emg)/n_E;
%     end
%     cost_grad = cost_grad/n_F;
%     %%
%                 
                
end