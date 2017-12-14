function varargout = CameraModule(varargin)
% CAMERAMODULE MATLAB code for CameraModule.fig
%      CAMERAMODULE, by itself, creates a new CAMERAMODULE or raises the existing
%      singleton*.
%
%      H = CAMERAMODULE returns the handle to a new CAMERAMODULE or the handle to
%      the existing singleton*.
%
%      CAMERAMODULE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CAMERAMODULE.M with the given input arguments.
%
%      CAMERAMODULE('Property','Value',...) creates a new CAMERAMODULE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CameraModule_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CameraModule_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CameraModule

% Last Modified by GUIDE v2.5 08-Jul-2016 16:05:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CameraModule_OpeningFcn, ...
                   'gui_OutputFcn',  @CameraModule_OutputFcn, ...
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

function SetExposure(hObject,handles,exposure,setCamera)
[~,indx]=min(abs(handles.ExposurePresets-1/exposure));
set(handles.ExposureSlider,'min',1,'max',length(handles.ExposurePresets),'value',indx);
if (setCamera)
    fprintf('Setting Exposure to %.5f\n',1.0/exposure);
    XimeaWrapper('SetExposure',exposure);
end
set(handles.ExposureEdit,'String', num2str(1/exposure));

maxRate = 10;
if strcmp(get(handles.timer,'Running'),'on')
    resetTimer = true;
else
    resetTimer = false;
end
if (resetTimer)
    stop(handles.timer);
end
if 1/exposure > maxRate
    set(handles.timer,'Period', 1/maxRate)
else
    set(handles.timer,'Period', exposure)
end
if (resetTimer)
    start(handles.timer);
end



function SetGain(hObject,handles,gain,setCamera)
[~,indx]=min(abs(handles.GainPresets-gain));
set(handles.gainSlider,'min',1,'max',length(handles.GainPresets),'value',indx);
if (setCamera)
    fprintf('Setting Gain to %.5f\n',gain);
    XimeaWrapper('SetGain',gain);
end
set(handles.GainEdit,'String', num2str(gain));


function CloseCameraModule(src,evnt,handles)

selection = questdlg('Close Camera Module?',...
    'Close Request Function',...
    'Yes','No','Yes');
switch selection,
    case 'Yes',
        myhandles = guidata(gcbo);
        if isfield(myhandles,'timer') && strcmp(myhandles.timer.Running,'on')
            stop(myhandles.timer);
            Dummy=XimeaWrapper('GetImageBuffer');
        end
        if XimeaWrapper('IsInitialized')
            XimeaWrapper('Release');
        end
        delete(myhandles.figure1)
    case 'No'
        return
end

% --- Executes just before CameraModule is made visible.
function CameraModule_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CameraModule (see VARARGIN)

% strDropBoxFolder = 'C:\Users\shayo\Dropbox';
% addpath([strDropBoxFolder,'\Code\Waveform Reshaping code\MEX\x64']);
set(handles.figure1,'position',[  284.2000   38.0769   92.2000   38.3077]);

if ~isfield(handles,'initialized')
    addpath(genpath(pwd()));
    InitGUI(hObject, eventdata, handles,varargin);
end

if ~isempty(varargin) && strcmp(varargin{1},'StopLiveView') 
    if isfield(handles,'timer') && strcmp(get(handles.timer,'Running'),'on')
        stopLiveView(handles);
        return;
    end
end



function InitGUI(hObject, eventdata, handles,varargin)
handles.output = hObject;
% Update handles structure
%set( handles.figure1, 'toolbar', 'figure' )
set(handles.hResolutionPopup,'String',{'Cropped 128x128','Full 1280x1024'},'value',1);
[X,Y,Res1,Res2]=GetCameraParams();
Z = zeros(Res1,Res2);
handles.hImage = image(Z,'parent',handles.axes1);
handles.acquiring = false;
handles.mousePos = [1,1];
handles.mouseDownPos = [1,1];
handles.ExposurePresets = [34482.7578,30000,20000,10000,9000,8000,7000,6000,5000,4000,3500,3000,2500,2000,1500,1000,800,500,200,100,50,20,10,1];
handles.GainPresets = 0:32;
handles.locateFiber = false;
hold(handles.axes1,'on');
set(handles.axes3,'visible','off');
set(handles.figure1,'visible','on')
set(handles.figure1, 'Colormap', gray(64));
set(handles.axes1,'visible','off');
set(handles.stretchRange,'value',0);
set (handles.figure1, 'WindowButtonMotionFcn', {@mouseMove, handles.figure1});
set (handles.figure1, 'WindowButtonDownFcn', {@mouseDown, handles.figure1});
set(handles.hImage,'CDataMapping','scaled');
set(handles.axes1,'Clim',[0 1024]);
hold(handles.axes1,'on');
handles.hMarker = plot(handles.axes1,Res1/2,Res2/2,'w+','visible','on');

