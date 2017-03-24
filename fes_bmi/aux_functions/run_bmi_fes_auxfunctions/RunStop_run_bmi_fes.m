function varargout = RunStop_run_bmi_fes(varargin)
% RunStop_run_bmi_fes MATLAB code for RunStop_run_bmi_fes.fig
%      RunStop_run_bmi_fes, by itself, creates a new RunStop_run_bmi_fes or raises the existing
%      singleton*.
%
%      H = RunStop_run_bmi_fes returns the handle to a new RunStop_run_bmi_fes or the handle to
%      the existing singleton*.
%
%      RunStop_run_bmi_fes('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RunStop_run_bmi_fes.M with the given input arguments.
%
%      RunStop_run_bmi_fes('Property','Value',...) creates a new RunStop_run_bmi_fes or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RunStop_run_bmi_fes_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RunStop_run_bmi_fes_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RunStop_run_bmi_fes

% Last Modified by GUIDE v2.5 24-Mar-2017 11:38:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;

gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RunStop_run_bmi_fes_OpeningFcn, ...
                   'gui_OutputFcn',  @RunStop_run_bmi_fes_OutputFcn, ...
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

% --- Executes just before RunStop_run_bmi_fes is made visible.
function RunStop_run_bmi_fes_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RunStop_run_bmi_fes (see VARARGIN)

% Choose default command line output for RunStop_run_bmi_fes
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
initialize_gui(hObject, handles);

% UIWAIT makes RunStop_run_bmi_fes wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = RunStop_run_bmi_fes_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = hObject;

% --------------------------------------------------------------------
function initialize_gui(hObject, handles)
% If the metricdata field is present and the pause flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to pause the data.
% Set up data structure

data = guihandles(hObject);
data.Stop = 0;
data.Pause = 0;
guidata(hObject,handles);
guidata(hObject,data);



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over stop.
function stop_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)





% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pause.
function pause_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in stop.
function stop_Callback(hObject, eventdata, handles)
% hObject    handle to stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(hObject);
data.Stop = 1;
guidata(hObject,data);

% --- Executes on button press in pause.
function pause_Callback(hObject, eventdata, handles)
% hObject    handle to pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(hObject);
data.Pause = 1;
guidata(hObject,data);
