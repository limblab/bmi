function fes_params = fes_params_defaults(varargin)
% fes_params = fes_params_defaults(varargin)
% 
% function to prepare all of the parameters to run real-time FES using the 
% "realtime_Wrapper" function. Without inputs, the function just spits out
% the default parameter structure. If an input is a struct, it populates
% any unfilled parameters with the default values. If inputs are name/value
% pairs, it will populate a structure with the inputs and fill the rest of
% the structure with the defaults.
%
% This function is a cleaned up version of "bmi_params_defaults", which was
% used with "runBMIFES". I removed unused parameters and added flags to
% differentiate between Cerebus and Plexon
%
% Edited 2018/02/01 KLB
%
% -- settings [defaults]--
%   'sigmoid'       : flag to decide whether or not to apply a sigmoid to
%                       emg preds [false]
%   'output'        : either 'stimulator' or 'none' [stimulator] (not
%                       implemented)
%   'online'        : chose between online(true) or offline(false) [true]
%   'offline_data'  : binnedData file to be replayed (when 'online'=false)
%                       [NaN]
%   'hp_rc'         : high-pass filter time constant in seconds (0 = no filtering of preds)
%   'pred_bounds'   : upper_bound for predictions in Hz [300]
%
%   'fes_stim_params'   : structure containing emg-to-stim parameters and electrode to muscle mapping
%   'decoder'       : structure containing decoder or .mat file
%   'neuronIDs'     : Array of n_neurons x 2, containing (ch_id, unit_id);
%   'n_lag'         : Number of lags to use [10]
%   'binsize'       : Cycle time for decoder in seconds. Has to match binsize in
%                       decoders [.05]
%
%   'display_plots' : Plot adaptation procedure [true]
%   'save_dir'      : directory for saving data ['.']
%   'save_name'     : prefix for saving files names [date and start time]
%
%   'cort_source'   : 'Plexon' or 'Blackrock' [Blackrock]
%
%   'meta'          : Structure with metadata. Can be supplemented 
%        'Animal'   : 'Rat' or 'Monkey' [Monkey]
%        'Name'     : Animal's name
%        'Lab'      : Lab where recording was performed ['Lab1']
%        'Computer' : Computer name where recorded (Stored Automatically)


fes_params_defaults = struct(...
    'sigmoid',          false,...
    'output',           'stimulator',...
    'offline_data',     NaN,...
    'hp_rc',            0,...
    'pred_bounds',      300,...
    'fes_stim_params',      fes_stim_params_defaults,...
    'decoder',          NaN,...
    'neuronIDs',        [[1:96]',zeros(96,1)],...
    'n_lag',            10,...
    'binsize',          .05,...
    'display_plots',    true,...
    'save_dir',         '.',...
    'save_name',        datestr(now,'yyyymmmdd_HHMM'),...
    'cort_source',      'Blackrock',...
    'meta',             struct('Animal','Monkey','Name','Jango',...
                            'Lab','Lab1','Computer',getenv('ComputerName')));

% change how we run through through the input variables
switch nargin
    case 0
        fes_params = struct; % gimme something empty so we don't throw an error later on
    case 1
        fes_params = varargin{1};
    otherwise
        if mod(nargin,2) ~= 0 % if there are an uneven number of name/value pairs
            error('Wrong number of inputs')
        else        % name/value pairs
            flds = varargin(1:2:end-1); % list of names
            vals = varargin(2:2:end);   % list of values
            fes_params = struct;
            for ii = 1:numel(flds) 
                fes_params.(flds{ii}) = vals{ii}; % load into a struct, so the loading routine's consistent
            end
        end
end

flds = fieldnames(fes_params);
for ii = 1:numel(flds) % check and load entered parameters
    switch flds{ii} % checking validity of entered parameters
        case 'sigmoid'
            if ~islogical(fes_params.sigmoid)
                error('sigmoid value must be true or false')
            end
        case 'output'
            if ~(strcmpi(fes_params.output,'stimulator')|strcmpi(fes_params.output,'none'))
                error('output value must be either ''stimulator'' or ''none''')
            end
        case 'offline_data'
            if ~isnan(fes_params.offline_data)
                error('offline_data hasn''t been implemented yet')
            end
        case 'hp_rc'
            if fes_params.hp_rc ~= 0
                error('hp_rc hasn''t been implemented yet')
            end
        case 'pred_bounds'
            if (fes_params.pred_bounds < 0) | ~isnumeric(fes_params.pred_bounds)
                error('pred_bounds must be a number greater than 0')
            end
        case 'fes_stim_params'
            fes_params.fes_stim_params = fes_stim_params_defaults(fes_params.stim_params); % load into struct, throw error as necessary
        case 'decoder'
            fes_params.neuron_decoder = plexon_Build_Model(fes_params.neuron_decoder); % load into struct, throw error as necessary
        case 'neuronIDs'
            if size(fes_params.neuronIDs,2) ~= 2 % this should throw an error if neuronIDs isn't a number
                error('neuronIDs needs to have electrode and unit labels for each channel')
            end
        case 'binsize'
            if numel(fes_params.binsize) ~= 1
                error('binsize needs to be a scalar')
            end
            if fes_params.binsize>1
                warning('Binsize is over 1, so I''m assuming you entered it in ms. Switching to seconds')
                fes_params.binsize = fes_params.binsize/1000;
            end
        case 'n_lag'
            if numel(fes_params.n_lag) ~= 1
                error('n_lag needs to be a scalar')
            end
        case 'display_plots'
            if ~islogical(fes_params.display_plots)
                error('display_plots needs to be either true or false')
            end
        case 'save_dir'
            if ~ischar(fes_params.save_dir)
                error('save_dir needs to be a directory location -- AKA a string!')
            end
        case 'save_name'
            if ~ischar(fes_params.save_name)
                error('save_name needs to be a file name')
            end
        case 'cort_source'
            if ~(strcmpi(fes_params.cort_source,'blackrock') || strcmpi(fes_params.cort_source,'plexon'))
                error('cort_source needs to either be ''Blackrock'' or ''Plexon''')
            end
        case 'meta'
            if ~isstruct(fes_params.meta)
                error('the ''meta'' field needs to be a struct')
            end
            fes_params.meta.Computer = getenv('ComputerName');
    end
    fes_params_defaults.(flds{ii}) = fes_params.(flds{ii});
end

% force the user to create a neuron decoder
if isnan(fes_params_defaults.decoder)
    decoder_params = struct('binSize',fes_params_defaults.binsize,...
        'filLen',fes_params_defaults.binsize*fes_params_defaults.n_lag,...
        'polynomial',false,...
        'chans',fes_params_defaults.neuronIDs);
    fes_params_defaults.decoder = plexon_Build_Model(decoder_params); % setup the decoder
end

fes_params = fes_params_defaults; % load into the output structure


end