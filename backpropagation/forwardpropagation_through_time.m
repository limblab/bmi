function Fpred = forwardpropagation_through_time(w1, w2, X)

EMG = [ones(size(X, 1), 1) X]*w1;

% Force prediction
Fpred = [ones(size(EMG, 1), 1) ilogit(EMG)]*w2(1:(size(EMG, 2)+1), :);
Fpred = ilogit(EMG)*w2(1:(size(EMG, 2)), :);
