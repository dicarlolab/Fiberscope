function varargout = DAQModule(varargin)
% DAQMODULE MATLAB code for DAQModule.fig
%      DAQMODULE, by itself, creates a new DAQMODULE or raises the existing
%      singleton*.
%
%      H = DAQMODULE returns the handle to a new DAQMODULE or the handle to
%      the existing singleton*.
%
%      DAQMODULE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DAQMODULE.M with the given input arguments.
%
%      DAQMODULE('Property','Value',...) creates a new DAQMODULE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DAQModule_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DAQModule_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DAQModule

% Last Modified by GUIDE v2.5 24-Dec-2015 09:03:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DAQModule_OpeningFcn, ...
                   'gui_OutputFcn',  @DAQModule_OutputFcn, ...
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


% --- Executes just before DAQModule is made visible.
function DAQModule_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DAQModule (see VARARGIN)

% Choose default command line output for DAQModule
handles.output = hObject;
fnDAQusb('Init');
rate = 10;

handles.counter = 1;
handles.values = zeros(1,5000);

handles.timer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period',1/rate);
handles.timer.StartDelay = 0;
handles.timer.UserData = hObject;
handles.timer.TimerFcn = @timerFunc;
handles.hPlot = plot(handles.axes1,[1 10],[1 10]);
set(handles.figure1,'CloseRequestFcn',{@CloseDAQModule,handles});
set(handles.figure1,'position',[629.6000   34.4615  135.2000   15.3846]);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DAQModule wait for user response (see UIRESUME)
% uiwait(handles.figure1);


function CloseDAQModule(src,evnt,handles)
fnDAQusb('Release');
myhandles = guidata(gcbo);
stop(handles.timer);
delete(myhandles.figure1);


function timerFunc(timerObject,A)
handles=guidata(timerObject.UserData);
LASER=1;
PHOTODIODE=0;
channel=LASER;
v = fnDAQusb('ReadAnalog',1,channel,10);

handles.values(handles.counter) = v;
mVvalues = handles.values(1:handles.counter);%/4096*10 * 1000;
if get(handles.mV,'value')
set(handles.hPlot ,'xdata',1:handles.counter,'ydata', mVvalues);
set(handles.hStats,'String', sprintf('%.2f +- %.2f (%.1f%%)',mean(mVvalues),std(mVvalues),std(mVvalues)/mean(mVvalues)*100));
else
    mWvalues = mVtomW(mVvalues);

    set(handles.hPlot ,'xdata',1:handles.counter,'ydata', mWvalues);
    set(handles.hStats,'String', sprintf('%.3f +- %.3f (%.1f%%)',mean(mWvalues),std(mWvalues),std(mWvalues)/mean(mWvalues)*100));
end


handles.counter=handles.counter+1;
if (handles.counter > 50000)
    handles.values = zeros(1,50000);
    handles.counter = 1;
end

guidata(handles.figure1, handles);

function mWvalues = mVtomW(mVvalues)
% dx = 8231-5250;
% dy = 0.44-0.023;
% at 50db setting, the amplification is 2.38*10^5V/A,
% and the responsivity at 473nm is ~1.5A/W
% so, we get 1.5867e+06 V/W
% 1V = (1/ (0.15* 2.38*10^5)) W = 0.028mW
% 10V = 0.28 mW
% offset is 4 mV.

mWvalues = (mVvalues-4)/1000.0* 0.028;

%8231 mV ~= 0.44mW
%5256 mV ~= 0.023mW


% --- Outputs from this function are returned to the command line.
function varargout = DAQModule_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in hStartStop.
function hStartStop_Callback(hObject, eventdata, handles)
if strcmpi(handles.timer.Running,'off')
    start(handles.timer);
else
    stop(handles.timer);
end


% --- Executes on button press in hClear.
function hClear_Callback(hObject, eventdata, handles)
stop(handles.timer);
WaitSecs(0.2);
handles.values = zeros(1,5000);
handles.counter = 1;
guidata(hObject,handles);
start(handles.timer);
