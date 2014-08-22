function [previous_trials,data,neuron_decoder] = decoder_adaptation(params,data,bin_count,previous_trials,neuron_decoder,emg_decoder,predictions)

data.fix_decoder = params.adapt_freeze && mod(data.sys_time,params.adapt_time+params.fixed_time)>=params.adapt_time;

% if params.cursor_assist
%     data.adapt_trial = true; % adapt every trial during cursor assist
% end

% adapt trial and within adapt window?
if data.adapt_trial && data.tgt_on && params.adapt && ~any(isnan(data.tgt_pos)) && ...
        (bin_count - data.tgt_bin)*params.binsize >= params.delay && ...
        (bin_count - data.tgt_bin)*params.binsize <= (params.delay+params.duration)
    data.adapt_bin = true;
else
    data.adapt_bin = false;
end

if data.adapt_bin
    % Save data for batch adapt
    previous_trials = [ dataset({bin_count, 'bin_count'}, ...
        {{data},'data'},...
        {data.tgt_id,'target_id'},...
        {predictions,'predictions'});...
        previous_trials(1:end-1,:)];
    if ~data.fix_decoder
        %         % gradient accumulator
        %         accum_g = zeros(size(neuron_decoder.H));
        %         accum_n = 0;
        for trial = 1:params.batch_length
            tmp_spikes = previous_trials.data{trial}.spikes;
            emgs = previous_trials.data{trial}.emgs;
            tmp_target_pos = previous_trials.data{trial}.tgt_pos;
            %
            %             accum_g = backpropagation_through_time_sigmoid_EMG(neuron_decoder.H, emg_decoder.H, ...
            %                 tmp_spikes, tmp_emgs, ...
            %                 tmp_target_pos(:)', ...
            %                 params.n_lag, params.n_lag_emg, params.lambda);
            %
            %             % count how many gradients we have accumulated
            %             accum_n = accum_n + 1;
            %         end
            %         g = accum_g/accum_n;
            %         neuron_decoder.H = neuron_decoder.H - params.LR*g;
            %     end
            
            %which EMGs would give me this force:
            TolX     = 0.01; %function search tolerance for EMG
            TypicalX = 0.1*ones(size(emgs));
            TolFun   = TolX; %tolerance on cost function? not exactly sure what this should be
            
            fmin_options = optimoptions('fminunc','GradObj','on','Display','none',...
                'TolX',TolX,'TolFun',TolFun,'TypicalX',TypicalX);
            
            %initial_emgs have to higher than 0 and lower than 10
            low_idx = find(emgs<=TolX);
            hi_idx  = find(emgs>=(10-TolX));
            tmp_emgs = emgs;
            tmp_emgs(low_idx) = emgs(low_idx)+repmat(TolX,1,length(low_idx));
            tmp_emgs(hi_idx)  = emgs(hi_idx) -repmat(TolX,1,length(hi_idx) );
            
            [opt_emgs,fmin_val,exit_flag,fmin_output,final_grad] = ...
                fminunc(@(EMG) Force2EMG_costfun(EMG,tmp_target_pos(1),emg_decoder.H,params.lambda),tmp_emgs,fmin_options);
            
            % replace negative values by 0
            opt_emgs(opt_emgs<0) = zeros(size(opt_emgs(opt_emgs<0)));
            % emg error:
            de = opt_emgs-emgs;
            de = max(de,0);
            
            % feed back through inverse of N2E sigmoid
%             de = sigmoid(de,'inverse');
            
            % look back at neurons, apply learning rate and update weights:
            g = [1;rowvec(tmp_spikes)]*de;
            %g(2:end, :) = g(2:end, :) - lambda*S2EMG_w(2:end, :);
            neuron_decoder.H = neuron_decoder.H + params.LR*g;

        end
        
    end
    
end