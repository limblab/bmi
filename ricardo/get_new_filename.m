function handles = get_new_filename(params,handles)

if params.save_data
    if params.online
%         handles.date_str = datestr(now,'yyyy_mm_dd_HHMMSS');
        handles.date_str = datestr(now,'yyyy-mm-dd');
        handles.save_dir = [params.save_dir filesep handles.date_str];
        if ~isdir(handles.save_dir)
            mkdir(handles.save_dir);
        end
        handles.filename = [params.save_name '_' handles.date_str '_'];
        existing_files = dir([handles.save_dir filesep handles.filename '*.nev']);
        counter = length(existing_files)+1;
        handles.filename = [handles.filename num2str(counter,'%03d')];
%         handles.date_str = datestr(now,'yyyy_mm_dd');
    else
        [path_name,handles.filename,~] = fileparts(params.offline_data);
        handles.filename = [handles.filename '_'];
        handles.date_str = path_name(find(path_name==filesep,1,'last')+1:end);
        handles.save_dir = [params.save_dir filesep handles.date_str];
        if ~isdir(handles.save_dir)
            mkdir(handles.save_dir);
        end
    end
end