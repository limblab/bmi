function neuron_decoder = adapt_offline(train_data,varargin)

params.adapt_params = adapt_params_defaults;

params.adapt        = true;
params.mode         = 'emg_cascade';
params.online       = false;
params.realtime     = false;
params.save_data    = false;
params.display_plots= false;
params.cursor_assist= false;
params.output       ='none';
params.print_out    = false;
params.save_data    = false;
params.save_dir     = [];

%Data files
params.offline_data   = train_data;

%Neuron Decoder
params.neuron_decoder = 'new_zeros';

%-------------------
neuron_decoder = run_decoder(params);
%-------------------
