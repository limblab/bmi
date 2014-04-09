function handles = setup_datafiles(params,handles,data,offline_data,w)

if params.save_data 
    handles.data_file = fullfile(handles.save_dir, [handles.filename 'data.txt']);        
    data_temp = get_new_data(params,data,offline_data,0,1,w);
    [~,~,emg_chans] = process_emg(data_temp);

    for i = 1:params.n_neurons
    %         headers = [headers 'spikes_chan' num2str(i) ','];
        spike_chans{i} = ['spikes_chan' num2str(i)];
    end

    headers = ['t_bin_start',spike_chans,'pred_x','pred_y',...
        emg_chans,'F_x','F_y','musc_force_1','musc_force_2','musc_force_3','musc_force_4'];
    %     headers = headers(1:end-1);    
    %     headers = [headers '\r\n'];
    fid_data = fopen(handles.data_file,'a');

     %Setup files for recording parameters and neural and cursor data:
    save(fullfile(handles.save_dir, [handles.filename 'params.mat']),'-struct','params');
    save(fullfile(handles.save_dir, [handles.filename 'params.mat']),'headers','-append');
    for iHeader = 1:length(headers)
        fprintf(fid_data,'%s',[headers{iHeader} ' ']);
    end
    fclose(fid_data);
end