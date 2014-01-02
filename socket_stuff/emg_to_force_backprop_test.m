% try to close server

for t = 0:10
    try
        pnet(t, 'close');
    catch
    end
end

n_lag = 1;
n_emg = 2;
n_force = 2;
n_neurons = 4;
LR = 1e-6;

% test with fake neurons

% run server
emg_to_force_backprop_server(zeros(n_neurons*n_lag + 1, n_emg), ...
    [1 0; 0 1], 1e-1, ...
    'n_lag', 1, 'n_neurons', 2, 'n_emg', 2, ...
    'n_port', 8000, 'display_plots', true);
