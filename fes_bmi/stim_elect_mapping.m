% Function that converts stimulation commands to a string that can be
% passed to the Ripple stimulator. Stimulation commands are defined in
% 'stim_PW'/'stim_amp', dependending on whether we do PW-modulated or
% amplitudes-modulated FES, and 'bmi_fes_stim_params'.
%
% function cmd_combined = stim_elect_mapping( stim_PW, stim_amp, bmi_fes_stim_params )
%
%


function cmd_combined = stim_elect_mapping( stim_PW, stim_amp, bmi_fes_stim_params )


cmd_combined                    = []; % the command that will be passed to the stimulator


% local variables for the stimulation waveforms
clock_cycle                     = 1/30000;
step_length                     = 1/30000/32; % a single "delay," for the stim waveform, in ms

% convert the stim_PW to s
stim_PW_us                      = stim_PW/1000;



% For PW-modulated FES
if strcmp(bmi_fes_stim_params.mode,'PW_modulation')

    
    
    % ---------------------------------------------------------------------
    % For monopolar stimulation (cathode_map = {})

    if isempty(bmi_fes_stim_params.cathode_map)


        % Fill the stimulation command for every muscle we want to
        % stimulate...  
        
        muscles_to_stimulate    = find(stim_PW);
        

        for i = 1:length( muscles_to_stimulate )
            
            % Read which electrodes are connected to this muscle, and what
            % is the percentage of the stimulation that should go to each
            % of them
            
            elecs_this_muscle   = cell2mat(bmi_fes_stim_params.anode_map(1,muscles_to_stimulate(i)));
            perc_ampl_this_muscle   = cell2mat(bmi_fes_stim_params.anode_map(2,muscles_to_stimulate(i)));
            
            
            % And for each stimulator channel connected to this muscle...
            
            for ii = 1:numel( elecs_this_muscle )

                cmd_ptr         = 1; % Ptr to build the command sequence
                               
                % Retrieve stim amplitude for this channel
                ampl            = round( bmi_fes_stim_params.amplitude_max(muscles_to_stimulate(i)) * ...
                                    perc_ampl_this_muscle(ii) / bmi_fes_stim_params.stim_resolut ); 
                cmd             = struct('elec', elecs_this_muscle(ii), 'period', 1000, 'repeats', bmi_fes_stim_params.freq, 'action', 'curcyc' );
           
                
                % ------------------------------------------------------------
                % The cathodic phase of the pulse
                               
                % The stimulation command comprises: 1) a pulse of duration
                % multiple of the clock cycle (33.3 us) [in cmd.seq(1)], and 2)
                % a "delay component", which is the remaining desired pulse
                % width, in ~1.04 us steps [in cmd.seq(2)].
                               
                % Number of 33.3 us in the desired PW
                
                nbr_cath_steps      = floor( stim_PW_us( muscles_to_stimulate(i) ) / clock_cycle );
                
                if nbr_cath_steps > 0
                
                    cmd.seq(cmd_ptr) = struct('length', nbr_cath_steps, ...
                                        'ampl', ampl, ...
                                        'pol', 0, ...
                                        'fs', 0, ...
                                        'enable', 1, ...
                                        'delay', 0, ...
                                        'ampSelect', 1); % ToDo: double check 'ampSelect'
                    
                    cmd_ptr         = cmd_ptr + 1;                
                end
                                    
                % Number of 1.04 us steps in the remaining of the desired PW
                % and the 33.3 us steps
                
                rem_cath_step       = rem( stim_PW_us(muscles_to_stimulate(i)), clock_cycle );
                delay_rem_cath_step = floor( rem_cath_step / step_length );
                
                if delay_rem_cath_step > 0
                    
                    cmd.seq(cmd_ptr) = struct('length', 1, ...
                                        'ampl', ampl, ...
                                        'pol', 0, ...
                                        'fs', 0, ...
                                        'enable', 0, ...
                                        'delay', delay_rem_cath_step, ...
                                        'ampSelect', 1);
                     
                    cmd_ptr         = cmd_ptr + 1;                
                end
                                   
                
                % ------------------------------------------------------------
                % The inter-phase interval
                
                % Consider the inter-phase interval after the cathodic
                % interval, which is already included in the previous command
                
                if delay_rem_cath_step ~= 0
                    ipi_post_cathodic   = clock_cycle - delay_rem_cath_step * step_length;
                else
                    ipi_post_cathodic   = 0;
                end
                
                % Number of 33.3 us steps in the desired inter-phase interval
                
                nbr_ipi_steps       = floor ( (bmi_fes_stim_params.inter_ph_int - ipi_post_cathodic) / clock_cycle);
                
                if nbr_ipi_steps > 0
                    
                    cmd.seq(cmd_ptr) = struct('length', nbr_ipi_steps, ...
                                        'ampl', 0, ...
                                        'pol', 0, ...
                                        'fs', 0, ...
                                        'enable', 0, ...
                                        'delay', 0, ...
                                        'ampSelect', 1);
                                                         
                    cmd_ptr         = cmd_ptr + 1;                
                end

                % Number of 1.04 us steps in the remaining of the desired
                % inter-phase interval and the 33.3 us steps
                
                rem_ipi             = rem( (bmi_fes_stim_params.inter_ph_int - ipi_post_cathodic), clock_cycle );
                delay_rem_ipi       = floor( rem_ipi / step_length );
                
                % Note that the command to complete the desired inter-phase
                % interval already includes some of the cathodic phase
                
                if delay_rem_ipi > 0
                
                    cmd.seq(cmd_ptr) = struct('length', 1, ...
                                        'ampl', ampl, ...
                                        'pol', 1, ...
                                        'fs', 0, ...
                                        'enable', 1, ...
                                        'delay', delay_rem_ipi, ...
                                        'ampSelect', 1);
                                                         
                    cmd_ptr         = cmd_ptr + 1;                
                end

                
                % ------------------------------------------------------------
                % The anodic phase of the pulse
                
                % Consider the part of the cathodic phase included in the
                % previous command
                
                if delay_rem_ipi ~= 0
                    anod_post_ipi   = clock_cycle - delay_rem_ipi * step_length;
                else
                    anod_post_ipi   = 0;
                end
                
                % Number of 33.3 us steps in the desired PW
                
                nbr_anod_steps      = floor( (stim_PW_us( muscles_to_stimulate(i) ) - anod_post_ipi) / clock_cycle );
                
                if nbr_anod_steps > 0
                    
                    cmd.seq(cmd_ptr) = struct('length', nbr_anod_steps, ...
                                        'ampl', ampl, ...
                                        'pol', 1, ...
                                        'fs', 0, ...
                                        'enable', 1, ...
                                        'delay', 0, ...
                                        'ampSelect', 1);
                                                         
                    cmd_ptr         = cmd_ptr + 1;                
                end
                
                % Number of 1.04 us steps in the remaining of the desired PW
                % and the 33.3 us steps
                
                rem_anod_step       = rem( (stim_PW_us( muscles_to_stimulate(i) ) - anod_post_ipi), clock_cycle );
                delay_rem_anod_step = floor( rem_anod_step / step_length );
                
                if delay_rem_anod_step > 0
                
                    
                    % ToDo: delete from here this temporary code
                    
                    % Double check if there's a mistmatch between the
                    % duration of the cathodic and anodic phases because of
                    % the rounding. If there's correct it!!
                    
                    duration_cath   = nbr_cath_steps * clock_cycle + ...
                                        delay_rem_cath_step * step_length;
                    
                    if delay_rem_ipi > 0
                                    
                        duration_anod = ( clock_cycle - delay_rem_ipi * step_length ) + ...
                                        nbr_anod_steps * clock_cycle + delay_rem_anod_step * step_length;
                    else
                        duration_anod = nbr_anod_steps * clock_cycle + delay_rem_anod_step * step_length;
                    end

                    if ( duration_anod - duration_cath ) > step_length/10
                       
                        disp(['(duration cathodic phase - duration anodic phase) > step_length/10  : ' ...
                            num2str(duration_anod - duration_cath)])
                        
                    end
                                    
                    % ToDo: delete until here this temporary code
                    
                    cmd.seq(cmd_ptr) = struct('length', 1, ...
                                        'ampl', ampl, ...
                                        'pol', 1, ...
                                        'fs', 0, ...
                                        'enable', 0, ...
                                        'delay', delay_rem_anod_step, ...
                                        'ampSelect', 1);
                                                         
                    cmd_ptr         = cmd_ptr + 1;                
                end                
                
                % There will be a 33.3 us - delay_rem_anod_step without
                % stimulation at the end, but it is negligible when compared to
                % the stimulation frequencies we are going to use

                
                % Concatenate the command
                cmd_combined        = cat(2,cmd_combined,cmd);

            end
        end
    
        
	% ---------------------------------------------------------------------
    % For bipolar stimulation (cathode_map has the return electrodes)

    else  
    end

    
elseif strcmp(bmi_fes_stim_params.mode,'amplitude_modulation')
end


end