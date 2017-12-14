function varargout = MonitorCamera(varargin)
% MONITORCAMERA MATLAB code for MonitorCamera.fig
%      MONITORCAMERA, by itself, creates a new MONITORCAMERA or raises the existing
%      singleton*.
%
%      H = MONITORCAMERA returns the handle to a new MONITORCAMERA or the handle to
%      the existing singleton*.
%
%      MONITORCAMERA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MONITORCAMERA.M with the given input arguments.
%
%      MONITORCAMERA('Property','Value',...) creates a new MONITORCAMERA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MonitorCamera_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MonitorCamera_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MonitorCamera

% Last Modified by GUIDE v2.5 29-Mar-2016 11:03:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MonitorCamera_OpeningFcn, ...
                   'gui_OutputFcn',  @MonitorCamera_OutputFcn, ...
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


% --- Executes just before MonitorCamera is made visible.
function MonitorCamera_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MonitorCamera (see VARARGIN)

% Choose default command line output for MonitorCamera
handles.output = hObject;

tmp = imaqhwinfo;
if isempty(tmp.InstalledAdaptors)
    return
end
% Create a video input object.
vid = videoinput('winvideo',1);

% Create a figure window. This example turns off the default
% toolbar, menubar, and figure numbering.
% 
 set(handles.figure1,'Toolbar','none',...
        'Menubar', 'none',...
        'NumberTitle','Off',...
        'Name','My Preview Window');
%set(handles.figure1,'toolbar',

% Create the image object in which you want to display 
% the video preview data. Make the size of the image
% object match the dimensions of the video frames.

vidRes = [1280,780];
nBands = 3;
hImage = image( zeros(vidRes(2), vidRes(1), nBands) ,'parent',handles.axes1);

% Display the video data in your GUI.

preview(vid, hImage);
% Update handles structure
guidata(hObject, handles);


preview(vid,hImage);

% --- Outputs from this function are returned to the command line.
function varargout = MonitorCamera_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
