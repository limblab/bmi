% 0 - set global variables
monkey = 'Kevin';
if strcmpi(monkey,'Jango')
    decoder_path = ['Z:\Jango_12a1\SavedFilters\Adaptation\' datestr(now,'yyyymmdd')];
    mkdir(decoder_path);
else
    decoder_path = ['Z:\Kevin_12A2\FES\SavedFilters\Adaptation' datestr(now,'yyyymmdd')];
    mkdir(decoder_path);
end
% 1 - Record Hand Control Data for 30 mins

% 2 - Convert Cerebus Files to binnedData format
train_data = convert2BDF2Binned;

% 2b- Select "best" N neurons (optional)
N = 50;
vv = var(train_data.spikeratedata);
[~,idx] = sort(vv,2,'descend');
train_data.spikeratedata = train_data.spikeratedata(:,idx(1:N));
train_data.neuronIDs = train_data.neuronIDs(idx(1:N),:);
clear vv v_val idx N

% 3 - Build N2F decoder:
opts = BuildModelGUI;
N2F = BuildModel(train_data,opts);
save([decoder_path '\' monkey '_' datestr(now,'yyyymmdd') '_N2F_Decoder.mat'],'N2F');

% 4 - Train adaptive decoder:
N2E = adapt_offline(train_data);
save([decoder_path '\' monkey '_' datestr(now,'yyyymmdd') '_N2E_Decoder.mat'],'N2E');

% 5a - Brain-control using optimal decoder:
params.mode = 'direct';
params.neuron_decoder = N2F;
params = bc_params(monkey,params);
% NOTE: uncheck the 'Record for' box.
run_decoder2(params); % 5 min

% 5b - Brain-control using non-supervised decoder:
params.mode = 'emg_cascade';
params.neuron_decoder = N2E;
params.emg_convolve = [0.5 1 0.5];
params.emg_convolve  = params.emg_convolve./sum(params.emg_convolve);
run_decoder2(params); % 5 min
