function [cost_out, cost_grad] = Force2EMG_costfun_sig(EMG, F, E2F, lambda)
    % EMG is predicted EMG
    % F is expected force
    % w are the EMG-to-Force vectors (1+MxN), +1=offset for mean, M = num_muscles, N = num_force
    % lambda is the regularization factor to minimize predicted EMG.
    % expected_emg correspond to the expected EMG pattern

    
    % sometimes, fmincon call the function with with NaNs in EMGs.
    % this is a lousy attempt at solving that:
    if any(any(isnan(EMG)))
        warning('NaN detected as initial optimization EMG values');
        cost_out = 99999;
        cost_grad= 0.0001*ones(size(EMG));
        return;
    end
    % end of temp cludgy NaN solving solution--
    
    n_F = size(E2F.H,2);
    [n_bins,n_E] = size(EMG);
    
    Fpred  = sigmoid(EMG,'direct')*E2F.H;
    dFpred = nan(n_bins,n_E,n_F);
    for f = 1:n_F
        dFpred(:,:,f) = sigmoid(EMG,'derivative')*diag(E2F.H(:,f));
    end
    
    cost_out  =  sum(   sum((F-Fpred).*(F-Fpred),2)/n_F  + ... %minimize Fpred error
                        lambda(1)*sum(EMG,2)/n_E       + ... %minimize EMG (L1)
                        lambda(2)*sum(EMG.^2,2)/n_E ); %minimize EMG square(L2)
%                         lambda(4)*sum((EMG-expected_emg).*(EMG-expected_emg),2)/n_E ); %minimize diff with emg_patterns
    
    cost_grad = zeros(size(EMG));                
    for f = 1:n_F
        cost_grad =  cost_grad + ...
                        (-2*dFpred(:,:,f)'*diag(F(:,f)-Fpred(:,f)))' +...
                        lambda(1)/n_E       + ...
                        lambda(2)*2*EMG/n_E ;
%                         lambda(4)*2*(EMG-expected_emg)/n_E;
    end
    cost_grad = cost_grad/n_F;

end