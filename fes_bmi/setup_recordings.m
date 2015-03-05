function filerec_params = setup_recordings(params)

if params.save_data
        
        if params.online
            date_str = datestr(now,'yyyymmdd_HHMMSS');
            filename = [params.save_name '_' date_str '_'];
            date_str = datestr(now,'yyyymmdd');
        else
            [path_name,filename,~] = fileparts(params.offline_data);
            filename = [filename '_'];
            date_str = path_name(find(path_name==filesep,1,'last')+1:end);
        end

        save_dir = [params.save_dir filesep date_str];
        if ~isdir(save_dir)
            mkdir(save_dir);
        end
        
        if params.adapt
            adapt_dir = [save_dir filesep filename 'adapt_decoders'];
            conflict_dir = isdir(adapt_dir);
            num_iter = 1;
            while conflict_dir
                num_iter = num_iter+1;
                adapt_dir = sprintf('%s%d%s',[save_dir filesep filename 'adapt_decoders('],num_iter,')');
                conflict_dir = isdir(adapt_dir);
            end
            mkdir(adapt_dir);
        end
        
        %Setup files for recording parameters and neural and cursor data:
        save(            fullfile(save_dir, [filename 'params.mat']),'-struct','params');
        spike_file     = fullfile(save_dir, [filename 'spikes.txt']);
        if ~strcmp(params.mode,'direct')
            emg_file   = fullfile(save_dir, [filename 'emgpreds.txt']);
        end
        if strcmp(params.output,'stimulator')
            stim_out_file = fullfile(save_dir, [filename 'stim_out.txt']);
        end
        curs_pred_file = fullfile(save_dir, [filename 'curspreds.txt']);
        curs_pos_file  = fullfile(save_dir, [filename 'cursorpos.txt']);     
        
        filerec_params = struct(...
            'adapt_dir'         ,adapt_dir,...
            'data_dir'          ,save_dir,...
            'spike_file'        ,spike_file,...
            'emg_file'          ,emg_file,...
            'stim_out_file'     ,stim_out_file,...
            'curs_pred_file'    ,curs_pred_file,...
            'curs_pos_file'     ,curs_pos_file);
            
end
