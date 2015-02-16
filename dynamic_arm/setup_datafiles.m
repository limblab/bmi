function [params,handles] = setup_datafiles(params,handles,data,offline_data,w,xpc,m_data_2)

recorded_files = dir(handles.save_dir);
recorded_files = {recorded_files(:).name};
if numel(recorded_files)<3 && exist(handles.save_dir,'dir')
    rmdir(handles.save_dir);
end

if params.save_data 
    load('temp_arm_params')
    params.arm_model = arm_params.control_mode;
    handles = get_new_filename(params,handles);
    handles.data_file = fullfile(handles.save_dir, [handles.filename '_data.txt']);        
    data_temp = get_new_data(params,data,offline_data,0,1,w,xpc,m_data_2);
    [~,~,emg_chans] = process_emg(params,data_temp,zeros(1,100));
    [ts_cell_array, ~, ~] = cbmex('trialdata', 1);

    spike_chans = cell(1,params.current_decoder.n_neurons);
    for i = 1:params.current_decoder.n_neurons
       spike_chans{i} = ['chan_' num2str(params.current_decoder.neuronIDs(i,1)) '-' num2str(params.current_decoder.neuronIDs(i,2))];
    end
    pred_labels = cell(1,size(params.current_decoder.outnames,1));
    for i = 1:size(params.current_decoder.outnames,1)
        pred_labels{i} = ['pred_' deblank(params.current_decoder.outnames(i,:))];
    end

    headers = ['t_bin_start',spike_chans,pred_labels,'cursor_x','cursor_y','sh_x','sh_y','el_x','el_y',...
        emg_chans,'F_x','F_y','musc_force_1','musc_force_2','musc_force_3',...
        'musc_force_4','cocontraction'];
    for iDecoder = 1:length(params.decoder_offsets)
        headers{end+1} = ['decoder_offset_ ' num2str(iDecoder)'];
    end

     %Setup files for recording parameters and neural and cursor data:    
    save(fullfile(handles.save_dir, [handles.filename '_params.mat']),'params','arm_params');
    save(fullfile(handles.save_dir, [handles.filename '_params.mat']),'headers','-append');
    
    handles.cerebus_file = fullfile(handles.save_dir, handles.filename);
    cbmex('fileconfig', handles.cerebus_file, '', 0)
    drawnow
end