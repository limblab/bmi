function [params,handles] = setup_datafiles(params,handles,data,offline_data,w)

if params.save_data 
    handles = get_new_filename(params,handles);
    handles.data_file = fullfile(handles.save_dir, [handles.filename '_data.txt']);        
    data_temp = get_new_data(params,data,offline_data,0,1,w);
    [~,~,emg_chans] = process_emg(data_temp);
    [ts_cell_array, ~, ~] = cbmex('trialdata', 1);
    params.n_neurons = sum(~cellfun(@isempty,strfind(ts_cell_array(:,1),'elec')));

    for i = 1:params.n_neurons
       spike_chans{i} = data_temp.labels{i,1};
    end

    headers = ['t_bin_start',spike_chans,'pred_x','pred_y',...
        emg_chans,'F_x','F_y','musc_force_1','musc_force_2','musc_force_3','musc_force_4'];

    fid_data = fopen(handles.data_file,'a');

     %Setup files for recording parameters and neural and cursor data:
    save(fullfile(handles.save_dir, [handles.filename '_params.mat']),'-struct','params');
    save(fullfile(handles.save_dir, [handles.filename '_params.mat']),'headers','-append');
    for iHeader = 1:length(headers)
        fprintf(fid_data,'%s',[headers{iHeader} ' ']);
    end
    fprintf(fid_data,'\n');
    fclose(fid_data);
    
    handles.cerebus_file = fullfile(handles.save_dir, handles.filename);
    cbmex('fileconfig', handles.cerebus_file, '', 0)
    drawnow
end