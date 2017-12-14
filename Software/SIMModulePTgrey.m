function varargout = SIMModulePTgrey(varargin)
% SIMModulePTgrey MATLAB code for SIMModulePTgrey.fig
%      SIMModulePTgrey, by itself, creates a new SIMModulePTgrey or raises the existing
%      singleton*.
%
%      H = SIMModulePTgrey returns the handle to a new SIMModulePTgrey or the handle to
%      the existing singleton*.
%
%      SIMModulePTgrey('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIMModulePTgrey.M with the given input arguments.
%
%      SIMModulePTgrey('Property','Value',...) creates a new SIMModulePTgrey or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SIMModulePTgrey_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SIMModulePTgrey_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SIMModulePTgrey

% Last Modified by GUIDE v2.5 16-Apr-2015 13:39:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SIMModulePTgrey_OpeningFcn, ...
                   'gui_OutputFcn',  @SIMModulePTgrey_OutputFcn, ...
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
    PTwrapper('SetGain',gain);
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
        
        if ALPwrapper('IsInitialized')
            ALPwrapper('Release');
        end
        
        if fnDAQusb('IsInitialized')
            fnDAQusb('Release');
        end
        
        
        delete(myhandles.figure1)
    case 'No'
        return
end

% --- Executes just before SIMModulePTgrey is made visible.
function SIMModulePTgrey_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SIMModulePTgrey (see VARARGIN)

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
Z = zeros(480,640);
handles.hImage = image(Z,'parent',handles.axes1);
handles.acquiring = false;
handles.mousePos = [1,1];
handles.ExposurePresets = [10000,9000,8000,7000,6000,5000,4000,3500,3000,2500,2000,1500,1000,800,500,200,100,50,20,10,1];
handles.GainPresets = 0:32;
set(handles.hBaselineEdit,'String',10);
set(handles.figure1,'visible','on')
set(handles.figure1, 'Colormap', gray(64));
set(handles.axes1,'visible','off');
set(handles.stretchRange,'value',1);
set(handles.AutoTurnLightWithEPI,'value',1);
set (handles.figure1, 'WindowButtonMotionFcn', {@mouseMove, handles.figure1});
set (handles.figure1, 'WindowButtonDownFcn', {@mouseDown, handles.figure1});
handles.mouseDownPos = [-1 -1];
cameraRate = 10;
handles.numFramesToRecord = 900;
handles.simGridSizePixels = 10;
set(handles.hEstimatedSize,'String',sprintf('Estimated Size: %.2f Gb',handles.numFramesToRecord*640*480*2/1e9));
set(handles.hExperimentNumber,'String',1);
handles.outputFolder = 'E:\FiberBundleExperiments\';
set(handles.hRateEdit,'String', num2str(cameraRate));
set(handles.hNumFramesEdit,'String',num2str(handles.numFramesToRecord));
set(handles.hDurationEdit,'String', sprintf('%.3f',handles.numFramesToRecord/cameraRate))
set(handles.hTriggerStimulus,'value',1);
set(handles.hFrameRadio,'value',1);
set(handles.hSimMode,'value',1);
set(handles.hGridEdit,'String',num2str(handles.simGridSizePixels));

set(handles.hDisplayMaxEdit,'String','4095');
set(handles.hDisplayMinEdit,'String','0');
rate = 50;
handles.timer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period',1/rate);
handles.timer.StartDelay = 0;
handles.timer.UserData = hObject;
handles.timer.TimerFcn = @timerFunc;
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
    if x >= 1 && y >= 1 && x <= 640 && y <= 480
    
    g_stats.counter = 1;
    handles.mouseDownPos =[x,y];
    end
end
guidata(fig, handles);


function ok=InitSIMModule(hObject, handles)
ok=true;
if (~PTwrapper('IsInitialized'))
    % Initialize Camera
    Hcam=PTwrapper('Init'); 
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

if (~ALPwrapper('IsInitialized'))
    % Initialize Camera
    Hdmd=ALPwrapper('Init'); 
    if (Hdmd)
        fprintf('Initialized DMD successfuly\n');
    else
        fprintf('Failed to initialize DMD\n');
        ok=false;
        return;
    end
else
    fprintf('Initialized DMD successfuly (already initialized)\n');
end

if (~fnDAQusb('IsInitialized'))
    % Initialize Camera
    hDAQ=fnDAQusb('Init'); 
    if (hDAQ)
        fprintf('Initialized DAQ successfuly\n');
    else
        fprintf('Failed to initialize DAQ\n');
        ok=false;
        return;
    end
else
    fprintf('Initialized DAQ successfuly (already initialized)\n');
end
   
expo=PTwrapper('GetExposure');
gain=PTwrapper('GetGain');
fprintf('Initial exposure: %.2f, gain :%.2f\n',1/expo,gain);
SetExposure(hObject,handles,expo,false);
SetGain(hObject,handles,gain,false);



% --- Outputs from this function are returned to the command line.
function varargout = SIMModulePTgrey_OutputFcn(hObject, eventdata, handles) 
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

function timerRecordFunc(timerObject,A)
if ALPwrapper('HasSequenceCompleted')
    stop(timerObject);
    handles = guidata(timerObject.UserData);
    dumpDataToDisk(handles);
    return;
end

handles = guidata(timerObject.UserData);
liveSim = get(handles.hSimLiveView,'value') > 0;
if (liveSim)
    [lastTriplet, frameIndex] = PTwrapper('PokeTriplet');
    if isempty(lastTriplet)
        lastImage = [];
    else
        gaussianWidth = handles.strctRun.simSmoothing;
        % compute SIM image from triplet.
        %Is=convn(double(lastTriplet), fspecial('gaussian',[10*gaussianWidth 10*gaussianWidth],gaussianWidth),'same');
         kernel1D = fspecial('gaussian',[10*gaussianWidth 1],gaussianWidth);
        Is=convn(convn(single(lastTriplet),kernel1D,'same'),kernel1D','same');
       
       lastImage = 1/(3*sqrt(2))* sqrt( (Is(:,:,1)-Is(:,:,2)).^2 + (Is(:,:,1)-Is(:,:,3)).^2 + (Is(:,:,2)-Is(:,:,3)).^2);
        
        if (get(handles.stretchRange,'value'))
             set(handles.axes1,'clim',[min(lastImage(:)),max(lastImage(:))]);
            set(handles.hImage,'CDataMapping','scaled');
        end
        drawnow
        % or...
        % % Phi = 1/3 * (fft2(Is(:,:,1)) + fft2(Is(:,:,2))*exp(i*2*pi/3)+fft2(Is(:,:,3)*exp(i*4*pi/3)));
        % % PhiFourier = fftshift(Phi);
        % % [X,Y]=meshgrid(1:size(Phi,2),1:size(Phi,1));
        % % Z = (sqrt( (X-size(Phi,2)/2).^2+(Y-size(Phi,1)/2).^2));
        % % Weight=normpdf(Z,0,highPassSigma);
        % % HighPassFilter=1-Weight/max(Weight(:));
        % % Phi_highPass=PhiFourier.*HighPassFilter;
        % % Isim_Jerome = abs( ifft2(Phi_highPass));

    end
else
    [lastImage, frameIndex] = PTwrapper('PokeLastImage');
    if get(handles.hGaussianFiltering,'value')
      gaussianWidth = 2.5;
      kernel1D = fspecial('gaussian',[10*gaussianWidth 1],gaussianWidth);
      kernel1D=kernel1D/sum(kernel1D);
      lastImage=convn(convn(double(lastImage),kernel1D,'same'),kernel1D','same');
    end
end

if ~isempty(lastImage)
    % display latest image
    set(handles.hImage,'cdata',lastImage);
    updatePixelStat(handles,lastImage,frameIndex);
    
    if (get(handles.stretchRange,'value'))
        set(handles.hImage,'CDataMapping','scaled');
        set(handles.axes1,'Clim',[min(lastImage(:)) max(lastImage(:))]);
    else
        set(handles.hImage,'CDataMapping','scaled');
        
            m1=min(4095,max(0,str2num(get(handles.hDisplayMaxEdit,'String'))));
            m2=min(4095,max(0,str2num(get(handles.hDisplayMinEdit,'String'))));
            set(handles.axes1,'Clim',[m2 m1]);
        
%        set(handles.axes1,'Clim',[0 4500]);
    end
    
    
end


function timerFunc(timerObject,A)
global g_stats
PTwrapper('SoftwareTrigger');
bufSize = PTwrapper('GetBufferSize');
if bufSize > 0
    % display latest image
    imageBuf = PTwrapper('GetImageBuffer');
    if size(imageBuf,3) >= 1
        handles = guidata(timerObject.UserData);
        lastImage = imageBuf(:,:,end);

    if get(handles.hGaussianFiltering,'value')
      gaussianWidth = 2.5;
      kernel1D = fspecial('gaussian',[10*gaussianWidth 1],gaussianWidth);
      kernel1D=kernel1D/sum(kernel1D);
      lastImage=convn(convn(double(lastImage),kernel1D,'same'),kernel1D','same');
    end

        set(handles.hImage,'cdata',lastImage);
        
        
        if (get(handles.stretchRange,'value'))
            set(handles.hImage,'CDataMapping','scaled');
            set(handles.axes1,'Clim',[min(lastImage(:)) max(lastImage(:))]);
            
        else
            set(handles.hImage,'CDataMapping','scaled');
            m1=min(4095,max(0,str2num(get(handles.hDisplayMaxEdit,'String'))));
            m2=min(4095,max(0,str2num(get(handles.hDisplayMinEdit,'String'))));
            set(handles.axes1,'Clim',[m2 m1]);
        end
        updatePixelStat(handles,lastImage,0);
    end
end

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
set(handles.StartStop,'String','Start');

% --- Executes on button press in StartStop.
function StartStop_Callback(hObject, eventdata, handles)
if strcmp(get(handles.timer,'Running'),'on')
    stopLiveView(handles)
else
    handles.acquiring = true;
    set(handles.StartStop,'String','Stop');
    handles.timer.TimerFcn = @timerFunc;
    start(handles.timer);
end

guidata(hObject, handles);



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
PTwrapper('Init');

if (resetTimer)
    start(handles.timer);
end



function hNumFramesEdit_Callback(hObject, eventdata, handles)
desiredNumFramesToAcquire = str2num(get(handles.hNumFramesEdit,'String'));
rate = str2num(get(handles.hRateEdit,'String'));
% calculate duration
duration = desiredNumFramesToAcquire/rate;
set(handles.hDurationEdit,'String',sprintf('%.2f',duration));
set(handles.hEstimatedSize,'String',sprintf('Estimated Size: %.2f Gb',desiredNumFramesToAcquire*640*480*2/1e9));

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
duration = str2num(get(handles.hDurationEdit,'String'));
rate = str2num(get(handles.hRateEdit,'String'));
desiredNumFramesToAcquire =ceil(duration*rate);
set(handles.hNumFramesEdit,'String',num2str(desiredNumFramesToAcquire));
set(handles.hEstimatedSize,'String',sprintf('Estimated Size: %.2f Gb',desiredNumFramesToAcquire*640*480*2/1e9));



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
% hObject    handle to hGridEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hGridEdit as text
%        str2double(get(hObject,'String')) returns contents of hGridEdit as a double


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
desiredNumFramesToAcquire = str2num(get(handles.hNumFramesEdit,'String'));
rate = str2num(get(handles.hRateEdit,'String'));
duration = desiredNumFramesToAcquire/rate;
set(handles.hDurationEdit,'String',sprintf('%.2f',duration));
set(handles.hEstimatedSize,'String',sprintf('Estimated Size: %.2f Gb',desiredNumFramesToAcquire*640*480*2/1e9));



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



% --- Executes on button press in hRecordButton.
function hRecordButton_Callback(hObject, eventdata, handles)
trigStim = get(handles.hTriggerStimulus,'value');


if isfield(handles,'strctRun') && ~ALPwrapper('HasSequenceCompleted')
    % abort run!
    stop(handles.timer);
    strctRun = handles.strctRun;
    set(handles.hLightON,'fontweight','normal');
    set(handles.hLightOff,'fontweight','bold');
    
    fprintf('Experiment %d aborted and not saved to disk!\n',strctRun.experimentNumber);
    
    ALPwrapper('StopSequence');
    try
    if (trigStim)
        StimulusClient('Abort');
        figure(handles.figure1);drawnow
    end
    catch
    end
    res=fnDAQusb('StopContinuousAcqusition',strctRun.SLOW_DAQ_ID);
    ALPwrapper('PlayUploadedSequence',strctRun.offID,10,1);
    ALPwrapper('ReleaseAllSequences');  
    
    set(handles.hRecordButton,'String','Record');
    
    return;
    
end
try
    if (trigStim)
        strctRun.strctStimulusParams=StimulusClient('Init');
        
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

DAQ1208packetSize = 31;
strctRun.comment = get(handles.hCommentEdit,'String');
strctRun.simMode = get(handles.hSimMode,'value')>0;
strctRun.simSmoothing = 4;
strctRun.cameraGain = PTwrapper('GetGain');
strctRun.cameraExposure= 1.0/PTwrapper('GetExposure');
strctRun.dmdRate = str2num(get(handles.hRateEdit,'String'));
desiredNumFramesToAcquire = str2num(get(handles.hNumFramesEdit,'String'));
% actual number of frames needs to be a multiple of 3 in case of SIM imaging, and of USB packet size...
if (strctRun.simMode)
    actualFrameNumber = (3*DAQ1208packetSize)*ceil(desiredNumFramesToAcquire/(3*DAQ1208packetSize));
    strctRun.numFrames = actualFrameNumber;
    strctRun.dmdNumRepetitions = actualFrameNumber/3;
else
    % epi Mode
    actualFrameNumber = (DAQ1208packetSize)*ceil(desiredNumFramesToAcquire/(DAQ1208packetSize));
    strctRun.numFrames = actualFrameNumber;
    strctRun.dmdNumRepetitions = actualFrameNumber;
 end
strctRun.durationSec = actualFrameNumber/str2num(get(handles.hRateEdit,'String'));

%% DMD
strctRun.simGrid = str2num(get(handles.hGridEdit,'String'));
width = strctRun.simGrid ; % grid size in pixels
phase = 0;               pat1D=mod(phase+[0:1024-1],width) >= width/2;pad1=repmat(pat1D,768,1);
phase = floor(width/3);  pat1D=mod(phase+[0:1024-1],width) >= width/2;pad2=repmat(pat1D,768,1);
phase = floor(2*width/3);pat1D=mod(phase+[0:1024-1],width) >= width/2;pad3=repmat(pat1D,768,1);
pat_phaseShift=reshape([pad1,pad2,pad3],768,1024,3);
strctRun.phaseID = ALPwrapper('UploadPatternSequence',pat_phaseShift);
strctRun.offID = ALPwrapper('UploadPatternSequence',false(768,1024));
strctRun.onID = ALPwrapper('UploadPatternSequence',true(768,1024));

%%
% Get baseline.
numBaselineFrames = min(100,max(1,str2num(get(handles.hBaselineEdit,'String'))));
I=PTwrapper('GetImageBuffer'); % clear buffer
res=ALPwrapper('PlayUploadedSequence',strctRun.offID,strctRun.dmdRate, numBaselineFrames);
ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
tic; while toc < 0.2; end;
strctRun.baseline=PTwrapper('GetImageBuffer'); % clear buffer
%% Camera


%% DAQ
strctRun.slowDAQrateHz = 2000;

strctRun.SLOW_DAQ_ID = 1;
strctRun.numSlowChannels = 2;
strctRun.slowDAQnumSamplesPerChannel = ceil(strctRun.slowDAQrateHz * strctRun.durationSec / DAQ1208packetSize)*DAQ1208packetSize;
res=fnDAQusb('StopContinuousAcqusition',strctRun.SLOW_DAQ_ID);
res=fnDAQusb('Allocate',strctRun.SLOW_DAQ_ID, strctRun.numSlowChannels, strctRun.slowDAQnumSamplesPerChannel, 1, 1);
res=fnDAQusb('StartContinuousAcqusitionFixedRateTrigger',strctRun.SLOW_DAQ_ID,strctRun.slowDAQrateHz ); 


%% Start acuqisiton
if (strctRun.simMode)
    res=ALPwrapper('PlayUploadedSequence',strctRun.phaseID,strctRun.dmdRate, strctRun.dmdNumRepetitions);
else
    if (get(handles.AutoTurnLightWithEPI,'value'))
        res=ALPwrapper('PlayUploadedSequence',strctRun.onID,strctRun.dmdRate, strctRun.dmdNumRepetitions);
        set(handles.hLightON,'fontweight','bold');
        set(handles.hLightOff,'fontweight','normal');
    else
        % used to create a control for light leakage from stimulus monitor...
        res=ALPwrapper('PlayUploadedSequence',strctRun.offID,strctRun.dmdRate, strctRun.dmdNumRepetitions);
        set(handles.hLightON,'fontweight','normal');
        set(handles.hLightOff,'fontweight','bold');
    end
end

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

if get(handles.hSimLiveView,'value')
  rate = 2;
else
    rate = 50;
end
handles.timer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period',1/rate);
handles.timer.StartDelay = 0;
handles.timer.UserData = hObject;
handles.timer.TimerFcn = @timerRecordFunc;

handles.strctRun = strctRun;

guidata(hObject, handles);


start(handles.timer);


function dumpDataToDisk(handles)
set(handles.hRecordButton,'String','Record');

tic; while toc < 0.2; end;   % wait a bit for buffer transfer...
% verify we have all data...
strctRun = handles.strctRun;
strctRun.images=PTwrapper('GetImageBuffer'); 
if (size(strctRun.images,3) ~= strctRun.numFrames)
    fprintf('CRITICAL ERROR! Number of images mismatch!\n');
    lightsOff(handles);
    ALPwrapper('ReleaseAllSequences');      
    return;
else
    fprintf('All frames recorded correctly.');
end
strctRun.valuesSlow=squeeze(fnDAQusb('GetBuffer',strctRun.SLOW_DAQ_ID));

lightsOff(handles);
set(handles.hLightON,'fontweight','normal');
set(handles.hLightOff,'fontweight','bold');

ALPwrapper('ReleaseAllSequences');  
strFileName = sprintf('%s/Experiment%04d.mat',handles.outputFolder,strctRun.experimentNumber);
fprintf('Dumping experiment %d to disk...',strctRun.experimentNumber);
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
onID = ALPwrapper('UploadPatternSequence',true(768,1024));
ALPwrapper('PlayUploadedSequence',onID,10,1); % turn off light
set(handles.hLightON,'fontweight','bold');
set(handles.hLightOff,'fontweight','normal');

function lightsOff(handles)
offID = ALPwrapper('UploadPatternSequence',false(768,1024));
ALPwrapper('PlayUploadedSequence',offID,10,1); % turn off light
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


% --- Executes on button press in hGaussianFiltering.
function hGaussianFiltering_Callback(hObject, eventdata, handles)
% hObject    handle to hGaussianFiltering (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hGaussianFiltering



function hDisplayMinEdit_Callback(hObject, eventdata, handles)
m2=min(4095,max(0,str2num(get(handles.hDisplayMinEdit,'String'))));
m1=min(4095,max(0,str2num(get(handles.hDisplayMaxEdit,'String'))));

if m2 > m1
    set(handles.hDisplayMinEdit,'String','0');
end


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


% --- Executes on button press in hTestAcqusitionSpeed.
function hTestAcqusitionSpeed_Callback(hObject, eventdata, handles)
