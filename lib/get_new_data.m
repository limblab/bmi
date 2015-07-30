function data = get_new_data(params,data,offline_data,bin_count,bin_dur,w,xpc,m_data_2)
    if params.online
        % read and flush data buffer
        [ts_cell_array, data.sys_time, continuous_cell_array] = cbmex('trialdata', 1);
%         data.sys_time = cbmex('time');
        [new_spikes,data.artifact_found] = get_new_spikes(ts_cell_array,params,bin_dur);
        [new_words,new_target,data.db_buf] = get_new_words(ts_cell_array{151,2:3},data.db_buf);       
        new_analog = get_new_analog(continuous_cell_array);       
        data.analog_channels = [continuous_cell_array{:,1}]';
        new_xpc_data.Force = nan(1,2);
        new_xpc_data.theta = nan(1,2);
        
        % Let's do the force stuff now (get force data)
        % From 'calc_from_raw.m', "elseif opts.rothandle" section:
        analog_data = continuous_cell_array;
        analog_data(:,1) = ts_cell_array([continuous_cell_array{:,1}]',1); % replace channel numbers with names
        handleforce = analog_data(strncmp(analog_data(:,1), 'ForceHandle', 11),3); % only take force data - "ForceHandle[1-6]", not EMGs        

        % Pass only mean force value for period: each cell of
        % 'handleforce' should be a 1-D array of force values, so take
        % mean of each
        if ~isempty(handleforce)
            data.handleforce = cell2mat(cellfun(@mean, handleforce, 'uni', 0));
            data.handleforce = (data.handleforce' - params.force_offsets)*params.fhcal*params.rotcal;
            theta = m_data_2.Data.theta;
            data.handleforce = [data.handleforce(1)*cos(2*pi-theta(2)) - data.handleforce(2)*sin(2*pi-theta(2)) ...
                data.handleforce(1)*sin(2*pi-theta(2)) + data.handleforce(2)*cos(2*pi-theta(2))];
        else
            disp('No handle force data read')
        end            
        
        data.force_xpc = new_xpc_data.Force;   
    else
        data.sys_time = double(offline_data.timeframe(bin_count));
        new_spikes = offline_data.spikeratedata(bin_count,:)';
        new_words  = offline_data.words(offline_data.words(:,1)>= data.sys_time & ...
            offline_data.words(:,1) < data.sys_time+params.binsize,:);
        new_target = offline_data.targets.corners(offline_data.targets.corners(:,1)>= data.sys_time & ...
            offline_data.targets.corners(:,1)< data.sys_time+params.binsize,2:end);
        new_analog = [];        
        data.analog_channels = [];
    end
    
    if size(data.spikes,2)~=size(new_spikes,1)
        data.spikes = zeros(size(data.spikes,1),size(new_spikes,1));
    end

    data.spikes = [new_spikes'; data.spikes(1:end-1,:)];
    num_new_words = size(new_words,1);
    data.words  = [new_words;     data.words(1:end-num_new_words,:)];
    data.analog = new_analog;
    data = get_binned_emg(data,analog_data);

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
function [new_spikes,artifact_found] = get_new_spikes(ts_cell_array,params,binsize)

    if ~isempty(strfind(ts_cell_array(:,1),'elec'))
        % Assign channel numbers from map file to acquired data
        [~,elec_map_idx,spike_chan_idx] = intersect(params.elec_map(:,4),ts_cell_array(:,1));        
        ts_cell_array(spike_chan_idx,1) = params.spike_chan_names(elec_map_idx)';
        
        if params.artifact_removal
            % Artifact removal
            tic
            chan_id = [];
            unit_id = [];
            spike_time = [];
            for iUnit = 1:6
                num_spikes = cellfun(@numel,ts_cell_array(spike_chan_idx,iUnit+1));
                chan_id = [chan_id ; cell2mat(arrayfun(@repmat,spike_chan_idx,num_spikes,ones(size(spike_chan_idx,1),1),'UniformOutput',false))];
                unit_id = [unit_id ; repmat(iUnit-1,sum(num_spikes),1)];
                spike_time_temp = ts_cell_array(spike_chan_idx,iUnit+1);
                spike_time = [spike_time ; cell2mat(spike_time_temp(~cellfun(@isempty,spike_time_temp)))];
            end

            [spike_time,spike_order] = sort(spike_time);
            chan_id = chan_id(spike_order);
            unit_id = unit_id(spike_order);

            remove_spike_times = [];
            for iWindow = 1:params.artifact_removal_window*30000
                rounded_spike_times = params.artifact_removal_window*round((double(spike_time+iWindow-1)/30000)/params.artifact_removal_window);
                [spike_repeats,spike_time_bins] = hist(rounded_spike_times,unique(rounded_spike_times));
                remove_spike_times = [remove_spike_times; spike_time_bins(spike_repeats>params.artifact_removal_num_channels)];
            end

            remove_spike_times = unique(remove_spike_times);
            [~,spike_removal_idx] = ismember(rounded_spike_times,remove_spike_times);

    %         spike_removal_idx = unique(spike_removal_idx);
            chan_id(spike_removal_idx>0) = [];
            unit_id(spike_removal_idx>0) = [];
            spike_time(spike_removal_idx>0) = [];

            tic
            for iChan = 1:length(spike_chan_idx)
                for iUnit = 1:6
                    ts_cell_array{spike_chan_idx(iChan),iUnit+1} = spike_time(chan_id==spike_chan_idx(iChan) & unit_id==(iUnit-1));
                end
            end
        end
%         disp(['Removed: ' num2str(sum(spike_removal_idx>0)) '. Did not remove: ' num2str(length(spike_time)) ' in ' num2str(toc) ' s.'])
        
    end
    artifact_found = 0;
    if isfield(params,'current_decoder')
        if ~isempty(params.current_decoder.H)
            new_spikes = zeros(size(params.current_decoder.neuronIDs,1),1);
            for iNeuron = 1:size(params.current_decoder.neuronIDs,1)
                ts_col_idx = params.current_decoder.neuronIDs(iNeuron,2)+2; 
%                 try
                new_spikes(iNeuron) = length(ts_cell_array{(strcmp(ts_cell_array(:,1),params.current_decoder.chanIDs(iNeuron))),...
                    ts_col_idx})/binsize;
%                 catch
%                     keyboard
%                 end
                if params.current_decoder.neuronIDs(iNeuron,2) == 255
                    new_spikes(iNeuron) = 0;
                end
            end
            % remove artifact (80% of neurons have spikes for this bin)   
            if (length(nonzeros(new_spikes))>.8*length(unique(params.current_decoder.neuronIDs(:,1))))  
                iArt = 0;
                while (length(nonzeros(new_spikes))>.8*length(unique(params.current_decoder.neuronIDs(:,1))) && iArt<5) 
                    new_spikes(new_spikes>0) = new_spikes(new_spikes>0) - 1/binsize;
                    iArt = iArt+1;
                end
                if iArt==5
                    new_spikes(:) = 0;
                end
                warning([num2str(iArt) ' artifacts detected, spikes removed']);
                if iArt >= params.stop_task_if_x_artifacts
                    artifact_found = 1;
                end
            end

            % remove artifacts (high freq thresh x-ing)
            % by capping FR at 400 Hz
            if any(new_spikes>400)
                new_spikes(new_spikes>400) = 400;
                warning('noise detected, FR capped at 400 Hz');
            end
        else
            new_spikes = zeros(0,1);
        end
    else
        new_spikes = zeros(0,1);
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
    try
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
    catch
        tgt_size = [];
        tgt_pos = [];
    end
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
function data = get_binned_emg(data,analog_data)
    emg_chans = find(~cellfun(@isempty,cellfun(@strfind,analog_data(:,1),repmat({'EMG'},size(analog_data,1),1),'UniformOutput',false)));
    new_emg = cellfun(@mean,analog_data(emg_chans,3))';
    if size(new_emg,2)~=size(data.emg_binned,2)
        data.emg_binned = zeros(10,size(new_emg,2));
    end
    data.emg_binned = [new_emg ; data.emg_binned];
    data.emg_binned = data.emg_binned(1:end-1,:);
end