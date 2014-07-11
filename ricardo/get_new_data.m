function data = get_new_data(params,data,offline_data,bin_count,bin_dur,w,xpc)
    if params.online
        % read and flush data buffer
%         ts_cell_array = cbmex('trialdata',1);
        [ts_cell_array, time, continuous_cell_array] = cbmex('trialdata', 1);
        data.sys_time = cbmex('time');
        new_spikes = get_new_spikes(ts_cell_array,params,bin_dur);
        [new_words,new_target,data.db_buf] = get_new_words(ts_cell_array{151,2:3},data.db_buf);
        analog_fs = max([continuous_cell_array{:,2}]);
        new_analog = get_new_analog(continuous_cell_array);       
        data.analog_channels = [continuous_cell_array{:,1}]';
        new_xpc_data = get_new_xpc_data(xpc);
        
        % Let's do the force stuff now (get force data)
        % From 'calc_from_raw.m', "elseif opts.rothandle" section:
        analog_data = continuous_cell_array;
        %           label_idcs = strncmp(ts_cell_array(:,1),'ForceHandle',11);
        analog_data(:,1) = ts_cell_array([continuous_cell_array{:,1}]',1); % replace channel numbers with names
        handleforce = analog_data(strncmp(analog_data(:,1), 'ForceHandle', 11),3); % only take force data - "ForceHandle[1-6]", not EMGs        
%         force(:,1) = temp(:,1).*cos(-th_2_adj)' - temp(:,2).*sin(th_2_adj)';
%         force(:,2) = temp(:,1).*sin(th_2_adj)' + temp(:,2).*cos(th_2_adj)';
        % Pass only mean force value for period: each cell of
        % 'handleforce' should be a 1-D array of force values, so take
        % mean of each
        data.handleforce = cell2mat(cellfun(@mean, handleforce, 'uni', 0));
        data.handleforce = (data.handleforce' - params.force_offsets)*params.fhcal*params.rotcal;
        data.handleforce = [data.handleforce(1)*cos(2*pi-new_xpc_data.theta(2)) - data.handleforce(2)*sin(2*pi-new_xpc_data.theta(2)) ...
            data.handleforce(1)*sin(2*pi-new_xpc_data.theta(2)) + data.handleforce(2)*cos(2*pi-new_xpc_data.theta(2))];
        
        data.force_xpc = new_xpc_data.Force;
%         if isnan(new_xpc_data.Force)
%             pause
%         end
    else
        data.sys_time = double(offline_data.timeframe(bin_count));
        new_spikes = offline_data.spikeratedata(bin_count,:)';
        new_words  = offline_data.words(offline_data.words(:,1)>= data.sys_time & ...
            offline_data.words(:,1) < data.sys_time+params.binsize,:);
        new_target = offline_data.targets.corners(offline_data.targets.corners(:,1)>= data.sys_time & ...
            offline_data.targets.corners(:,1)< data.sys_time+params.binsize,2:end);
        new_analog = [];
        analog_fs = 1;
        data.analog_channels = [];
    end

    data.spikes = [new_spikes'; data.spikes(1:end-1,:)];
    num_new_words = size(new_words,1);
    data.words  = [new_words;     data.words(1:end-num_new_words,:)];
    data.analog = new_analog;
%     data.analog = [new_analog; data.analog(1:end-1,:)];    
%     
%     if size(data.analog,1)>analog_fs*3
%         data.analog = data.analog(1:analog_fs*3,:);
%     end

    if ~isempty(new_target)
        data.pending_tgt_pos  = [ (new_target(3)+new_target(1))/2 ...
            (new_target(4)+new_target(2))/2 ];
        data.pending_tgt_size = [   new_target(3)-new_target(1) ...
            new_target(2)-new_target(4) ];
        %                 fprintf('tgt from db: %d\n',get_tgt_id(new_target(2:end)));
    end

    if ~isempty(new_words)
        for i=1:size(new_words,1)
            % new word Start
            if new_words(i,2) == w.Start
                data.traj_pct = 0;
                data.tgt_id   = nan;
            end
            
            % new word Ot_On?
            if bitand(hex2dec('F0'),new_words(i,2))==w.OT_On
                data.tgt_id   = bitand(hex2dec('0F'),new_words(i,2))+1;
                data.tgt_ts   = new_words(i,1);
%                 data.tgt_pos  = data.pending_tgt_pos;
%                 data.tgt_size = data.pending_tgt_size;
                [data.tgt_pos,data.tgt_size] = get_default_tgt_pos_size(data.tgt_id);
                data.tgt_bin  = bin_count;
                data.tgt_on   = true;
                data.pending_tgt_pos = [NaN NaN];
                data.pending_tgt_size= [NaN NaN];
                % fprintf('OT_on : %d\n',new_tgt_id);
            end
            % new word CT_ON?
            if new_words(i,2) == w.CT_On
                data.tgt_id   = 0;
                data.tgt_ts   = new_words(i,1);
%                 data.tgt_pos  = [0 0];
%                 data.tgt_size = CT_size;
                [data.tgt_pos,data.tgt_size] = get_default_tgt_pos_size(data.tgt_id);
                data.tgt_bin  = bin_count;
                data.tgt_on   = true;
                % fprintf('CT_on\n');
            end
            % Adapt word
            if new_words(i,2)==w.Adapt || ~params.online
                data.adapt_trial = true;
                % fprintf('Adapt Trial\n');
            end
            if new_words(i,2) == w.Catch
                %catch_flag?
            end
            % End trial
            if w.IsEndWord(new_words(i,2))
                data.adapt_trial = false;
                data.tgt_on      = false;
                data.effort_flag = false;
            end
        end
    end
end                
function new_spikes = get_new_spikes(ts_cell_array,params,binsize)

%     new_spikes = zeros(n_neurons,1);

    %firing rate for new spikes
%     for i = 1:n_neurons
%         new_spikes(i) = length(ts_cell_array{i,2})/binsize;
%     end

%     new_spikes = cellfun(@length,ts_cell_array(1:params.n_neurons,2))/binsize;
    if ~isempty(strfind(ts_cell_array(:,1),'elec'))
        [~,elec_map_idx,data_idx] = intersect(params.elec_map(:,4),ts_cell_array(:,1));
        chan_names = arrayfun(@(i) ['chan' num2str(params.elec_map{i,3})],1:size(params.elec_map,1),'UniformOutput',false);        
        ts_cell_array(data_idx,1) = chan_names(elec_map_idx)';
    end
    
    if isfield(params,'neuron_decoder')
        if ~isempty(params.neuron_decoder.H)
            new_spikes = zeros(size(params.neuron_decoder.neuronIDs,1),1);
            for iNeuron = 1:size(params.neuron_decoder.neuronIDs,1)
        %         ts_row_idx = find((strcmp(ts_cell_array(:,1),['elec' num2str(params.neuron_decoder.neuronIDs(iNeuron,1))])));
                ts_col_idx = params.neuron_decoder.neuronIDs(iNeuron,2)+2; 
                new_spikes(iNeuron) = length(ts_cell_array{(strcmp(ts_cell_array(:,1),['chan' num2str(params.neuron_decoder.neuronIDs(iNeuron,1))])),...
                    ts_col_idx})/binsize;
                if params.neuron_decoder.neuronIDs(iNeuron,2) == 0
                    new_spikes(iNeuron) = 0;
                end
            end
        else
            new_spikes = zeros(0,1);
        end
    else
        new_spikes = zeros(0,1);
    end
    %remove artifact (80% of neurons have spikes for this bin)
%     while (length(nonzeros(new_spikes))>.8*length(unique(params.neuron_decoder.neuronIDs(:,1))))
%         warning('artifact detected, spikes removed');
%         new_spikes(new_spikes>0) = new_spikes(new_spikes>0) - 1/binsize;
%     end
    
    % remove artifacts (high freq thresh x-ing)
    % by capping FR at 400 Hz
    if any(new_spikes>400)
        new_spikes(new_spikes>400) = 400;
        warning('noise detected, FR capped at 400 Hz');
    end
end
function [new_words, new_target, db_buf] = get_new_words(new_ts,new_words,db_buf)
    if ~isempty(new_ts)
        all_words = [new_ts, uint32(bitshift(bitand(hex2dec('FF00'),new_words),-8))];
        all_words = all_words(logical(all_words(:,2)),:);

        min_db_val = hex2dec('F0');
        max_db_val = hex2dec('FF');
        
        % behavior words:
        new_words = double(all_words( all_words(:,2) < min_db_val, :));

%         % databursts:
          new_db = [];
          new_target = [];
%         new_db = all_words( all_words(:,2) >= min_db_val & all_words(:,2) <= max_db_val, :);
% 
%         if isempty(new_db)
%             %no databurst this time
%             if ~isempty(db_buf)
%                 % we should have received more bytes
%                 warning('missing databurst bytes, databurst info discarded');
%             end
%             new_target = [];
%             db_buf = [];
%         else
%             try
%                 if ~isempty(db_buf)
%                     % continue filling databurst buffer started previous bin
%                     num_bytes = (db_buf(1,2) - min_db_val) + 16*(db_buf(2,2) - min_db_val);
%                 else
%                     num_bytes = (new_db(1,2) - min_db_val) + 16*(new_db(2,2) - min_db_val);
%                 end
% 
% 
%                 db_buf = [db_buf; new_db];
% 
%                 if size(db_buf,1) >= num_bytes*2
%                     if size(db_buf,1)>num_bytes*2
%                         fprintf('extra bytes in databurst (%d out of %d)\n',size(db_buf,1),num_bytes*2);
%                     end
%                     % we have the whole data burst, process and flush.
%                     raw_bytes  = db_buf(1:num_bytes*2, 2);
%                     half_bytes = reshape(raw_bytes,2,[]) - min_db_val;
%                     databurst  = double(16*half_bytes(2,:) + half_bytes(1,:));
%                     new_target = bytes2float(databurst(num_bytes-15:end))';
%                     db_buf = [];
%                 else
%                     % partial databurst, wait for next bin for rest of databurst
%                     new_target = [];
%                 end
%             catch e
%                 warning('error reading databurst, no target info extracted');
%                 new_target = [NaN NaN NaN NaN];
%                 db_buf = [];
%             end
%         end
    else
        if ~isempty(db_buf)
            % we should have received more bytes
            warning('missing databurst bytes, databurst info discarded');
        end
        new_target = [];
        db_buf = [];
    end
end
function [tgt_pos,tgt_size] = get_default_tgt_pos_size(tgt_id)
    tgt_size = [3 3];
    def_tgt_pos  = [ 0      0;...
                     8      0;... 
                     5.66   5.66;...
                     0      8;...
                     -5.66  5.66;...
                     -8     0;...
                     -5.66  -5.66;...
                     0      -8;...
                     5.66   -5.66];
      tgt_pos = def_tgt_pos(tgt_id+1,:);
end
function new_analog = get_new_analog(continuous_cell_array)      
   cellsz = cellfun(@size,continuous_cell_array(:,3),'uni',false);
   cellsz = [cellsz{:}];
   cellsz = cellsz(1:2:end);
   max_cellsz = max(cellsz);
   new_analog = nan(max_cellsz,size(continuous_cell_array,1));
   
%    Upsample analog data to highest sampling rate
   for iChan = 1:size(continuous_cell_array,1)
       if cellsz(iChan)==max_cellsz
           new_analog(:,iChan) = double(continuous_cell_array{iChan,3});
       else
           new_analog(:,iChan) = resample(double(continuous_cell_array{iChan,3}),max_cellsz,cellsz(iChan));
       end
   end 
end
function new_xpc_data = get_new_xpc_data(xpc)
    fopen(xpc.xpc_read);
    xpc_data = fread(xpc.xpc_read);
    fclose(xpc.xpc_read);

    if length(xpc_data)>=72
        new_xpc_data.Force = [typecast(uint8(xpc_data(41:48)),'double') typecast(uint8(xpc_data(49:56)),'double')];
        new_xpc_data.theta = [typecast(uint8(xpc_data(57:64)),'double') typecast(uint8(xpc_data(65:72)),'double')];
    else
        new_xpc_data.Force = nan(1,2);
        new_xpc_data.theta = nan(1,2);
        disp('No udp data read')
    end
end