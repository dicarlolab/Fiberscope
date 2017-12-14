function varargout = MotorModule(varargin)
% MOTORMODULE MATLAB code for MotorModule.fig
%      MOTORMODULE, by itself, creates a new MOTORMODULE or raises the existing
%      singleton*.
%
%      H = MOTORMODULE returns the handle to a new MOTORMODULE or the handle to
%      the existing singleton*.
%
%      MOTORMODULE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MOTORMODULE.M with the given input arguments.
%
%      MOTORMODULE('Property','Value',...) creates a new MOTORMODULE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MotorModule_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MotorModule_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MotorModule

% Last Modified by GUIDE v2.5 13-Jan-2017 16:51:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MotorModule_OpeningFcn, ...
                   'gui_OutputFcn',  @MotorModule_OutputFcn, ...
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


% --- Executes just before MotorModule is made visible.
function MotorModule_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MotorModule (see VARARGIN)

% Choose default command line output for MotorModule
handles.output = hObject;
if (~MotorControllerWrapper('IsInitialized'))
    [handles.initialized] = MotorControllerWrapper('Init');
   
    if (~handles.initialized)
        displayMessage(handles,'Cannot connect to motor');
    end
    [~,handles.minStepSizeUm] = MotorControllerWrapper('GetStepSizeMicrons');
    if ismac
          handles.initialized = true;
          return;
    end
    if (~AgilisWrapper('IsInitialized'))
        res = AgilisWrapper('Init');
        if (~res)
            displayMessage(handles,'Cannot connect to agilis motor');
        end
    end
    
 else
    handles.initialized = true;
end
set(handles.hAgilisPCcontrol,'value',1);
set(handles.figure1,'position',[ -140.0000   25.0000  135.6000   55.2308]);
% Update handles structure
guidata(hObject, handles);
Update(handles);
set(handles.figure1,'CloseRequestFcn',{@CloseMotorModule,handles});



function CloseMotorModule(src,evnt,handles)

selection = questdlg('Close Motor Module?',...
    'Close Request Function',...
    'Yes','No','Yes');
switch selection,
    case 'Yes',
        myhandles = guidata(gcbo);
%         if isfield(myhandles,'timer') && strcmp(myhandles.timer.Running,'on')
%             stop(myhandles.timer);
%             Dummy=ISwrapper('GetImageBuffer');
%         end
        if MotorControllerWrapper('IsInitialized')
            MotorControllerWrapper('Release');
        end
        if AgilisWrapper('IsInitialized')
            AgilisWrapper('Release');
        end        
        delete(myhandles.figure1);
    case 'No'
        return
end

function Update(handles)

if handles.initialized 
    [~,relativePosition]= MotorControllerWrapper('GetRelativePosition');
    [~,pos] = MotorControllerWrapper('GetPositionMicrons');
    [~,speed] = MotorControllerWrapper('GetSpeed');
    [~,step] = MotorControllerWrapper('GetStepSizeMicrons');
else
    step = 0;
    pos = 0;
    speed = 0;
    relativePosition = 0;
end
set(handles.StepSize,'String',sprintf('%.02f',step))
set(handles.currPosition,'String',sprintf('%dmm, %.0f um',floor(pos/1e3),(pos/1e3-floor(pos/1e3))*1000))
set(handles.currPositionRelative,'String',sprintf('%.0f um',round(pos-relativePosition)));
set(handles.TargetPos,'String',sprintf('%.04f',pos/1e3))
set(handles.Speed,'String',sprintf('%.01f',speed))
displayMessage(handles,'Connected to motor.');


function displayMessage(handles, msg)
set(handles.messageText,'String',msg);
% UIWAIT makes MotorModule wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MotorModule_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isfield(handles,'output')
varargout{1} = handles.output;
end

