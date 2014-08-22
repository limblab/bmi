function [cost_out, cost_grad] = Force2EMG_costfun(EMG, F, w, lambda)
    % EMG is predicted EMG
    % F is expected force
    % w are the EMG-to-Force vectors (MxN), M = num_muscle, N = num_force
    % lambda is the regularization factor to minimize predicted EMG.

    n_EMGs = size(EMG,2);
    n_outs = size(w,2);
    n_bins = size(EMG,1);
    
    Fpred  = sigmoid(EMG,'direct')*w;

    dFpred = nan(n_bins,n_EMGs,n_outs);
    for o = 1:n_outs
        dFpred(:,:,o) = sigmoid(EMG,'derivative')*diag(w(:,o));
    end
    
%     dFpred = sigmoid(EMG,'derivative')*diag(w);
    
    dFpred(isnan(dFpred)) = 0;
    
    cost_out  =  sum( sum((F-Fpred).*(F-Fpred),2)  + ... %minimize Fpred error
                       lambda*sum(EMG.^2,2) ); %minimize overal EMG preds)
    
    cost_grad = zeros(size(EMG));             
    for o = 1:n_outs
        cost_grad = cost_grad + (-2*dFpred(:,:,o)'*diag(F(:,o)-Fpred(:,o)))' + 2*lambda*EMG;
    end
    cost_grad = cost_grad/n_outs;
    
end