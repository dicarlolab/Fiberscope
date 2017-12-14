function varargout = FilterWheelModule(varargin)
% FILTERWHEELMODULE MATLAB code for FilterWheelModule.fig
%      FILTERWHEELMODULE, by itself, creates a new FILTERWHEELMODULE or raises the existing
%      singleton*.
%
%      H = FILTERWHEELMODULE returns the handle to a new FILTERWHEELMODULE or the handle to
%      the existing singleton*.
%
%      FILTERWHEELMODULE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FILTERWHEELMODULE.M with the given input arguments.
%
%      FILTERWHEELMODULE('Property','Value',...) creates a new FILTERWHEELMODULE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FilterWheelModule_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FilterWheelModule_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FilterWheelModule

% Last Modified by GUIDE v2.5 02-Dec-2015 10:53:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FilterWheelModule_OpeningFcn, ...
                   'gui_OutputFcn',  @FilterWheelModule_OutputFcn, ...
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


% --- Executes just before FilterWheelModule is made visible.
function FilterWheelModule_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FilterWheelModule (see VARARGIN)

% Choose default command line output for FilterWheelModule
handles.output = hObject;
handles.varargin = varargin;
set(handles.figure1,'position',[ -239.0000   57.4615   89.6000   23.0769]);


if (~FilterWheelWrapper('IsInitialized'))
    [handles.initialized, X] = FilterWheelWrapper('Init');
   handles.currentPositions = mod(X, 6);
    if (~handles.initialized)
        displayMessage(handles,'Cannot connect to filter wheel module');
    else
        displayMessage(handles, 'Connected To Filter Wheel');    
    end
else
    handles.initialized = true;
    [Res,X1]= FilterWheelWrapper('GetFilterWheelPosition',1);
    [Res,X2]= FilterWheelWrapper('GetFilterWheelPosition',2);
    
    handles.currentPositions = [mod(X1, 6),mod(X2, 6)];
    displayMessage(handles, 'Connected To Filter Wheel');
end

set(handles.pos0_473nm,'String', FilterWheelWrapper('GetPositionName',[1,0]),'Value', handles.currentPositions(1) == 0);
set(handles.pos1_473nm,'String', FilterWheelWrapper('GetPositionName',[1,1]),'Value', handles.currentPositions(1) == 1);
set(handles.pos2_473nm,'String', FilterWheelWrapper('GetPositionName',[1,2]),'Value', handles.currentPositions(1) == 2);
set(handles.pos3_473nm,'String', FilterWheelWrapper('GetPositionName',[1,3]),'Value', handles.currentPositions(1) == 3);
set(handles.pos4_473nm,'String', FilterWheelWrapper('GetPositionName',[1,4]),'Value', handles.currentPositions(1) == 4);
set(handles.pos5_473nm,'String', FilterWheelWrapper('GetPositionName',[1,5]),'Value', handles.currentPositions(1) == 5);

set(handles.pos0_532nm,'String', FilterWheelWrapper('GetPositionName',[2,0]),'Value', handles.currentPositions(2) == 0);
set(handles.pos1_532nm,'String', FilterWheelWrapper('GetPositionName',[2,1]),'Value', handles.currentPositions(2) == 1);
set(handles.pos2_532nm,'String', FilterWheelWrapper('GetPositionName',[2,2]),'Value', handles.currentPositions(2) == 2);
set(handles.pos3_532nm,'String', FilterWheelWrapper('GetPositionName',[2,3]),'Value', handles.currentPositions(2) == 3);
set(handles.pos4_532nm,'String', FilterWheelWrapper('GetPositionName',[2,4]),'Value', handles.currentPositions(2) == 4);
set(handles.pos5_532nm,'String', FilterWheelWrapper('GetPositionName',[2,5]),'Value', handles.currentPositions(2) == 5);


% Update handles structure
guidata(hObject, handles);
set(handles.figure1,'CloseRequestFcn',{@CloseFilterWheelModule,handles});


if ~isempty(varargin) && strcmp(varargin{1},'SetNaturalDensity') 
    selectedFilterWheel= varargin{2}(1);
    selectedND= varargin{2}(2);
    [Res, filterPos]=FilterWheelWrapper('SetNaturalDensity',[selectedFilterWheel,selectedND]);
    if selectedFilterWheel == 1
    switch filterPos
        case 0
            set(handles.pos0_473nm,'value',1);
        case 1
            set(handles.pos1_473nm,'value',1);
        case 2
            set(handles.pos2_473nm,'value',1);
        case 3
            set(handles.pos3_473nm,'value',1);
        case 4
            set(handles.pos4_473nm,'value',1);
        case 5
            set(handles.pos5_473nm,'value',1);
    end
    else
    switch filterPos
        case 0
            set(handles.pos0_532nm,'value',1);
        case 1
            set(handles.pos1_532nm,'value',1);
        case 2
            set(handles.pos2_532nm,'value',1);
        case 3
            set(handles.pos3_532nm,'value',1);
        case 4
            set(handles.pos4_532nm,'value',1);
        case 5
            set(handles.pos5_532nm,'value',1);
    end
        
    end
    
