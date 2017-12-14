function varargout = EPIModule(varargin)
% EPIMODULE MATLAB code for EPIModule.fig
%      EPIMODULE, by itself, creates a new EPIMODULE or raises the existing
%      singleton*.
%
%      H = EPIMODULE returns the handle to a new EPIMODULE or the handle to
%      the existing singleton*.
%
%      EPIMODULE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EPIMODULE.M with the given input arguments.
%
%      EPIMODULE('Property','Value',...) creates a new EPIMODULE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EPIModule_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EPIModule_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EPIModule

% Last Modified by GUIDE v2.5 03-Apr-2017 14:11:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EPIModule_OpeningFcn, ...
                   'gui_OutputFcn',  @EPIModule_OutputFcn, ...
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
    PTwrapper('SetExposure',exposure);
    exposureSet = PTwrapper('GetExposure');
    fprintf('Exposure set to %.5f\n',1.0/exposureSet);
end
set(handles.ExposureEdit,'String', num2str(1/exposure));

maxRate = 50;
if strcmp(get(handles.timer,'Running'),'on')
    resetTimer = true;
else
    resetTimer = false;
end
if (resetTimer)
    stop(handles.timer);
end
warning off
if 1/exposure > maxRate
    set(handles.timer,'Period', 1/maxRate)
else
    set(handles.timer,'Period', exposure)
end
warning on
if (resetTimer)
    start(handles.timer);
end



function SetGain(hObject,handles,gain,setCamera)
[~,indx]=min(abs(handles.GainPresets-gain));
set(handles.gainSlider,'min',1,'max',length(handles.GainPresets),'value',indx);
if (setCamera)
    fprintf('Setting Gain to %.5f\n',gain);
    PTwrapper('SetGain',gain);
    gain = PTwrapper('GetGain');
    fprintf('Gain set to %.5f\n',gain);
end
set(handles.GainEdit,'String', num2str(gain));


function CloseCameraModule(src,evnt,handles)

selection = questdlg('Close SIM Module?',...
    'Close Request Function',...
    'Yes','No','Yes');
switch selection,
    case 'Yes',
        myhandles = guidata(gcbo);
        if isfield(myhandles,'timer') && strcmp(myhandles.timer.Running,'on')
            stop(myhandles.timer);
            Dummy=PTwrapper('GetImageBuffer');
        end
        if PTwrapper('IsInitialized')
            PTwrapper('Release');
        end
        
        if ALPwrapper('IsInitialized',0)
            ALPwrapper('Release',0);
        end
        
        if fnDAQusb('IsInitialized')
            fnDAQusb('Release');
        end
        
        
        delete(myhandles.figure1)
    case 'No'
        return
end

% --- Executes just before EPIModule is made visible.
function EPIModule_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EPIModule (see VARARGIN)

% strDropBoxFolder = 'C:\Users\shayo\Dropbox';
% addpath([strDropBoxFolder,'\Code\Waveform Reshaping code\MEX\x64']);

if ~isfield(handles,'initialized')
    InitGUI(hObject, eventdata, handles,varargin);
end

if ~isempty(varargin) && strcmp(varargin{1},'StopLiveView') 
    if isfield(handles,'timer') && strcmp(get(handles.timer,'Running'),'on')
        stopLiveView(handles)
        return;
    end
end



function InitGUI(hObject, eventdata, handles,varargin)
handles.output = hObject;
% Update handles structure
%set( handles.figure1, 'toolbar', 'figure' )
ResH = 1200;
ResW = 1920;
Z = zeros(ResH,ResW);
handles.hImage = image(Z,'parent',handles.axes1);
handles.acquiring = false;
handles.mousePos = [1,1];
handles.ExposurePresets = [10000,9000,8000,7000,6000,5000,4000,3500,3000,2500,2000,1500,1000,800,500,200,100,50,20,10,1];
handles.GainPresets = 0:32;
set(handles.hBaselineEdit,'String',10);
set(handles.figure1,'visible','on')
set(handles.figure1, 'Colormap', gray(64));
set(handles.axes1,'visible','off');
set(handles.stretchRange,'value',0);
set (handles.figure1, 'WindowButtonMotionFcn', {@mouseMove, handles.figure1});
set (handles.figure1, 'WindowButtonDownFcn', {@mouseDown, handles.figure1});
handles.mouseDownPos = [-1 -1];
cameraRate = 10;
handles.numFramesToRecord = 900;
handles.epiDynamicRange = [0 4095];
set(handles.hEstimatedSize,'String',sprintf('Estimated Size: %.2f Gb',handles.numFramesToRecord*ResW*ResH*2/1e9));
set(handles.hExperimentNumber,'String',1);
handles.outputFolder = 'G:\EPISessions\';
set(handles.hRateEdit,'String', num2str(cameraRate));
set(handles.hNumFramesEdit,'String',num2str(handles.numFramesToRecord));
set(handles.hDurationEdit,'String', sprintf('%.3f',handles.numFramesToRecord/cameraRate))
set(handles.hTriggerStimulus,'value',1);
set(handles.hFrameRadio,'value',1);
%set(handles.hSimMode,'value',0);
handles.cameraOffset = [0,0];
handles.cameraResolution = [ResW,ResH];

