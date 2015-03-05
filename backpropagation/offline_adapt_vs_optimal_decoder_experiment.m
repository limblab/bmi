% 
% 1 - Record Hand Control Data for 30 mins
%
% 2 - Convert Cerebus Files to binnedData format
%       >> convertBatch2BDF2Binned;
%       load binnedData file in workspace.
% 
% 2b- Select "best" N neurons (optional)
%       >> N = 50;
%       >> vv = var(binnedData.spikeratedata);
%       >> [v_val,idx] = sort(vv,2,'descend');
%       >> binnedData.spikeratedata = binnedData.spikeratedata(:,idx(1:N));
%       >> binnedData.neuronIDs = binnedData.neuronIDs(idx(1:N),:);
%       >> binnedData.spikeguide = neuronIDs2spikeguide(binnedData.neuronIDs);
%       >> clear vv v_val idx
%
% 3 - Build N2F decoder:
%       >> opts = BuildModelGUI;
%       >> N2F = BuildModel(binnedData,opts);
%       >> decoder_path = 'Z:\Jango_12a1\SavedFilters\Adaptation\20150217';
%       >> mkdir(decoder_path);
%       >> save([decoder_path '\Jango_2015217_WFHC_002&003_N2F_Decoder.mat'],'N2F');
%
% 4 - Train adaptive decoder:
%       >> N2E = adapt_offline(binnedData);
%       >> save([decoder_path '\Jango_20150217_WFHC_002&003_N2E_adapt_Decoder.mat'],'N2E');
%
% 5a - Brain-control using optimal decoder:
%       >> edit bc_params: mode == 'direct' and neuron decoder filename
%       >> run_decoder(bc_params); % 5 min
%
% 5b - Brain-control using non-supervised decoder:
%       >> edit bc_params: mode == 'emg_cascade' and neuron decoder filename
%       >> run_decoder(bc_params); % 5 min