end

function CloseFilterWheelModule(src,evnt,handles)

selection = questdlg('Close Filter Wheel Module?',...
    'Close Request Function',...
    'Yes','No','Yes');
switch selection,
    case 'Yes',
        myhandles = guidata(gcbo);
        if FilterWheelWrapper('IsInitialized')
            FilterWheelWrapper('Release');
        end
        delete(myhandles.figure1);
    case 'No'
        return
end


% --- Outputs from this function are returned to the command line.
function varargout = FilterWheelModule_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ~isempty(handles.varargin) 
    if length(handles.varargin) >= 1 && ischar(handles.varargin{1}) && strcmp(handles.varargin{1},'IsInitialized') 
        varargout{1} = handles.initialized;
    else
        varargout{1} = [];
    end
else
    varargout{1} = handles.output;
end


function displayMessage(handles, msg)
set(handles.messageText,'String',msg);


% --- Executes when selected object is changed in ActiveWheel473nm.
function ActiveWheel473nm_SelectionChangeFcn(hObject, eventdata, handles)
switch eventdata.NewValue
    case handles.pos0_473nm
        handles.currentPositions(1) = 0;
    case handles.pos1_473nm
        handles.currentPositions(1) = 1;
    case handles.pos2_473nm
        handles.currentPositions(1) = 2;
    case handles.pos3_473nm
        handles.currentPositions(1) = 3;
    case handles.pos4_473nm
        handles.currentPositions(1) = 4;
    case handles.pos5_473nm
        handles.currentPositions(1) = 5;
end
FilterWheelWrapper('SetFilterWheelPosition',[1, handles.currentPositions(1)]);
guidata(hObject,handles);




% --- Executes on button press in hShutterGreen.
function hShutterGreen_Callback(hObject, eventdata, handles)
[~,state]=FilterWheelWrapper('GetShutterState');
if (~state(2))
    FilterWheelWrapper('ShutterOFF',2);
    set(handles.hShutterGreen,'String','532nm Shutter is OFF');
else
    FilterWheelWrapper('ShutterON',2);
    set(handles.hShutterGreen,'String','532nm Shutter is ON');
end


% --- Executes on button press in hShutterBlue.
function hShutterBlue_Callback(hObject, eventdata, handles)
[~,state]=FilterWheelWrapper('GetShutterState');
if (~state(1))
    FilterWheelWrapper('ShutterOFF',1);
    set(handles.hShutterBlue,'String','473nm Shutter is OFF');
else
    FilterWheelWrapper('ShutterON',1);
    set(handles.hShutterBlue,'String','473nm Shutter is ON');
end

    


% --- Executes on button press in StepRight532nm.
function StepRight532nm_Callback(hObject, eventdata, handles)
FilterWheelWrapper('StepRight',2);

% --- Executes on button press in StepLeft532nm.
function StepLeft532nm_Callback(hObject, eventdata, handles)
FilterWheelWrapper('StepLeft',1);


% --- Executes on button press in StepRight473nm.
function StepRight473nm_Callback(hObject, eventdata, handles)
FilterWheelWrapper('StepRight',1);

% --- Executes on button press in StepLeft473nm.
function StepLeft473nm_Callback(hObject, eventdata, handles)
FilterWheelWrapper('StepLeft',1);

% --- Executes when selected object is changed in ActiveWheel532nm.
function ActiveWheel532nm_SelectionChangedFcn(hObject, eventdata, handles)
switch eventdata.NewValue
    case handles.pos0_532nm
        handles.currentPositions(2) = 0;
    case handles.pos1_532nm
        handles.currentPositions(2) = 1;
    case handles.pos2_532nm
        handles.currentPositions(2) = 2;
    case handles.pos3_532nm
        handles.currentPositions(2) = 3;
    case handles.pos4_532nm
        handles.currentPositions(2) = 4;
    case handles.pos5_532nm
        handles.currentPositions(2) = 5;
end
FilterWheelWrapper('SetFilterWheelPosition',[2, handles.currentPositions(2)]);
guidata(hObject,handles);

