% Wiener prediction server
try
     pnet(0, 'close');
catch
end
% Random weights for 160 neurons with 10 lags
n_lag = 10;
n_neurons = 97;

w = 0.05*randn(1 + n_neurons*n_lag, 2);

Wiener_predictor = @(s, dummy)Wiener_filter([1 s(:)'], w);
fprintf('Running server...\n');
prediction_server('127.0.0.1', 8000, ...
    n_neurons, n_lag, Wiener_predictor);