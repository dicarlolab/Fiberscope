function varargout = LEDdriverGUI(varargin)
% LEDDRIVERGUI MATLAB code for LEDdriverGUI.fig
%      LEDDRIVERGUI, by itself, creates a new LEDDRIVERGUI or raises the existing
%      singleton*.
%
%      H = LEDDRIVERGUI returns the handle to a new LEDDRIVERGUI or the handle to
%      the existing singleton*.
%
%      LEDDRIVERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LEDDRIVERGUI.M with the given input arguments.
%
%      LEDDRIVERGUI('Property','Value',...) creates a new LEDDRIVERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LEDdriverGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LEDdriverGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LEDdriverGUI

% Last Modified by GUIDE v2.5 20-Jun-2016 10:48:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LEDdriverGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @LEDdriverGUI_OutputFcn, ...
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


% --- Executes just before LEDdriverGUI is made visible.
function LEDdriverGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LEDdriverGUI (see VARARGIN)

% Choose default command line output for LEDdriverGUI
handles.output = hObject;
LEDdriverWrapper('Init');

intensity = str2num(get(handles.hIntensity1,'string'));
LEDdriverWrapper('SetIntensity',[0 intensity]);

count = str2num(get(handles.hNumPulses1,'string'));
LEDdriverWrapper('SetNumPulses',[0 count]);

duration = str2num(get(handles.hDurationON1,'string'));
LEDdriverWrapper('SetDurationOn',[0 duration]);

duration = str2num(get(handles.hDurationOFF1,'string'));
LEDdriverWrapper('SetDurationOff',[0 duration]);

% Update handles structure
guidata(hObject, handles);
set(handles.figure1,'CloseRequestFcn',{@CloseModule,handles});

% UIWAIT makes LEDdriverGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function CloseModule(src,evnt,handles)

selection = questdlg('Close LED Driver Module?',...
    'Close Request Function',...
    'Yes','No','Yes');
switch selection,
    case 'Yes',
        myhandles = guidata(gcbo);

       
            LEDdriverWrapper('Release');
       
           
        delete(myhandles.figure1);
    case 'No'
        return
end


% --- Outputs from this function are returned to the command line.
function varargout = LEDdriverGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in hTrigger1.
function hTrigger1_Callback(hObject, eventdata, handles)
LEDdriverWrapper('SimulateTrigger',0);


% --- Executes on button press in hTurnON1.
function hTurnON1_Callback(hObject, eventdata, handles)
LEDdriverWrapper('TurnOn',0);

% --- Executes on button press in hTurnOFF1.
function hTurnOFF1_Callback(hObject, eventdata, handles)
LEDdriverWrapper('TurnOff',0);


function hDurationON1_Callback(hObject, eventdata, handles)
duration = str2num(get(handles.hDurationON1,'string'));
LEDdriverWrapper('SetDurationOn',[0 duration]);

% --- Executes during object creation, after setting all properties.
function hDurationON1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDurationON1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hDurationOFF1_Callback(hObject, eventdata, handles)
duration = str2num(get(handles.hDurationOFF1,'string'));
LEDdriverWrapper('SetDurationOff',[0 duration]);

% --- Executes during object creation, after setting all properties.
function hDurationOFF1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDurationOFF1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hIntensity1_Callback(hObject, eventdata, handles)
intensity = str2num(get(handles.hIntensity1,'string'));
LEDdriverWrapper('SetIntensity',[0 intensity]);


% --- Executes during object creation, after setting all properties.
function hIntensity1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hIntensity1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hNumPulses1_Callback(hObject, eventdata, handles)
count = str2num(get(handles.hNumPulses1,'string'));
LEDdriverWrapper('SetNumPulses',[0 count]);


% --- Executes during object creation, after setting all properties.
function hNumPulses1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hNumPulses1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
