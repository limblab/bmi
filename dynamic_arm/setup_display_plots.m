function handles = setup_display_plots(params,handles)

    handles.fig_handle = figure;
    set(handles.fig_handle,'Position',[250 330 560 600])
    if params.display_plots
        subplot(121)
        handles.curs_handle = plot(0,0,'ko');
        set(handles.curs_handle,'MarkerSize',6,'MarkerFaceColor','k','MarkerEdgeColor','k');
        %     xlim([-12 12]); ylim([-12 12]);
        xlim([-20 20]); ylim([-20 20]);
        axis square; axis equal; axis manual;
        hold on;    
        handles.tgt_handle  = plot(0,0,'bo');
        set(handles.tgt_handle,'LineWidth',2,'MarkerSize',15);
        handles.xpred_disp = annotation(gcf,'textbox', [0.3 0.85 0.16 0.05],...
            'FitBoxToText','off','String',sprintf('xpred: %.2f',0));
        handles.ypred_disp = annotation(gcf,'textbox', [0.3 0.79 0.16 0.05],...
            'FitBoxToText','off','String',sprintf('ypred: %.2f',0));
    end
    subplot(122)
    axis off
    handles.control_panel = uipanel('Units','normalized','Position',[.5 0 .5 1]);
    
    handles.general_group = uipanel('Parent',handles.control_panel,...
        'Units','normalized','Position',[.025 .6 .95 .4]);    
    handles.stop_bmi = uicontrol('Style','toggle','String','Stop BMI',...
        'Parent',handles.general_group,'Units','normalized','Position',[.1 .85 .3 .15]);  
    handles.label_stop_if_x_artifacts = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.general_group,...
        'String','Stop trial if X artifacts','Position',[.43 .85 .3 .15]);
    handles.textbox_stop_if_x_artifacts = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.general_group,...
        'String',num2str(params.stop_task_if_x_artifacts),'Position',[.74 .85 .18 .15],'Callback',@artifactchange_Callback);    
    handles.label_stop_if_x_force = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.general_group,...
        'String','Stop trial if |dforce|<X','Position',[.43 .7 .3 .15]);
    handles.textbox_stop_if_x_force = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.general_group,...
        'String',num2str(params.stop_task_if_x_force),'Position',[.74 .7 .18 .15],'Callback',@minforcechange_Callback);    
    handles.button_stop_task = uicontrol('Units','normalized','Style','pushbutton',...
        'Parent',handles.general_group,...
        'String','Stop trial','Position',[.5 .55 .3 .15],'Callback',@stoptask_Callback);
    handles.record = uicontrol('Style','toggle','String','Start recording',...
        'Parent',handles.general_group,'Units','normalized','Position',[.1 .55 .3 .15],...
        'Callback',@record_Callback); 
    handles.label_monkey_name = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.general_group,...
        'String','Monkey name','Position',[.1 .35 .3 .1]);
    handles.textbox_monkey_name = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.general_group,...
        'String','Chewie','Position',[.45 .375 .4 .1],...
        'Callback',@monkeynamechange_Callback);    
    handles.label_task_name = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.general_group,...
        'String','Task name','Position',[.1 .25 .3 .1]);
    handles.textbox_task_name = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.general_group,...
        'String','RP','Position',[.45 .275 .4 .1],...
        'Callback',@tasknamechange_Callback);   
   
   
    handles.mode_select_group = uibuttongroup('Parent',handles.control_panel,...
        'Units','normalized','Position',[.025 .3 .95 .33],'SelectionChangeFcn',@mode_selection);
    handles.radio_button_n2e = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','n2e1','Position',[.1 .85 .8 .15]);
    handles.radio_button_n2e = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','n2e2','Position',[.1 .7 .8 .15]);
%     handles.textbox_offset_rate = uicontrol('Units','normalized','Style','edit',...
%         'Parent',handles.mode_select_group,...
%         'String','60','Position',[.4 .85 .2 .1],'Callback',@offset_rate_change_Callback);
%     handles.textbox_offset_x = uicontrol('Units','normalized','Style','edit',...
%         'Parent',handles.mode_select_group,...
%         'String','0','Position',[.6 .85 .2 .1],'Callback',@x_offset_change_Callback);
%     handles.textbox_offset_y = uicontrol('Units','normalized','Style','edit',...
%         'Parent',handles.mode_select_group,...
%         'String','0','Position',[.8 .85 .2 .1],'Callback',@y_offset_change_Callback);
    handles.radio_button_n2e_cart = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','n2e_cartesian','Position',[.1 .55 .6 .15]);
    handles.radio_button_emg = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','emg','Position',[.1 .4 .8 .15]);
    handles.radio_button_vel = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','vel','Position',[.1 .25 .8 .15]);
