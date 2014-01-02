function [g1_new, g2_new] = backpropagation_through_time(S2EMG_w, ...
    EMG2F_w, S, EMG, F, S_lag, EMG_lag)
%BPTT Computes the backpropagation gradient when there is a recurrent 
% EMG has, in each column, a lagged history of EMG, where the first column
% is the newest value and the last column is the oldest.
% S are the spikes in the same form

% Force prediction
Fpred = EMG(:)'*EMG2F_w;

% Gradient of squared error
df = F - Fpred;
%df(2) = -df(2);
% gradient of EMG
de = df*EMG2F_w';
g = zeros(size(S2EMG_w));
de_reshaped = reshape(de, EMG_lag, []);
% look back at neurons and accumulate the gradient
for t = 1:EMG_lag
    g = g + ...
        [1 rowvec(S(t:(t+S_lag-1),:))']'*de_reshaped(t, :);
%          [1 rowvec(S(:, t:(t+S_lag-1)))']'*de_reshaped(t, :);
end

g(2:end, :) = 0.8*g(2:end, :); % ??
g1_new = -g;
g2_new = -[EMG2F_w(:, 1)*df(1) EMG2F_w(:, 2)*df(2)];

end