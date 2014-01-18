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

% Last Modified by GUIDE v2.5 13-Jan-2014 18:12:45

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


% --- Executes on button press in cerebus_radio.
function cerebus_radio_Callback(hObject, eventdata, handles)
% hObject    handle to cerebus_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of cerebus_radio
    set(handles.input_file_txtbox,'enable','off');
    set(handles.input_file_browse_button,'enable','off');

% --- Executes on button press in off_file_radio.
function off_file_radio_Callback(hObject, eventdata, handles)
% hObject    handle to off_file_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of off_file_radio
    set(handles.input_file_txtbox,'enable','on');
    set(handles.input_file_browse_button,'enable','on');

% --- Executes on button press in input_file_browse_button.
function input_file_browse_button_Callback(hObject, eventdata, handles)
% hObject    handle to input_file_browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



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


% --- Executes on button press in save_output_cbx.
function save_output_cbx_Callback(hObject, eventdata, handles)
% hObject    handle to save_output_cbx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of save_output_cbx


% --- Executes on button press in xpc_radio.
function xpc_radio_Callback(hObject, eventdata, handles)
% hObject    handle to xpc_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of xpc_radio


% --- Executes on button press in stimulator_radio.
function stimulator_radio_Callback(hObject, eventdata, handles)
% hObject    handle to stimulator_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of stimulator_radio


% --- Executes on button press in no_outputs_radio.
function no_outputs_radio_Callback(hObject, eventdata, handles)
% hObject    handle to no_outputs_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of no_outputs_radio



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


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in adapt_enable_cbx.
function adapt_enable_cbx_Callback(hObject, eventdata, handles)
% hObject    handle to adapt_enable_cbx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of adapt_enable_cbx


% --- Executes on button press in emg_cascade_button.
function emg_cascade_button_Callback(hObject, eventdata, handles)
% hObject    handle to emg_cascade_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of emg_cascade_button


% --- Executes on button press in direct_mode_button.
function direct_mode_button_Callback(hObject, eventdata, handles)
% hObject    handle to direct_mode_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of direct_mode_button
