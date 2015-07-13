% Function that makes a security check on the parameters for
% intracortically-controlled FES.


function params = check_bmi_fes_settings( neuron_decoder, params )


% check that everything in params.bmi_fes_stim_params is consistent
% size-wise

params_to_check             = {'muscles','anode_map','EMG_min','EMG_max','PW_min',...
                                'PW_max','amplitude_min','amplitude_max'};

nbr_muscles_bmi_fes         = zeros(1,length(params_to_check));

nbr_emgs_decoder            = size(neuron_decoder.H,2);
stim_anodes                 = find(~cellfun(@isempty,params.bmi_fes_stim_params.anode_map(1,:)));
nbr_stim_anodes             = length(stim_anodes);
nbr_perc_stim_per_anode     = length(find(~cellfun(@isempty,params.bmi_fes_stim_params.anode_map(2,:))));


% check that all the parameters listed in 'params_to_check' have the same
% number of muscles 
for i = 1:length(params_to_check)
    nbr_muscles_bmi_fes(i)  = length(getfield(params.bmi_fes_stim_params,params_to_check{i}));
%    nbr_muscles_bmi_fes(i)  = size(params.bmi_fes_stim_params.(all_param_names{params_to_check(i)}),2);
end

% the cathode can be empty (if we're using a common return)
if ~isempty(params.bmi_fes_stim_params.cathode_map{1})
    nbr_muscles_bmi_fes     = [nbr_muscles_bmi_fes, size(params.bmi_fes_stim_params.cathode_map,2)];
end

if numel(unique(nbr_muscles_bmi_fes)) > 1
    error('Some of the parameters in bmi_fes_stim_params do not have the right dimension')
end


% check that the nbr of decoded EMGs we have specified matches the number
% of muscles that we want to stimulate (non-empty muscles in the first row
% of 'anode_map') 
if nbr_emgs_decoder ~= nbr_stim_anodes
    error('The number of decoded EMGs does not match the number of stimulation anodes')
end

% check if we have specified for each anode the percentage of the current
% amplitude that will be delivered to each muscle (this is the second row
% of 'anode_map')
if nbr_stim_anodes ~= nbr_perc_stim_per_anode
    error('You have to specify how much current goes to each anode you are stimulating')
end

% check if the sum of the percetange of the current for each muscle's anode
% = 1 
for i = 1:nbr_stim_anodes
    if sum(params.bmi_fes_stim_params.anode_map{2,stim_anodes(i)}) ~= 1
       error('The sum of the percentages of current to each anode cannot be > 1');
    end
end


% Now redimension all of the fields with the muscles specified in the EMG
% decoder
pos_dec_muscles_in_fes_params           = zeros(1,nbr_emgs_decoder);
for i = 1:nbr_emgs_decoder
    pos_dec_muscles_in_fes_params(i)    = find( strncmp( params.bmi_fes_stim_params.muscles, ...
                                            params.neuron_decoder.outnames(i), length(params.neuron_decoder.outnames{i}) ) );
end

for i = 1:length(params_to_check)
    temp_field                          = params.bmi_fes_stim_params.(params_to_check{i});
    params.bmi_fes_stim_params.(params_to_check{i})     = temp_field(:,pos_dec_muscles_in_fes_params);
end