handles.epiDynamicRange = [0 4095];

set(handles.hDisplayMaxEdit,'String',num2str(handles.epiDynamicRange(2)));
set(handles.hDisplayMinEdit,'String',num2str(handles.epiDynamicRange(1)));
rate = 50;
handles.timer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period',1/rate);
handles.timer.StartDelay = 0;
handles.timer.UserData = hObject;
handles.varargin = varargin;
guidata(hObject, handles);
handles.initialized =InitSIMModule(hObject, handles);
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
handles.mousePos =[x,y];
guidata(fig, handles);


function mouseDown(obj,A,fig)
global g_stats
handles = guidata(fig);
C = get (handles.axes1, 'CurrentPoint');
if strcmp(get(fig,'selectionType'),'alt')
    g_stats.counter = 1;
else
    x=C(1,1);
    y=C(1,2);
    if x >= 1 && y >= 1 && x <= 1920 && y <= 1200
    
    g_stats.counter = 1;
    handles.mouseDownPos =[x,y];
    end
end
guidata(fig, handles);


function ok=InitSIMModule(hObject, handles)
ok=true;
if (~PTwrapper('IsInitialized'))
    % Initialize Camera
    Hcam=initWithResolution(handles);
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

if (~ALPwrapper('IsInitialized',0))
    % Initialize Camera
    ALPwrapper('Init',0); 
else
    fprintf('Initialized DMD successfuly (already initialized)\n');
end
USB1608_ID= 0;
fnDAQusb('StopContinuousAcqusition',USB1608_ID);
fnDAQusb('ResetCounters',USB1608_ID);
fnDAQusb('Release');
if (~fnDAQusb('IsInitialized'))
    res= fnDAQusb('Init',USB1608_ID);
    if (res ~= 1) 
        fprintf('Failed to initialize boards!\n');
        return;
    end
end

expo=PTwrapper('GetExposure');
gain=PTwrapper('GetGain');
fprintf('Initial exposure: %.2f, gain :%.2f\n',1/expo,gain);
SetExposure(hObject,handles,expo,false);
SetGain(hObject,handles,gain,false);



% --- Outputs from this function are returned to the command line.
function varargout = EPIModule_OutputFcn(hObject, eventdata, handles) 
if ~isempty(handles.varargin) 
    if length(handles.varargin) >= 1 && ischar(handles.varargin{1}) && strcmp(handles.varargin{1},'IsInitialized') 
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
val = get(hObject,'String');
if isempty(val)
    val = 20;
else
    val=str2num(val);
end
SetExposure(hObject,handles,1.0/val,true);


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

function timerRecordFunc(timerObject,A)
if ALPwrapper('HasSequenceCompleted',0)
    stop(timerObject);
    handles = guidata(timerObject.UserData);
    dumpDataToDisk(handles);
    return;
end

handles = guidata(timerObject.UserData);
stremToDisk = get(handles.hStreamToDisk,'value');
epiDisplay(handles, false,stremToDisk);



function updatePixelStat(handles,lastImage,frameIndex)
global g_stats
if handles.mouseDownPos(1) >= 1 && handles.mouseDownPos(1) <= size(lastImage,2) && ...
        handles.mouseDownPos(2) >= 1 && handles.mouseDownPos(2) <= size(lastImage,1)
    
    if isempty(g_stats)
        g_stats.counter = 1;
        g_stats.values = zeros(1,100000);
    end
    value = lastImage(round(handles.mouseDownPos(2)),round(handles.mouseDownPos(1)));
    g_stats.values(g_stats.counter) = value;
    plot(handles.timeAxes,1:g_stats.counter,g_stats.values(1:g_stats.counter));
    
    [afHist,afCent]=hist(double(g_stats.values(1:g_stats.counter)));
    afHist=afHist/sum(afHist);
    plot(handles.histogramAxes,afCent, afHist);
    
    M = mean(g_stats.values(1:g_stats.counter));
    S = std(double(g_stats.values(1:g_stats.counter)));
    set(handles.hStatisticsText,'Title',sprintf('[%.0f, %.0f], Mean: %.2f, Std:%.2f, SNR:%.2f',handles.mouseDownPos(1),handles.mouseDownPos(2),M,S,M/S));
    
    g_stats.counter=g_stats.counter+1;
end

if isempty(frameIndex)
    frameIndex = 0;
end

if (handles.mousePos(1) >= 1 && handles.mousePos(1) <= size(lastImage,2) && ...
        handles.mousePos(2) >= 1 && handles.mousePos(2) <= size(lastImage,1))
    set(handles.infoText,'String',sprintf('[%d], %s, %.1f %.1f = %.1f',frameIndex,datestr(now,13),handles.mousePos(1),handles.mousePos(2),lastImage(round(handles.mousePos(2)),round(handles.mousePos(1)))));
