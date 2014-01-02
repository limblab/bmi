function c = test_lagged_decoder(eta, lag_emg, lag_n)
% perform wiener filter back-propagation learning using lag_n for lag from
% neuron to EMG, and lag_emg lags from EMG to force.
% Number of epochs is equal to m and learning rate is eta

%data = load('cache/test_all_algorithms.mat');
% generate dataset
L = 100;
N = [ones(L, 1) zeros(L, 1);
    zeros(L, 1) ones(L, 1)];
EMG = [ones(L, 1) zeros(L, 1);
    zeros(L, 1) ones(L, 1)];
EMG = EMG + randn(size(EMG))*0.1;
F = [ones(L, 1) zeros(L, 1);
    zeros(L, 1) -ones(L, 1)];

F = F + randn(size(F))*0.1;

% N = data.N;
% F = data.F;
% EMG = data.emg;
n_emg = size(EMG, 2);

% compute emg to force decoder
lagged_N = lagmatrix(N, 0:(lag_n-1));
idx_good = all(~isnan(lagged_N), 2);
lagged_N = lagged_N(idx_good, :);
EMGtmp = EMG(idx_good, :);

w_N2F = lscov(cbind(1, lagged_N), F(idx_good, :));

% Neuron to EMG decoder
w_N2emg = lscov([ones(size(lagged_N, 1), 1) lagged_N], EMGtmp);

lagged_emg = lagmatrix(EMG, 0:(lag_emg-1));
idx_good = all(~isnan(lagged_emg), 2);
lagged_emg = lagged_emg(idx_good, :);
Ftmp = F(idx_good, :);
% w_emg2F = lscov([ones(size(lagged_emg, 1), 1) lagged_emg], ...
%     Ftmp);

% w_N2F = lscov(cbind(1, lagged_N), Ftmp);

% w_emg2F = 0.1*randn(lag_emg*size(EMG, 2) + 1, size(F, 2));
w_emg2F = zeros(lag_emg*size(EMG, 2) + 1, size(F, 2));
w_emg2F(2, 1) =1;
w_emg2F(3, 2) =1;
% w_N2emg = 0.0001*randn(lag_n*size(N, 2) + 1, size(EMG, 2));


predicted_stored_emg = zeros(1, size(EMG, 2)*lag_emg);

for epoch = 1:30
%     idxs = randperm(size(lagged_N, 1)-lag_emg-lag_n);
    idxs = 1:(size(lagged_N, 1)-lag_emg-lag_n);
    total_df = 0;
    n_df = 0;
    for start = idxs(idxs>20)
%         predicted_stored_emg2 = (cbind(1, ...
%             lagged_N(start:start+lag_emg-1, :)) * ...
%             w_N2emg)';
        predicted_stored_emg2 = (cbind(1, ...
            lagged_N((start+lag_emg-1):-1:start, :)) * ...
            w_N2emg)';
%         end
        
        % apply back-propagation
%         Fpred = [1 predicted_stored_emg2(:)']*w_emg2F;
        Fpred = [1 (predicted_stored_emg2(:)')]*w_emg2F;
        df = F(start+lag_emg-1, :) - Fpred;
        if mod(round(start/5000), 2) == 0 || true
            Fpred_N2F = cbind(1, lagged_N(start+lag_emg-1, :))*w_N2F;
            hold off;
            plot(F(start+lag_emg-1, 1), F(start+lag_emg-1, 2), 'bo');
            hold on;
            plot(Fpred(1), Fpred(2), 'ro');
            plot(Fpred_N2F(1), Fpred_N2F(2), 'g+');
        end
        ylim([-2 2]);
        xlim([-2 2]);
        drawnow;        
        total_df = total_df + (F(start+lag_emg-1, :) - Fpred).^2;
        n_df = n_df + 1;
        
        %         de = [1 predicted_stored_emg] .* (df*w_emg2F');
        de = (df*w_emg2F');
        g = zeros(size(w_N2emg));
        % add gradients through time
        de_reshaped = reshape(de(2:end), lag_emg, []);
        for z = 1:lag_emg
            g = g + ...
                [1 lagged_N(start+lag_emg-z, :)]'*de_reshaped(end-z+1, :);
        end
%         g = [1 lagged_N(start+9, :)]'*de;
%                     total_g = sum(reshape(g(:, 2:end), size(g, 1), ...
%                         length(predicted_emg), []), 3);
        
        w_N2emg = w_N2emg + eta*g;
        %             w_N2emg = w_N2emg - ...
        %                 eta*total_g;
    end
%     EMGpred = ([ones(size(lagged_N, 1), 1) lagged_N]*w_N2emg);
%     EMGpred_lagged = lagmatrix(EMGpred, 0:(lag_emg-1));
%     idx_good = all(~isnan(EMGpred_lagged), 2);
%     EMGpred_lagged = EMGpred_lagged(idx_good, :);
%     
%     Fpred_total = [ones(size(EMGpred_lagged, 1), 1) ilogit(EMGpred_lagged)]*...
%         w_emg2F;
    disp('Epoch');
    disp(epoch);
%     disp(diag(corr(Fpred_total, Ftmp(idx_good, :))).^2);
    disp(total_df/n_df);
    
end