function [data_buffer,data,neuron_decoder] = decoder_adaptation2(params,data,bin_count,data_buffer,neuron_decoder,emg_decoder,force_pred)

data.fix_decoder = params.adapt_freeze && mod(data.sys_time,params.adapt_time+params.fixed_time)>=params.adapt_time;

% if params.cursor_assist
%     data.adapt_trial = true; % adapt every trial during cursor assist
% end

% adapt trial and within adapt window?
if data.adapt_trial && data.tgt_on && params.adapt && ~any(isnan(data.tgt_pos)) && ...
        (bin_count - data.tgt_bin)*params.binsize >= params.delay && ...
        (bin_count - data.tgt_bin)*params.binsize <= (params.delay+params.duration)
    
    % adaptation_period during an adaptation trial. Accumulate data
    if data.trial_count > data_buffer.trial_number{1}
        data.adapt_bin = true;
        
        % very beginning of adaptation period. Store data as new trial.
        data_buffer = [ dataset({{data.trial_count}, 'trial_number'}, ...
                        {{data.spikes} ,'spikes'},...
                        {{data.tgt_id} ,'tgt_id'},...
                        {{data.tgt_pos},'tgt_pos'},...
                        {{data.emgs}   ,'emg_pred'},...
                        {{force_pred}  ,'force_pred'});
                        data_buffer(1:end-1,:)];
    else
        % during adaptation period but not first bin
        % accumulate spikes and predictions from every bins
        data_buffer.spikes{1}    = [data.spikes(1,:); data_buffer.spikes{1}];
        data_buffer.tgt_id{1}    = [data.tgt_id     ; data_buffer.tgt_id{1}];
        data_buffer.tgt_pos{1}   = [data.tgt_pos    ; data_buffer.tgt_pos{1}];
        data_buffer.emg_pred{1}  = [data.emgs       ; data_buffer.emg_pred{1}];
        data_buffer.force_pred{1}= [force_pred      ; data_buffer.force_pred{1}];
    end
        
end

if data.adapt_flag
    data.adapt_flag = false;
    if ~data.fix_decoder % && any(max(data_buffer.tgt_id{1}) == [1 5])
        % gradient accumulator
        accum_g = zeros(size(neuron_decoder.H));
        accum_n = 0;
        
        for trial = 1:params.batch_length
            spikes   = data_buffer.spikes{trial};
            emgs     = data_buffer.emg_pred{trial};
            tgt_pos  = data_buffer.tgt_pos{trial};
            n_bins   = size(emgs,1);
            
            %which EMGs would give me the expected force:
            TolX     = 1e-4; %function search tolerance for EMG
            TypicalX = 0.1*ones(size(emgs));
            TolFun   = 1e-4; %tolerance on cost function? not exactly sure what this should be
            
%             fmin_options = optimoptions('fminunc','GradObj','on','Display','none',...
%                 'TolX',TolX,'TolFun',TolFun,'TypicalX',TypicalX);
            fmin_options = optimoptions('fmincon','GradObj','on','Display','notify-detailed',...
                'TolX',TolX,'TolFun',TolFun,'TypicalX',TypicalX);            

%             %initial_emgs have to higher than 0 and lower than 1 cause
%             %gradient of the piecewise sigmoidal function is 0 there
%             tmp_emgs = emgs;
%             tmp_emgs(tmp_emgs<=TolX)    = tmp_emgs(tmp_emgs<=TolX) +TolX;
%             tmp_emgs(tmp_emgs>=1-TolX) = tmp_emgs(tmp_emgs>=1-TolX)-TolX;
              
            % emg bound:
            emg_min = zeros(size(emgs));
            emg_max = ones( size(emgs));
            
%             opt_emgs = fminunc(@(EMG) Force2EMG_costfun(EMG,tgt_pos(:,1),emg_decoder.H,params.lambda),tmp_emgs,fmin_options);
%             [opt_emgs,fval,exitflag] = fminbnd(@(EMG) Force2EMG_costfun(EMG,tgt_pos(:,1),emg_decoder.H,params.lambda),0,1);
            [opt_emgs,~,exitflag] = fmincon(@(EMG) Force2EMG_costfun(EMG,tgt_pos,emg_decoder.H,params.lambda),emgs,[],[],[],[],emg_min,emg_max,[],fmin_options);
            if ~exitflag
                warning('optimization failed');
                continue;
            end
            
            % replace negative values by 0
%             opt_emgs(opt_emgs<0) = zeros(size(opt_emgs(opt_emgs<0)));
            
%             h = figure; hold on;
%             plot(tgt_pos(:,1),'b');
%             plot(sigmoid(opt_emgs(:,1),'direct'),'c');
%             plot(-sigmoid(opt_emgs(:,2),'direct'),'g');
%             pause; close(h);

            % emg error:
            de = opt_emgs-emgs;
%             de = flip(max(de,0));
            
            % look back at neurons
            g = zeros(size(neuron_decoder.H));
            for t = 1:n_bins
                g = g + [1 rowvec(spikes(t:(t+params.n_lag-1),:))']'*de(t,:);
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
        neuron_decoder.H = neuron_decoder.H + params.LR*accum_g;
    end
    
end