else
    set(handles.infoText,'String',sprintf('[%d], %s',frameIndex,datestr(now,13)));
end
return

    

function stopLiveView(handles)
handles.acquiring = false;
stop(handles.timer);
ALPwrapper('StopSequence',0);
StimulusClient('Abort',0);figure(handles.figure1);
lightsOff(handles);
set(handles.StartStop,'String','Start');

% --- Executes on button press in StartStop.
function StartStop_Callback(hObject, eventdata, handles)
if strcmp(get(handles.timer,'Running'),'on')
    stopLiveView(handles)
else
    
    imageBuf = PTwrapper('GetImageBuffer'); % clear buffer
    handles.acquiring = true;
    set(handles.StartStop,'String','Stop');
    dmdRate = str2num(get(handles.hRateEdit,'String'));
    onID = ALPwrapper('UploadPatternSequence',0,ones(768,1024)>0);
    ALPwrapper('PlayUploadedSequence',0,onID, dmdRate, 0); % loop
    handles.timer.TimerFcn = @epiTimerFunc;
    
    start(handles.timer);
end

guidata(hObject, handles);


function showLastImage(handles, lastImage)
global g_stats g_averageImage g_lastFrameRead
[X,Y,ResW,ResH]=GetCameraParams();

if get(handles.hImageAccumulation,'value')
    if isempty(g_averageImage)
        g_averageImage.counter = 1;
        g_averageImage.avgImage = zeros(ResH,ResW);
    end
    
    n=g_averageImage.counter;
    g_averageImage.avgImage = ((n-1)*g_averageImage.avgImage + double(lastImage))/n;
    g_averageImage.counter=g_averageImage.counter+1;
    lastImage = g_averageImage.avgImage;
end    

set(handles.hImage,'cdata',lastImage);


if (get(handles.stretchRange,'value'))
    set(handles.hImage,'CDataMapping','scaled');
    set(handles.axes1,'Clim',[min(lastImage(:)) 1+max(lastImage(:))]);
    
else
    set(handles.hImage,'CDataMapping','scaled');
    m1=min(4095,max(0,str2num(get(handles.hDisplayMaxEdit,'String'))));
    m2=min(4095,max(0,str2num(get(handles.hDisplayMinEdit,'String'))));
    set(handles.axes1,'Clim',[m2 m1]);
end
%frameIndex= PTwrapper('GetBufferSize');
updatePixelStat(handles,lastImage,g_lastFrameRead);
drawnow
return;

    
function epiDisplay(handles, clearbuf, streamToDisk)
global g_lastFrameRead
bufSize = PTwrapper('GetBufferSize');
[flipCounter1,flipCounter2] = fnDAQusb('ReadCounters',0);
set(handles.hCounter,'string', sprintf('Counter: %d',flipCounter1));
if bufSize > 0
    ResW = 1920;
    ResH = 1200;
    % display latest image
    if clearbuf || streamToDisk
        [imageBuf, imageIndex] = PTwrapper('GetImageBuffer');
         if streamToDisk
            strctRun = handles.strctRun;
            for k=1:size(imageBuf,3)
                
                data =  reshape(imageBuf(:,:,k),ResW*ResH,1);
                start = [1 imageIndex];
                count = [ResW*ResH 1];
                h5write(strctRun.imagesFile,'/DS1',data,start,count);
                fprintf('Dumped frame %d\n',imageIndex);
%                 h5write(strctRun.imagesFile,'/DS1', reshape(imageBuf(:,:,k),ResW*ResH,1), [1,imageIndex], [ResW*ResH,1]);
                imageIndex=imageIndex+1;
            end
        end
    else
        [imageBuf, imageIndex] = PTwrapper('PokeLastImageTuple',1);
    end

    if ~isempty(g_lastFrameRead) && imageIndex == g_lastFrameRead
         return; % image was displayed already. Do nothing!
    else
        g_lastFrameRead = imageIndex;
    end
    
    lastImage = imageBuf(:,:,end);
    showLastImage(handles,lastImage);
end
return;

function epiTimerFunc(timerObject,A)
handles = guidata(timerObject.UserData);
epiDisplay(handles, true,false);


function hiloDisplay(handles, clearbuf, streamToDisk)
global g_lastFrameRead
bufSize = PTwrapper('GetBufferSize');
[X,Y,ResW,ResH]=GetCameraParams();

