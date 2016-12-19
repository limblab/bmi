function varargout = RunBMIGUI(varargin)
% RUNBMIGUI MATLAB code for RunBMIGUI.fig
%      RUNBMIGUI, by itself, creates a new RUNBMIGUI or raises the existing
%      singleton*.
%
%      H = RUNBMIGUI returns the handle to a new RUNBMIGUI or the handle to
%      the existing singleton*.
%
%      RUNBMIGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RUNBMIGUI.M with the given input arguments.
%
%      RUNBMIGUI('Property','Value',...) creates a new RUNBMIGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RunBMIGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RunBMIGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RunBMIGUI

% Last Modified by GUIDE v2.5 17-Dec-2016 18:08:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RunBMIGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @RunBMIGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before RunBMIGUI is made visible.
function RunBMIGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RunBMIGUI (see VARARGIN)

% Choose default command line output for RunBMIGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% defaults for settings
handles.savedir = pwd;

handles.monkey = 'Jango';
handles.stim_mode = 'monopolar'; % stimulation style
handles.stimulator = 'stimulator';   % stimulator type
handles.task = 'WF';
handles.polyorder = 0;

% defaults for sp structure
handles.emg_list_4_dec = {'FCRr', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDSu', 'PL', 'APB'};
handles.sp.EMG_to_stim_map = [{'FCRr', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDSu', 'PL', 'APB'}; ...
                                    {'FCRr', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDSu', 'PL', 'APB'}];
handles.sp.muscles = {'FCRr', 'FCUu', 'FDPr', 'FDPu', 'FDSr', 'FDSu', 'PL', 'APB'};
handles.sp.anode_map        = [{ [3 5 7], [9 11 13], [15 17 19], [21 23 25], [27 29 31], ...
                                        [2 4 6], [8 10 12], [14 16 18] }; ...
                                        { [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3], ...
                                        [1/3 1/3 1/3], [1/3 1/3 1/3], [1/3 1/3 1/3] }];
handles.sp.cathode_map  = {};
handles.sp.EMG_min = repmat(.15,1,numel(handles.sp.muscles));
handles.sp.EMG_max = repmat(.9,1,numel(handles.sp.muscles));
handles.sp.PW_min = repmat( 0.05, 1, numel(handles.sp.muscles));
handles.sp.PW_max = repmat( 0.5, 1, numel(handles.sp.muscles));
handles.sp.amplitude_min = repmat(0,1,numel(handles.sp.muscles));
handles.sp.amplitude_max = repmat(4,1,numel(handles.sp.muscles));
handles.sp.return = 'stimulator';
handles.sp.perc_catch_trials = 15;





% UIWAIT makes RunBMIGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = RunBMIGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in MonkeyName.
function MonkeyName_Callback(hObject, eventdata, handles)
% hObject    handle to MonkeyName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns MonkeyName contents as cell array
%        contents{get(hObject,'Value')} returns selected item from MonkeyName


% --- Executes during object creation, after setting all properties.
function MonkeyName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MonkeyName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_monkey.
function popup_monkey_Callback(hObject, eventdata, handles)
% hObject    handle to popup_monkey (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_monkey contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_monkey
contents = cellstr(get(hObject,'String'));
handles.monkey = contents{get(hObject,'Value')};

% --- Executes during object creation, after setting all properties.
function popup_monkey_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_monkey (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over popup_monkey.
function popup_monkey_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to popup_monkey (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popup_task.
function popup_task_Callback(hObject, eventdata, handles)
% hObject    handle to popup_task (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(hObject,'Value')
    case 1
        handles.task = 'WF';
    case 2
        handles.task = 'WM';
    case 3
        handles.task = 'MG_PG';
    case 4
        handles.task = 'MG_PT';
end


% --- Executes during object creation, after setting all properties.
function popup_task_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_task (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_stimulation.
function popup_stimulation_Callback(hObject, eventdata, handles)
% hObject    handle to popup_stimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_stimulation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_stimulation
switch get(hObject,'Value')
    case 1
        handles.stim_mode = 'monopolar';
    case 2
        handles.stim_mode = 'bipolar';
end


% --- Executes during object creation, after setting all properties.
function popup_stimulation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_stimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_stimulator.
function popup_stimulator_Callback(hObject, eventdata, handles)
% hObject    handle to popup_stimulator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch get(hObject,'Value') % returns selected item from popup_stimulator
    case 1
        handles.stimulator = 'stimulator';
    case 2
        handles.stimulator = 'wireless_stim';
    case 3
        handles.stimulator = 'catch';
end
        

% --- Executes during object creation, after setting all properties.
function popup_stimulator_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_stimulator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_online.
function check_online_Callback(hObject, eventdata, handles)
% hObject    handle to check_online (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_online
if ~ get(hObject,'Value') %
    set(handles.edit_savedir,'Enable','off'); % disables saving the stimulation and predictions
    set(handles.push_savedir,'Enable','off');
else
    set(handles.push_savedir,'Enable','on');
    set(handles.edit_savedir,'Enable','on');
end



function edit_savedir_Callback(hObject, eventdata, handles)
% hObject    handle to edit_savedir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_savedir as text
%        str2double(get(hObject,'String')) returns contents of edit_savedir as a double


% --- Executes during object creation, after setting all properties.
function edit_savedir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_savedir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in push_savedir.
function push_savedir_Callback(hObject, eventdata, handles)
% hObject    handle to push_savedir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.savedir = uigetdir(pwd,'Stimulation Save Location'); % current save locat'n
set(handles.edit_savedir,'String',handles.savedir); % show value in text box





function edit_newdecoder_Callback(hObject, eventdata, handles)
% hObject    handle to edit_newdecoder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_newdecoder as text
%        str2double(get(hObject,'String')) returns contents of edit_newdecoder as a double


% --- Executes during object creation, after setting all properties.
function edit_newdecoder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_newdecoder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in push_newdecoder.
function push_newdecoder_Callback(hObject, eventdata, handles)
% hObject    handle to push_newdecoder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[nevFileName,nevPathName,~] = uigetfile('*.nev','Decoder .nev File');
set(handles.edit_newdecoder,'String',[nevPathName, nevFileName]);


function edit_existingdecoder_Callback(hObject, eventdata, handles)
% hObject    handle to edit_existingdecoder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_existingdecoder as text
%        str2double(get(hObject,'String')) returns contents of edit_existingdecoder as a double


% --- Executes during object creation, after setting all properties.
function edit_existingdecoder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_existingdecoder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in push_existingdecoder.
function push_existingdecoder_Callback(hObject, eventdata, handles)
% hObject    handle to push_existingdecoder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[nevFileName,nevPathName,~] = uigetfile('*.mat','Existing folder location');
set(handles.edit_existingdecoder,'String',[nevPathName, nevFileName]);



% --- Executes on button press in radio_newdecoder.
function radio_newdecoder_Callback(hObject, eventdata, handles)
% hObject    handle to radio_newdecoder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_newdecoder
    if get(hObject,'Value')   % toggle radio and associated inputs
        set(handles.radio_existingdecoder,'Value',0);
        set(handles.push_newdecoder,'Enable','on');
        set(handles.edit_newdecoder,'Enable','on');
        set(handles.edit_newdecoderorder,'Enable','on');
        set(handles.text_newdecoder,'Enable','on');
        set(handles.push_existingdecoder,'Enable','off');
        set(handles.edit_existingdecoder,'Enable','off');
        set(handles.push_decoder,'String','Build Decoder');
    end


% --- Executes on button press in radio_existingdecoder.
function radio_existingdecoder_Callback(hObject, eventdata, handles)
% hObject    handle to radio_existingdecoder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_existingdecoder
    if get(hObject,'Value')   % toggle radio and associated inputs
        set(handles.radio_newdecoder,'Value',0);
        set(handles.push_newdecoder,'Enable','off');
        set(handles.edit_newdecoder,'Enable','off');
        set(handles.edit_newdecoderorder,'Enable','off');
        set(handles.text_newdecoder,'Enable','off');
        set(handles.push_existingdecoder,'Enable','on');
        set(handles.edit_existingdecoder,'Enable','on');
        set(handles.push_decoder,'String','Load Decoder');
    end


% --- Executes on button press in push_decoder.
function push_decoder_Callback(hObject, eventdata, handles)
% hObject    handle to push_decoder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(handles.radio_newdecoder,'Value')
    N2E = build_emg_decoder_from_nev( get(handles.edit_newdecoder,'String'), handles.task, handles.emg_list_4_dec, handles.poly_order); %run it. We'll do error handling later

else
    N2E = LoadDataStruct(get(handles.edit_existingdecoder,'String')); % load N2E from existing decoder
    % This section is all stolen from call_run_bmi_fes
    if isfield(N2E, 'H')
        emg_pos_in_dec  = zeros(1,numel(handles.emg_list_4_dec));
        for i = 1:length(emg_pos_in_dec)
            % don't look at EMGs with label length longer than the label
            % you are looking for because it can give an error (e.g., if
            % you are looking for the position of FCR and there is an FCRl
            % and an FCR matlab will try to return two values)
            indx_2_look = [];
            for ii = 1:length(N2E.outnames)
                if length(N2E.outnames{ii}) == length(handles.emg_list_4_dec{i}) 
                    indx_2_look = [indx_2_look, ii];
                end
            end
            % find the index of the EMGs in the decoder
            emg_pos_in_dec(1,i) = indx_2_look( find( strncmp(N2E.outnames(indx_2_look),...
                                    handles.emg_list_4_dec(i),length(handles.emg_list_4_dec{i})) ));
        end
        % Get rid of the other muscles in the decoder
        N2E.H           = N2E.H(:,emg_pos_in_dec);
        N2E.outnames    = handles.emg_list_4_dec;
    else
        error('Invalid neuron-to-emg decoder');
    end
    
    
    % save N2E in the handles structure so we can use it later
    handles.N2E = N2E;
    
    set(handles.text_serial,'Enable','on')
    set(handles.edit_serial,'Enable','on')
    set(handles.text_perc,'Enable','on')
    set(handles.edit_perc,'Enable','on')
    set(handles.check_plot,'Enable','on')
    set(handles.push_stim,'Enable','on')
end



function edit_newdecoderorder_Callback(hObject, eventdata, handles)
% hObject    handle to edit_newdecoderorder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.poly_order = int16(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function edit_newdecoderorder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_newdecoderorder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_EMGsettings.
function check_EMGsettings_Callback(hObject, eventdata, handles)
% hObject    handle to check_EMGsettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_EMGsettings
if get(hObject,'Value')
    set(handles.edit_EMGsettings,'Enable','off');
    set(handles.push_EMGsettings,'Enable','off');
else
    set(handles.edit_EMGsettings,'Enable','on');
    set(handles.push_EMGsettings,'Enable','on');
end



function edit_EMGsettings_Callback(hObject, eventdata, handles)
% hObject    handle to edit_EMGsettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_EMGsettings as text
%        str2double(get(hObject,'String')) returns contents of edit_EMGsettings as a double


% --- Executes during object creation, after setting all properties.
function edit_EMGsettings_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_EMGsettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in push_EMGsettings.
function push_EMGsettings_Callback(hObject, eventdata, handles)
% hObject    handle to push_EMGsettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[nevFileName,nevPathName,~] = uigetfile('*.mat','Muscle Stimulation Settings'); % Browse for .mat file
set(handles.edit_existingdecoder,'String',[nevPathName, nevFileName]); % put the file name in the edit box
load([nevPathName, nevFileName]);
if ~exist('sp','struct')
    wrndlg(sprintf('File does not contain required settings.\nUsing default setting instead.'),'Stimulation settings');
else
    % set saved fields from .mat file
    Names = fieldnames(sp);
    for i = 1:length(Names)
        handles.sp = setfield(handles.sp,Names{i},sp.(Names{i}));
    end
end


% --- Executes when selected object is changed in uibutton_stim.
function uibutton_stim_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uibutton_stim 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit_COM_Callback(hObject, eventdata, handles)
% hObject    handle to edit_COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_COM as text
%        str2double(get(hObject,'String')) returns contents of edit_COM as a double


% --- Executes during object creation, after setting all properties.
function edit_COM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_plot.
function check_plot_Callback(hObject, eventdata, handles)
% hObject    handle to check_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_plot



function edit_perc_Callback(hObject, eventdata, handles)
% hObject    handle to edit_perc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_perc as text
%        str2double(get(hObject,'String')) returns contents of edit_perc as a double


% --- Executes during object creation, after setting all properties.
function edit_perc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_perc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in push_stim.
function push_stim_Callback(hObject, eventdata, handles)
% hObject    handle to push_stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

params.output = handles.output; % which output are we saving to?
params.online = get(handles.check_online,'Value'); % online?
params.save_data = params.online; % are we supposed to save the data?
params.save_dir = handles.savedir; % directory to save everything
handles.sp.perc_catch_trials = int16(get(handles.edit_perc,'String'));
params.neuron_decoder = handles.N2E;
params.mode = 'emg_only';
params.n_emgs = numel(handles.emg_list_4_dec);
params.display_plots = get(handles.push_plot,'Value');
params.bmi_fes_stim_params = handles.sp;    % Everything we've written so far as sp
params.bmi_fes_stim_params.return = handles.stim_mode;

% time to run it all
run_bmi_fes(params);
