function varargout = AlignALP(varargin)
% ALIGNALP MATLAB code for AlignALP.fig
%      ALIGNALP, by itself, creates a new ALIGNALP or raises the existing
%      singleton*.
%
%      H = ALIGNALP returns the handle to a new ALIGNALP or the handle to
%      the existing singleton*.
%
%      ALIGNALP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ALIGNALP.M with the given input arguments.
%
%      ALIGNALP('Property','Value',...) creates a new ALIGNALP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AlignALP_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AlignALP_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AlignALP

% Last Modified by GUIDE v2.5 29-Nov-2016 15:13:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AlignALP_OpeningFcn, ...
                   'gui_OutputFcn',  @AlignALP_OutputFcn, ...
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


% --- Executes just before AlignALP is made visible.
function AlignALP_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AlignALP (see VARARGIN)

% Choose default command line output for AlignALP
handles.output = hObject;
handles.rotation = 50;
handles.freq= 0.15;
% Update handles structure

guidata(hObject, handles);
updateUI(handles);
% UIWAIT makes AlignALP wait for user response (see UIRESUME)
% uiwait(handles.figure1);


function updateUI(handles)
set(handles.hCarrier,'string',num2str(handles.freq));
set(handles.hRotation,'string',num2str(handles.rotation));

randPhase=2*pi*zeros(64,64);
handles.dmd.leeBlockSize = 10;
handles.dmd.hadamardSize = 64;
numReferencePixels = 64;
leeBlockSize = 10;
selectedCarrier =handles.freq;
carrierRotation = handles.rotation/ 180*pi;
interferenceBasisPatterns = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize,selectedCarrier, carrierRotation);
ALPuploadAndPlay(0,interferenceBasisPatterns,22000,1);


% --- Outputs from this function are returned to the command line.
function varargout = AlignALP_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in hRotNeg.
function hRotNeg_Callback(hObject, eventdata, handles)
% hObject    handle to hRotNeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.rotation = handles.rotation - 2;
guidata(hObject, handles);
updateUI(handles)

% --- Executes on button press in hRotPos.
function hRotPos_Callback(hObject, eventdata, handles)
% hObject    handle to hRotPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.rotation = handles.rotation + 2;
guidata(hObject, handles);
updateUI(handles)


% --- Executes on button press in hCarPos.
function hCarPos_Callback(hObject, eventdata, handles)
% hObject    handle to hCarPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.freq = handles.freq + 0.01;
guidata(hObject, handles);
updateUI(handles)


% --- Executes on button press in hCarNeg.
function hCarNeg_Callback(hObject, eventdata, handles)
% hObject    handle to hCarNeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.freq = handles.freq - 0.01;
guidata(hObject, handles);
updateUI(handles)

