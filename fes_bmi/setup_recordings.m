%
% Create handles for saving the data recorded during a BMI experiment, as
% well as the corresponding outputs (cursor predictions if it's a classic
% 'brain control' experiment, and stimulator commands if it is a BMI-FES
% experiment
% 
%   function handles = setup_recordings(params,handles)
%

function handles = setup_recordings(params,handles)

    % define directory and file name. For an online experiment, the code
    % will be store in folder with today's date, and a file name with the
    % current date and time
    if params.online
        date_str = datestr(now,'yyyymmdd_HHMMSS');
        filename = [params.save_name '_' date_str '_'];
        date_str = datestr(now,'yyyymmdd');
    % for an offline experiment, the data will be stored in the same
    % firectory
    else
        [path_name,filename,~] = fileparts(params.offline_data);
        filename = [filename '_'];
        date_str = path_name(find(path_name==filesep,1,'last')+1:end);
    end
    handles.filename = filename;
    
    % create directory if it doesn´ exist
    if params.save_data
        save_dir = [params.save_dir filesep date_str];
        if ~isdir(save_dir)
            mkdir(save_dir);
        end
        handles.save_dir = save_dir;
    end
    
    % In an online adaptation experiment, add iteration number
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
        handles.adapt_dir = adapt_dir;
    end

    
    % Save parameters in a mat file
    save( fullfile(save_dir, [filename 'params.mat']),'-struct','params');
    % save spike data, EMG data
    handles.spike_file     = fullfile(save_dir, [filename 'spikes.txt']);
    if ~strcmp(params.mode,'direct')
        handles.emg_file   = fullfile(save_dir, [filename 'emgpreds.txt']);
    end
    % for an FES experiment, save stimulation command
    if strcmp(params.output,'stimulator') || strcmp(params.output,'wireless_stim')
        handles.stim_out_file = fullfile(save_dir, [filename 'stim_out.txt']);
    end
    % save cursor position and predictions
    handles.curs_pred_file = fullfile(save_dir, [filename 'curspreds.txt']);
    handles.curs_pos_file  = fullfile(save_dir, [filename 'cursorpos.txt']);

end