% --- Executes on button press in stepDown.
function stepDown_Callback(hObject, eventdata, handles)
[Res,pos] = MotorControllerWrapper('StepDown');
if Res
    set(handles.currPosition,'String',sprintf('%.04f',pos/1e3))
    set(handles.TargetPos,'String',sprintf('%.04f',pos/1e3))
else
   displayMessage(handles,'Timed out.');
end
%Update(handles);



% --- Executes on button press in stepUp.
function stepUp_Callback(hObject, eventdata, handles)
[Res,pos]= MotorControllerWrapper('StepUp');
if (Res)
    set(handles.currPosition,'String',sprintf('%.04f',pos/1e3))
    set(handles.TargetPos,'String',sprintf('%.04f',pos/1e3))
else
   displayMessage(handles,'Timed out.');
end
%Update(handles);


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StepSize_Callback(hObject, eventdata, handles)
newStepSize = str2num(get(hObject,'String'));
set(hObject,'String',sprintf('%.2f',newStepSize));
[Res,pos] = MotorControllerWrapper('SetStepSize',newStepSize);
if (Res)
    displayMessage(handles,sprintf('Set step size to :%.2f',newStepSize));
end


% --- Executes during object creation, after setting all properties.
function StepSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StepSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Speed_Callback(hObject, eventdata, handles)
newSpeed = min(700,max(0.16,str2num(get(hObject,'String'))));
set(hObject,'String',sprintf('%.2f',newSpeed));
[Res,pos] = MotorControllerWrapper('SetSpeed',newSpeed);
if (Res)
    displayMessage(handles,sprintf('Set speed to :%.2f',newSpeed));
end


% --- Executes during object creation, after setting all properties.
function Speed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in moveTo.
function moveTo_Callback(hObject, eventdata, handles)
NewDepth = 1000*str2num(get(handles.TargetPos,'String'));
%[Res,pos] = MotorControllerWrapper('SetSpeed',500);
MotorControllerWrapper('SetAbsolutePositionMicrons',NewDepth);
%Update(handles);



function TargetPos_Callback(hObject, eventdata, handles)
% hObject    handle to TargetPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TargetPos as text
%        str2double(get(hObject,'String')) returns contents of TargetPos as a double


% --- Executes during object creation, after setting all properties.
function TargetPos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TargetPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in motorTimer.
function motorTimer_Callback(hObject, eventdata, handles)
% hObject    handle to motorTimer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of motorTimer


% --- Executes on button press in ResetScreen.
function ResetScreen_Callback(hObject, eventdata, handles)
res = MotorControllerWrapper('ResetScreen');


% --- Executes on button press in ResetPosition.
function ResetPosition_Callback(hObject, eventdata, handles)
MotorControllerWrapper('ResetPosition')
Update(handles);


% --- Executes on button press in MotorTimerToggle.
function MotorTimerToggle_Callback(hObject, eventdata, handles)
% hObject    handle to MotorTimerToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of MotorTimerToggle


% --- Executes on button press in hSave.
function hSave_Callback(hObject, eventdata, handles)
MotorControllerWrapper('StorePosition');


% --- Executes on button press in hRecallPostion.
function hRecallPostion_Callback(hObject, eventdata, handles)
MotorControllerWrapper('RecallPosition');


% --- Executes on button press in hRefreshPosition.
function hRefreshPosition_Callback(hObject, eventdata, handles)
Update(handles);

% --- Executes on button press in hResetRelative.
function hResetRelative_Callback(hObject, eventdata, handles)
MotorControllerWrapper('ResetRelative');

Update(handles);

% --- Executes on button press in hUp50um.
function hUp50um_Callback(hObject, eventdata, handles)
MotorControllerWrapper('SetSpeed',10);
MotorControllerWrapper('SetRelativePositionMicrons',-50);
Update(handles);

% --- Executes on button press in hUp500um.
function hUp500um_Callback(hObject, eventdata, handles)
MotorControllerWrapper('SetSpeed',50);
MotorControllerWrapper('SetRelativePositionMicrons',-500);
Update(handles);

