function handles = setup_display_plots(params,handles)

    handles.fig_handle = figure;
    set(handles.fig_handle,'Position',[250 330 560 420])
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
    handles.stop_bmi = uicontrol('Style','toggle','String','Stop BMI',...
        'Parent',handles.control_panel,'Units','normalized','Position',[.1 .85 .3 .1]);  

    handles.label_stop_if_x_artifacts = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.control_panel,...
        'String','Stop trial if X artifacts','Position',[.5 .85 .3 .1]);
    handles.textbox_stop_if_x_artifacts = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.control_panel,...
        'String',num2str(params.stop_task_if_x_artifacts),'Position',[.5 .8 .3 .05],'Callback',@artifactchange_Callback);
    handles.button_stop_task = uicontrol('Units','normalized','Style','pushbutton',...
        'Parent',handles.control_panel,...
        'String','Stop trial','Position',[.5 .7 .3 .05],'Callback',@stoptask_Callback);
    
    handles.record = uicontrol('Style','toggle','String','Start recording',...
        'Parent',handles.control_panel,'Units','normalized','Position',[.1 .7 .3 .1],'Value',0,...
        'Callback',@togglebutton_Callback);   
    handles.mode_select_group = uibuttongroup('Parent',handles.control_panel,...
        'Units','normalized','Position',[.1 .1 .8 .55],'SelectionChangeFcn',@mode_selection);
    handles.radio_button_n2e = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','n2e','Position',[.1 .85 .8 .2]);
    handles.radio_button_n2e = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','n2e_cartesian','Position',[.1 .7 .8 .2]);
    handles.radio_button_emg = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','emg','Position',[.1 .55 .8 .2]);
    handles.radio_button_vel = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','vel','Position',[.1 .40 .8 .2]);
    handles.textbox_offset_rate = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.mode_select_group,...
        'String','60','Position',[.4 .4 .2 .1],'Callback',@offset_rate_change_Callback);
    handles.textbox_offset_x = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.mode_select_group,...
        'String','0','Position',[.6 .4 .2 .1],'Callback',@x_offset_change_Callback);
    handles.textbox_offset_y = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.mode_select_group,...
        'String','0','Position',[.8 .4 .2 .1],'Callback',@y_offset_change_Callback);
    handles.radio_button_iso = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','iso','Position',[.1 .25 .3 .2]);
    temp = strcmp(get(get(handles.mode_select_group,'Children'),'String'),params.mode);
    temp2 = get(handles.mode_select_group,'Children');
    temp2 = temp2(temp);
    set(handles.mode_select_group,'SelectedObject',temp2);
    handles.label_force_to_cursor_gain = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.mode_select_group,...
        'String','Force to cursor gain','Position',[.1 .1 .6 .2]);
    handles.textbox_force_to_cursor_gain = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.mode_select_group,...
        'String','.2','Position',[.7 .25 .2 .1],'Callback',@gainchange_Callback);
    handles.label_force_offset = uicontrol('Units','normalized','Style','text',...
        'Parent',handles.mode_select_group,...
        'String','Force offsets','Position',[.05 .05 .6 .2]);
    handles.textbox_force_offset_x = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.mode_select_group,...
        'String','0','Position',[.6 .15 .2 .1],'Callback',@force_x_offsetchange_Callback);
    handles.textbox_force_offset_y = uicontrol('Units','normalized','Style','edit',...
        'Parent',handles.mode_select_group,...
        'String','0','Position',[.8 .15 .2 .1],'Callback',@force_y_offsetchange_Callback);
    handles.radio_button_test_force = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','test force','Position',[.1 0 .4 .15]);
    handles.radio_button_test_torque = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',handles.mode_select_group,...
        'String','test torque','Position',[.6 0 .4 .15]);

end

function togglebutton_Callback(hObject,eventdata)
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
    params.task_name = ['DCO_' params.mode];
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

function x_offset_change_Callback(hObject,eventdata)
    new_x_offset = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.vel_offsets(1) = new_x_offset;    
    assignin('base','params',params);
end

function y_offset_change_Callback(hObject,eventdata)
    new_y_offset = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.vel_offsets(2) = new_y_offset;    
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

function stoptask_Callback(hObject,eventdata)    
    params = evalin('base','params');
    params.stop_trial = 1;
    assignin('base','params',params);
end
