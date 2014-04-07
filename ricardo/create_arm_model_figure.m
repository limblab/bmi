function h = create_arm_model_figure
    h = [];

    close all
    h.h_fig = figure;
    subplot(221)
    h.h_plot_1 = plot(1:10,zeros(1,10),'-');    
    ylim([0 0.1])
    subplot(222)
    plot(0,0,'.k')
    h.h_plot_2 = plot([0 0],[0 0],'-r');
    xlim([-10 10])
    ylim([-10 10])    
    axis square
    subplot(223)    
    h.h_plot_3 = plot(0,0,'-k');    
    xlim([-1 1])
    ylim([-1 1]) 
    axis square
    drawnow

    arm_params = evalin('base','arm_params');

    h.controls = uipanel('Position',[.55 .05 .4 .4],'Units','normalized');

    h.textboxes = uipanel('Units','normalized','Position',[0 .1 1 .4],...
        'Parent',h.controls);
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
    for iBox = 1:length(values)
        set(h.textbox(iBox),'String',num2str(values(iBox)),'Enable','on')
    end
    for iBox = length(values)+1:8
        set(h.textbox(iBox),'String',[],'Enable','off')
    end
end

function set_params(h_set_params,event,h)
    arm_params = evalin('base','arm_params');
    idx = get(h.param_list,'Value');
    strings = get(h.param_list,'String');
    values = [];
    for iBox = 1:length(arm_params.(strings{idx}))
        values(iBox) = str2double(get(h.textbox(iBox),'String'));
    end
    arm_params.(strings{idx}) = values;
    assignin('base','arm_params',arm_params)
end


