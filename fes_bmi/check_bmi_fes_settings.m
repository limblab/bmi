% Function that makes a security check on the parameters for
% intracortically-controlled FES.


function params = check_bmi_fes_settings( neuron_decoder, params )


params_to_check             = {'muscles','anode_map','EMG_min','EMG_max','PW_min',...
                                'PW_max','amplitude_min','amplitude_max'};
                            
nbr_emgs_decoder            = size(neuron_decoder.H,2);
stim_anodes                 = find(~cellfun(@isempty,params.bmi_fes_stim_params.anode_map(1,:)));
nbr_stim_anodes             = size(stim_anodes,2);
nbr_perc_stim_per_anode     = length(find(~cellfun(@isempty,params.bmi_fes_stim_params.anode_map(2,:))));


% variable to store the number of muscles included in each of the
% "params_to_check"
nbr_muscles_bmi_fes_params  = zeros(1,length(params_to_check));


% -------------------------------------------------------------------------
% check that all the parameters listed in 'params_to_check' have the same
% number of muscles 
for i = 1:length(params_to_check)
    nbr_muscles_bmi_fes_params(i)   = length( params.bmi_fes_stim_params.(params_to_check{i}) );
end

% the cathode can be empty (if we're using a common return). If we are
% doing bipolar stimulation (cathode not empty), check that cathodes have
% the right number of muscles
if ~isempty(params.bmi_fes_stim_params.cathode_map{1})
    nbr_stim_cathodes               = size(params.bmi_fes_stim_params.cathode_map,2);
    nbr_muscles_bmi_fes_params      = [nbr_muscles_bmi_fes_params, nbr_stim_cathodes];

    % some stuff that will be used later
    nbr_perc_stim_per_cathode       = length(find(~cellfun(@isempty,params.bmi_fes_stim_params.cathode_map(2,:))));
    stim_cathodes                   = find(~cellfun(@isempty,params.bmi_fes_stim_params.cathode_map(1,:)));
end

if numel(unique(nbr_muscles_bmi_fes_params)) > 1
    error('Some of the parameters in bmi_fes_stim_params do not have the right dimension')
end


% -------------------------------------------------------------------------
% check that the nbr of decoded EMGs we have specified matches the number
% of muscles that we want to stimulate (non-empty muscles in the first row
% of 'anode_map') 
if nbr_emgs_decoder ~= nbr_stim_anodes
    error('The number of decoded EMGs does not match the number of stimulation anodes')
end


% -------------------------------------------------------------------------
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


% -------------------------------------------------------------------------
% check a number of things for the cathodes, if doing bipolar stimulation
if ~isempty(params.bmi_fes_stim_params.cathode_map{1})
    
    % check if we have specified the return for each electrode
    if stim_anodes ~= stim_cathodes
        error('The stimulation cathodes do not match the anodes');
    end
    
    % check that the number of cathodes matches the number of anodes
    if nbr_stim_cathodes ~= nbr_stim_anodes
        error('The number of stimulation cathodes does not match the anodes');
    end
    
    % check if we have specified for each anode the percentage of the
    % current amplitude that will be delivered to each muscle (this is the
    % second row of 'cathode_map')  
    if nbr_stim_cathodes ~= nbr_perc_stim_per_cathode
        error('You have to specify how much current goes to each cathode you are stimulating')
    end
    
    % check if the sum of the percetange of the current for each muscle's
    % cathode = 1  
    for i = 1:nbr_stim_cathodes
        if sum(params.bmi_fes_stim_params.cathode_map{2,stim_cathodes(i)}) ~= 1
           error('The sum of the percentages of current to each anode cannot be > 1');
        end
    end
end


% -------------------------------------------------------------------------
% check that the decoded muscles are in the EMG_to_stim_map
pos_dec_muscle_in_EMG_stim_map          = zeros(1,nbr_emgs_decoder);
for i = 1:nbr_emgs_decoder
    % store the position of the decoder muscles in EMG_to_stim_map, which
    % will be used for redimensioning all the fields in bmi_fes_stim_params
    pos_dec_muscle_in_EMG_stim_map(i)   = find( strncmp( params.neuron_decoder.outnames{i}, ...
            params.bmi_fes_stim_params.EMG_to_stim_map(1,:), length(params.neuron_decoder.outnames{i}) ) );
    % if a decoder muscle is missing in EMG_to_stim map, quit...
    if isempty( pos_dec_muscle_in_EMG_stim_map(i) )
        error(['Muscle ' params.neuron_decoder.outnames{i} ' not included in EMG_to_stim_map']);
    end
end

% -------------------------------------------------------------------------
% redimension all of the parameters in 'bmi_fes_stim_params', so they are
% only specified for those stimulation muscles in 'EMG_to_stim_map'
muscles_to_stim                         = params.bmi_fes_stim_params.EMG_to_stim_map(2,pos_dec_muscle_in_EMG_stim_map);
pos_muscles_to_stim                     = zeros(1,nbr_emgs_decoder);
for i = 1:nbr_emgs_decoder
    pos_muscles_to_stim(i)              = find( strncmp( muscles_to_stim{i}, params.bmi_fes_stim_params.muscles, length(muscles_to_stim{i}) ) );
end

for i = 1:length(params_to_check)
    temp_field                          = params.bmi_fes_stim_params.(params_to_check{i});
    params.bmi_fes_stim_params.(params_to_check{i})     = temp_field(:,pos_muscles_to_stim);
end

