function handles = setup_display_plots(params,handles)

    if params.display_plots
        handles.fig_handle = figure;
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
        subplot(122)
        axis off
        handles.control_panel = uipanel('Units','normalized','Position',[.5 0 .5 1]);
        handles.stop_bmi = uicontrol('Style','toggle','String','Stop BMI',...
            'Parent',handles.control_panel,'Units','normalized','Position',[.1 .85 .3 .1]);    
        handles.record = uicontrol('Style','toggle','String','Start recording',...
            'Parent',handles.control_panel,'Units','normalized','Position',[.1 .7 .3 .1],'Value',0,...
            'Callback',@togglebutton_Callback);   
        handles.mode_select_group = uibuttongroup('Parent',handles.control_panel,...
            'Units','normalized','Position',[.1 .1 .8 .5],'SelectionChangeFcn',@selcbk);
        handles.radio_button_n2e = uicontrol('Units','normalized','Style','radiobutton',...
            'Parent',handles.mode_select_group,...
            'String','N2E','Position',[.1 .8 .8 .2]);
        handles.radio_button_emg = uicontrol('Units','normalized','Style','radiobutton',...
            'Parent',handles.mode_select_group,...
            'String','EMG','Position',[.1 .6 .8 .2]);
        handles.radio_button_vel = uicontrol('Units','normalized','Style','radiobutton',...
            'Parent',handles.mode_select_group,...
            'String','Vel','Position',[.1 .4 .8 .2]);
        handles.radio_button_iso = uicontrol('Units','normalized','Style','radiobutton',...
            'Parent',handles.mode_select_group,...
            'String','Iso','Position',[.1 .2 .8 .2]);
        temp = strcmp(get(get(handles.mode_select_group,'Children'),'String'),params.mode);
        temp2 = get(handles.mode_select_group,'Children');
        temp2 = temp2(temp);
        set(handles.mode_select_group,'SelectedObject',temp2);
        handles.label_force_to_cursor_gain = uicontrol('Units','normalized','Style','text',...
            'Parent',handles.mode_select_group,...
            'String','Force to cursor gain','Position',[.1 0 .6 .2]);
        handles.textbox_force_to_cursor_gain = uicontrol('Units','normalized','Style','edit',...
            'Parent',handles.mode_select_group,...
            'String','.2','Position',[.7 .1 .2 .1],'Callback',@gainchange_Callback);
    else
        handles = [];
    end
end

function togglebutton_Callback(hObject,eventdata)
    button_state = get(hObject,'Value');
    if button_state == get(hObject,'Max')
        set(hObject,'String','Stop recording')
    elseif button_state == get(hObject,'Min')
        set(hObject,'String','Start recording')
    end
end

function selcbk(source,eventdata)
    params = evalin('base','params');
    params.mode = get(eventdata.NewValue,'String');    
    assignin('base','params',params);
end

function gainchange_Callback(hObject,eventdata)
    new_gain = str2double(get(hObject,'String'));
    params = evalin('base','params');
    params.force_to_cursor_gain = new_gain;    
    assignin('base','params',params);
end