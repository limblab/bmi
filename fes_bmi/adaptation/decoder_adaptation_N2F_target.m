function [data_buffer,data,neuron_decoder] = decoder_adaptation_N2F_target(params,data,bin_count,data_buffer,neuron_decoder)
% This version is for adaptation using time-varying EMG patterns, based on
% a predefined cursor trajectory


data.fix_decoder = params.adapt_params.adapt_freeze && mod(data.sys_time,params.adapt_params.adapt_time+params.adapt_params.fixed_time)>=params.adapt_params.adapt_time;

% if params.cursor_assist
%     data.adapt_trial = true; % adapt every trial during cursor assist
% end

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
            spikes      = data_buffer.spikes{trial};
            curs_preds  = data_buffer.curs_pred{trial};
            n_bins      = size(curs_preds,1);
            tgt_pos     = data_buffer.tgt_pos{trial};
            
            % force prediction error:
            df = tgt_pos-curs_preds;
              
            % look back at neurons
            g = zeros(size(neuron_decoder.H));
            for t = 1:n_bins
                g = g + [1 rowvec(spikes(t:(t+params.n_lag-1),:))']'*df(t,:);
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