if bufSize >= 2
    % always get doublets. First one is epi. Second one is grid.
    if (clearbuf || streamToDisk)
        numImagesToGetFromBuffer = 2*floor(bufSize/2);
        
        
        [imageBuf, imageIndex] = PTwrapper('GetImageBuffer',numImagesToGetFromBuffer);
        if streamToDisk
            strctRun = handles.strctRun;
            for k=1:size(imageBuf,3)
                h5write(strctRun.imagesFile,'/DS1', reshape(imageBuf(:,:,k),ResW*ResH,1), [1,imageIndex], [ResW*ResH,1]);
                imageIndex=imageIndex+1;
            end
        end
        
    else
        [imageBuf, imageIndex] = PTwrapper('PokeLastImageTuple',2);
    end
     
        if ~isempty(g_lastFrameRead) && imageIndex == g_lastFrameRead
             return; % image was displayed already. Do nothing!
        else
            g_lastFrameRead = imageIndex;
        end
    
   
    if get(handles.hSimLiveView,'value')
        epiImage = LP(double(imageBuf(:,:,end-1)),4);
        gridImage = LP(double(imageBuf(:,:,end)),4);
        eta = str2num(get(handles.hHiLoEtaEdit,'String'));
        gaussianWidth = str2num(get(handles.hGaussianSmoothingKernelSize,'String'));
        imageRecon= HiLo(epiImage, gridImage, eta, gaussianWidth,3);
        showLastImage(handles, imageRecon);
    else
        showLastImage(handles, imageBuf(:,:,end));
    end
end

function hiloTimerFunc(timerObject,A)
handles = guidata(timerObject.UserData);
hiloDisplay(handles,true,false);


function simTimerFunc(timerObject,A)
handles = guidata(timerObject.UserData);
simDisplay(handles, true,false);

function simDisplay(handles, clearbuf, streamToDisk)
global g_lastFrameRead
bufSize = PTwrapper('GetBufferSize');
[X,Y,ResW,ResH]=GetCameraParams();

if bufSize >= 3
    % always get triplets...
    if (clearbuf || streamToDisk)
        numImagesToGetFromBuffer = 3*floor(bufSize/3);
        
        [imageBuf, imageIndex] = PTwrapper('GetImageBuffer',numImagesToGetFromBuffer);
        if streamToDisk
            strctRun = handles.strctRun;
            for k=1:size(imageBuf,3)
                h5write(strctRun.imagesFile,'/DS1', reshape(imageBuf(:,:,k),ResW*ResH,1), [1,imageIndex], [ResW*ResH,1]);
                imageIndex=imageIndex+1;
            end
        end

    else
        [imageBuf, imageIndex] = PTwrapper('PokeLastImageTuple',3);
    end
    
    
    if ~isempty(g_lastFrameRead) && imageIndex == g_lastFrameRead
        return; % image was displayed already. Do nothing!
    else
        g_lastFrameRead = imageIndex;
    end
    
    % take last triplet...
    if get(handles.hSimLiveView,'value')
        lastTriplet = double(imageBuf(:,:,end-2:end));
        imageRecon= 1/(3*sqrt(2))* sqrt( (lastTriplet(:,:,1)-lastTriplet(:,:,2)).^2 + ...
            (lastTriplet(:,:,1)-lastTriplet(:,:,3)).^2 + (lastTriplet(:,:,2)-lastTriplet(:,:,3)).^2);
        showLastImage(handles, imageRecon);
    else
        showLastImage(handles, imageBuf(:,:,end));
    end
end

% --- Executes on button press in stretchRange.
function stretchRange_Callback(hObject, eventdata, handles)
% if get(hObject,'value')
%     set(handles.hImage,'CDataMapping','direct');
% else
%     set(handles.hImage,'CDataMapping','scaled');
%     set(handles.axes1,'Clim',[0 4095]);
%     
% end

% --- Executes on button press in Jet.
function Jet_Callback(hObject, eventdata, handles)
figure(handles.figure1);
axes(handles.axes1);
if get(hObject,'value')
    set(handles.figure1, 'Colormap', jet(64));
else
    set(handles.figure1, 'Colormap', gray(64));
    
end



% --- Executes on button press in ResetDriver.
function ResetDriver_Callback(hObject, eventdata, handles)
if strcmp(get(handles.timer,'Running'),'on')
    resetTimer = true;
else
    resetTimer = false;
end

if (resetTimer)
    stop(handles.timer);
end

PTwrapper('Release');
WaitSecs(1);
initWithResolution(handles);

if (resetTimer)
    start(handles.timer);
end



function hNumFramesEdit_Callback(hObject, eventdata, handles)
[X,Y,ResW,ResH]=GetCameraParams();

desiredNumFramesToAcquire = str2num(get(handles.hNumFramesEdit,'String'));
rate = str2num(get(handles.hRateEdit,'String'));
% calculate duration
duration = desiredNumFramesToAcquire/rate;
set(handles.hDurationEdit,'String',sprintf('%.2f',duration));
set(handles.hEstimatedSize,'String',sprintf('Estimated Size: %.2f Gb',desiredNumFramesToAcquire*ResW*ResH*2/1e9));

% --- Executes during object creation, after setting all properties.
function hNumFramesEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hNumFramesEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hDurationEdit_Callback(hObject, eventdata, handles)
[X,Y,ResW,ResH]=GetCameraParams();

