function [params,handles] = setup_datafiles(params,handles,data,offline_data,w,xpc)

if params.save_data 
    handles = get_new_filename(params,handles);
    handles.data_file = fullfile(handles.save_dir, [handles.filename '_data.txt']);        
    data_temp = get_new_data(params,data,offline_data,0,1,w,xpc);
    [~,~,emg_chans] = process_emg(params,data_temp,zeros(1,100));
    [ts_cell_array, ~, ~] = cbmex('trialdata', 1);
%     params.n_neurons = sum(~cellfun(@isempty,strfind(ts_cell_array(:,1),'elec')));

    params.n_neurons = size(params.neuron_decoder.neuronIDs,1);
    spike_chans = cell(1,params.n_neurons);
    for i = 1:params.n_neurons
%        spike_chans{i} = data_temp.labels{i,1};
       spike_chans{i} = ['chan_' num2str(params.neuron_decoder.neuronIDs(i,1)) '-' num2str(params.neuron_decoder.neuronIDs(i,2))];
    end

    headers = ['t_bin_start',spike_chans,'pred_x','pred_y','sh_x','sh_y','el_x','el_y',...
        emg_chans,'F_x','F_y','musc_force_1','musc_force_2','musc_force_3','musc_force_4'];

%     fid_data = fopen(handles.data_file,'a');

     %Setup files for recording parameters and neural and cursor data:
    load('temp_arm_params')
    save(fullfile(handles.save_dir, [handles.filename '_params.mat']),'params','arm_params');
    save(fullfile(handles.save_dir, [handles.filename '_params.mat']),'headers','-append');
%     for iHeader = 1:length(headers)
%         fprintf(fid_data,'%s',[headers{iHeader} ' ']);
%     end
%     fprintf(fid_data,'\n');
%     fclose(fid_data);
    
    handles.cerebus_file = fullfile(handles.save_dir, handles.filename);
    cbmex('fileconfig', handles.cerebus_file, '', 0)
    drawnow
end