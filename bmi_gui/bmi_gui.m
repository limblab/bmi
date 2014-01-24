function varargout = bmi_gui(varargin)
% BMI_GUI MATLAB code for bmi_gui.fig
%      BMI_GUI, by itself, creates a new BMI_GUI or raises the existing
%      singleton*.
%
%      H = BMI_GUI returns the handle to a new BMI_GUI or the handle to
%      the existing singleton*.
%
%      BMI_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BMI_GUI.M with the given input arguments.
%
%      BMI_GUI('Property','Value',...) creates a new BMI_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before bmi_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to bmi_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help bmi_gui

% Last Modified by GUIDE v2.5 23-Jan-2014 15:42:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @bmi_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @bmi_gui_OutputFcn, ...
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


% --- Executes just before bmi_gui is made visible.
function bmi_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to bmi_gui (see VARARGIN)

% Choose default command line output for bmi_gui
handles.output = hObject;

%global variables
handles.neuron_decoder = [];
handles.emg_decoder    = [];

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes bmi_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = bmi_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% ------------------------------------------------------------
% Inputs Panel
% ------------------------------------------------------------

%--- Executes on button press in input_file_browse_button.
function input_file_browse_button_Callback(hObject, eventdata, handles)
% hObject    handle to input_file_browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uigetfile('*.mat', 'Select Binned Data File');
if ~isempty(filename)
    set(handles.input_file_txtbox,'String',fullfile(pathname,filename));
    set(handles.input_file_txtbox,'HorizontalAlignement',right);
end

function input_file_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to input_file_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of input_file_txtbox as text
%        str2double(get(hObject,'String')) returns contents of input_file_txtbox as a double

% --- Executes during object creation, after setting all properties.
function input_file_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to input_file_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes when selected object is changed in inputs_panel.
function inputs_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in inputs_panel 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
h = get(handles.inputs_panel,'SelectedObject');
s = get(h,'String');
if strcmp(s,'Cerebus')
    set(handles.input_file_txtbox,'enable','off');
    set(handles.input_file_browse_button,'enable','off');
else
    set(handles.input_file_txtbox,'enable','on');
    set(handles.input_file_browse_button,'enable','on');
end

% ------------------------------------------------------------
% Outputs Panel
% ------------------------------------------------------------

function output_file_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to output_file_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of output_file_txtbox as text
%        str2double(get(hObject,'String')) returns contents of output_file_txtbox as a double


% --- Executes during object creation, after setting all properties.
function output_file_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to output_file_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in output_file_browse_button.
function output_file_browse_button_Callback(hObject, eventdata, handles)
% hObject    handle to output_file_browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in save_dir_cbx.
function save_dir_cbx_Callback(hObject, eventdata, handles)
% hObject    handle to save_dir_cbx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of save_dir_cbx
if get(hObject,'Value')
    set(handles.output_file_txtbox, 'enable','on');
    set(handles.output_file_browse_button,'enable','on');
else
    set(handles.output_file_txtbox, 'enable','off');
    set(handles.output_file_browse_button,'enable','off');
end

% ------------------------------------------------------------
% Decoders Panel
% ------------------------------------------------------------

function emg_decoder_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to emg_decoder_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg_decoder_txtbox as text
%        str2double(get(hObject,'String')) returns contents of emg_decoder_txtbox as a double


% --- Executes during object creation, after setting all properties.
function emg_decoder_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg_decoder_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in emg_dec_browse_button.
function emg_dec_browse_button_Callback(hObject, eventdata, handles)
% hObject    handle to emg_dec_browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function neuron_decoder_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to neuron_decoder_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of neuron_decoder_txtbox as text
%        str2double(get(hObject,'String')) returns contents of neuron_decoder_txtbox as a double