%     handles.textbox_offset_rate = uicontrol('Units','normalized','Style','edit',...
%         'Parent',handles.mode_select_group,...
%         'String','60','Position',[.4 .4 .2 .1],'Callback',@offset_rate_change_Callback);
%     handles.textbox_offset_x = uicontrol('Units','normalized','Style','edit',...
%         'Parent',handles.mode_select_group,...
%         'String','0','Position',[.6 .4 .2 .1],'Callback',@x_offset_change_Callback);
%     handles.textbox_offset_y = uicontrol('Units','normalized','Style','edit',...
%         'Parent',handles.mode_select_group,...
%         'String','0','Position',[.8 .4 .2 .1],'Callback',@y_offset_change_Callback);
    handles.radio_button_iso = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','iso','Position',[.1 .1 .3 .15]);
    temp = strcmp(get(get(handles.mode_select_group,'Children'),'String'),params.mode);
    temp2 = get(handles.mode_select_group,'Children');
    temp2 = temp2(temp);
    set(handles.mode_select_group,'SelectedObject',temp2);
    handles.label_force_to_cursor_gain = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.mode_select_group,...
        'String','Force to cursor gain','Position',[.25 .25 .3 .07]);
    handles.textbox_force_to_cursor_gain = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.mode_select_group,...
        'String','.2','Position',[.7 .25 .2 .07],'Callback',@gainchange_Callback);
    handles.label_force_offset = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.mode_select_group,...
        'String','Force offsets','Position',[.25 .15 .3 .07]);
    handles.textbox_force_offset_x = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.mode_select_group,...
        'String','0','Position',[.6 .15 .2 .07],'Callback',@force_x_offsetchange_Callback);
    handles.textbox_force_offset_y = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.mode_select_group,...
        'String','0','Position',[.8 .15 .2 .07],'Callback',@force_y_offsetchange_Callback);
    handles.radio_button_test_force = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','test force','Position',[.3 0 .4 .15]);
    handles.radio_button_test_torque = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','test torque','Position',[.6 0 .4 .15]);
    
    
    handles.offsets_group = uipanel('Parent',handles.control_panel,...
        'Units','normalized','Position',[.025 .05 .95 .2]);
    handles.label_offset_time_constant = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.offsets_group,...
        'String','Offset time constant','Position',[.1 .85 .4 .12]);
    handles.textbox_offset_rate = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.offsets_group,...
        'String','1000000000000000000000000000000000000000000000000000000000000000000000000','Position',[.6 .85 .2 .12],'Callback',@offset_rate_change_Callback);
    handles.label_offsets = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.offsets_group,...
        'String','Offsets','Position',[.1 .7 .15 .12]);
    handles.textbox_offset_1 = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.offsets_group,...
        'String','0','Position',[.1 .5 .2 .12],'Callback',@offset_1_change_Callback);
    handles.textbox_offset_2 = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.offsets_group,...
        'String','0','Position',[.3 .5 .2 .12],'Callback',@offset_2_change_Callback);
    handles.textbox_offset_3 = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.offsets_group,...
        'String','0','Position',[.5 .5 .2 .12],'Callback',@offset_3_change_Callback);
    handles.textbox_offset_4 = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.offsets_group,...
        'String','0','Position',[.7 .5 .2 .12],'Callback',@offset_4_change_Callback);

end

function record_Callback(hObject,eventdata)
    button_state = get(hObject,'Value');
    if button_state == get(hObject,'Max')
        set(hObject,'String','Stop recording')
    elseif button_state == get(hObject,'Min')
        set(hObject,'String','Start recording')
    end
end

function mode_selection(source,eventdata)
    params = evalin('base','params');
    params.mode = get(eventdata.NewValue,'String');
    params.task_name = [params.task_name(1:strfind(params.task_name,'_')) params.mode];
    params = load_decoders(params);
    assignin('base','params',params);
end

function gainchange_Callback(hObject,eventdata)
    new_gain = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.force_to_cursor_gain = new_gain;    
    assignin('base','params',params);
end

function offset_rate_change_Callback(hObject,eventdata)
    new_rate = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.offset_time_constant = new_rate;    
    assignin('base','params',params);
end

function offset_1_change_Callback(hObject,eventdata)
    new_offset = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.decoder_offsets(1) = new_offset;    
    assignin('base','params',params);
end

function offset_2_change_Callback(hObject,eventdata)
    new_offset = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.decoder_offsets(2) = new_offset;    
    assignin('base','params',params);
end

function offset_3_change_Callback(hObject,eventdata)
    new_offset = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.decoder_offsets(3) = new_offset;    
    assignin('base','params',params);
end

function offset_4_change_Callback(hObject,eventdata)
    new_offset = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.decoder_offsets(4) = new_offset;    
    assignin('base','params',params);
end

function force_x_offsetchange_Callback(hObject,eventdata)
    new_x_offset = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.force_offset(1) = new_x_offset;    
    assignin('base','params',params);
end

function force_y_offsetchange_Callback(hObject,eventdata)
    new_y_offset = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.force_offset(2) = new_y_offset;    
    assignin('base','params',params);
end

function artifactchange_Callback(hObject,eventdata)
    new_X_artifact = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.stop_task_if_x_artifacts = new_X_artifact;    
    assignin('base','params',params);
end

function minforcechange_Callback(hObject,eventdata)
    new_min_force = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.stop_task_if_x_force = new_min_force;    
    assignin('base','params',params);
end

function stoptask_Callback(hObject,eventdata)    
    params = evalin('base','params');
    params.stop_trial = 1;
    assignin('base','params',params);
end

function tasknamechange_Callback(hObject,eventdata)    
    params = evalin('base','params');
    params.task_name = [get(hObject,'String') '_' params.mode];
    assignin('base','params',params);
end

function monkeynamechange_Callback(hObject,eventdata)    
    params = evalin('base','params');
    params.monkey_name = get(hObject,'String');
    params.save_dir = [params.save_dir(1:strfind(params.save_dir,filesep)) get(hObject,'String')]; 
    assignin('base','params',params);
end

