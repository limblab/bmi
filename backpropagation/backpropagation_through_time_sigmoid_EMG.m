function [g1_new, g2_new] = backpropagation_through_time(S2EMG_w, ...
    EMG2F_w, S, EMG, F, S_lag, EMG_lag, lambda)
%BPTT Computes the backpropagation gradient when there is a recurrent 
% EMG has, in each row, a lagged history of EMG, where the first row
% is the newest value and the last row is the oldest.
% S are the spikes in the same form
% The weight arrays contain 'n_signals*n_lag+1' rows, to account for the
% stationary weight in firts row. Accordingly, S and EMG have a
% unit signal added to the other values.

EMG = [1 rowvec(EMG(:))'];

% Force prediction
Fpred = EMG(:)'*EMG2F_w;

% Gradient of squared error
df = F - Fpred;

% gradient of EMG
% previous error gradient without sigmoid de = df*EMG2F_w(2:end,:)';
de = (EMG(2:end).*(1-EMG(2:end))*(df*EMG2F_w(2:end,:)');
g = zeros(size(S2EMG_w));
de_reshaped = reshape(de, EMG_lag, []);

% look back at neurons and accumulate the gradient
for t = 1:EMG_lag
    g = g + ...
          [1 rowvec(S(t:(t+S_lag-1),:))']'*de_reshaped(t, :);
%          [1 rowvec(S(:, t:(t+S_lag-1)))']'*de_reshaped(t, :);
end

g1_new = -g/EMG_lag;
g1_new(2:end, :) = g1_new(2:end, :) - lambda*S2EMG_w(2:end, :);

g2_new = -[EMG2F_w(:, 1)*df(1) EMG2F_w(:, 2)*df(2)];

end