function [neuron_decoder,emg_decoder,params] = load_N2E2F_decoders(params)
    switch params.mode
        case 'emg_cascade'
            % load existing emg decoder
            if ~isstruct(params.emg_decoder)
                emg_decoder = LoadDataStruct(params.emg_decoder);
                if ~isfield(emg_decoder, 'H')
                    warning('Invalid emg-to-force decoder');
                    neuron_decoder = [];
                    emg_decoder = [];
                    return;
                end
            else
                emg_decoder = params.emg_decoder;
            end
            
            if emg_decoder.binsize ~= params.binsize
                waring(['EMG decoder was calculated for a different bin size'...
                        ' than the neuron decoder - abort']);
                neuron_decoder = [];
                emg_decoder = [];
                return;
            end
            
            params.n_lag_emg = emg_decoder.fillen/emg_decoder.binsize;
            params.n_emgs = round(size(emg_decoder.H,1)/params.n_lag_emg);
            
            if ~isempty(params.emg_convolve)
                if length(params.emg_convolve) > 1
                    % we want to modify the (1bin) emg decoder to include force dynamics
                    if emg_decoder.fillen > params.binsize
                        warning(['Attempting to apply a filter to an emg decoder' ...
                                 ' which already includes temporal dynamics - abort']);
                        neuron_decoder = [];
                        emg_decoder = [];
                        return;
                    end
                    % make sure the filter is normalized
                    params.emg_convolve = params.emg_convolve/sum(params.emg_convolve);
                    emg_decoder.H = reshape((rowvec(emg_decoder.H)*params.emg_convolve)',...
                                                length(params.emg_convolve)*params.n_emgs,params.n_forces);
                    params.n_lag_emg = length(params.emg_convolve);                        
                    emg_decoder.fillen = params.n_lag_emg * emg_decoder.binsize;
                end
            end
            
            if strncmp(params.neuron_decoder,'new',3)
                % create new neuron decoder from scratch
                neuron_decoder = struct(...
                    'P'        , [] ,...
                    'neuronIDs', params.neuronIDs,...
                    'binsize'  , params.binsize,...
                    'fillen'   , params.binsize*params.n_lag,...
                    'decoder_type','N2E');
                if strcmp(params.neuron_decoder,'new_rand')
                    if strcmp(params.adapt_params.type,'normal')
                        %weight scaling for neurons-to-EMG:
                        w_factor = 0.00001;
                    else
                        %weight scaling for neurons-to-force
                        w_factor = 0.0001;
                    end
                        neuron_decoder.H = randn(1 + params.n_neurons*params.n_lag, params.n_emgs)*w_factor;
                elseif strcmp(params.neuron_decoder,'new_zeros')
                    neuron_decoder.H = zeros(1 + params.n_neurons*params.n_lag, params.n_emgs);
                end
            else
                % load existing neuron decoder
                if ~isstruct(params.neuron_decoder)
                    neuron_decoder = LoadDataStruct(params.neuron_decoder);
                    if ~isfield(neuron_decoder, 'H')
                        warning('Invalid neuron-to-emg decoder');
                        neuron_decoder = [];
                        emg_decoder = [];
                        return;
                    end
                else
                    neuron_decoder = params.neuron_decoder;
                end
                % overwrite parameters according to loaded decoder
                params.n_lag     = round(neuron_decoder.fillen/neuron_decoder.binsize);
                params.n_neurons = size(neuron_decoder.neuronIDs,1);
                params.binsize   = neuron_decoder.binsize;
                params.neuronIDs = neuron_decoder.neuronIDs;
            end
            
            if round(emg_decoder.binsize*1000) ~= round(neuron_decoder.binsize*1000) 
                warning('Incompatible binsize between neurons and emg decoders');
                neuron_decoder = [];
                emg_decoder = [];
                return;
            end
%             
%             if params.n_emgs ~= size(neuron_decoder.H,2)
%                 warning(['The number of outputs from the neuron_decoder (%d) does not match\n' ...
%                                'the number of inputs of the emg_decoder...(%d).'],...
%                                size(neuron_decoder.H,2),params.n_emgs);
%                 neuron_decoder = [];
%                 emg_decoder = [];
%                 return;
%             end

            
        case 'direct'
            if strncmp(params.neuron_decoder,'new',3)
                % create new neuron decoder from scratch
                neuron_decoder = struct(...
                    'P'        , [] ,...
                    'neuronIDs', params.neuronIDs,...
                    'binsize'  , params.binsize,...
                    'fillen'   , params.binsize*params.n_lag,...
                    'decoder_type','N2F');
                if strcmp(params.neuron_decoder,'new_rand')
                    neuron_decoder.H = randn(1 + params.n_neurons*params.n_lag, params.n_forces)*0.00001;
                elseif strcmp(params.neuron_decoder,'new_zeros')
                    neuron_decoder.H = zeros(1 + params.n_neurons*params.n_lag, params.n_forces);
                end
            else % load existing decoder
                if ~isstruct(params.neuron_decoder)
                    neuron_decoder = LoadDataStruct(params.neuron_decoder);
                    if ~isfield(neuron_decoder, 'H')
                        warning('Invalid Neuron Decoder');
                        neuron_decoder = [];
                        emg_decoder = [];
                        return;
                    end
                else
                    neuron_decoder = params.neuron_decoder;
                end
                % overwrite parameters according to loaded decoder
                params.n_lag = round(neuron_decoder.fillen/neuron_decoder.binsize);
                params.n_neurons = size(neuron_decoder.neuronIDs,1);
                params.binsize   = neuron_decoder.binsize;
                params.neuronIDs = neuron_decoder.neuronIDs;
            end
                emg_decoder = [];
                params.n_emgs = 0;
                params.n_lag_emg = 0;
                
                
        case 'emg_only'
            if strncmp(params.neuron_decoder,'new',3)
                warning('Option not yet available');
                return;
            else
                % load existing neuron-to-emg decoder
                if ~isstruct(params.neuron_decoder)
                    neuron_decoder = LoadDataStruct(params.neuron_decoder);
                    if ~isfield(neuron_decoder, 'H')
                        warning('Invalid neuron-to-emg decoder');
                        neuron_decoder = [];
                        emg_decoder = [];
                        return;
                    end
                else
                    neuron_decoder = params.neuron_decoder;
                end
                % overwrite parameters according to loaded decoder
                params.n_lag = round(neuron_decoder.fillen/neuron_decoder.binsize);
                params.n_neurons = size(neuron_decoder.neuronIDs,1);
                params.binsize   = neuron_decoder.binsize;
                params.neuronIDs = neuron_decoder.neuronIDs;
            end            
            
            emg_decoder = [];

        otherwise
            warning('Invalid decoding mode. Please specifiy params.mode = [''emg_cascade'' | ''direct'' ]');
            neuron_decoder = [];
            emg_decoder = [];
    end

end