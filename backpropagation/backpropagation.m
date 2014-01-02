function [g1_new, g2_new] = backpropagation(w1, w2, X, y)
%BACKPROPAGATION compute gradient of a two-layer network with two outputs

% put weights together, one for each output
w_all1 = [w1(:); w2(:, 1)];
w_all2 = [w1(:); w2(:, 2)];

% MLPregressionLoss computes back propagation for a general neural network
[~, g_all1] = MLPregressionLoss(w_all1, X, y(1), ...
    size(w2, 1));
[~, g_all2] = MLPregressionLoss(w_all2, X, y(2), ...
    size(w2, 1));

nInputVars = length(w1(:));

input_gradient = g_all1(1:nInputVars) + g_all2(1:nInputVars);
output_gradient = [g_all1((nInputVars+1):end) g_all2((nInputVars+1):end)]; 

% backpropagate errors
g1_new = reshape(input_gradient, size(w1));
g2_new = reshape(output_gradient, size(w2));
end