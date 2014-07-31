function params = load_decoders(params)

    for iDecoder = 1:numel(params.decoders)
        if ~strcmp(params.decoders(iDecoder).decoder_type,'null')
            decoder = LoadDataStruct(params.decoders(iDecoder).decoder_file);
            if ~isfield(decoder, 'H')
                error(['Invalid Decoder: ' params.decoders(iDecoder).decoder_file]);
            end        
            decoder_fields = fields(decoder);
            for iField = 1:length(decoder_fields)
                params.decoders(iDecoder).(decoder_fields{iField}) = decoder.(decoder_fields{iField});
            end
            params.decoders(iDecoder).n_lag = round(decoder.fillen/decoder.binsize);
            params.decoders(iDecoder).n_neurons = size(decoder.neuronIDs,1);
            params.decoders(iDecoder).binsize   = decoder.binsize;
            params.decoders(iDecoder).emg_decoder = [];
            params.decoders(iDecoder).n_emgs = 0;
            params.decoders(iDecoder).n_lag_emg = 0;
        end
    end
    if ~strcmp(params.decoders(iDecoder).decoder_type,'null')
        params.decoders(iDecoder+1).decoder_file = '';
        params.decoders(iDecoder+1).decoder_type = 'null';
        params.decoders(iDecoder+1).neuronIDs = [];
        params.decoders(iDecoder+1).H = [];
        params.decoders(iDecoder+1).P = [];
        params.decoders(iDecoder+1).T = [];
        params.decoders(iDecoder+1).patch = [];
        params.decoders(iDecoder+1).outnames = [];
        params.decoders(iDecoder+1).fillen = 0.5;
        params.decoders(iDecoder+1).binsize = .05;
        params.decoders(iDecoder+1).input_type = 'spike';
        params.decoders(iDecoder+1).n_lag = 0;
        params.decoders(iDecoder+1).n_neurons = 0;
        params.decoders(iDecoder+1).binsize   = 0.05;
        params.decoders(iDecoder+1).emg_decoder = [];
        params.decoders(iDecoder+1).n_emgs = 0;
        params.decoders(iDecoder+1).n_lag_emg = 0;
    end
    
    if any(strcmpi({params.decoders.decoder_type},params.mode))
        params.current_decoder = params.decoders(strcmpi({params.decoders.decoder_type},params.mode));
    else
        params.current_decoder = params.decoders(strcmpi({params.decoders.decoder_type},'null'));
    end
    
end