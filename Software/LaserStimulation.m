function varargout = LaserStimulation(varargin)
% LASERSTIMULATION MATLAB code for LaserStimulation.fig
%      LASERSTIMULATION, by itself, creates a new LASERSTIMULATION or raises the existing
%      singleton*.
%
%      H = LASERSTIMULATION returns the handle to a new LASERSTIMULATION or the handle to
%      the existing singleton*.
%
%      LASERSTIMULATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LASERSTIMULATION.M with the given input arguments.
%
%      LASERSTIMULATION('Property','Value',...) creates a new LASERSTIMULATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LaserStimulation_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LaserStimulation_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LaserStimulation

% Last Modified by GUIDE v2.5 01-Apr-2016 10:23:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LaserStimulation_OpeningFcn, ...
                   'gui_OutputFcn',  @LaserStimulation_OutputFcn, ...
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


% --- Executes just before LaserStimulation is made visible.
function LaserStimulation_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LaserStimulation (see VARARGIN)

% Choose default command line output for LaserStimulation
handles.output = hObject;
set(handles.hCont473,'value',1);
set(handles.hCont532,'value',1);

set(handles.hDuration473,'string','1000');
set(handles.hDuration532,'string','1000');

set(handles.hFreq473,'string','10');
set(handles.hFreq532,'string','10');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes LaserStimulation wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LaserStimulation_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in hPulsed473.
function hPulsed473_Callback(hObject, eventdata, handles)
% hObject    handle to hPulsed473 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hPulsed473


% --- Executes on button press in hCont473.
function hCont473_Callback(hObject, eventdata, handles)
% hObject    handle to hCont473 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hCont473



function hDuration473_Callback(hObject, eventdata, handles)
% hObject    handle to hDuration473 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hDuration473 as text
%        str2double(get(hObject,'String')) returns contents of hDuration473 as a double


% --- Executes during object creation, after setting all properties.
function hDuration473_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDuration473 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hFreq473_Callback(hObject, eventdata, handles)
% hObject    handle to hFreq473 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hFreq473 as text
%        str2double(get(hObject,'String')) returns contents of hFreq473 as a double


% --- Executes during object creation, after setting all properties.
function hFreq473_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hFreq473 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hPulsed532.
function hPulsed532_Callback(hObject, eventdata, handles)
% hObject    handle to hPulsed532 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hPulsed532


% --- Executes on button press in hCont532.
function hCont532_Callback(hObject, eventdata, handles)
% hObject    handle to hCont532 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hCont532



function hDuration532_Callback(hObject, eventdata, handles)
% hObject    handle to hDuration532 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hDuration532 as text
%        str2double(get(hObject,'String')) returns contents of hDuration532 as a double


% --- Executes during object creation, after setting all properties.
function hDuration532_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDuration532 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hFreq532_Callback(hObject, eventdata, handles)
% hObject    handle to hFreq532 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hFreq532 as text
%        str2double(get(hObject,'String')) returns contents of hFreq532 as a double


% --- Executes during object creation, after setting all properties.
function hFreq532_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hFreq532 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hStart473.
function hStart473_Callback(hObject, eventdata, handles)
cont = get(handles.hCont473,'value');
Duration = str2num(get(handles.hDuration473,'string'));
Freq = str2num(get(handles.hFreq473,'string'));


randPhase=2*pi*zeros(64,64);
numReferencePixels = 64;
leeBlockSize = 10;
selectedCarrier = 0.200;
carrierRotation = 125/180*pi;
pattern = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize,selectedCarrier, carrierRotation);

if cont
    rate = 1/(2*Duration/1e3);
    cnt = 1;
    ALPuploadAndPlay(pattern,rate,cnt,true);
else
    cnt = ceil((Duration/1e3)/(1/(Freq/2)));
    ALPuploadAndPlay(pattern,Freq/2,cnt,true);
end
ALPuploadAndPlay(zeros(768,1024)>0,22000,1,true);


% --- Executes on button press in hStart532.
function hStart532_Callback(hObject, eventdata, handles)
cont = get(handles.hCont532,'value');
Duration = str2num(get(handles.hDuration532,'string'));
Freq = str2num(get(handles.hFreq532,'string'));
pattern = zeros(768,1024)>0;

randPhase=2*pi*zeros(64,64);
numReferencePixels = 64;
leeBlockSize = 10;
selectedCarrier = 0.200;
carrierRotation = 168/180*pi;
pattern = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize,selectedCarrier, carrierRotation);


if cont
    rate = 1/(2*Duration/1e3);
    cnt = 1;
    ALPuploadAndPlay(pattern,rate,cnt,true);
else
    cnt = ceil((Duration/1e3)/(1/(Freq/2)));
    ALPuploadAndPlay(pattern,Freq/2,cnt,true);
end
ALPuploadAndPlay(zeros(768,1024)>0,22000,1,true);