% --- Executes during object creation, after setting all properties.
function neuron_decoder_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to neuron_decoder_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in neuron_dec_browse_button.
function neuron_dec_browse_button_Callback(hObject, eventdata, handles)
% hObject    handle to neuron_dec_browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% ------------------------------------------------------------
% Adaptation Panel
% ------------------------------------------------------------

function adapt_params_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to adapt_params_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of adapt_params_txtbox as text
%        str2double(get(hObject,'String')) returns contents of adapt_params_txtbox as a double


% --- Executes during object creation, after setting all properties.
function adapt_params_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adapt_params_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in adapt_enable_cbx.
function adapt_enable_cbx_Callback(hObject, eventdata, handles)
% hObject    handle to adapt_enable_cbx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of adapt_enable_cbx
if get(hObject,'Value')
    set(handles.adapt_lr_label,'enable','on');
    set(handles.adapt_delay_label,'enable','on');
    set(handles.adapt_duration_label,'enable','on');
    set(handles.adapt_lr_txtbox,'enable','on');
    set(handles.adapt_delay_txtbox,'enable','on');
    set(handles.adapt_duration_txtbox,'enable','on');
    set(handles.adapt_freeze_cbx,'enable','on');
    adapt_freeze_cbx_Callback(handles.adapt_freeze_cbx, eventdata, handles)
else
    set(handles.adapt_lr_label,'enable','off');
    set(handles.adapt_delay_label,'enable','off');
    set(handles.adapt_duration_label,'enable','off');
    set(handles.adapt_lr_txtbox,'enable','off');
    set(handles.adapt_delay_txtbox,'enable','off');
    set(handles.adapt_duration_txtbox,'enable','off');
    set(handles.adapt_freeze_cbx,'enable','off');
    set(handles.adapt_off_time_txtbox,'enable','off');
    set(handles.adapt_time_label1,'enable','off');
    set(handles.adapt_on_time_txtbox,'enable','off');
    set(handles.adapt_time_label2,'enable','off'); 
end

% --- Executes on button press in adapt_params_browse_button.
function adapt_params_browse_button_Callback(hObject, eventdata, handles)
% hObject    handle to adapt_params_browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function adapt_lr_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to adapt_lr_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of adapt_lr_txtbox as text
%        str2double(get(hObject,'String')) returns contents of adapt_lr_txtbox as a double


% --- Executes during object creation, after setting all properties.
function adapt_lr_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adapt_lr_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function adapt_delay_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to adapt_delay_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of adapt_delay_txtbox as text
%        str2double(get(hObject,'String')) returns contents of adapt_delay_txtbox as a double


% --- Executes during object creation, after setting all properties.
function adapt_delay_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adapt_delay_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function adapt_duration_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to adapt_duration_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of adapt_duration_txtbox as text
%        str2double(get(hObject,'String')) returns contents of adapt_duration_txtbox as a double

% --- Executes during object creation, after setting all properties.
function adapt_duration_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adapt_duration_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in adapt_freeze_cbx.
function adapt_freeze_cbx_Callback(hObject, eventdata, handles)
% hObject    handle to adapt_freeze_cbx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of adapt_freeze_cbx
if get(hObject,'Value')
    set(handles.adapt_off_time_txtbox,'enable','on');
    set(handles.adapt_time_label1,'enable','on');
    set(handles.adapt_on_time_txtbox,'enable','on');
    set(handles.adapt_time_label2,'enable','on'); 
else
    set(handles.adapt_off_time_txtbox,'enable','off');
    set(handles.adapt_time_label1,'enable','off');
    set(handles.adapt_on_time_txtbox,'enable','off');
    set(handles.adapt_time_label2,'enable','off'); 
end

function adapt_off_time_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to adapt_off_time_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of adapt_off_time_txtbox as text
%        str2double(get(hObject,'String')) returns contents of adapt_off_time_txtbox as a double


% --- Executes during object creation, after setting all properties.
function adapt_off_time_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adapt_off_time_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function adapt_on_time_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to adapt_on_time_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of adapt_on_time_txtbox as text
%        str2double(get(hObject,'String')) returns contents of adapt_on_time_txtbox as a double