% plot(handles.axes1, Res1/2,Res2/2,'w+');
rate = 10;
handles.timer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period',1/rate);
handles.timer.StartDelay = 0;
handles.timer.UserData = hObject;
handles.timer.TimerFcn = @timerFunc;
handles.varargin = varargin;
guidata(hObject, handles);
handles.initialized =InitCameraModule(hObject, handles);
if ~handles.initialized
    set(handles.statusText,'String','Failed to initialize camera!');
else
    set(handles.statusText,'String','Camera initialized!');
end
guidata(hObject, handles);
set(handles.figure1,'CloseRequestFcn',{@CloseCameraModule,handles});

function mouseMove(obj,A,fig)
handles = guidata(fig);
C = get (handles.axes1, 'CurrentPoint');
x=C(1,1);
y=C(1,2);


if handles.locateFiber
   set(handles.hMarker,'xdata',floor(x/64)*64,'ydata',floor(y/64)*64,'visible','on');
   %plot(handles.axes1,ceil(x/64)*64 - 64,ceil(y/64)*64 - 64,'g+');
else
    set(handles.hMarker,'visible','off');
end

handles.mousePos =[x,y];
guidata(fig, handles);

% 
% function mouseDown(obj,A,fig)
% global g_stats
% handles = guidata(fig);
% C = get (handles.axes1, 'CurrentPoint');
% [OffsetX, OffsetY, Res] = GetCameraParams();
% 
% if strcmp(get(fig,'selectionType'),'alt')
%     g_stats.counter = 1;
% else
%     x=C(1,1);
%     y=C(1,2);
%     if x >= 1 && y >= 1 && x <= Res && y <= Res
%     
%     g_stats.counter = 1;
%     handles.mouseDownPos =[x,y];
%     end
% end
% guidata(fig, handles);



function ok=InitCameraModule(hObject, handles)
ok=true;
[OffsetX, OffsetY, ResX,ResY] = GetCameraParams();

if (~XimeaWrapper('IsInitialized'))
    % Initialize Camera
   Hcam=XimeaWrapper('InitWithResolutionOffset',OffsetX,OffsetY,ResX,ResY);

    if (Hcam)
        fprintf('Initialized CAM successfuly\n');
    else
        fprintf('Failed to initialize camera\n');
        ok=false;
        return;
    end
else
    fprintf('Initialized CAM successfuly (already initialized)\n');
end
   
expo=XimeaWrapper('GetExposure');
gain=XimeaWrapper('GetGain');
fprintf('Initial exposure: %.2f, gain :%.2f\n',1/expo,gain);
SetExposure(hObject,handles,expo,false);
SetGain(hObject,handles,gain,false);



% --- Outputs from this function are returned to the command line.
function varargout = CameraModule_OutputFcn(hObject, eventdata, handles) 
if ~isempty(handles.varargin) 
    if length(handles.varargin) >= 1 && ~isempty(handles.varargin{1}) && ischar(handles.varargin{1}{1}) && strcmp(handles.varargin{1},'IsInitialized') 
        varargout{1} = handles.initialized;
    else
        varargout{1} = [];
    end
else
    varargout{1} = handles.output;
end


% --- Executes on slider movement.
function gainSlider_Callback(hObject, eventdata, handles)
scrollerIndex = round(get(hObject,'value'));
SetGain(hObject,handles,handles.GainPresets(round(scrollerIndex)),true);


% --- Executes during object creation, after setting all properties.
function gainSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gainSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function ExposureSlider_Callback(hObject, eventdata, handles)
scrollerIndex = get(hObject,'value');
SetExposure(hObject,handles,1.0/handles.ExposurePresets(round(scrollerIndex)),true);

