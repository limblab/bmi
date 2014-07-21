function params = load_decoders(params)
    params.null_decoder.neuronIDs = [];
    params.null_decoder.H = [];
    params.null_decoder.P = [];
    params.null_decoder.T = [];
    params.null_decoder.patch = [];
    params.null_decoder.outnames = [];
    params.null_decoder.fillen = 0.5;
    params.null_decoder.binsize = .05;
    params.null_decoder.input_type = 'spike';
    params.null_decoder.decoder_file = '';
    params.null_decoder.n_lag = 10;
    params.null_decoder.n_neurons = 0;
    params.null_decoder.emg_decoder = [];
    params.null_decoder.n_emgs = 0;
    params.null_decoder.n_lag_emg = 0;
    params.current_decoder = params.null_decoder;
    
    if isfield(params,'N2E_decoder')        
        decoder = LoadDataStruct(params.N2E_decoder.decoder_file);
        decoder.decoder_file = params.N2E_decoder.decoder_file;
        if ~isfield(decoder, 'H')
            error('Invalid Decoder');
        end
        % overwrite parameters according to loaded decoder            
        decoder.n_lag = round(decoder.fillen/decoder.binsize);
        decoder.n_neurons = size(decoder.neuronIDs,1);
        decoder.binsize   = decoder.binsize;
        decoder.emg_decoder = [];
        decoder.n_emgs = 0;
        decoder.n_lag_emg = 0;
        params.N2E_decoder = decoder;  
        clear decoder
    end
    if isfield(params,'vel_decoder')
        decoder = LoadDataStruct(params.vel_decoder.decoder_file);
        decoder.decoder_file = params.N2E_decoder.decoder_file;
        if ~isfield(decoder, 'H')
            error('Invalid Decoder');
        end
        % overwrite parameters according to loaded decoder            
        decoder.n_lag = round(decoder.fillen/decoder.binsize);
        decoder.n_neurons = size(decoder.neuronIDs,1);
        decoder.binsize   = decoder.binsize;
        decoder.emg_decoder = [];
        decoder.n_emgs = 0;
        decoder.n_lag_emg = 0;
        params.vel_decoder = decoder; 
        clear decoder
    end
    
%         
%         
%     switch params.mode
%         case 'emg_cascade'
%             if strncmp(params.neuron_decoder_name,'new',3)
%                 % create new neuron decoder from scratch
%                 params.neuron_decoder = struct(...
%                     'P'        , [] ,...
%                     'neuronIDs', [(1:params.n_neurons)' zeros(params.n_neurons,1)],...
%                     'binsize'  , params.binsize,...
%                     'fillen'   , params.binsize*params.n_lag);
%                 if strcmp(params.neuron_decoder_name,'new_rand')
%                     params.neuron_decoder.H = randn(1 + params.n_neurons*params.n_lag, params.n_emgs)*0.00001;
%                 elseif strcmp(params.neuron_decoder_name,'new_zeros')
%                     params.neuron_decoder.H = zeros(1 + params.n_neurons*params.n_lag, params.n_emgs);
%                 end
%             else
%                 % load existing neuron decoder
%                 params.neuron_decoder = LoadDataStruct(params.neuron_decoder_name);
%                 if ~isfield(params.neuron_decoder, 'H')
%                     disp('Invalid neuron-to-emg decoder');
%                     return;
%                 end
%                 % overwrite parameters according to loaded decoder
%                 params.n_lag     = round(params.neuron_decoder.fillen/params.neuron_decoder.binsize);
%                 params.n_neurons = size(params.neuron_decoder.neuronIDs,1);
%                 params.binsize   = params.neuron_decoder.binsize;
%             end
%             
%             % load existing emg decoder
%             params.emg_decoder = LoadDataStruct(params.emg_decoder);
%             if ~isfield(params.emg_decoder, 'H')
%                 error('Invalid emg-to-force decoder');
%             end
%             params.n_lag_emg = round(params.emg_decoder.fillen/params.emg_decoder.binsize);
%             params.n_emgs = round((size(params.emg_decoder.H,1)-1)/params.n_lag_emg);
%             if round(params.emg_decoder.binsize*1000) ~= round(params.neuron_decoder.binsize*1000) 
%                 error('Incompatible binsize between neurons and emg decoders');
%             end
%             if params.n_emgs ~= size(params.neuron_decoder.H,2)
%                 error(sprintf(['The number of outputs from the params.neuron_decoder (%d) does not match\n' ...
%                                'the number of inputs of the params.emg_decoder...(%d).'],...
%                                size(params.neuron_decoder.H,2),params.n_emgs));
%             end
%             params.n_forces = size(params.emg_decoder.H,2);
%         case 'direct'
%             params.neuron_decoder = LoadDataStruct(params.neuron_decoder_name);
%             if ~isfield(params.neuron_decoder, 'H')
%                 error('Invalid Decoder');
%             end
%             % overwrite parameters according to loaded decoder            
%             params.n_lag = round(params.neuron_decoder.fillen/params.neuron_decoder.binsize);
%             params.n_neurons = size(params.neuron_decoder.neuronIDs,1);
%             params.binsize   = params.neuron_decoder.binsize;
%             params.emg_decoder = [];
%             params.n_emgs = 0;
%             params.n_lag_emg = 0;
%         case 'EMG'
%             params.neuron_decoder = LoadDataStruct(params.neuron_decoder_name);
%             if ~isfield(params.neuron_decoder, 'H')
%                 error('Invalid Decoder');
%             end
%             % overwrite parameters according to loaded decoder            
%             params.n_lag = round(params.neuron_decoder.fillen/params.neuron_decoder.binsize);
%             params.n_neurons = size(params.neuron_decoder.neuronIDs,1);
%             params.binsize   = params.neuron_decoder.binsize;
%             params.emg_decoder = [];
%             params.n_emgs = 0;
%             params.n_lag_emg = 0; 
%         case 'N2E'
%             params.neuron_decoder = LoadDataStruct(params.neuron_decoder_name);
%             if ~isfield(params.neuron_decoder, 'H')
%                 error('Invalid Decoder');
%             end
%             % overwrite parameters according to loaded decoder            
%             params.n_lag = round(params.neuron_decoder.fillen/params.neuron_decoder.binsize);
%             params.n_neurons = size(params.neuron_decoder.neuronIDs,1);
%             params.binsize   = params.neuron_decoder.binsize;
%             params.emg_decoder = [];
%             params.n_emgs = 0;
%             params.n_lag_emg = 0;      
%         case 'Iso'
%             params.neuron_decoder = [];
%             params.neuron_decoder.H = [];
%             params.neuron_decoder.neuronIDs = [];
%             % overwrite parameters according to loaded decoder            
%             params.n_lag = [];
%             params.n_neurons = [];
%             params.binsize   = .05;
%             params.emg_decoder = [];
%             params.n_emgs = [];
%             params.n_lag_emg = [];  
%         otherwise
%             error('Invalid decoding mode. Please specifiy params.mode = [''emgcascade'' | ''direct'' ]');
%     end
end