% --- Executes during object creation, after setting all properties.
function adapt_on_time_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adapt_on_time_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% ------------------------------------------------------------
% Read/Write Parameters Function
% ------------------------------------------------------------

function params = get_all_params(handles)

s = get(get(handles.mode_panel,'SelectedObject'),'String');
if strcmp(s,'Direct')
    mode = 'direct';
else
    mode = 'emg_cascade';
end

s = get(get(handles.inputs_panel,'SelectedObject'),'String');
if strcmp(s,'Cerebus')
    online = true;
else
    online = false;
end

params = struct( ...
    'mode'          ,mode,...
    'adapt'         ,get(handles.adapt_enable_cbx,'Value'),...
    'cursor_assist' ,get(handles.cursor_assist_cbx,'Value'),...
    'neuron_decoder',get(handles.input_file_txtbox,'String'),...
    'emg_decoder'   ,get(handles.emg_decoder_txtbox,'String'),...
    'output'        ,get(get(handles.outputs_panel,'SelectedObject'),'String'),...
    'online'        ,online,...
    'realtime'      ,1,...
    'offline_data'   ,'Z:\Jango_12a1\BinnedData\EMGCascade\2014-01-03_decoder_training\Jango_2014-01-03_WF_001.mat',...
    'cursor_traj'   ,'Z:\Jango_12a1\Mean_Paths\mean_paths_HC_Jango_WF_2014-01-03.mat',...
    ...
    'n_neurons'     ,96,...    
    'n_lag'         ,20,...
    'n_emgs'        ,6,...
    'n_lag_emg'     ,10,...
    'n_forces'      ,2,...
    'binsize'       ,0.05,... 
    'db_size'       ,34,...
    'ave_fr'        ,20,...
    'max_init_w'    ,0,... 
    ...
    'LR'            ,str2double(get(handles.adapt_lr_txtbox,'String')),...
    'batch_length'  ,1,...
    'delay'         ,str2double(get(handles.adapt_delay_txtbox,'String')),...
    'duration'      ,str2double(get(handles.adapt_duration_txtbox,'String')),...
    'adapt_freeze'  ,get(handles.adapt_freeze_cbx,'Value'),...
    'adapt_time'    ,str2double(get(handles.adapt_on_time_txtbox,'String')),...
    'fixed_time'    ,str2double(get(handles.adapt_off_time_txtbox,'String')),...
    'simulate'      ,false,...
    ...
    'display_plots' ,true,...
    'show_progress' ,false,...
    'save_data'     ,true,...
    'save_dir'      ,['E:\Data-lab1\12A1-Jango\AdaptationFiles\' date]...
);


% --- Executes on button press in cursor_assist_cbx.
function cursor_assist_cbx_Callback(hObject, eventdata, handles)
% hObject    handle to cursor_assist_cbx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cursor_assist_cbx


% --- Executes on button press in cursor_traj_browse_button.
function cursor_traj_browse_button_Callback(hObject, eventdata, handles)
% hObject    handle to cursor_traj_browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function cursor_traj_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to cursor_traj_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cursor_traj_txtbox as text
%        str2double(get(hObject,'String')) returns contents of cursor_traj_txtbox as a double


% --- Executes during object creation, after setting all properties.
function cursor_traj_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cursor_traj_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in neuron_dec_popup.
function neuron_dec_popup_Callback(hObject, eventdata, handles)
% hObject    handle to neuron_dec_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns neuron_dec_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from neuron_dec_popup
switch get(hObject,'Value')
    case 2
        % load from file
        disp('load from file');
    case 3
        % new decoder with zero weights
        handles.neuron_decoder = new_decoder_gui;
    otherwise
        % None selected
        handles.neuron_decoder = [];
end        
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function neuron_dec_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to neuron_dec_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
