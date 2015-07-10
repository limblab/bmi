function neuron_decoder = adapt_offline(train_data,varargin)

params = [];
if nargin>1 params = varargin{1}; end


%% default params:
def_params.adapt        = true;
def_params.mode         = 'emg_cascade';
def_params.sigmoid      = true;
def_params.online       = false;
def_params.realtime     = false;
def_params.cursor_assist= true;
def_params.save_data    = false;
def_params.display_plots= false;
def_params.cursor_assist= false;
def_params.output       ='none';
def_params.print_out    = false;
def_params.save_data    = false;
def_params.save_dir     = [];
%Data files
def_params.offline_data   = train_data;
%Neuron Decoder
def_params.neuron_decoder = 'new_rand';

%% params specific to this particular data set
params.neuronIDs = train_data.neuronIDs;
params.n_neurons = size(params.neuronIDs,1);

%% fill up params with default values
if isfield(params,'adapt_params')
    % fill up the adapt_params substructure if present.
    params.adapt_params = adapt_params_defaults(params.adapt_params);
end

all_param_names = fieldnames(def_params);
for i=1:numel(all_param_names)
    if ~isfield(params,all_param_names(i))
        params.(all_param_names{i}) = def_params.(all_param_names{i});
    end
end

%% Run decoder training
%-------------------
neuron_decoder = run_decoder(params);
%-------------------
