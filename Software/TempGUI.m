function varargout = TempGUI(varargin)
% TEMPGUI MATLAB code for TempGUI.fig
%      TEMPGUI, by itself, creates a new TEMPGUI or raises the existing
%      singleton*.
%
%      H = TEMPGUI returns the handle to a new TEMPGUI or the handle to
%      the existing singleton*.
%
%      TEMPGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEMPGUI.M with the given input arguments.
%
%      TEMPGUI('Property','Value',...) creates a new TEMPGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TempGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TempGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TempGUI

% Last Modified by GUIDE v2.5 21-Mar-2017 14:31:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TempGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @TempGUI_OutputFcn, ...
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


% --- Executes just before TempGUI is made visible.
function TempGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TempGUI (see VARARGIN)

% Choose default command line output for TempGUI
handles.output = hObject;
TemperatureSensorWrapper('Release');
if (~TemperatureSensorWrapper('IsInitialized'))
    TemperatureSensorWrapper('Init');
end

handles.timer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period',1,'TimerFcn',@RunTimerCallback);
handles.timer.UserData = handles;
% Update handles structure
handles.t0 = GetSecs();
setappdata(handles.figure1,'counter',1);
setappdata(handles.figure1,'measurements',zeros(0,2));
guidata(hObject, handles);
start(handles.timer);
% UIWAIT makes TempGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


function RunTimerCallback(timr,b)
handles = timr.UserData;
t = TemperatureSensorWrapper('GetTemperature');
if (~isempty(t) && ~isnan(mean(t)) )
    set(handles.hTempLabel,'String', sprintf('%.2f',nanmean(t)));
    counter =getappdata(handles.figure1,'counter'); 
    measurements = getappdata(handles.figure1,'measurements');
    measurements(counter,:) = [GetSecs(), nanmean(t)];    
    counter=counter+1;
    plot(handles.axes1,measurements(:,1)-measurements(1,1), measurements(:,2),'k');
    setappdata(handles.figure1,'counter',counter); 
    setappdata(handles.figure1,'measurements',measurements);
end

% --- Outputs from this function are returned to the command line.
function varargout = TempGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
