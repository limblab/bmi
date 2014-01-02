% try to close server

for t = 0:10
    try
        pnet(t, 'close');
    catch
    end
end

savedir = ['/home/limblab/Desktop/Adapt_files/' date];
% N2E_dec       = 'new_rand';
N2E_dec       = 'new_zeros';
% N2E_dec       = [savedir '/previous_trials_05-Nov-2013 17:32:39.mat'];

n_lag         = 10;
n_emg         = 6;
n_force       = 2;
n_neurons     = 96;
LR            = 1.2e-10;
display_plots = false;
batch_length  = 8;
simulate      = false;
adapt_time    = 10*60;
fixed_time    = 2*60;
show_progress = false;
cursor_assist = true;


% load EMG-to-force decoder
% EMG2F_w = randn(n_emg, n_force); % fake EMG-to-force decoder
% EMG2F_w = randn(1+ n_emg*n_lag, n_force); % fake EMG-to-force decoder, including lag
EMG2F_w = load('/home/limblab/Desktop/SpikeDataLocal/SavedFilters/EMG2F/Spike_2013-09-23_500ms10binsEMG2F.mat');
EMG2F_w = EMG2F_w.H;
EMG2F_w2 = [];
for lag = 1:10
    EMG2F_w2 = [EMG2F_w2;
        EMG2F_w(t:10:end, :)];
end
EMG2F_w = EMG2F_w2;
EMG2F_w = [1     0;
            0.7   0.7;
           -1     0;
           -0.7   0.7;
           -0.7  -0.7;
            0.7  -0.7;
            0     1;
            0    -1];
n_emg = 8;


if strcmp(N2E_dec,'new_rand')
    S2EMG_w = randn(1 + n_neurons*n_lag, n_emg)*0.00001;
elseif strcmp(N2E_dec,'new_zeros')
    S2EMG_w = zeros(1 + n_neurons*n_lag, n_emg);
else
    d = load(N2E_dec);
    if isfield(d, 'S2EMG_w')
        S2EMG_w = d.S2EMG_w;
    else
        disp('Invalid initial spike-to-EMG decoder');
        return;
    end
end

% run server
emg_to_force_backprop_server(S2EMG_w, EMG2F_w, LR, ...
    'n_lag', n_lag, 'n_neurons', n_neurons, 'n_emg', n_emg, ...
    'n_port', 8000, ...
    'display_plots', display_plots, ...
    'n_adapt_to_last', batch_length, ...
    'simulate', simulate, ...
    'adaptation_time', adapt_time, ...
    'fixed_time',fixed_time,...
    'show_adaptation_progress', show_progress,...
    'cursor_assist', true);
