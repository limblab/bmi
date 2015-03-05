function handles = start_cerebus_stream(params,handles,xpc)

% Cerebus Stream via Central
connection = cbmex('open',1);
if ~connection
    echoudp('off');
    if exist('xpc','var')
        fclose(xpc);
        delete(xpc);
        echoudp('off')
        clear xpc
    end
    close(handles.keep_running);
    error('Connection to Central Failed');
end

if params.save_data
    handles.cerebus_file   = fullfile(handles.save_dir, handles.filename);
    cbmex('fileconfig', handles.cerebus_file, '', 0);% open 'file storage' app, or stop ongoing recordings
    drawnow; %wait until the app opens
%     bin_start_t = 0.0; % time at beginning of next bin

%     %start cerebus file recording :
%     cbmex('fileconfig', cerebus_file, '', 1);
%     data.sys_time = cbmex('time');
end    