% --- Executes on button press in hUp5mm.
function hUp5mm_Callback(hObject, eventdata, handles)
MotorControllerWrapper('SetSpeed',400);
MotorControllerWrapper('SetRelativePositionMicrons',-5000);
Update(handles);

% --- Executes on button press in hDown50um.
function hDown50um_Callback(hObject, eventdata, handles)
MotorControllerWrapper('SetSpeed',10);
MotorControllerWrapper('SetRelativePositionMicrons',50);
Update(handles);

% --- Executes on button press in hDown500um.
function hDown500um_Callback(hObject, eventdata, handles)
MotorControllerWrapper('SetSpeed',50);
MotorControllerWrapper('SetRelativePositionMicrons',500);
Update(handles);

% --- Executes on button press in hDown5mm.
function hDown5mm_Callback(hObject, eventdata, handles)
MotorControllerWrapper('SetSpeed',400);
MotorControllerWrapper('SetRelativePositionMicrons',5000);
Update(handles);

  


% --- Executes on button press in hAgilisStepDown.
function hAgilisStepDown_Callback(hObject, eventdata, handles)
StepSizeUm = str2num(get(handles.hAgilisStepSizeUm,'String'));


if strcmpi(get(handles.StepUnits,'String'),'µm')
    AgilisWrapper('RelativeMoveUm',StepSizeUm);
    set(handles.currAgilisPosition,'String',sprintf('%.2f um', AgilisWrapper('GetPositionUm')));
else
    AgilisWrapper('RelativeMove',StepSizeUm);
    set(handles.currAgilisPosition,'String',sprintf('%.2f Steps', AgilisWrapper('GetPosition')));
end

% --- Executes on button press in hAgilisStepUp.
function hAgilisStepUp_Callback(hObject, eventdata, handles)
StepSizeUm = str2num(get(handles.hAgilisStepSizeUm,'String'));
if strcmpi(get(handles.StepUnits,'String'),'µm')
    AgilisWrapper('RelativeMoveUm',-StepSizeUm);
    set(handles.currAgilisPosition,'String',sprintf('%.2f um', AgilisWrapper('GetPositionUm')));
else
    AgilisWrapper('RelativeMove',-StepSizeUm);
    set(handles.currAgilisPosition,'String',sprintf('%.2f Steps', AgilisWrapper('GetPosition')));
end


% --- Executes on button press in hAgilisPCcontrol.
function hAgilisPCcontrol_Callback(hObject, eventdata, handles)
if get(hObject,'value')
    AgilisWrapper('PCmode');
else
    AgilisWrapper('ManualMode');
end


function hAgilisStepSizeUm_Callback(hObject, eventdata, handles)
% hObject    handle to hAgilisStepSizeUm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hAgilisStepSizeUm as text
%        str2double(get(hObject,'String')) returns contents of hAgilisStepSizeUm as a double


% --- Executes during object creation, after setting all properties.
function hAgilisStepSizeUm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hAgilisStepSizeUm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hCalibrateAgilis.
function hCalibrateAgilis_Callback(hObject, eventdata, handles)
%AgilisWrapper('CalibrateStepSize');
AlignAgilent();


% --- Executes on button press in StepUnits.
function StepUnits_Callback(hObject, eventdata, handles)
if strcmpi(get(handles.StepUnits,'String'),'µm')
    set(handles.StepUnits,'String','Steps');
else
    set(handles.StepUnits,'String','µm');
end


% --- Executes on button press in hBlockDuringMovement.
function hBlockDuringMovement_Callback(hObject, eventdata, handles)
% hObject    handle to hBlockDuringMovement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hBlockDuringMovement


% --- Executes on button press in hHomeButton.
function hHomeButton_Callback(hObject, eventdata, handles)
 ThorlabsStageControllerWrapper('Home');
