function varargout = new_decoder_gui(varargin)
% NEW_DECODER_GUI MATLAB code for new_decoder_gui.fig
%      NEW_DECODER_GUI, by itself, creates a new NEW_DECODER_GUI or raises the existing
%      singleton*.
%
%      H = NEW_DECODER_GUI returns the handle to a new NEW_DECODER_GUI or the handle to
%      the existing singleton*.
%
%      NEW_DECODER_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NEW_DECODER_GUI.M with the given input arguments.
%
%      NEW_DECODER_GUI('Property','Value',...) creates a new NEW_DECODER_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before new_decoder_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to new_decoder_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help new_decoder_gui

% Last Modified by GUIDE v2.5 24-Jan-2014 12:30:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @new_decoder_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @new_decoder_gui_OutputFcn, ...
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


% --- Executes just before new_decoder_gui is made visible.
function new_decoder_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to new_decoder_gui (see VARARGIN)

% Choose default command line output for new_decoder_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes new_decoder_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = new_decoder_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

max_init_w = str2double(get(handles.init_max_value_txtbox, 'String'));             
n_in = str2double(get(handles.num_inputs_txtbox,'String'));
n_out= str2double(get(handles.num_outputs_txtbox,'String'));
n_lags= str2double(get(handles.num_lags_txtbox,'String'));
binsize= str2double(get(handles.binsize_txtbox,'String'));
H = max_init_w*(randn(1 + n_in*n_lags, n_out)-0.5);

% create new decoder
new_decoder = struct(...
    'P'        , [] ,...
    'neuronIDs', [(1:n_in)' zeros(n_in,1)],...
    'binsize'  , binsize,...
    'fillen'   , binsize*n_lag,...
    'numlags'  , n_lags,...
    'H'        , H);

varargout = {new_decoder};
close(handles.figure1);
drawnow;

function init_max_value_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to init_max_value_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of init_max_value_txtbox as text
%        str2double(get(hObject,'String')) returns contents of init_max_value_txtbox as a double


% --- Executes during object creation, after setting all properties.
function init_max_value_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to init_max_value_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function init_value_high_Callback(hObject, eventdata, handles)
% hObject    handle to init_value_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of init_value_high as text
%        str2double(get(hObject,'String')) returns contents of init_value_high as a double


% --- Executes during object creation, after setting all properties.
function init_value_high_CreateFcn(hObject, eventdata, handles)
% hObject    handle to init_value_high (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function num_inputs_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to num_inputs_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_inputs_txtbox as text
%        str2double(get(hObject,'String')) returns contents of num_inputs_txtbox as a double


% --- Executes during object creation, after setting all properties.
function num_inputs_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_inputs_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function num_outputs_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to num_outputs_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_outputs_txtbox as text
%        str2double(get(hObject,'String')) returns contents of num_outputs_txtbox as a double


% --- Executes during object creation, after setting all properties.
function num_outputs_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_outputs_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function num_lags_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to num_lags_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_lags_txtbox as text
%        str2double(get(hObject,'String')) returns contents of num_lags_txtbox as a double


% --- Executes during object creation, after setting all properties.
function num_lags_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_lags_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in OK_button.
function OK_button_Callback(hObject, eventdata, handles)
% hObject    handle to OK_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(eventdata)
    if strcmp(eventdata.Key,'return')
        uiresume(handles.figure1);
    end
else
    uiresume(handles.figure1);
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over init_max_value_txtbox.
function init_max_value_txtbox_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to init_max_value_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function binsize_txtbox_Callback(hObject, eventdata, handles)
% hObject    handle to binsize_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of binsize_txtbox as text
%        str2double(get(hObject,'String')) returns contents of binsize_txtbox as a double


% --- Executes during object creation, after setting all properties.
function binsize_txtbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to binsize_txtbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function bin_size_label_Callback(hObject, eventdata, handles)
% hObject    handle to bin_size_label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bin_size_label as text
%        str2double(get(hObject,'String')) returns contents of bin_size_label as a double


% --- Executes during object creation, after setting all properties.
function bin_size_label_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bin_size_label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