duration = str2num(get(handles.hDurationEdit,'String'));
rate = str2num(get(handles.hRateEdit,'String'));
desiredNumFramesToAcquire =ceil(duration*rate);
set(handles.hNumFramesEdit,'String',num2str(desiredNumFramesToAcquire));
set(handles.hEstimatedSize,'String',sprintf('Estimated Size: %.2f Gb',desiredNumFramesToAcquire*ResW*ResH*2/1e9));



% --- Executes during object creation, after setting all properties.
function hDurationEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDurationEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hGridEdit_Callback(hObject, eventdata, handles)
if strcmp(get(handles.timer,'Running'),'on')
    stopLiveView(handles)
    StartStop_Callback(hObject, eventdata, handles);
end

% --- Executes during object creation, after setting all properties.
function hGridEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hGridEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hRateEdit_Callback(hObject, eventdata, handles)
[X,Y,ResW,ResH]=GetCameraParams();

desiredNumFramesToAcquire = str2num(get(handles.hNumFramesEdit,'String'));
rate = str2num(get(handles.hRateEdit,'String'));
duration = desiredNumFramesToAcquire/rate;
set(handles.hDurationEdit,'String',sprintf('%.2f',duration));
set(handles.hEstimatedSize,'String',sprintf('Estimated Size: %.2f Gb',desiredNumFramesToAcquire*ResW*ResH*2/1e9));



% --- Executes during object creation, after setting all properties.
function hRateEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hRateEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hOutputFolder.
function hOutputFolder_Callback(hObject, eventdata, handles)
X=uigetdir();
if X(1) ~= 0
    handles.outputFolder = [X,filesep];
    guidata(hObject,handles);
end




function dumpDataToDisk(handles)
strctRun = handles.strctRun;

res=fnDAQusb('StopContinuousAcqusition',strctRun.USB1608_ID);
set(handles.hRecordButton,'String','Record');

WaitSecs(1);% verify we have all data...

strFileName = sprintf('%s/Experiment%04d.mat',handles.outputFolder,strctRun.experimentNumber);
fprintf('Dumping experiment %d to disk...',strctRun.experimentNumber);
  ResW=1920;
    ResH=1200;

if get(handles.hStreamToDisk,'value')
      [imageBuf, imageIndex] = PTwrapper('GetImageBuffer');
    for k=1:size(imageBuf,3)
        h5write(strctRun.imagesFile,'/DS1', reshape(imageBuf(:,:,k),ResW*ResH,1), [1,imageIndex], [ResW*ResH,1]);
        imageIndex=imageIndex+1;
    end
    numImagesArrived = imageIndex-1;
else    
    strctRun.images=PTwrapper('GetImageBuffer'); 
    
%     f='G:\EpiSessions\myfile4.h5';
    h5create(strctRun.imagesFile,'/DS1',[ResW*ResH Inf],'ChunkSize',[ResH/8,ResW/8],'Datatype','uint16');
    for j = 1:size(strctRun.images,3)
        fprintf('%d\n',j);drawnow
          data =  reshape(strctRun.images(:,:,k),ResW*ResH,1);
          start = [1 j];
          count = [ResW*ResH 1];
          h5write(strctRun.imagesFile,'/DS1',data,start,count);
    end

    
    numImagesArrived = size(strctRun.images,3);
end

if numImagesArrived ~= strctRun.numFrames
    fprintf('CRITICAL ERROR! Number of images mismatch!\n');
    lightsOff(handles);
    ALPwrapper('ReleaseAllSequences',0);
    return;
else
    fprintf('All frames recorded correctly.');
end

strctRun.valuesSlow=squeeze(fnDAQusb('GetBuffer',strctRun.USB1608_ID));

lightsOff(handles);
set(handles.hLightON,'fontweight','normal');
set(handles.hLightOff,'fontweight','bold');

ALPwrapper('ReleaseAllSequences',0);  
if get(handles.hCompress,'value')
    save(strFileName,'strctRun','-v7.3');    
else
    savefast(strFileName,'strctRun');
end
fprintf('Done!\n');

% increase experiment number
set(handles.hExperimentNumber,'String',num2str(strctRun.experimentNumber+1));

% --- Executes on button press in hTriggerStimulus.
function hTriggerStimulus_Callback(hObject, eventdata, handles)
% hObject    handle to hTriggerStimulus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hTriggerStimulus



function hExperimentNumber_Callback(hObject, eventdata, handles)
% hObject    handle to hExperimentNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hExperimentNumber as text
%        str2double(get(hObject,'String')) returns contents of hExperimentNumber as a double


