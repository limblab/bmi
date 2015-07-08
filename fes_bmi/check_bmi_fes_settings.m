% Function that makes a security check on the parameters for
% intracortically-controlled FES

function check_bmi_fes_settings( neuron_decoder, params )


% check that everything in params.bmi_fes_stim_params is consistent
% size-wise

params_to_check             = [1:3 6:10];
nbr_muscles_bmi_fes         = zeros(1,length(params_to_check));

all_param_names             = fieldnames(params.bmi_fes_stim_params);

for i = 1:length(params_to_check)
    nbr_muscles_bmi_fes(i)  = size(params.bmi_fes_stim_params.(all_param_names{params_to_check(i)}),2);
end

if size(params.bmi_fes_stim_params.cathode_map,2) > 0
    nbr_muscles_bmi_fes     = [nbr_muscles_bmi_fes, size(params.bmi_fes_stim_params.cathode_map,2)];
end

if numel(unique(nbr_muscles_bmi_fes)) > 1
    error('Some of the parameters in bmi_fes_stim_params do not have the right dimension')
end


% check that we nbr of decoded EMGs we have specified match the 
nbr_emgs_decoder            = size(neuron_decoder.H,2);

if nbr_emgs_decoder ~= unique(nbr_muscles_bmi_fes)
    warning('the number of decoded EMGs does not match bmi_fes_stim_params')
end