% --- Executes during object creation, after setting all properties.
function ExposureSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExposureSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function ExposureEdit_Callback(hObject, eventdata, handles)
SetExposure(hObject,handles,1.0/str2num(get(hObject,'String')),true);


% --- Executes during object creation, after setting all properties.
function ExposureEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExposureEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function GainEdit_Callback(hObject, eventdata, handles)
SetGain(hObject,handles,str2num(get(hObject,'String')),true);


% --- Executes during object creation, after setting all properties.
function GainEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GainEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Snap.
function Snap_Callback(hObject, eventdata, handles)
% hObject    handle to Snap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function timerFunc(timerObject,A)
global g_stats 
    

if isempty(g_stats) || (~isempty(g_stats) && g_stats.counter == 1)
    g_stats.counter = 1;
    g_stats.values = zeros(1,5000);
    g_stats.meanI = zeros(128,128);
end

XimeaWrapper('SoftwareTrigger');
bufSize = XimeaWrapper('GetBufferSize');

if bufSize > 0
    % display latest image
    imageBuf = XimeaWrapper('GetImageBuffer');
    if size(imageBuf,3) >= 1
        handles = guidata(timerObject.UserData);
        lastImage = imageBuf(:,:,end);
        
        if (get(handles.hAveraging,'value'))
            
            g_stats.meanI = ((g_stats.counter-1) * g_stats.meanI + mean(imageBuf,3)) / g_stats.counter;
              lastImage = g_stats.meanI;
        end
        
    if  get(handles.hSmooth,'value')
    gaussianWidth = 0.7;
    kernel1D = fspecial('gaussian',[10*gaussianWidth 1],gaussianWidth);
    lastImage=convn(convn(double(lastImage),kernel1D,'same'),kernel1D','same');
    end    
    
    
        
        set(handles.hImage,'cdata',lastImage);

        if get(handles.histogramPlot,'value') > 0
            histBins = 0:4095;%%max(lastImage(:));
            histCount = hist(double(lastImage(:)),0:4095);
            plot(handles.axes3,histBins,histCount);
            set(handles.axes3,'xlim',[0 4095]);
        end
         if (handles.mousePos(1) >= 1&& handles.mousePos(1) <= size(imageBuf,2) && ...
                handles.mousePos(2) >= 1&& handles.mousePos(2) <= size(imageBuf,1))
            set(handles.infoText,'String',sprintf('%s, %.1f %.1f = %d',datestr(now,13),handles.mousePos(1),handles.mousePos(2),imageBuf(round(handles.mousePos(2)),round(handles.mousePos(1)),end)));
        else
            set(handles.infoText,'String',sprintf('%s',datestr(now,13)));
         end
        
         y=round(handles.mouseDownPos(2));
         x=round(handles.mouseDownPos(1));
        set(handles.hMarker,'xdata',x,'ydata',y,'visible','on');

         if (get(handles.hCenterAvg,'value'))
             value = mean(lastImage(:));
         else
            value = lastImage(y,x);
         end
            
          g_stats.values(g_stats.counter) = value;
          plot(handles.axes2,1:g_stats.counter,g_stats.values(1:g_stats.counter));
            M = mean(g_stats.values(1:g_stats.counter));
            S = std(double(g_stats.values(1:g_stats.counter)));
            set(handles.hStatisticsText,'String',sprintf('[%.0f, %.0f], Mean: %.2f, Std:%.2f, SNR:%.2f, TOT: %.2f',handles.mouseDownPos(1),handles.mouseDownPos(2),M,S,M/S, mean(lastImage(:)) ));
          
          g_stats.counter=g_stats.counter+1;
          if (g_stats.counter > 5000)
              g_stats.values = zeros(1,5000);
              g_stats.counter = 1;
          end
         
    end

end


function stopLiveView(handles)
handles.acquiring = false;
stop(handles.timer);
set(handles.StartStop,'String','Start');
%XimeaWrapper('SetTriggerMode',true);

% --- Executes on button press in StartStop.
function StartStop_Callback(hObject, eventdata, handles)
if strcmp(get(handles.timer,'Running'),'on')
    stopLiveView(handles)
else
    handles.acquiring = true;
    set(handles.StartStop,'String','Stop');
    %XimeaWrapper('SetTriggerMode',false);
    start(handles.timer);
end

guidata(hObject, handles);


% --- Executes on button press in stretchRange.
function stretchRange_Callback(hObject, eventdata, handles)
if get(hObject,'value')
    set(handles.hImage,'CDataMapping','direct');
else
    set(handles.hImage,'CDataMapping','scaled');
    set(handles.axes1,'Clim',[0 1024]);
    
end

% --- Executes on button press in Jet.
function Jet_Callback(hObject, eventdata, handles)
figure(handles.figure1);
axes(handles.axes1);
if get(hObject,'value')
    set(handles.figure1, 'Colormap', jet(64));
else
    set(handles.figure1, 'Colormap', gray(64));
    
end


% --- Executes on button press in histogramPlot.
function histogramPlot_Callback(hObject, eventdata, handles)
if get(hObject,'value')
    set(handles.axes3,'visible','on');
else
    set(handles.axes3,'visible','off');
end


% --- Executes on button press in ResetDriver.
function ResetDriver_Callback(hObject, eventdata, handles)
[OffsetX, OffsetY, Res] = GetCameraParams();

if strcmp(get(handles.timer,'Running'),'on')
    resetTimer = true;
else
    resetTimer = false;
end

if (resetTimer)
    stop(handles.timer);
end

if XimeaWrapper('IsInitialized')
    XimeaWrapper('Release');
end
Ham=XimeaWrapper('InitWithResolutionOffset',OffsetX,OffsetY,Res,Res,7);

if (resetTimer)
    %XimeaWrapper('SetTriggerMode',false);
    start(handles.timer);
end


% --- Executes on button press in hSmooth.
function hSmooth_Callback(hObject, eventdata, handles)
% hObject    handle to hSmooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hSmooth


% --- Executes on selection change in hResolutionPopup.
function hResolutionPopup_Callback(hObject, eventdata, handles)
Value = get(handles.hResolutionPopup,'value');
stopLiveView(handles);
XimeaWrapper('Release');
WaitSecs(1);
if (Value == 1)
    [x0,y0,res1,res2]=GetCameraParams();
    Ham=XimeaWrapper('InitWithResolutionOffset',x0,y0,res1,res2);
    Z = zeros(res2,res1);
    res(1) = res1;
    res(2) = res2;    
else
    Ham=XimeaWrapper('InitWithResolutionOffset',0,0,1280,1024);
    res(1) = 1280;
    res(2) = 1024;
    Z = zeros(1024,1280);
end
%XimeaWrapper('SetTriggerMode',false);
hold(handles.axes1,'off');
handles.hImage = image(Z,'parent',handles.axes1);
hold(handles.axes1,'on');
handles.hMarker = plot(handles.axes1,0,0,'g+');
handles.acquiring = true;
set(handles.axes1,'xlim',[0 res(1)],'ylim',[0 res(2)]);
set(handles.StartStop,'String','Stop');
axis(handles.axes1,'off')
set(handles.hImage,'CDataMapping','scaled');
set(handles.axes1,'Clim',[0 1024]);
set(handles.timer,'Period', 1/10);
guidata(hObject,handles);
start(handles.timer);


% --- Executes during object creation, after setting all properties.
function hResolutionPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hResolutionPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in hLocateFiber.
function hLocateFiber_Callback(hObject, eventdata, handles)

stopLiveView(handles);

XimeaWrapper('SoftwareTrigger');
WaitSecs(0.2);
X=XimeaWrapper('GetImageBuffer'); % make sure buffer is clean
if size(X,1) == 128
    fprintf('Switching to Full Resolution mode');
    XimeaWrapper('Release');
    XimeaWrapper('Init');
end
%XimeaWrapper('SetExposure',1/2000);
X=XimeaWrapper('GetImageBuffer'); % make sure buffer is clean
XimeaWrapper('SoftwareTrigger');
WaitSecs(0.1);
I=XimeaWrapper('GetImageBuffer'); % make sure buffer is clean


L=I>median(I(:))+5*mad(double(I(:)));
R=regionprops(L);
[~,indx]=max(cat(1,R.Area));

minArea=10000;
maxArea = 20000;
if (R(indx).Area < minArea || R(indx).Area > maxArea )
    fprintf('Segmentation failed\n');
else 
    X=round(R(indx).Centroid(1))-64;
    Y=round(R(indx).Centroid(2))-64;
    fprintf('Setting fiber position at %d,%d\n',X,Y);
    %figure(10);clf;imagesc(L);hold on;plot(X,Y,'g+');
    hFileId=fopen('FiberPosition.txt');
    s=sprintf('%d %d',X,Y);
    fwrite(hFileId, s);
    fclose(hFileId);
end
fprintf('Releasing and reopeninig in ROI mode\n');
XimeaWrapper('Release');

XimeaWrapper('InitWithResolutionOffset',X,Y,128,128);
StartStop_Callback(hObject, eventdata, handles);
%guidata(hObject, handles);
% set (handles.figure1, 'WindowButtonDownFcn', {@mouseDown, handles.figure1});
% 







function mouseDown(obj,A,fig)
global g_stats
handles = guidata(fig);
C = get (handles.axes1, 'CurrentPoint');
[OffsetX, OffsetY, Res] = GetCameraParams();
    x=C(1,1);
    y=C(1,2);
  if x >= 1 && y >= 1 && x <= Res && y <= Res
 
    handles.mouseDownPos =[x,y];

  end
if strcmp(get(fig,'selectionType'),'alt')
    g_stats.counter = 1;
else
    if x >= 1 && y >= 1 && x <= Res && y <= Res
    
    g_stats.counter = 1;
    end
end
if handles.locateFiber
    
 x0=floor(x/16)*16 - 64;
 y0=floor(y/2)*2 - 64;
    fprintf('Fiber Location Updated to %d, %d!\n',round(x0),round(y0));
     handles.locateFiber = false;
%  reWriteCameraParams(round(x0),round(y0),128);
%  
%  
% [OffsetX, OffsetY, Res] = GetCameraParams();
% 
 
 
end
guidata(fig, handles);


% --- Executes on button press in hCalibMoveTop.
function hCalibMoveTop_Callback(hObject, eventdata, handles)
fprintf('*******************************************\n');
[OffsetX, OffsetY, Res] = GetCameraParams();
[OffsetX, OffsetY, Res] = reWriteCameraParams(OffsetX,OffsetY-64,Res);
stop(handles.timer);
XimeaWrapper('Release');
WaitSecs(0.5);
XimeaWrapper('InitWithResolutionOffset',OffsetX,OffsetY,Res,Res,7);
start(handles.timer);

% --- Executes on button press in hCalibMoveLeft.
function hCalibMoveLeft_Callback(hObject, eventdata, handles)
fprintf('*******************************************\n');
[OffsetX, OffsetY, Res] = GetCameraParams();
[OffsetX, OffsetY, Res] = reWriteCameraParams(OffsetX-64,OffsetY,Res);
stop(handles.timer);
XimeaWrapper('Release');
WaitSecs(0.5);
XimeaWrapper('InitWithResolutionOffset',OffsetX,OffsetY,Res,Res,7);
start(handles.timer);

% --- Executes on button press in hCalibMoveRight.
function hCalibMoveRight_Callback(hObject, eventdata, handles)
fprintf('*******************************************\n');
[OffsetX, OffsetY, Res] = GetCameraParams();
[OffsetX, OffsetY, Res] = reWriteCameraParams(OffsetX+64,OffsetY,Res);
stop(handles.timer);
XimeaWrapper('Release');
WaitSecs(0.5);
XimeaWrapper('InitWithResolutionOffset',OffsetX,OffsetY,Res,Res,7);
start(handles.timer);

% --- Executes on button press in hCalibMoveDown.
function hCalibMoveDown_Callback(hObject, eventdata, handles)
fprintf('*******************************************\n');
[OffsetX, OffsetY, Res] = GetCameraParams();
[OffsetX, OffsetY, Res] = reWriteCameraParams(OffsetX,OffsetY+64,Res);
stop(handles.timer);
XimeaWrapper('Release');
WaitSecs(0.5);
XimeaWrapper('InitWithResolutionOffset',OffsetX,OffsetY,Res,Res,7);
start(handles.timer);


% --- Executes on button press in hCenterAvg.
function hCenterAvg_Callback(hObject, eventdata, handles)
% hObject    handle to hCenterAvg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hCenterAvg


% --- Executes on button press in hAveraging.
function hAveraging_Callback(hObject, eventdata, handles)
global g_stats 

if get(hObject,'value') == 1
    g_stats.counter = 1;
end
