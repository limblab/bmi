function [data_buffer,data,neuron_decoder] = decoder_adaptation6(params,data,bin_count,data_buffer,neuron_decoder,emg_decoder)
% this version 6 adapts the neurons-to-emg decoder looking back at the data
% once per trial, and find the optimal EMG that would produce the force
% matching the actual cursor position at all time points. It is
% computationally expensive.

data.fix_decoder = params.adapt_params.adapt_freeze && mod(data.sys_time,params.adapt_params.adapt_time+params.adapt_params.fixed_time)>=params.adapt_params.adapt_time;

% adapt trial and within adapt window?
if data.adapt_trial && data.tgt_on && params.adapt && ~any(isnan(data.tgt_pos)) && ...
        (bin_count - data.tgt_bin)*params.binsize >= params.adapt_params.delay && ...
        (bin_count - data.tgt_bin)*params.binsize <= (params.adapt_params.delay+params.adapt_params.duration)
    
    % adaptation_period during an adaptation trial. Accumulate data
    if data.trial_count > data_buffer.trial_number{1}
        data.adapt_bin = true;
        
        % very beginning of adaptation period. Store data as new trial.
        data_buffer = [ dataset({{data.trial_count}, 'trial_number'}, ...
                        {{data.spikes}   ,'spikes'    },...
                        {{data.tgt_id}   ,'tgt_id'    },...
                        {{data.tgt_pos}  ,'tgt_pos'   },...
                        {{data.emgs}     ,'emg_pred'  },...
                        {{data.curs_pred},'curs_pred' },...
                        {{data.curs_act} ,'curs_act'  });...
                        data_buffer(1:end-1,:)];
    else
        % during adaptation period but not first bin
        % accumulate spikes and predictions from every bins
        data_buffer.spikes{1}   = [data.spikes(1,:); data_buffer.spikes{1}];
        data_buffer.tgt_id{1}   = [data.tgt_id     ; data_buffer.tgt_id{1}];
        data_buffer.tgt_pos{1}  = [data.tgt_pos    ; data_buffer.tgt_pos{1}];
        data_buffer.emg_pred{1} = [data.emgs       ; data_buffer.emg_pred{1}];
        data_buffer.curs_act{1} = [data.curs_act   ; data_buffer.curs_act{1}];
        data_buffer.curs_pred{1}= [data.curs_pred  ; data_buffer.curs_pred{1}];
    end
        
end

if data.adapt_flag
    data.adapt_flag = false;
    if ~data.fix_decoder % && any(max(data_buffer.tgt_id{1}) == [1 5])
        % gradient accumulator
        accum_g = zeros(size(neuron_decoder.H));
        accum_n = 0;
        
        for trial = 1:min(params.adapt_params.batch_length,data_buffer.trial_number{1})
            spikes   = data_buffer.spikes{trial};
            emgs     = data_buffer.emg_pred{trial};
            [n_bins, n_emgs] = size(emgs);
            curs_act = data_buffer.curs_act{trial};
            opt_emgs = emgs;
            tgt_id   = data_buffer.tgt_id{trial};
            
            %Optimization Parameters:
            TolX     = 1e-4; %function search tolerance for EMG
            TypicalX = 0.1*ones(1,n_emgs);
            TolFun   = 1e-4; %tolerance on cost function? not exactly sure what this should be
%             fmin_options = optimoptions('fmincon','GradObj','on','Display','notify-detailed',...
%                                         'TolX',TolX,'TolFun',TolFun,'TypicalX',TypicalX);
            fmin_options = optimset('fmincon');
            fmin_options = optimset(fmin_options,'Algorithm','interior-point','GradObj','on','Display','notify-detailed',...
                                        'TolX',TolX,'TolFun',TolFun,'TypicalX',TypicalX,'FunValCheck','on');
                                    
            %emg bound:
            emg_min = zeros(1,n_emgs);
            emg_max = ones(1,n_emgs);
            
            % gradient
            g = zeros(size(neuron_decoder.H));
            
            % optimize one bin at a time.
            for t = 1:n_bins
                if ~tgt_id(t)
                    % center target
                    opt_emgs(t,:) = zeros(1,n_emgs);
                else
                    init_emg_val = opt_emgs(max(1,t-1),:);
                    [opt_emgs(t,:),~,exitflag] = fmincon(@(EMG) Force2EMG_costfun_sig(EMG,curs_act(t,:),params.emg_decoder,params.adapt_params.lambda),init_emg_val,[],[],[],[],emg_min,emg_max,[],fmin_options);
                    if ~exitflag
                        warning('optimization failed');
                        continue;
                    end
                end
                % emg error:
                de = opt_emgs(t,:)-emgs(t,:);
                
                % look back at neurons
                g = g + [1 rowvec(spikes(t:(t+params.n_lag-1),:))']'*de;
            end
            g = g/n_bins;

            % apply L2 regularization
             %g(2:end, :) = g(2:end, :) - lambda*S2EMG_w(2:end, :);
            % accumulate gradient
            accum_g = accum_g + g;
            accum_n = accum_n + 1;
        end
        % update neuron_decoder
        accum_g = accum_g/accum_n;
        neuron_decoder.H = neuron_decoder.H + params.adapt_params.LR*accum_g;
    end
    
end