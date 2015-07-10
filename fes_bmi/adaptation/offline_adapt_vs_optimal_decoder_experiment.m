% 0 - set global variables
monkey = 'Jango';
if strcmpi(monkey,'Jango')
    decoder_path = ['Z:\Jango_12a1\SavedFilters\Adaptation\' datestr(now,'yyyymmdd')];
    mkdir(decoder_path);
else
    decoder_path = ['Z:\Kevin_12A2\FES\SavedFilters\Adaptation\' datestr(now,'yyyymmdd')];
    mkdir(decoder_path);
end
% 1 - Record Hand Control Data for 25 mins
    %       THRESHOLD = -5*Vrms

% 2 - Convert Cerebus Files to binnedData format
train_data2 = convert2BDF2Binned;
%     0.5 MIN FR THRESHOLD

% 2b- Select "best" N neurons (optional)
% N = 50;
% vv = var(train_data.spikeratedata);
% [~,idx] = sort(vv,2,'descend');
% train_data.spikeratedata = train_data.spikeratedata(:,idx(1:N));
% train_data.neuronIDs = train_data.neuronIDs(idx(1:N),:);
% clear vv idx N

% 2c- Concat data from training sets if needed (optional)
% train_data = concatBinnedData(train_data1,train_data2);

% 2d- Split data into training and testing sets (optional)
[train_data,test_data] = splitBinnedData(train_data,20*60,train_data.timeframe(end));

% 3 - Build N2F decoder:
opts = BuildModelGUI;
N2F = BuildModel(train_data,opts);
save([decoder_path '\' monkey '_' datestr(now,'yyyymmdd') '_N2F_Decoder.mat'],'N2F');

% 4 - Train adaptive decoder:
N2E = adapt_offline(train_data);
save([decoder_path '\' monkey '_' datestr(now,'yyyymmdd') '_N2E_Decoder.mat'],'N2E');

% 5 - Brain-control
params = bc_params(monkey);
% NOTE: uncheck the 'Record for' box from the file storage app first.

% 5a - Brain-control using optimal decoder:
params.mode = 'direct';
params.neuron_decoder = N2F;
run_decoder(params); % 5 min

% 5b - Brain-control using non-supervised decoder:
params.mode = 'emg_cascade';
params.neuron_decoder = N2E;
run_decoder(params); % 5 min
