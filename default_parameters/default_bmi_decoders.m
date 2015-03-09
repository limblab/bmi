function decoders = default_bmi_decoders

neuron_decoder.decoder_file = 'Jango_20141203_default_N2F_decoder.mat';
emg_decoder.decoder_file    = 'E2F_default';

decoders = [neuron_decoder; emg_decoder];