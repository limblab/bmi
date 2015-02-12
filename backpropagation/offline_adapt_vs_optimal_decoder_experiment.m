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
%       >> save('Z:\Jango_12a1\SavedFilters\Adaptation\20150212\Jango_2015212_WFHC_001_N2F_Decoder.mat';
%
% 4 - Train adaptive decoder:
%       >> N2E = adapt_offline(traindata);
%       >> save('Z:\Jango_12a1\SavedFilters\Adaptation\20150212\Jango_20150212_WFHC_001_N2E_adapt_Decoder.mat';
%
% 5a - Brain-control using optimal decoder:
%       >> edit bc_params: mode and neuron decoder
%       >> run_decoder(bc_params); % 5 min
%
% 5b - Brain-control using non-supervised decoder:
%       >> edit bc_params: mode and neuron decoder
%       >> run_decoder(bc_params); % 5 min