% --- Executes during object creation, after setting all properties.
function hExperimentNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hExperimentNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hSimLiveView.
function hSimLiveView_Callback(hObject, eventdata, handles)
% hObject    handle to hSimLiveView (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hSimLiveView


% --- Executes on button press in hCompress.
function hCompress_Callback(hObject, eventdata, handles)
% hObject    handle to hCompress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hCompress


% --- Executes on button press in hLightON.
function hLightON_Callback(hObject, eventdata, handles)
lightsON(handles)

% --- Executes on button press in hLightOff.
function hLightOff_Callback(hObject, eventdata, handles)
 lightsOff(handles)


function hCommentEdit_Callback(hObject, eventdata, handles)
% hObject    handle to hCommentEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hCommentEdit as text
%        str2double(get(hObject,'String')) returns contents of hCommentEdit as a double


% --- Executes during object creation, after setting all properties.
function hCommentEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hCommentEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lightsON(handles)
onID = ALPwrapper('UploadPatternSequence',0,true(768,1024));
ALPwrapper('PlayUploadedSequence',0,onID,10,1); % turn off light
set(handles.hLightON,'fontweight','bold');
set(handles.hLightOff,'fontweight','normal');

function lightsOff(handles)
offID = ALPwrapper('UploadPatternSequence',0,false(768,1024));
ALPwrapper('PlayUploadedSequence',0,offID,10,1); % turn off light
set(handles.hLightON,'fontweight','normal');
set(handles.hLightOff,'fontweight','bold');



function hBaselineEdit_Callback(hObject, eventdata, handles)
% hObject    handle to hBaselineEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hBaselineEdit as text
%        str2double(get(hObject,'String')) returns contents of hBaselineEdit as a double


% --- Executes during object creation, after setting all properties.
function hBaselineEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hBaselineEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AutoTurnLightWithEPI.
function AutoTurnLightWithEPI_Callback(hObject, eventdata, handles)
% hObject    handle to AutoTurnLightWithEPI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AutoTurnLightWithEPI



function hDisplayMinEdit_Callback(hObject, eventdata, handles)
m2=min(4095,max(0,str2num(get(handles.hDisplayMinEdit,'String'))));
m1=min(4095,max(0,str2num(get(handles.hDisplayMaxEdit,'String'))));

if m2 > m1
    set(handles.hDisplayMinEdit,'String','0');
    m2 = 0;
end

if get(handles.hEpiMode,'value')
    handles.epiDynamicRange(1) = m2;
elseif get(handles.hSimMode,'value')
    handles.simDynamicRange(1) = m2;
elseif get(handles.hHiLoMode,'value')
    handles.hiloDynamicRange(1) = m2;
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function hDisplayMinEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDisplayMinEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hDisplayMaxEdit_Callback(hObject, eventdata, handles)
m2=min(4095,max(0,str2num(get(handles.hDisplayMinEdit,'String'))));
m1=min(4095,max(0,str2num(get(handles.hDisplayMaxEdit,'String'))));

if m1 < m2
    set(handles.hDisplayMaxEdit,'String','4095');
end
handles.epiDynamicRange(2) = m1;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function hDisplayMaxEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDisplayMaxEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% 
% 
% function varargout=PTwrapper(varargin)
% if nargout <= 1
%     varargout={PTwrapper(varargin{:})};
% else
%     [A,B]=PTwrapper(varargin{:});
%     varargout{1} = A;
%     varargout{2} = B;
% end
% 


% --- Executes on button press in hTestAcqusitionSpeed.
function hTestAcqusitionSpeed_Callback(hObject, eventdata, handles)
N = 20;
dmdRate = str2num(get(handles.hRateEdit,'String'));
e=PTwrapper('GetExposure');
fprintf('DMD set to %d Hz. Exposure set to %.2f ms, maximal theoretical rate: %.2f\n',dmdRate,e*1000,1/e)
I=PTwrapper('GetImageBuffer');
ALPuploadAndPlay(zeros(768,1024)>0, dmdRate, N);
expectedTime = 1.5*ceil(1/dmdRate * N); % allow time for image transfer
WaitSecs(expectedTime);
n=PTwrapper('GetBufferSize');
if N ~= n
    fprintf('Missing frames. Only %d/%d received\n',n,N);
else
    fprintf('All frames arrived\n');
end


% --- Executes when selected object is changed in hImagingMode.
function hImagingMode_SelectionChangeFcn(hObject, eventdata, handles)

if strcmp(get(handles.timer,'Running'),'on')
    stopLiveView(handles)
    StartStop_Callback(hObject, eventdata, handles);
end
if get(handles.hEpiMode,'value')
    set(handles.hDisplayMinEdit,'String', num2str(handles.epiDynamicRange(1)));
    set(handles.hDisplayMaxEdit,'String', num2str(handles.epiDynamicRange(2)));
elseif get(handles.hSimMode,'value')
    set(handles.hDisplayMinEdit,'String', num2str(handles.simDynamicRange(1)));
    set(handles.hDisplayMaxEdit,'String', num2str(handles.simDynamicRange(2)));
elseif get(handles.hHiLoMode,'value')
    set(handles.hDisplayMinEdit,'String', num2str(handles.hiloDynamicRange(1)));
    set(handles.hDisplayMaxEdit,'String', num2str(handles.hiloDynamicRange(2)));
end


function hGaussianSmoothingKernelSize_Callback(hObject, eventdata, handles)
% hObject    handle to hGaussianSmoothingKernelSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hGaussianSmoothingKernelSize as text
%        str2double(get(hObject,'String')) returns contents of hGaussianSmoothingKernelSize as a double


% --- Executes during object creation, after setting all properties.
function hGaussianSmoothingKernelSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hGaussianSmoothingKernelSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hHiLoEtaEdit_Callback(hObject, eventdata, handles)
% hObject    handle to hHiLoEtaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hHiLoEtaEdit as text
%        str2double(get(hObject,'String')) returns contents of hHiLoEtaEdit as a double


% --- Executes during object creation, after setting all properties.
function hHiLoEtaEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hHiLoEtaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function CamWait(N)
fprintf('Waiting for %d...',N);
pX = 0;
while PTwrapper('GetBufferSize') < N
    X=PTwrapper('GetBufferSize');
    if X > pX + 1
        pX = X;
        fprintf('%d ',X);
    end
end
fprintf('Done!\n');

% --- Executes on button press in hRecordButton.
function hRecordButton_Callback(hObject, eventdata, handles)
trigStim = get(handles.hTriggerStimulus,'value');

if isfield(handles,'strctRun') && ~ALPwrapper('HasSequenceCompleted',0)
    % abort run!
    stop(handles.timer);
    strctRun = handles.strctRun;
    set(handles.hLightON,'fontweight','normal');
    set(handles.hLightOff,'fontweight','bold');
    
    fprintf('Experiment %d aborted and not saved to disk!\n',strctRun.experimentNumber);
    
    ALPwrapper('StopSequence',0);
    try
    if (trigStim)
        StimulusClient('Abort');figure(handles.figure1);
        figure(handles.figure1);drawnow
    end
    catch
    end
    res=fnDAQusb('StopContinuousAcqusition',strctRun.USB1608_ID);
    ALPwrapper('PlayUploadedSequence',0,strctRun.offID,10,1);
    ALPwrapper('ReleaseAllSequences',0);  
    StimulusClient('Abort');figure(handles.figure1);
    set(handles.hRecordButton,'String','Record');
    
    return;
    
end
try
    if (trigStim)
        strctRun.strctStimulusParams=StimulusClient('Init');figure(handles.figure1);
        
        figure(handles.figure1);drawnow
    end
catch
    fprintf('WARNING - did not connect to stimulus server/client!\n');
end
   

stopLiveView(handles);


strctRun.experimentNumber = str2num(get(handles.hExperimentNumber,'String'));
strFileName = sprintf('%s/Experiment%04d.mat',handles.outputFolder,strctRun.experimentNumber);
if exist(strFileName,'file')
 ButtonName = questdlg('Experiment Exist. What to do?', ...
                         'Question', ...
                         'Cancel', 'Override', 'Generate New Number', 'Generate New Number');

 if isempty(ButtonName)|| strcmp(ButtonName,'Cancel')
     return;
 elseif strcmp(ButtonName,'Generate New Number')
         astrctFiles = dir([handles.outputFolder,'*.mat']);
         strctRun.experimentNumber = length(astrctFiles)+1;
         set(handles.hExperimentNumber,'String',num2str(strctRun.experimentNumber ));
 end
 
end
fprintf('Starting experiment %d...\n',strctRun.experimentNumber);
MaxImagesInCameraBuffer = 25000;

strctRun.comment = get(handles.hCommentEdit,'String');
strctRun.cameraGain = PTwrapper('GetGain');
strctRun.cameraExposure= 1.0/PTwrapper('GetExposure');
strctRun.dmdRate = str2num(get(handles.hRateEdit,'String'));
actualFrameNumber = str2num(get(handles.hNumFramesEdit,'String'));
strctRun.numFrames = actualFrameNumber;
% actual number of frames needs to be a multiple of 3 in case of SIM imaging, and of USB packet size...
    % epi Mode
strctRun.durationSec = actualFrameNumber/str2num(get(handles.hRateEdit,'String'));

%% DMD
strctRun.offID = ALPwrapper('UploadPatternSequence',0,false(768,1024));
strctRun.onID = ALPwrapper('UploadPatternSequence',0,true(768,1024));

%%
% Get baseline.
numBaselineFrames = min(100,max(1,str2num(get(handles.hBaselineEdit,'String'))));
I=PTwrapper('GetImageBuffer'); % clear buffer
res=ALPwrapper('PlayUploadedSequence',0,strctRun.offID,strctRun.dmdRate, numBaselineFrames);
ALPwrapper('WaitForSequenceCompletion',0); % Block. Wait for sequence to end.
CamWait(numBaselineFrames);
strctRun.baseline=PTwrapper('GetImageBuffer'); % clear buffer

PTwrapper('ResetTriggerCounter');
%% Streaming?
strctRun.imagesFile = sprintf('%s/Experiment%04d.h5',handles.outputFolder,strctRun.experimentNumber);
ResH=1200;
ResW=1920;
stremToDisk = get(handles.hStreamToDisk,'value');
if stremToDisk
      h5create(strctRun.imagesFile,'/DS1',[ResW*ResH Inf],'ChunkSize',[ResH/8,ResW/8],'Datatype','uint16');
end
%% DAQ
strctRun.slowDAQrateHz = 2000;

strctRun.USB1608_PACKET_SIZE = 256;
strctRun.USB1608_ID = 0;
strctRun.numSlowChannels = 2; %Photodiode, DMD 
strctRun.SlowDAQvoltageRangeV = 10;
overheadTime = 10; % since we used fixed rate trigger, we could potentially override the buffer.
% allow several seconds for safety (after DMD finished).
strctRun.slowDAQnumSamplesPerChannel = ceil(strctRun.slowDAQrateHz * (strctRun.durationSec+overheadTime) / strctRun.USB1608_PACKET_SIZE)*strctRun.USB1608_PACKET_SIZE;
res=fnDAQusb('StopContinuousAcqusition',strctRun.USB1608_ID);
res=fnDAQusb('ResetCounters',strctRun.USB1608_ID);

res=fnDAQusb('Allocate',strctRun.USB1608_ID, strctRun.numSlowChannels, strctRun.slowDAQnumSamplesPerChannel, 1, 1, strctRun.slowDAQnumSamplesPerChannel);
res=fnDAQusb('StartContinuousAcqusitionFixedRateTrigger',strctRun.USB1608_ID,strctRun.slowDAQrateHz, strctRun.SlowDAQvoltageRangeV,true ); 


%% Start acuqisiton
        res=ALPwrapper('PlayUploadedSequence',0,strctRun.onID,strctRun.dmdRate, actualFrameNumber);
        set(handles.hLightON,'fontweight','bold');
        set(handles.hLightOff,'fontweight','normal');
%% Stimulus
try
    if (trigStim)
        StimulusClient('Run');
        figure(handles.figure1);drawnow
    end
catch
end

handles.recording = true;
set(handles.hRecordButton,'String','Abort');

rate = 30;
handles.timer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period',1/rate);
handles.timer.StartDelay = 0;
handles.timer.UserData = hObject;
handles.timer.TimerFcn = @timerRecordFunc;

handles.strctRun = strctRun;

guidata(hObject, handles);


start(handles.timer);


% --- Executes on button press in hImageAccumulation.
function hImageAccumulation_Callback(hObject, eventdata, handles)
% [X,Y,ResW,ResH]=GetCameraParams();

global g_averageImage
if get(hObject,'value') == 1
    g_averageImage.counter = 1;
    g_averageImage.avgImage = zeros(1200,1920);
end

        



% --- Executes on button press in hAlignOffset.
function hAlignOffset_Callback(hObject, eventdata, handles)
% hObject    handle to hAlignOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stopLiveView(handles);
PTwrapper('Release');

Ham=PTwrapper('InitWithResolutionOffset',0,0,1920,1200,7);
I=PTwrapper('GetImageBuffer');
N=5;
ALPuploadAndPlay(ones(768,1024)>0,2,N);
WaitSecs(4);
I=PTwrapper('GetImageBuffer');
if size(I,3) ~= N
    fprintf('Camera did not initialize correctly. Try again\n');
    return;
end;
X=mean(I,3);

set(handles.hImage,'cdata',X);
set(handles.axes1,'xlim',[0.5 1920.5])
set(handles.axes1,'ylim',[0.5 1200.5])
set(handles.axes1,'clim',[min(X(:)), max(X(:))])
set(handles.hImage,'CDataMapping','scaled');
fprintf('Now zoom, then click ENTER\n');
pause;
tmp=round([get(handles.axes1,'xlim'), get(handles.axes1,'ylim')]/64)*64;
offsetX = tmp(1);
offsetY = tmp(3);
fprintf('Setting new offset to %d, %d\',offsetX,offsetY );

set(handles.axes1,'xlim',[0.5 640.5])
set(handles.axes1,'ylim',[0.5 480.5])

handles.cameraOffset = [offsetX, offsetY];
guidata(hObject, handles);
PTwrapper('Release');
initWithResolution(handles);

return;


function Hcam=initWithResolution(handles)
[X,Y,ResW,ResH]=GetCameraParams();

Hcam=PTwrapper('InitWithResolutionOffset',0,0,1920,1200,7);

%Hcam=PTwrapper('InitWithResolutionOffset',handles.cameraOffset(1),handles.cameraOffset(2),ResW,ResH,7); 


% --- Executes on button press in hStreamToDisk.
function hStreamToDisk_Callback(hObject, eventdata, handles)
