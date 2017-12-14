function varargout = ModuleSelectorGUI(varargin)
% MODULESELECTORGUI MATLAB code for ModuleSelectorGUI.fig
%      MODULESELECTORGUI, by itself, creates a new MODULESELECTORGUI or raises the existing
%      singleton*.
%
%      H = MODULESELECTORGUI returns the handle to a new MODULESELECTORGUI or the handle to
%      the existing singleton*.
%
%      MODULESELECTORGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MODULESELECTORGUI.M with the given input arguments.
%
%      MODULESELECTORGUI('Property','Value',...) creates a new MODULESELECTORGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ModuleSelectorGUI_OpeningFcn gets called.  Anc
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ModuleSelectorGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ModuleSelectorGUI

% Last Modified by GUIDE v2.5 01-Apr-2016 10:43:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ModuleSelectorGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ModuleSelectorGUI_OutputFcn, ...
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


% --- Executes just before ModuleSelectorGUI is made visible.
function ModuleSelectorGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ModuleSelectorGUI (see VARARGIN)

% Choose default command line output for ModuleSelectorGUI
addpath(genpath(pwd()));
handles.output = hObject;
set(handles.figure1,'position',[ 390.6000    1.0000  109.4000   25.7692]);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ModuleSelectorGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ModuleSelectorGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in hCalibrationModule.
function hCalibrationModule_Callback(hObject, eventdata, handles)
CalibrationModule();

% --- Executes on button press in hCameraModule.
function hCameraModule_Callback(hObject, eventdata, handles)
CameraModule();

% --- Executes on button press in hFilterModule.
function hFilterModule_Callback(hObject, eventdata, handles)
FilterWheelModule();

% --- Executes on button press in hMotorModule.
function hMotorModule_Callback(hObject, eventdata, handles)
MotorModule();

% --- Executes on button press in hROIModule.
function hROIModule_Callback(hObject, eventdata, handles)
ROIModule();


% --- Executes on button press in hStimulus.
function hStimulus_Callback(hObject, eventdata, handles)

addpath('E:\Dropbox (MIT)\Code\Waveform Reshaping code\SimpleServer');
StimulusClient();


% --- Executes on button press in hLaserStability.
function hLaserStability_Callback(hObject, eventdata, handles)
DAQModule();


% --- Executes on button press in hAll.
function hAll_Callback(hObject, eventdata, handles)
CameraModule();
CalibrationModule();
FilterWheelModule();
MotorModule();
MonitorCamera();
LaserStimulation();

% --- Executes on button press in hMonitorCam.
function hMonitorCam_Callback(hObject, eventdata, handles)
MonitorCamera();


% --- Executes on button press in hLaserStim.
function hLaserStim_Callback(hObject, eventdata, handles)
LaserStimulation();
