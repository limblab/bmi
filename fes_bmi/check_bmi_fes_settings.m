% Function that makes a security check on the parameters for
% intracortically-controlled FES.


function params = check_bmi_fes_settings( neuron_decoder, params )


params_to_check             = {'muscles','anode_map','EMG_min','EMG_max','PW_min',...
                                'PW_max','amplitude_min','amplitude_max'}; % parameters to check for consistency
                            
                            
nbr_emgs_decoder            = size(neuron_decoder.H,2);
stim_anodes                 = find(~cellfun(@isempty,params.bmi_fes_stim_params.anode_map(1,:)));
nbr_stim_anodes             = size(stim_anodes,2);
nbr_perc_stim_per_anode     = length(find(~cellfun(@isempty,params.bmi_fes_stim_params.anode_map(2,:))));


% to store the number of muscles included in each of the "params_to_check"
nbr_muscles_bmi_fes_params  = zeros(1,length(params_to_check));


% -------------------------------------------------------------------------
% 1. check that all parameters in 'params_to_check' have the same number of
% muscles  

for i = 1:length(params_to_check)
    nbr_muscles_bmi_fes_params(i) = length( params.bmi_fes_stim_params.(params_to_check{i}) );
end

% * If doing bipolar stim (cathode not empty), check that cathodes has the
% same number of muscles as anodes 
%   -- The cathode can be empty (when doing monopolar stim). 
if ~isempty(params.bmi_fes_stim_params.cathode_map{1})
    
    % add the nbr of muscles to the list of number of muscles for all vars
    nbr_muscles_bmi_fes_params  = [nbr_muscles_bmi_fes_params, size(params.bmi_fes_stim_params.cathode_map,2)];

    stim_cathodes               = find(~cellfun(@isempty,params.bmi_fes_stim_params.cathode_map(1,:)));
    nbr_stim_cathodes           = size(stim_cathodes,2);
    nbr_perc_stim_per_cathode   = length(find(~cellfun(@isempty,params.bmi_fes_stim_params.cathode_map(2,:))));
    
    params_to_check{numel(params_to_check)+1}   = 'cathode_map';
end

% * the check itself
if numel(unique(nbr_muscles_bmi_fes_params)) > 1
    error('Some of the parameters in bmi_fes_stim_params do not have the right dimension')
end


% -------------------------------------------------------------------------
% 2. checks for the EMG decoder

% * check that the specified nbr of decoded EMGs matches the number of
% muscles that want to be stimulated (non-empty muscles in the first row of
% 'anode_map')   
if nbr_emgs_decoder ~= nbr_stim_anodes
    error('The number of decoded EMGs does not match the number of stimulation anodes')
end

% * check that the decoded muscles are in the EMG_to_stim_map
pos_dec_muscle_in_EMG_stim_map      = zeros(1,nbr_emgs_decoder);
for i = 1:nbr_emgs_decoder
    % don't look at EMGs with label length longer than the label
    % you are looking for because it can give an error (e.g., if
    % you are looking for the position of FCR and there is an FCRl
    % and an FCR matlab will try to return two values)
    indx_2_look = [];
    for ii = 1:length(params.bmi_fes_stim_params.EMG_to_stim_map(1,:))
        if length(params.bmi_fes_stim_params.EMG_to_stim_map{1,ii}) ...
                == length(params.neuron_decoder.outnames{i});
            indx_2_look = [indx_2_look, ii];
        end
    end
    % store the position of the decoder muscles in EMG_to_stim_map, which
    % will be used for redimensioning all the fields in bmi_fes_stim_params
    pos_dec_muscle_in_EMG_stim_map(i) = indx_2_look( find( strncmp( params.neuron_decoder.outnames{i}, ...
            params.bmi_fes_stim_params.EMG_to_stim_map(1,indx_2_look), length(params.neuron_decoder.outnames{i}) ) ) );
%     % if a decoder muscle is missing in EMG_to_stim map, quit...
%     if ~pos_dec_muscle_in_EMG_stim_map(i)
%         error(['Muscle ' params.neuron_decoder.outnames{i} ' not included in EMG_to_stim_map']);
%     end
end

% * check if the muscles to which we want to assign the predicted EMGs are
% available
for i = 1:numel(params.bmi_fes_stim_params.EMG_to_stim_map(2,:))
   if ~find( strcmpi(params.bmi_fes_stim_params.EMG_to_stim_map(2,i),params.bmi_fes_stim_params.muscles))
       error(['Muscle ' params.bmi_fes_stim_params.EMG_to_stim_map{2,i} ' not included in muscles']);
   end
end


% -------------------------------------------------------------------------
% 3. checks for the stimulation anodes 

% * check if we have specified for each anode the percentage of the current
% amplitude that will be delivered to each muscle (this is the second row
% of 'anode_map')
if nbr_stim_anodes ~= nbr_perc_stim_per_anode
    error('You have to specify how much current goes to each anode you are stimulating')
end

% * check if the sum of the percetange (0-1) of the current for each
% muscle's anodes == 1  
for i = 1:nbr_stim_anodes
    if sum(params.bmi_fes_stim_params.anode_map{2,stim_anodes(i)}) ~= 1
       error('The sum of the percentages of current to each anode cannot be > 1');
    end
end


% -------------------------------------------------------------------------
% 4. checks for the stimulation cathodes
%    -- if doing bipolar stim

if ~isempty(params.bmi_fes_stim_params.cathode_map{1})
    
    % * check if we have specified the return for each electrode
    if stim_anodes ~= stim_cathodes
        error('The stimulation cathodes do not match the anodes');
    end
    
    % * check that the nbr of cathodes matches the nbr of anodes
    if nbr_stim_cathodes ~= nbr_stim_anodes
        error('The number of stimulation cathodes does not match the anodes');
    end
    
    % * check if we have specified for each anode the percentage of the
    % current amplitude that will be delivered to each muscle (this is the
    % second row of 'cathode_map')  
    if nbr_stim_cathodes ~= nbr_perc_stim_per_cathode
        error('You have to specify how much current goes to each cathode you are stimulating')
    end
    
    % * check if the sum of the percetange of the current for each muscle's
    % cathodes == 1  
    for i = 1:nbr_stim_cathodes
        if sum(params.bmi_fes_stim_params.cathode_map{2,stim_cathodes(i)}) ~= 1
           error('The sum of the percentages of current to each anode cannot be > 1');
        end
    end
end


% -------------------------------------------------------------------------
% 5. redimension all of the parameters in 'bmi_fes_stim_params', so they
% are only specified for those stimulation muscles in 'EMG_to_stim_map' 

muscles_to_stim                 = params.bmi_fes_stim_params.EMG_to_stim_map(2,pos_dec_muscle_in_EMG_stim_map);
pos_muscles_to_stim             = zeros(1,nbr_emgs_decoder);

for i = 1:nbr_emgs_decoder
    pos_muscles_to_stim(i)      = find( strncmp( muscles_to_stim{i}, params.bmi_fes_stim_params.muscles, length(muscles_to_stim{i}) ) );
end

for i = 1:length(params_to_check)
    temp_field                  = params.bmi_fes_stim_params.(params_to_check{i});
    params.bmi_fes_stim_params.(params_to_check{i}) = temp_field(:,pos_muscles_to_stim);
end
