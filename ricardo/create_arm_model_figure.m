function h = create_arm_model_figure
    h = [];

    close all    
    h.h_fig = figure;
    set(h.h_fig,'Position',[1150 200 720 560])
    
    % dt plot
    subplot(321)
    h.h_plot_dt = plot(1:10,zeros(1,10),'-');
    ylim([0 0.1])
    xlabel('sample')
    ylabel('t (s)')
    
    % Endpoint force plot
    subplot(322)
    plot(0,0,'.k')
    h.h_plot_force = plot([0 0],[0 0],'-r');
    xlim([-10 10])
    ylim([-10 10])    
    axis square
    title('Endpoint force (N)')
    
    % Arm position plot
    subplot(323)    
    hold on
    h.h_plot_arm = plot(0,0,'-k');    
    h.h_plot_arm_2 = plot(0,0,'-','Color',[.5 .5 .5]);
    xlim([-30 30])
    ylim([-30 30]) 
    axis square
    title('Arm position (cm)')
    
    % EMG bar graph
    subplot(325)    
    h.h_emg_bar = bar(zeros(1,4));
    set(gca,'XTickLabel',{'AD(rt)','PD(lf)','Bi(up)','Tri(dn)'})
    ylim([0 1])
    title('Normalized EMG')
    
    drawnow

    % Parameters
    arm_params = evalin('base','arm_params');

    h.controls = uipanel('Position',[.55 .02 .4 .58],'Units','normalized');

    h.textboxes = uipanel('Units','normalized','Position',[0 .1 1 .4],...
        'Parent',h.controls,'Visible','off');
    h.textbox(1) = uicontrol('Style','edit','Units','normalized',...
        'Parent',h.textboxes,'Position',[0 .5 .25 .5]);
    h.textbox(2) = uicontrol('Style','edit','Units','normalized',...
        'Parent',h.textboxes,'Position',[.25 .5 .25 .5]);
    h.textbox(3) = uicontrol('Style','edit','Units','normalized',...
        'Parent',h.textboxes,'Position',[.5 .5 .25 .5]);
    h.textbox(4) = uicontrol('Style','edit','Units','normalized',...
        'Parent',h.textboxes,'Position',[.75 .5 .25 .5]);
    h.textbox(5) = uicontrol('Style','edit','Units','normalized',...
        'Parent',h.textboxes,'Position',[0 0 .25 .5]);
    h.textbox(6) = uicontrol('Style','edit','Units','normalized',...
        'Parent',h.textboxes,'Position',[.25 0 .25 .5]);
    h.textbox(7) = uicontrol('Style','edit','Units','normalized',...
        'Parent',h.textboxes,'Position',[.5 0 .25 .5]);
    h.textbox(8) = uicontrol('Style','edit','Units','normalized',...
        'Parent',h.textboxes,'Position',[.75 0 .25 .5]);
    
    h.radio_button_panel = uipanel('Units','normalized','Position',[0 .1 1 .4],...
        'Parent',h.controls,'Visible','off');
    h.radio_button_group = uibuttongroup('Units','normalized','Parent',h.radio_button_panel,...
        'Position',[0 0 1 1],'SelectedObject',[]);
    h.radio_button_dynamic = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',h.radio_button_group,...
        'String','hill','Position',[.1 .8 .5 .15]);
    h.radio_button_prosthesis = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',h.radio_button_group,...
        'String','prosthesis','Position',[.1 .6 .5 .15]);
    h.radio_button_hu = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',h.radio_button_group,...
        'String','hu','Position',[.1 .4 .5 .15]);
    h.radio_button_miller = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',h.radio_button_group,...
        'String','miller','Position',[.1 .2 .5 .15]);
    h.radio_button_perreault = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',h.radio_button_group,...
        'String','perreault','Position',[.1 0 .5 .15]);
    h.radio_button_ruiz = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',h.radio_button_group,...
        'String','ruiz','Position',[.5 .8 .5 .15]);   
    h.radio_button_bmi = uicontrol('Units','normalized','Style','radiobutton',...
        'Parent',h.radio_button_group,...
        'String','bmi','Position',[.5 .6 .5 .15]); 
  
    h.param_list = uicontrol('Style','listbox','Units','normalized',...
        'Position',[0 .5 1 .5],...
        'Parent',h.controls,...
        'Callback',{@show_params,h});
    set(h.param_list,'string',fields(arm_params))
    
    h.set_params = uicontrol('Style','pushbutton','Units','normalized',...
        'Parent',h.controls,'Position',[0 0 1 .1],'String','Set params',...
        'Callback',{@set_params,h});
end

function show_params(h_param_list,event,h)
    arm_params = evalin('base','arm_params');
    idx = get(h_param_list,'Value');   
    strings = get(h_param_list,'String');
    values = arm_params.(strings{idx});
    if isnumeric(values)
        set(h.textboxes,'Visible','on')
        set(h.radio_button_panel,'Visible','off')
        for iBox = 1:length(values)
            set(h.textbox(iBox),'String',num2str(values(iBox)),'Enable','on')
        end
        for iBox = length(values)+1:8
            set(h.textbox(iBox),'String',[],'Enable','off')
        end
    else
        set(h.textboxes,'Visible','off')
        set(h.radio_button_panel,'Visible','on')
        
        temp = strcmp(arm_params.control_mode,...
            get(get(h.radio_button_group,'Children'),'String'));
        temp2 = get(h.radio_button_group,'Children');
        current_selection = temp2(temp);
        set(h.radio_button_group,'SelectedObject',current_selection)
%         set(h.textbox(1),'String',num2str(values),'Enable','on')        
%         for iBox =2:8
%             set(h.textbox(iBox),'String',[],'Enable','off')
%         end
    end
end

function set_params(h_set_params,event,h)
    arm_params = evalin('base','arm_params');
    idx = get(h.param_list,'Value');
    strings = get(h.param_list,'String');
    values = [];
    if isnumeric(arm_params.(strings{idx}))
        for iBox = 1:length(arm_params.(strings{idx}))
            values(iBox) = str2double(get(h.textbox(iBox),'String'));
        end        
    else
        values = get(get(h.radio_button_group,'SelectedObject'),'String');
    end
    arm_params.(strings{idx}) = values;
    assignin('base','arm_params',arm_params)
end


