function [previous_trials,data,neuron_decoder] = decoder_adaptation(params,data,bin_count,previous_trials,neuron_decoder,emg_decoder,predictions)

data.fix_decoder = params.adapt_freeze && mod(data.sys_time,params.adapt_time+params.fixed_time)>=params.adapt_time;

if params.cursor_assist
    data.adapt_trial = true; % adapt every trial during cursor assist
end

% adapt trial and within adapt window?
if data.adapt_trial && data.tgt_on && params.adapt && ~any(isnan(data.tgt_pos)) && ...
        (bin_count - data.tgt_bin)*params.binsize >= params.delay && ...
        (bin_count - data.tgt_bin)*params.binsize <= (params.delay+params.duration)
    adapt_bin = true;
else
    adapt_bin = false;
end

if adapt_bin
    % Save data for batch adapt
    previous_trials = [ dataset({bin_count, 'bin_count'}, ...
        {{data},'data'},...
        {data.tgt_id,'target_id'},...
        {predictions,'predictions'});...
        previous_trials(1:end-1,:)];
    if ~data.fix_decoder
        % gradient accumulator
        accum_g = zeros(size(neuron_decoder.H));
        accum_n = 0;
        for trial = 1:params.batch_length
            tmp_spikes = previous_trials.data{trial}.spikes;
            tmp_emgs = previous_trials.data{trial}.emgs;
            tmp_target_pos = previous_trials.data{trial}.tgt_pos;
            
            accum_g = backpropagation_through_time(neuron_decoder.H, emg_decoder.H, ...
                tmp_spikes, tmp_emgs, ...
                tmp_target_pos(:)', ...
                params.n_lag, params.n_lag_emg);
            
            %                         %??? temp: prevent divergence caused possibly by
            %                         %floating point error? divide by 0 ????
            %                         if any(any(accum_g))>100/params.LR
            %                             high_weights = find(accum_g>100/params.LR);
            %                             w   = num2str(accum_g(high_weights));
            %                             w_i = num2str(high_weights);
            %                             fprintf('super high weight(s) : %s\nDetected at indexes %s\n',w,w_i);
            %                             accum_g(abs(accum_g)>100/params.LR) = 0;
            %                         end
            
            % count how many gradients we have accumulated
            accum_n = accum_n + 1;
        end
        g = accum_g/accum_n;
        neuron_decoder.H = neuron_decoder.H - params.LR*g;
        adaptation_idx = adaptation_idx + 1;
    end
end