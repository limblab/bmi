function [dw] = backpropagation_simple(S2EMG_w, EMG2F_w, spikes, n_lag, target, cursor)
%BPS Computes the backpropagation gradient when there is no EMG lag

% Gradient of squared error
df = target - cursor;

% gradient of EMG
de = df*EMG2F_w';

% look back at neurons and compute the gradient
   dw = -[1 rowvec(spikes(1:n_lag,:))']'*de;
    
%          [1 rowvec(S(:, t:(t+S_lag-1)))']'*de_reshaped(t, :);

% g(2:end, :) = 0.8*g(2:end, :); % ??
dw = -dw;

end
