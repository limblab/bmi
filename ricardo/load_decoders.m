function [neuron_decoder,emg_decoder,params] = load_decoders(params)
    switch params.mode
        case 'emg_cascade'
            if strncmp(params.neuron_decoder,'new',3)
                % create new neuron decoder from scratch
                neuron_decoder = struct(...
                    'P'        , [] ,...
                    'neuronIDs', [(1:params.n_neurons)' zeros(params.n_neurons,1)],...
                    'binsize'  , params.binsize,...
                    'fillen'   , params.binsize*params.n_lag);
                if strcmp(params.neuron_decoder,'new_rand')
                    neuron_decoder.H = randn(1 + params.n_neurons*params.n_lag, params.n_emgs)*0.00001;
                elseif strcmp(params.neuron_decoder,'new_zeros')
                    neuron_decoder.H = zeros(1 + params.n_neurons*params.n_lag, params.n_emgs);
                end
            else
                % load existing neuron decoder
                neuron_decoder = LoadDataStruct(params.neuron_decoder);
                if ~isfield(neuron_decoder, 'H')
                    disp('Invalid neuron-to-emg decoder');
                    return;
                end
                % overwrite parameters according to loaded decoder
                params.n_lag     = round(neuron_decoder.fillen/neuron_decoder.binsize);
                params.n_neurons = size(neuron_decoder.neuronIDs,1);
                params.binsize   = neuron_decoder.binsize;
            end
            
            % load existing emg decoder
            emg_decoder = LoadDataStruct(params.emg_decoder);
            if ~isfield(emg_decoder, 'H')
                error('Invalid emg-to-force decoder');
            end
            params.n_lag_emg = round(emg_decoder.fillen/emg_decoder.binsize);
            params.n_emgs = round((size(emg_decoder.H,1)-1)/params.n_lag_emg);
            if round(emg_decoder.binsize*1000) ~= round(neuron_decoder.binsize*1000) 
                error('Incompatible binsize between neurons and emg decoders');
            end
            if params.n_emgs ~= size(neuron_decoder.H,2)
                error(sprintf(['The number of outputs from the neuron_decoder (%d) does not match\n' ...
                               'the number of inputs of the emg_decoder...(%d).'],...
                               size(neuron_decoder.H,2),params.n_emgs));
            end
            params.n_forces = size(emg_decoder.H,2);
        case 'direct'
            neuron_decoder = LoadDataStruct(params.neuron_decoder);
            if ~isfield(neuron_decoder, 'H')
                error('Invalid Decoder');
            end
            % overwrite parameters according to loaded decoder            
            params.n_lag = round(neuron_decoder.fillen/neuron_decoder.binsize);
            params.n_neurons = size(neuron_decoder.neuronIDs,1);
            params.binsize   = neuron_decoder.binsize;
            emg_decoder = [];
            params.n_emgs = 0;
            params.n_lag_emg = 0;
        case 'EMG'
            neuron_decoder = LoadDataStruct(params.neuron_decoder);
            if ~isfield(neuron_decoder, 'H')
                error('Invalid Decoder');
            end
            % overwrite parameters according to loaded decoder            
            params.n_lag = round(neuron_decoder.fillen/neuron_decoder.binsize);
            params.n_neurons = size(neuron_decoder.neuronIDs,1);
            params.binsize   = neuron_decoder.binsize;
            emg_decoder = [];
            params.n_emgs = 0;
            params.n_lag_emg = 0; 
        case 'N2E'
            neuron_decoder = LoadDataStruct(params.neuron_decoder);
            if ~isfield(neuron_decoder, 'H')
                error('Invalid Decoder');
            end
            % overwrite parameters according to loaded decoder            
            params.n_lag = round(neuron_decoder.fillen/neuron_decoder.binsize);
            params.n_neurons = size(neuron_decoder.neuronIDs,1);
            params.binsize   = neuron_decoder.binsize;
            emg_decoder = [];
            params.n_emgs = 0;
            params.n_lag_emg = 0;      
        case 'Iso'
            neuron_decoder = [];
            neuron_decoder.H = [];
            % overwrite parameters according to loaded decoder            
            params.n_lag = [];
            params.n_neurons = [];
            params.binsize   = .05;
            emg_decoder = [];
            params.n_emgs = [];
            params.n_lag_emg = [];  
        otherwise
            error('Invalid decoding mode. Please specifiy params.mode = [''emgcascade'' | ''direct'' ]');
    end
end