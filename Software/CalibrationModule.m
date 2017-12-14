function varargout = CalibrationModule(varargin)
% CALIBRATIONMODULE MATLAB code for CalibrationModule.fig
%      CALIBRATIONMODULE, by itself, creates a new CALIBRATIONMODULE or raises the existing
%      singleton*.
%
%      H = CALIBRATIONMODULE returns the handle to a new CALIBRATIONMODULE or the handle to
%      the existing singleton*.
%
%      CALIBRATIONMODULE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CALIBRATIONMODULE.M with the given input arguments.
%
%      CALIBRATIONMODULE('Property','Value',...) creates a new CALIBRATIONMODULE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CalibrationModule_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CalibrationModule_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CalibrationModule

% Last Modified by GUIDE v2.5 15-Dec-2016 12:29:35

% Begin initialization code - DO NOT EDITguide
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CalibrationModule_OpeningFcn, ...
                   'gui_OutputFcn',  @CalibrationModule_OutputFcn, ...
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


% --- Executes just before CalibrationModule is made visible.
function CalibrationModule_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CalibrationModule (see VARARGIN)

% Choose default command line output for CalibrationModule


% strDropBoxFolder = 'C:\Users\shayo\Dropbox';
% addpath([strDropBoxFolder,'\Code\Waveform Reshaping code\MEX\x64']);
% Choose default command line output for CameraModule
handles.output = hObject;
handles.varargin = varargin;
if ~isempty(varargin)
    strCommand =  varargin{1};
    if (strcmpi(strCommand,'GetAlgorithmParams'))
        output.strctCalibrationParams = getCalibrationParamsFromGUI(handles);
        output.strctSegmentationParams = getSegmetnationParams(handles);
        
        handles.output = output;
        guidata(hObject,handles);
        return;
    elseif (strcmpi(strCommand,'Calibrate'))
        [~,~,handles.output]=RunCalibration(hObject);
        return;
    end
    
%     handles.dmd = varargin{1};
%     guidata(hObject,handles);
%     sessionList = SessionWrapper('ListSessions');
%     set(handles.hSessionPopup,'String',sessionList,'value',length(sessionList));
%     Depths = SessionWrapper('LoadSession',sessionList{end});
%     set(handles.hActiveCalibration,'String',Depths,'value',length(Depths));
   
end
set(handles.figure1,'position',[ -365.6000   22.8462  215.8000   30.8462]);
guidata(hObject, handles);

set (handles.figure1, 'WindowButtonDownFcn', {@mouseDown, handles.figure1});

if ~isfield(handles,'dmd')
    addpath(genpath(pwd()));

    % first time GUI boots up
    set(handles.CalibrationFilterWheel473nm,'String',{'ND1','ND2','ND3','ND4','ND5','ND6'});
    set(handles.SegmentationFilterWheel473nm,'String',{'ND1','ND2','ND3','ND4','ND5','ND6'});
    set(handles.SweepTestFilterWheel473nm,'String',{'ND1','ND2','ND3','ND4','ND5','ND6'});

    set(handles.CalibrationFilterWheel532nm,'String',{'ND1','ND2','ND3','ND4','ND5','ND6'});
    set(handles.SegmentationFilterWheel532nm,'String',{'ND1','ND2','ND3','ND4','ND5','ND6'});
    set(handles.SweepTestFilterWheel532nm,'String',{'ND1','ND2','ND3','ND4','ND5','ND6'});

    handles.numModes = [256,1024,4096,8192,13000,16384,20000];
    handles.numBlocks = [16,32,64,96,128,192];
    handles.numMirrorsPerMode = [4,6,8,10,11,12,16,18,20,24,30,40];
    set(handles.hNumModesPopup,'String',numArrayToCell(handles.numModes),'value',3);
    set(handles.hNumBlocksPopup,'String',numArrayToCell(handles.numBlocks),'value',3);
    set(handles.hNumMirrorsPerBlock,'String',numArrayToCell(handles.numMirrorsPerMode),'value',6);
    set(handles.hSpotRadiusPix,'string','3');
    %set( handles.figure1, 'toolbar', 'figure' )
    [X,Y,Res1,Res2]=GetCameraParams();
    Z = zeros(Res1,Res2);
    handles.hImage = image(Z,'parent',handles.axes1);
    colormap(handles.axes1,'gray');
    set(handles.axes1,'visible','off');
    
    devices = ALPwrapper('GetDevices');
    acDevices = cell(1,length(devices));
    for k=1:length(devices)
       acDevices{k} = sprintf('ALP %d, %d',k,devices(k).Serial);
    end
    set(handles.hALPlist,'string',acDevices,'value',1);
    
    guidata(hObject, handles);
    
    InitCalibrationModule(hObject, handles);
    set(handles.figure1,'CloseRequestFcn',{@CloseCalibrationModule,handles});
  %  set(handles.figure1,'position',[  2.0000    5.6154  125.4000   40.5385]);
end

function CloseCalibrationModule(src,evnt,handles)
selection = questdlg('Close Calibration Module?',...
    'Close Request Function',...
    'Yes','No','Yes');
switch selection,
    case 'Yes',
        myhandles = guidata(gcbo);
        ALPID = get(handles.hALPlist,'value')-1;
        if (ALPwrapper('IsInitialized',ALPID))
            ALPwrapper('Release',ALPID);
        end
        delete(myhandles.figure1)
    case 'No'
        return
end

function B=numArrayToCell(A)
B=cell(1,length(A));
for k=1:length(A)
    B{k}=num2str(A(k));
end;
return;

function InitCalibrationModule(hObject, handles)
    SessionWrapper('Init');
    dmd.deviceID = get(handles.hALPlist,'value')-1;
    
    dmd.carrierRotation = [124/180*pi, 86/180*pi];
    dmd.selectedCarrier = [0.21 0.3]; % 0.2
    
    

    dmd.width = 1024;
    dmd.height = 768;
    dmd.effectiveDMDsize = min(dmd.width,dmd.height);
    
    dmd.fiberDiameterUm = 100; % um
    dmd.exposureForSegmtation = 6000.0;
    dmd.exposureForCalibration = 6000.0;
    dmd.exposureForSweepTest = 6000.0;
    dmd.naturalDensityForSegmentation = [3 2];
    dmd.naturalDensityForCalibration = [3 2];
    dmd.naturalDensityForSweepTest = 4;
    dmd.backgroundLevel = 320;
    dmd.fiberBox = [];
    dmd.cameraRate = 1500;%
    dmd.quantization = 1; % Crop / resize I to make things more compact (?)
    dmd.patternsLoadedAndUploaded = false;
    dmd.calibrationFinished = false;
    
    dmd.timer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period',2); % 0.5 Hz
    dmd.timer.StartDelay = 0;
    dmd.timer.UserData = hObject;
    dmd.timer.TimerFcn = @TestStabilityTimerFunc;
     
    % Initialize Camera
 
    dmd.hadamardSequenceID = -1;
    dmd.sweepSequenceID = -1;
    dmd.spotSequenceID = -1;
    dmd.onID = ALPwrapper('UploadPatternSequence',dmd.deviceID,true(768,1024));
    if (dmd.onID == -1)
        ALPwrapper('Release',dmd.deviceID);
        ALPwrapper('Init',dmd.deviceID);
        dmd.onID = ALPwrapper('UploadPatternSequence',dmd.deviceID,true(768,1024));
    end
    [~,L]=LeeHologram(zeros(dmd.height,dmd.width), dmd.selectedCarrier(1), dmd.carrierRotation(1)); % Default: Blue laser
    dmd.zeroID=ALPwrapper('UploadPatternSequence',dmd.deviceID,L);
    
    res=ALPwrapper('PlayUploadedSequence',dmd.deviceID,dmd.zeroID,10, 1);
    ALPwrapper('WaitForSequenceCompletion',dmd.deviceID); % Block. Wait for sequence to end.
    set(handles.segmentationExposureEdit,'String',num2str(dmd.exposureForSegmtation));
    set(handles.calibrationExposureEdit,'String',num2str(dmd.exposureForCalibration));
    set(handles.sweepTestExposureEdit,'String',num2str(dmd.exposureForSweepTest));
    
    set(handles.CalibrationFilterWheel473nm, 'value', dmd.naturalDensityForCalibration(1));
    set(handles.SegmentationFilterWheel473nm, 'value', dmd.naturalDensityForSegmentation(1));
    set(handles.SweepTestFilterWheel473nm, 'value', dmd.naturalDensityForSweepTest);
    
    set(handles.CalibrationFilterWheel532nm, 'value', dmd.naturalDensityForCalibration(2));
    set(handles.SegmentationFilterWheel532nm, 'value', dmd.naturalDensityForSegmentation(2));
    set(handles.SweepTestFilterWheel532nm, 'value', dmd.naturalDensityForSweepTest);

    set(handles.hCarrierFreq473,'String', num2str(dmd.selectedCarrier(1)));
    set(handles.hCarrierFreq532,'String', num2str(dmd.selectedCarrier(2)));

    set(handles.hCarrierAngle473,'String', num2str(dmd.carrierRotation(1)/pi*180));
    set(handles.hCarrierAngle532,'String', num2str(dmd.carrierRotation(2)/pi*180));
    
    set(handles.hDepthMin3D,'String','0');
    set(handles.hDepthMax3D,'String','50');    
    set(handles.hDepthInterval3D,'String','50');
    set(handles.calibAvgEdit,'String','1');
    set(handles.SegmentationFilterWheel473nm,'String',{'ND1','ND2','ND3','ND4','ND5','ND6'});
    set(handles.hCameraRate,'String',num2str(dmd.cameraRate));
    set(handles.hSweep473,'value',0);
    set(handles.hPSFZtest,'value',0);
     sessionList = SessionWrapper('ListSessions');
    set(handles.hSessionPopup,'String',sessionList,'value',length(sessionList));
    % Load depths 
    if ~isempty(sessionList)
        Depths = SessionWrapper('LoadSession',sessionList{end});
        set(handles.hActiveCalibration,'String',Depths,'value',length(Depths));
    end
    
    guidata(hObject, handles);    
% displayMessage(handles,'initialized DMD!');
% 



% --- Outputs from this function are returned to the command line.
function varargout = CalibrationModule_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ~isempty(handles.varargin) 
    if length(handles.varargin) >= 1 && ischar(handles.varargin{1}) && strcmp(handles.varargin{1},'GetCalibration') 
        varargout{1} = handles.output;
    end
else
    varargout{1} = handles.output;
end


% --- Executes on button press in InitializeButton.
function InitializeButton_Callback(hObject, eventdata, handles)
% Load hadamard stuff...

function displayMessage(handles,strMessage)
set(handles.statusText,'String',strMessage);
fprintf('%s\n',strMessage);
drawnow

function [segmentationParams] = getSegmetnationParams(handles)
segmentationParams.hCalibrateGreen = get(handles.hCalibrateGreen,'value')>0;
segmentationParams.hCalibrateBlue = get(handles.hCalibrateBlue,'value')>0;
segmentationParams.exposureForSegmtation = str2num(get(handles.segmentationExposureEdit,'string'));
segmentationParams.naturalDensityForSegmentation = [get(handles.SegmentationFilterWheel473nm,'value'),get(handles.SegmentationFilterWheel532nm,'value')];



leeBlockSize = handles.numMirrorsPerMode(get(handles.hNumMirrorsPerBlock,'value'));
hadamardSize = handles.numBlocks(get(handles.hNumBlocksPopup,'value'));
dmd.width = 1024;
dmd.height = 768;
dmd.effectiveDMDsize = min(dmd.width,dmd.height);
segmentationParams.numReferencePixels = max(0,(dmd.effectiveDMDsize-leeBlockSize*hadamardSize)/2);
segmentationParams.leeBlockSize = handles.numMirrorsPerMode(get(handles.hNumMirrorsPerBlock,'value'));
segmentationParams.selectedCarrier = [str2num(get(handles.hCarrierFreq473,'string')),str2num(get(handles.hCarrierFreq532,'string'))];
segmentationParams.carrierRotation = [str2num(get(handles.hCarrierAngle473,'string')),str2num(get(handles.hCarrierAngle532,'string'))]/180*pi;

segmentationParams.ALPID = get(handles.hALPlist,'value')-1;
segmentationParams.hFullFOV =  handles.hFullFOV;
segmentationParams.dmdHeight = 768;
segmentationParams.dmdWidth = 1024;

return;

% --- Executes on button press in SegmentButton.
function ok=SegmentButton_Callback(hObject, eventdata, handles)
[params] = getSegmetnationParams(handles);
[ok, strctSegmentationResult]=SegmentationCLI(params, handles.axes1);
handles.strctSegmentationResult = strctSegmentationResult;
% handles.dmd.radius = strctSegmentation.radius;
% handles.dmd.fiberBox = strctSegmentation.fiberBox;
guidata(hObject,handles);
return;




% --- Executes on button press in SaveCalibration.
function SaveCalibration_Callback(hObject, eventdata, handles)
% hObject    handle to SaveCalibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in LoadCalibration.
function LoadCalibration_Callback(hObject, eventdata, handles)
% hObject    handle to LoadCalibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function segmentationExposureEdit_Callback(hObject, eventdata, handles)
handles.dmd.exposureForSegmtation= str2num(get(hObject,'String'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function segmentationExposureEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to segmentationExposureEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% 
% % --- Executes on button press in zeroPhaseMaskButton.
% function zeroPhaseMaskButton_Callback(hObject, eventdata, handles)
% % res=ALPwrapper('PlayUploadedSequence',handles.dmd.zeroID,10, 1);
% % ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
% [~,L]=LeeHologram(zeros(768,1024),0.19);
% ALPuploadAndPlay(L,1,1);

% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
frameToShow = round(get(hObject,'value')* (size(handles.dmd.sweepSequenceImages,3)-1))+1;
cla(handles.axes1);
colormap(handles.axes1,'gray');
handles.hImage = image(handles.dmd.sweepSequenceImages(:,:,frameToShow),'parent',handles.axes1,'CDataMapping','scaled');
set(handles.axes1,'xlim',[0 handles.dmd.fiberBox(3)],...
                  'ylim',[0 handles.dmd.fiberBox(4)]);
set(handles.axes1,'Clim',[0 1024]);
drawnow



% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function strctParams = getCalibrationParamsFromGUI(handles)

strctParams.deviceID = get(handles.hALPlist,'value')-1;

strctParams.dmdWidth = 1024;
strctParams.dmdHeight = 768;
strctParams.dmdEffectiveDMDsize = min(strctParams.dmdWidth,strctParams.dmdHeight);


strctParams.numBasis =  handles.numModes(get(handles.hNumModesPopup,'value'));
strctParams.hadamardSize = handles.numBlocks(get(handles.hNumBlocksPopup,'value'));
strctParams.leeBlockSize = handles.numMirrorsPerMode(get(handles.hNumMirrorsPerBlock,'value'));
strctParams.numReferencePixels = max(0,(strctParams.dmdEffectiveDMDsize-strctParams.leeBlockSize*strctParams.hadamardSize)/2);

strctParams.selectedCarrier = [str2num(get(handles.hCarrierFreq473,'String')),str2num(get(handles.hCarrierFreq532,'String'))];
strctParams.carrierRotation = [str2num(get(handles.hCarrierAngle473,'String'))/180*pi,str2num(get(handles.hCarrierAngle532,'String'))/180*pi];
strctParams.sweepTests = [get(handles.hSweep473,'value') >0 , get(handles.hSweep532,'value') > 0];
strctParams.fullReconstruction = get(handles.hFullCalibration,'value')>0;
strctParams.CalibrationMotorDirection = get(handles.hMoveDownDuringZsweep,'value');

strctParams.Calib3D = get(handles.h3DCalibration,'value');
strctParams.CalibDepths = get(handles.hDepthCalibration,'value');
strctParams.colorChannels = [get(handles.hCalibrateBlue,'value')>0,get(handles.hCalibrateGreen,'value')]>0;

strctParams.FineDepthMinUm = str2num(get(handles.hDepthMin3D,'String'));
strctParams.FineDepthMaxUm = str2num(get(handles.hDepthMax3D,'String'));
strctParams.FineDepthIntervalUm = str2num(get(handles.hDepthInterval3D,'String'));

strctParams.DepthMinUm = str2num(get(handles.hDepthMin,'String'));
strctParams.DepthMaxUm = str2num(get(handles.hDepthMax,'String'));
strctParams.DepthIntervalUm = str2num(get(handles.hDepthInterval,'String'));

strctParams.numCalibrationAverages = str2num(get(handles.calibAvgEdit,'String'));

strctParams.exposureForCalibration = str2num(get(handles.calibrationExposureEdit,'String'));
strctParams.naturalDensityForSegmentation(1) = get(handles.SegmentationFilterWheel473nm, 'value');
strctParams.naturalDensityForCalibration(1) = get(handles.CalibrationFilterWheel473nm, 'value');
strctParams.naturalDensityForSweepTest(1) = get(handles.SweepTestFilterWheel473nm, 'value');

strctParams.naturalDensityForSegmentation(2) = get(handles.SegmentationFilterWheel532nm, 'value');
strctParams.naturalDensityForCalibration(2) = get(handles.CalibrationFilterWheel532nm, 'value');
strctParams.naturalDensityForSweepTest(2) = get(handles.SweepTestFilterWheel532nm, 'value');
strctParams.cameraRate = str2num(get(handles.hCameraRate,'string'));

strctParams.spotRadiusPixels = str2num(get(handles.hSpotRadiusPix,'string'));
strctParams.quantization = 1; % Crop / resize I to make things more compact (?)
strctParams.returnToZero =  get(handles.hReturnToPos0,'value');
strctParams.psfZtest= get(handles.hPSFZtest,'value');
%runSweepTest = sum(strctCalibrationParams.sweepTests > 0);
% psfZtest 
% if runSweepTest || psfZtest
%     set(handles.hFullCalibration,'value',true);
% end    

return ;


% --- Executes on button press in RunCalibration.
function RunCalibration_Callback(hObject, eventdata, handles)
strctSegmentationParams = getSegmetnationParams(handles);
[~,strctSegmentationResult] = SegmentationCLI(strctSegmentationParams,[]);

strctCalibrationParams = getCalibrationParamsFromGUI(handles);
handles.calibration = CalibrationClass(strctCalibrationParams,strctSegmentationResult);
handles.calibration.Calibrate();
guidata(hObject,handles);

%[ok,stats,CalibSessionFileName]=CalibrationCLI(strctParams);

sessionList = SessionWrapper('ListSessions');
set(handles.hSessionPopup,'String',sessionList,'value',length(sessionList));
% Load depths
Depths = SessionWrapper('LoadSession',sessionList{end});
set(handles.hActiveCalibration,'String',Depths,'value',length(Depths));

% 
% function TestStabilityTimerFunc(timerObject,A)
% handles = guidata(timerObject.UserData);
% dmd = handles.dmd;
% 
% 
% I=PTwrapper('GetImageBuffer'); % clear buffer
% res=ALPwrapper('PlayUploadedSequence',dmd.zeroID,10, 10); % play the zero phase sequence ten times.
% ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
% WaitSecs(0.5); % allow enough time for image transfer
% I=PTwrapper('GetImageBuffer');
% 
% dmd.tm(dmd.iteration)=GetSecs();
% meanI = mean(double(I),3);
% dmd.diffI(dmd.iteration) = mean(abs(meanI(:)-dmd.I0(:)));
% 
% L=bwlabel(meanI>dmd.backgroundLevel);
% R=regionprops(L);
% [~,maxCC]=max(cat(1,R.Area));
% dmd.cent(dmd.iteration,:)=R(maxCC).Centroid;
% 
% figure(1);
% clf;
% subplot(1,4,1);
% imagesc(meanI-dmd.I0);
% colorbar
% colormap gray
% % set(gca,'xlim',[0 350],'ylim',[0 350]);
% subplot(1,4,2);
% timeSec = (dmd.tm(1:dmd.iteration)-dmd.tm(1))/60;
% plot(timeSec,dmd.diffI(1:dmd.iteration));
% set(gca,'xlim',[0.1 1+timeSec(end)]);
% xlabel('Minutes');
% title(sprintf('%d : %.4f',dmd.iteration,dmd.diffI(dmd.iteration)));
% subplot(1,4,3);
% imagesc(meanI);
% subplot(1,4,4);
% plot(timeSec,(dmd.cent(1:dmd.iteration,:)-repmat(dmd.cent(1,:),dmd.iteration,1)));
% set(gcf,'position',[47         609        1804         369]);
% drawnow
% 
% dmd.iteration = dmd.iteration+1;
% handles.dmd = dmd;
% guidata(timerObject.UserData,handles)

% --- Executes on button press in TestStability.
% function TestStability_Callback(hObject, eventdata, handles)
% dmd = handles.dmd;
% if strcmp(get(dmd.timer,'Running'),'on')
%     StopStabilityTest(hObject);
% else
%     StartStabilityTest(hObject);
% end

% function StopStabilityTest(hObject)
% handles = guidata(hObject);
% stop(handles.dmd.timer);
% set(handles.TestStability,'String','Start Stability');

% 
% function StartStabilityTest(hObject)
% handles = guidata(hObject);
% cameraInitalized=CameraModule('IsInitialized');
% if (~cameraInitalized)
%     figure(handles.figure1);
%     displayMessage(handles,'Unable to initialize camera module');
%     return
% end
% CameraModule('StopLiveView');
% figure(handles.figure1);
% dmd = handles.dmd;
% %%
% % Play the zero phase pattern!
% dmd.timer.UserData = hObject;
% 
% I=PTwrapper('GetImageBuffer');
% PTwrapper('SetExposure',1.0/handles.dmd.exposureForSegmtation);
% 
% res=ALPwrapper('PlayUploadedSequence',dmd.zeroID,10, 1);
% ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
% while PTwrapper('GetBufferSize') == 0; end
% dmd.I0=double(PTwrapper('GetImageBuffer'));
% % J=zeros(480,640,1000);
% dmd.tm=zeros(1,8000);
% dmd.diffI = zeros(1,8000);
% dmd.cent = zeros(8000,2);
% dmd.iteration = 1;
% dmd.timer.UserData = hObject;
% handles.dmd = dmd;
% guidata(hObject,handles);
% set(handles.TestStability,'String','Stop Stability');
% start(dmd.timer);



function calibrationExposureEdit_Callback(hObject, eventdata, handles)
%handles.dmd.exposureForCalibration = str2num(get(hObject,'String'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function calibrationExposureEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calibrationExposureEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hDepthMin3D_Callback(hObject, eventdata, handles)
% hObject    handle to hDepthMin3D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hDepthMin3D as text
%        str2double(get(hObject,'String')) returns contents of hDepthMin3D as a double


% --- Executes during object creation, after setting all properties.
function hDepthMin3D_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDepthMin3D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% 
% % --- Executes on button press in SweepTest.
% function SweepTest_Callback(hObject, eventdata, handles)
% 
% ok = false;
% cameraInitalized=CameraModule('IsInitialized');
% if (~cameraInitalized)
%     figure(handles.figure1);
%     displayMessage(handles,'Unable to initialize camera module');
%     return
% end
% CameraModule('StopLiveView');
% figure(handles.figure1);
% 
% dmd=handles.dmd;
% 
% if ~isfield(dmd,'newSize')
%     displayMessage(handles,'Run calibration first!');
%     return;
% end
% 
% if isfield(dmd,'Enhancement')
%     selection = questdlg('Sweep Sequence exist. What do to?',...
%     'Warning',...
%     'Run again','Quit','Quit');
% 
%     if strcmp(selection ,'Quit')
%         return;
%     end
% end
% 
% 
% 
% if ~FilterWheelModule('IsInitialized')
%     figure(handles.figure1);
%     displayMessage(handles,'Unable to initialize filter wheel module');
%     return
% end
% FilterWheelModule('SetNaturalDensity',dmd.naturalDensityForSweepTest);
% figure(handles.figure1);
% 
% 
% 
% displayMessage(handles,'Getting baseline...');
% PTwrapper('SetExposure',1.0/handles.dmd.exposureForSweepTest);
% % sometimes, for very short exposures, this causes the camera to stuck!
% % Play sequence
% offID = ALPwrapper('UploadPatternSequence',false(768,1024));
% I=PTwrapper('GetImageBuffer'); % clear buffer
% res=ALPwrapper('PlayUploadedSequence',offID,dmd.cameraRate, 100);
% ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
% ALPwrapper('ReleaseSequence',offID);
% WaitSecs(0.2+1/dmd.cameraRate);
% B = PTwrapper('GetImageBuffer');
% dmd.Baseline=mean(single(B),3);
% 
% % Now, run things in chunks (not enough memory to hold all these images...)
% chunkSize = 15000;
% startInd=1:chunkSize:dmd.numSpots;
% endInd = min(dmd.numSpots,startInd+chunkSize-1);
% 
% numChunks = length(startInd);
% dmd.MaxIntensity = zeros(1,dmd.numSpots);
% dmd.MaxLocation = zeros(1,dmd.numSpots);
% dmd.Enhancement = zeros(1,dmd.numSpots);
% dmd.maxDisc = zeros(2*dmd.radius+1,2*dmd.radius+1);
% 
% dmd.secondaryPeak = zeros(1,dmd.numSpots);
% dmd.secondaryPeakLocation = zeros(1,dmd.numSpots);
%  
% 
% [X,Y]=meshgrid(1:2*dmd.radius+1,1:2*dmd.radius+1);
% binaryDisc = sqrt((X-(dmd.radius+1)).^2+(Y-(dmd.radius+1)).^2) <= dmd.radius;
% dmd.BaselineCropped = single(dmd.Baseline(dmd.fiberBox(2):dmd.fiberBox(2)+2*dmd.radius,...
%                                           dmd.fiberBox(1):dmd.fiberBox(1)+2*dmd.radius));
% 
% 
% ALPwrapper('ReleaseAllSequences');
% for iteration=1:numChunks
%     SweepSequence = dmd.holograms(:,:,startInd(iteration):endInd(iteration));
%     numPatternsToShow = endInd(iteration)-startInd(iteration)+1;
%     displayMessage(handles,sprintf('Iteration %d/%d: Uploading %d patterns....',iteration,numChunks, numPatternsToShow))
%     if (dmd.sweepSequenceID > 0)
%         ALPwrapper('ReleaseSequence',dmd.sweepSequenceID);
%     end
%     dmd.sweepSequenceID=ALPwrapper('UploadPatternSequence',SweepSequence);
%     displayMessage(handles,sprintf('Iteration %d/%d: Running sequence (%.2f min)....',iteration,numChunks, numPatternsToShow/dmd.cameraRate/60));    
%     
%     ALPuploadAndPlay(zeros(768,1024)>0,100,100); ALPwrapper('WaitForSequenceCompletion'); WaitSecs(0.5);Q=PTwrapper('GetImageBuffer');
%     
%     res=ALPwrapper('PlayUploadedSequence',dmd.sweepSequenceID,dmd.cameraRate, 1);
%     ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
%     WaitSecs(1);
% %     b=PTwrapper('GetBufferSize')
%     Q=PTwrapper('GetImageBuffer');
%     if size(Q,3) ~= numPatternsToShow
%         displayMessage(handles,'Error during intensity normalization. Missed frames!');
%         return
%     end
%     Qr=Q(dmd.fiberBox(2):dmd.fiberBox(2)+2*dmd.radius,dmd.fiberBox(1):dmd.fiberBox(1)+2*dmd.radius,:);
%     clear Q;
%     % collect statistics: maximum intensity and location of max intensity?
%    displayMessage(handles,sprintf('Iteration %d/%d: Extracting Statistics....',iteration,numChunks));
%     for k=1:numPatternsToShow
%         globalind = startInd(iteration)+k-1;
%         Tmp=single(Qr(:,:,k))-dmd.BaselineCropped;        
%         [my,mx]=ind2sub(size(dmd.maxDisc), dmd.hologramSpotPos(globalind));
%         % expected spot position is at [mx,my]
%         ay = min(size(dmd.maxDisc,1),max(1,my-5:my+5));
%         ax = min(size(dmd.maxDisc,2),max(1,mx-5:mx+5));
%         [AX,AY]=meshgrid(ax,ay);
%         neighInd= sub2ind(size(dmd.maxDisc), AY(:),AX(:));
%         [dmd.MaxIntensity(globalind), maxind]=max(Tmp(neighInd));
%         dmd.MaxLocation(globalind) = sub2ind(size(dmd.maxDisc), AY(maxind), AX(maxind));
%         dmd.maxDisc( dmd.hologramSpotPos(globalind)) = dmd.MaxIntensity(globalind);
%         % clear the local enhancement, and compute the mean
%         Tmp(neighInd)=0;
%         [dmd.secondaryPeak(globalind),dmd.secondaryPeakLocation(globalind)] = max(Tmp(:));
%         dmd.Enhancement(globalind) = dmd.MaxIntensity(globalind)/mean(Tmp(binaryDisc));
%     end
% end
% %% Analyze spot formation quality
% MaxI = zeros(dmd.newSize(1:2));
% Enha = zeros(dmd.newSize(1:2));
% MaxI(dmd.hologramSpotPos) = dmd.MaxIntensity;
% Enha(dmd.hologramSpotPos) = dmd.Enhancement;
% SecondPeak = zeros(dmd.newSize(1:2));
% SecondPeak(dmd.hologramSpotPos) = dmd.secondaryPeak;
% [y0,x0]=ind2sub(dmd.newSize(1:2),dmd.hologramSpotPos(:));
% [y1,x1]=ind2sub(dmd.newSize(1:2),dmd.MaxLocation(:));
% 
% 
% figure(12);
% clf;
% subplot(2,2,1);
% imagesc(MaxI);
% myColorbar
% axis off
% title('Max Spot Intensity');
% subplot(2,2,2);
% imagesc(Enha);
% myColorbar
% axis off
% title('Enhancement');
% subplot(2,2,3);
% posError = (sqrt((x1-x0).^2+(y1-y0).^2)) > 0;
% quiver(x0(posError),y0(posError),x1(posError)-x0(posError),y1(posError)-y0(posError));
% title('Displacement errors');
% subplot(2,2,4);
% imagesc(SecondPeak,[0 max(MaxI(:))]);
% myColorbar();
% title('Second peak intensity');
% %%
% % look at problems forming the spot
% 
% %%
% 
% dmd.sweepSequenceImages= Qr;
% 
% handles.dmd = dmd;
% guidata(hObject,handles);
% 
% ReplaySweepSequence(handles);
% return;


% 
% function ReplaySweepSequence(handles)
% if ~isfield(handles.dmd,'sweepSequenceImages')
%     displayMessage(handles,'Run a sweep first!');
%     return;
% end
% cla(handles.axes1);
% colormap(handles.axes1,'gray');
% handles.hImage = image(single(handles.dmd.sweepSequenceImages(:,:,1)),'parent',handles.axes1,'CDataMapping','scaled');
% set(handles.axes1,'xlim',[0 handles.dmd.fiberBox(3)],...
%                   'ylim',[0 handles.dmd.fiberBox(4)]);
% set(handles.axes1,'Clim',[0 1095]);
% numImages = size(handles.dmd.sweepSequenceImages,3);
% imagesToDisplay = round(linspace(1,numImages,200));
% try
% for k=1:length(imagesToDisplay)
%     set(handles.hImage,'cdata',handles.dmd.sweepSequenceImages(:,:,imagesToDisplay(k)));
%     drawnow
% end
% catch
% end


%      figure(11);
%     clf;
%      colormap gray
%     maxQr = max(Qr(:));
%     for k=1:5:size(Q,3)
%         imagesc(Q(:,:,k),[0 1+maxQr*1.1])
%         hold on;
%         plot(fiberCenter(1)+cos(afAngle)*fiberDiameterPix/2,fiberCenter(2)+sin(afAngle)*fiberDiameterPix/2,'g');
%         set(gca,'ylim',[fiberBox(2),fiberBox(2)+fiberBox(4)-1],'xlim',[fiberBox(1),fiberBox(1)+fiberBox(3)]);
%         drawnow
%         hold off;
%     end
%     impixelinfo


% --- Executes on button press in ReplaySweep.
function ReplaySweep_Callback(hObject, eventdata, handles)
ReplaySweepSequence(handles);

function sweepTestExposureEdit_Callback(hObject, eventdata, handles)
% handles.dmd.exposureForSweepTest = str2num(get(hObject,'String'));
% guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function sweepTestExposureEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sweepTestExposureEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hDepthMax3D_Callback(hObject, eventdata, handles)
% hObject    handle to hDepthMax3D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hDepthMax3D as text
%        str2double(get(hObject,'String')) returns contents of hDepthMax3D as a double


% --- Executes during object creation, after setting all properties.
function hDepthMax3D_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDepthMax3D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hDepthInterval3D_Callback(hObject, eventdata, handles)
% hObject    handle to hDepthInterval3D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hDepthInterval3D as text
%        str2double(get(hObject,'String')) returns contents of hDepthInterval3D as a double


% --- Executes during object creation, after setting all properties.
function hDepthInterval3D_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDepthInterval3D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in SegmentationFilterWheel473nm.
function SegmentationFilterWheel473nm_Callback(hObject, eventdata, handles)
% handles.dmd.naturalDensityForSegmentation(1) = get(handles.SegmentationFilterWheel473nm, 'value');
% guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function SegmentationFilterWheel473nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SegmentationFilterWheel473nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in CalibrationFilterWheel473nm.
function CalibrationFilterWheel473nm_Callback(hObject, eventdata, handles)
% hObject    handle to CalibrationFilterWheel473nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns CalibrationFilterWheel473nm contents as cell array
%        contents{get(hObject,'Value')} returns selected item from CalibrationFilterWheel473nm
% handles.dmd.naturalDensityForCalibration(1) = get(handles.CalibrationFilterWheel473nm, 'value');
% guidata(hObject,handles);

   

% --- Executes during object creation, after setting all properties.
function CalibrationFilterWheel473nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CalibrationFilterWheel473nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SweepTestFilterWheel473nm.
function SweepTestFilterWheel473nm_Callback(hObject, eventdata, handles)
% hObject    handle to SweepTestFilterWheel473nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SweepTestFilterWheel473nm contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SweepTestFilterWheel473nm
% handles.dmd.naturalDensityForSweepTest = get(handles.SweepTestFilterWheel473nm, 'value');
% guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function SweepTestFilterWheel473nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SweepTestFilterWheel473nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function calibAvgEdit_Callback(hObject, eventdata, handles)
% hObject    handle to calibAvgEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of calibAvgEdit as text
%        str2double(get(hObject,'String')) returns contents of calibAvgEdit as a double


% --- Executes during object creation, after setting all properties.
function calibAvgEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calibAvgEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function mouseDown(obj,A,fig)
handles = guidata(fig);
if isfield(handles,'calibration') && XimeaWrapper('IsInitialized')
    C = get (handles.axes1, 'CurrentPoint');
    x=C(1,1)-handles.calibration.strctCalibrationParams.fiberBox(1);
    y=C(1,2)-handles.calibration.strctCalibrationParams.fiberBox(2);

    Q=XimeaWrapper('GetImageBuffer'); 
    handles.calibration.formSpot(x,y);
    
    WaitSecs(0.1);
    Q=XimeaWrapper('GetImageBuffer');
   
    
    cla(handles.axes1);
    colormap(handles.axes1,'jet');
    handles.hImage = image(single(Q),'parent',handles.axes1,'CDataMapping','scaled');
    set(handles.axes1,'xlim',[0 handles.calibration.strctCalibrationParams.fiberBox(3)],...
        'ylim',[0 handles.calibration.strctCalibrationParams.fiberBox(4)]);
    set(handles.axes1,'Clim',[0 1095]);
    
    drawnow
end


% function formSpotWithoutPreComputedHolograms(handles, x,y)
% if ~isfield(handles.dmd,'newSize')
%     return;
% end
% [Ay,Ax]=ind2sub(handles.dmd.newSize(1:2), handles.dmd.hologramSpotPos);
% % find closest point...
% [~, indx]=min( sqrt ((Ax-x).^2+ (Ay-y).^2));
% 
% Sk = handles.dmd.phaseBasisReal* sin(handles.dmd.Kinv_angle(:,handles.dmd.hologramSpotPos(indx))); %Sk=dmd.phaseBasisReal*sin(K);
% Ck = handles.dmd.phaseBasisReal* cos(handles.dmd.Kinv_angle(:,handles.dmd.hologramSpotPos(indx))); % Ck=dmd.phaseBasisReal*cos(K);
% Ein=atan2(Sk,Ck);
% 
% inputPhases=reshape(Ein, handles.dmd.hadamardSize,handles.dmd.hadamardSize);
% hologram = CudaFastLee(inputPhases,handles.dmd.numReferencePixels, handles.dmd.leeBlockSize, handles.dmd.selectedCarrier, handles.dmd.carrierRotation);
% ALPuploadAndPlay(hologram,200,1)
%         
% function formSpot(handles, x,y)
% [Ay,Ax]=ind2sub(handles.dmd.newSize(1:2), handles.dmd.hologramSpotPos);
% % find closest point...
% [~, indx]=min( sqrt ((Ax-x).^2+ (Ay-y).^2));
% P=handles.dmd.holograms(:,:,indx);
% % P(1:64,:) = 0;
% % P(705:768,:) = 0;
% % P(:,1:8) = 0;
% % P(:,121:128)=0;
% devID = get(handles.hALPlist,'value')-1;
% ALPuploadAndPlay(devID,P,200,1)
% 


% --- Executes on button press in hRandomPhaseButton532nm.
function hRandomPhaseButton532nm_Callback(hObject, eventdata, handles)
randPhase=2*pi*rand(64,64);
leeBlockSize = handles.numMirrorsPerMode(get(handles.hNumMirrorsPerBlock,'value'));
hadamardSize = handles.numBlocks(get(handles.hNumBlocksPopup,'value'));

dmd.width = 1024;
dmd.height = 768;
dmd.effectiveDMDsize = min(dmd.width,dmd.height);



numReferencePixels = max(0,(dmd.effectiveDMDsize-leeBlockSize*hadamardSize)/2);
leeBlockSize = handles.numMirrorsPerMode(get(handles.hNumMirrorsPerBlock,'value'));

selectedCarrier =str2num(get(handles.hCarrierFreq532,'string'));
carrierRotation =str2num(get(handles.hCarrierAngle532,'string'))/180*pi;
interferenceBasisPatterns = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize,selectedCarrier, carrierRotation);
ALPID=get(handles.hALPlist,'value')-1;
ALPuploadAndPlay(ALPID,interferenceBasisPatterns,2200,4);
% randPhase=2*pi*zeros(64,64);
% leeBlockSize = handles.numMirrorsPerMode(get(handles.hNumMirrorsPerBlock,'value'));
% hadamardSize = handles.numBlocks(get(handles.hNumBlocksPopup,'value'));
% 
% dmd.width = 1024;
% dmd.height = 768;
% dmd.effectiveDMDsize = min(dmd.width,dmd.height);
%     
% 
% numReferencePixels = max(0,(dmd.effectiveDMDsize-leeBlockSize*hadamardSize)/2);
% leeBlockSize = handles.numMirrorsPerMode(get(handles.hNumMirrorsPerBlock,'value'));
% 
% selectedCarrier =str2num(get(handles.hCarrierFreq532,'string'));
% carrierRotation =str2num(get(handles.hCarrierAngle532,'string'))/180*pi;
% interferenceBasisPatterns = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize,selectedCarrier, carrierRotation);
% ALPID=get(handles.hALPlist,'value')-1;
% 
% ALPuploadAndPlay(ALPID,interferenceBasisPatterns,2200,4);

% --- Executes on button press in hRandomPhaseButton473nm.
function hRandomPhaseButton473nm_Callback(hObject, eventdata, handles)
randPhase=2*pi*rand(64,64);
leeBlockSize = handles.numMirrorsPerMode(get(handles.hNumMirrorsPerBlock,'value'));
hadamardSize = handles.numBlocks(get(handles.hNumBlocksPopup,'value'));

dmd.width = 1024;
dmd.height = 768;
dmd.effectiveDMDsize = min(dmd.width,dmd.height);



numReferencePixels = max(0,(dmd.effectiveDMDsize-leeBlockSize*hadamardSize)/2);
leeBlockSize = handles.numMirrorsPerMode(get(handles.hNumMirrorsPerBlock,'value'));

selectedCarrier =str2num(get(handles.hCarrierFreq473,'string'));
carrierRotation =str2num(get(handles.hCarrierAngle473,'string'))/180*pi;
interferenceBasisPatterns = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize,selectedCarrier, carrierRotation);
ALPID=get(handles.hALPlist,'value')-1;
ALPuploadAndPlay(ALPID,interferenceBasisPatterns,2200,4);

% --- Executes on button press in hNewCalibSession.
function hNewCalibSession_Callback(hObject, eventdata, handles)
% hObject    handle to hNewCalibSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SessionWrapper('NewSession');


% --- Executes on button press in hResetALP.
function hResetALP_Callback(hObject, eventdata, handles)
% hObject    handle to hResetALP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clear ALPwrapper;
devices = ALPwrapper('GetDevices');
acDevices = cell(1,length(devices));
for k=1:length(devices)
    acDevices{k} = sprintf('ALP %d, %d',k,devices(k).Serial);
end
set(handles.hALPlist,'string',acDevices,'value',1);
    
guidata(hObject, handles);



function hCameraRate_Callback(hObject, eventdata, handles)
% handles.dmd.cameraRate = str2num(get(handles.hCameraRate,'String'));
% guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function hCameraRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hCameraRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in hActiveCalibration.
function hActiveCalibration_Callback(hObject, eventdata, handles)
selectedCalibration = get(hObject,'value');
% Load a different calibration...
calibFile= SessionWrapper('GetSession');
fprintf('Loading calibration...');
calib = CalibrationClass(calibFile);
% if get(handles.hMoveMotor,'value')
%     encoderLocationMicrons = h5read(calibFile,sprintf('/calibrations/calibration%d/actualEncoderLocation',selectedCalibration));
%     if ~MotorControllerWrapper('IsInitialized')
%         MotorControllerWrapper('Init')
%     end
%     MotorControllerWrapper('SetSpeed',500);
%     MotorControllerWrapper('SetAbsolutePositionMicrons', encoderLocationMicrons);
% end




% --- Executes during object creation, after setting all properties.
function hActiveCalibration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hActiveCalibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hMoveMotor.
function hMoveMotor_Callback(hObject, eventdata, handles)
% hObject    handle to hMoveMotor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hMoveMotor


% --- Executes on selection change in hSessionPopup.
function hSessionPopup_Callback(hObject, eventdata, handles)
sessionList = SessionWrapper('ListSessions');
selectedFile = get(handles.hSessionPopup,'value');
% Load depths
Depths = SessionWrapper('LoadSession',sessionList{selectedFile});
set(handles.hActiveCalibration,'String',Depths,'value',length(Depths));
    


% --- Executes during object creation, after setting all properties.
function hSessionPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hSessionPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over hSessionPopup.
function hSessionPopup_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to hSessionPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dbg = 1;

% --- Executes on button press in hRescanCalibrations.
function hRescanCalibrations_Callback(hObject, eventdata, handles)
% hObject    handle to hRescanCalibrations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in hSweep473.
function hSweep473_Callback(hObject, eventdata, handles)
% hObject    handle to hSweep473 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hSweep473


% --- Executes on button press in hPSFZtest.
function hPSFZtest_Callback(hObject, eventdata, handles)
% hObject    handle to hPSFZtest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hPSFZtest



function hPSF_Z_Range_Callback(hObject, eventdata, handles)
% hObject    handle to hPSF_Z_Range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hPSF_Z_Range as text
%        str2double(get(hObject,'String')) returns contents of hPSF_Z_Range as a double


% --- Executes during object creation, after setting all properties.
function hPSF_Z_Range_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hPSF_Z_Range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hPSF_Z_Step_Callback(hObject, eventdata, handles)
% hObject    handle to hPSF_Z_Step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hPSF_Z_Step as text
%        str2double(get(hObject,'String')) returns contents of hPSF_Z_Step as a double


% --- Executes during object creation, after setting all properties.
function hPSF_Z_Step_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hPSF_Z_Step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in h3DCalibration.
function h3DCalibration_Callback(hObject, eventdata, handles)
% hObject    handle to h3DCalibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of h3DCalibration

% --- Executes on button press in hSweepTestButton.
function hSweepTestButton_Callback(hObject, eventdata, handles)
CameraModule('StopLiveView');
% dmd = handles.dmd;
strFigureTitle=sprintf('Session %d', SessionWrapper('GetSessionID'));
if get(handles.hSweep473,'value')
    
    handles.calibration.sweepTest(strFigureTitle,1);
end
if get(handles.hSweep532,'value')
    handles.calibration.sweepTest(strFigureTitle,2);
end


function roi=createSubsampledROI(dmd,subsampling)
roi.radius  =dmd.radius ;
roi.boundingbox = [1 1 2*dmd.radius+1 2*dmd.radius+1]; % full FOV
roi.subsampling = subsampling;
roi.maxDMDrate = 22000;
roi.Mask = zeros(2*roi.radius+1,2*roi.radius+1);
roi.selectedRate = roi.maxDMDrate ;
roi=recomputeROI(roi,1);

function dmd=recomputeHolograms(dmd)
fprintf('Full reconstruction was not run during calibration...Generating holograms...\n');
if ~isfield(dmd,'phaseBasisReal') || (isfield(dmd,'phaseBasisReal') && isempty(dmd.phaseBasisReal))
    walshBasis = fnBuildWalshBasis(dmd.hadamardSize, dmd.numBasis); % returns hadamardSize x hadamardSize x hadamardSize^2
    phaseBasis = single((walshBasis == 1)*pi);
    dmd.phaseBasisReal = single(reshape(real(exp(1i*phaseBasis)),dmd.hadamardSize*dmd.hadamardSize,dmd.numModes));
end
Sk = dmd.phaseBasisReal* sin(dmd.Kinv_angle(:,dmd.hologramSpotPos)); %Sk=dmd.phaseBasisReal*sin(K);
Ck = dmd.phaseBasisReal* cos(dmd.Kinv_angle(:,dmd.hologramSpotPos)); % Ck=dmd.phaseBasisReal*cos(K);
Ein=atan2(Sk,Ck);
inputPhases=reshape(Ein, dmd.hadamardSize,dmd.hadamardSize,dmd.numSpots);
dmd.holograms = CudaFastLee(inputPhases,dmd.numReferencePixels, dmd.leeBlockSize, dmd.selectedCarrier(colorChannel), dmd.carrierRotation(colorChannel));

function dmd = sweepTest(dmd,handles,strFigureTitle,colorChannel)



displayMessage(handles, 'Now Running a spot test');
if ~isfield(dmd,'holograms')
    dmd=recomputeHolograms(dmd);
end
roi=createSubsampledROI(dmd,4);
cameraRate = str2num(get(handles.hCameraRate,'String'));
abSelectedSpots = ismember(dmd.hologramSpotPos,roi.selectedSpots);
indicesToHolograms = find(abSelectedSpots);
% analyze enhancement factor
[y,x]=ind2sub(size(roi.Mask),dmd.hologramSpotPos(abSelectedSpots));
patternsToPlay = dmd.holograms(:, :,indicesToHolograms);
x = x + dmd.fiberBox(1);
y = y + dmd.fiberBox(2);
if get(handles.hHDRSweep,'value')
    ND = [0,1,2,3,4];
    exposures = [6000];
else
    ND = get(handles.SweepTestFilterWheel473nm, 'value');
    exposures =str2num(get(handles.sweepTestExposureEdit,'String'));
end
stats = SmartSweepTest(dmd.deviceID,patternsToPlay,  x,y,roi,strFigureTitle,ND,exposures,cameraRate,dmd.fiberBox,colorChannel);
% Dump data to disk.

dumpVariableToCalibration(stats.meanEnhancement,'meanEnhancement');
dumpVariableToCalibration(stats.meanEnhancementHalfRadius,'meanEnhancementHalfRadius');

dumpVariableToCalibration(stats.RawImages,'rawCalibrationImages');
stats.RawImages = [];
dumpVariableToCalibration(stats.ND ,'naturalDensitySweeps');
dumpVariableToCalibration(stats.exposures ,'exposureSweeps');
dumpVariableToCalibration(roi.selectedSpots, 'selectedSpeedTestSpots');

dumpVariableToCalibration([x(:),y(:)],'sweepTestPositions');
dumpVariableToCalibration(dmd.hologramSpotPos(abSelectedSpots),'sweepTestPositionsIndices');
dumpVariableToCalibration(stats.enhancemnentFactor,'enhancemnentFactor');
dumpVariableToCalibration(stats.enhancemnentFactor2D,'enhancemnentFactor2D');
dumpVariableToCalibration(stats.displacementMap,'displacementMap');
dumpVariableToCalibration(stats.maxIntensityMapping,'maxIntensityMapping');
dumpVariableToCalibration(stats.mapIntensity2D,'mapIntensity2D');

dumpVariableToCalibration(stats.gaussianFitAmplitude,'gaussianFitAmplitude');
dumpVariableToCalibration(stats.gaussianFitAmplitude2D,'gaussianFitAmplitude2D');
dumpVariableToCalibration(stats.gaussianFitSigma,'gaussianFitSigma');
dumpVariableToCalibration(stats.gaussianFitSigma2D,'gaussianFitSigma2D');
dumpVariableToCalibration(roi.boundingbox,'boundingbox');
dumpVariableToCalibration(roi.Mask,'RoiMask');
%
dmd.stats = stats;

return
% % % % % % % 
% % % % % % % [X,Y]=meshgrid(1:2*dmd.radius+1,1:2*dmd.radius+1);
% % % % % % % binaryDisc = sqrt((X-(dmd.radius+1)).^2+(Y-(dmd.radius+1)).^2) <= dmd.radius;
% % % % % % % % find center pixel coordinates
% % % % % % % % get coordinates of binary disc
% % % % % % % dmd.hologramSpotPos = find(binaryDisc(:));
% % % % % % % 
% % % % % % % dmd.numSpots = length(dmd.hologramSpotPos);
% % % % % % % roi.radius  =dmd.radius ;
% % % % % % % roi.boundingbox = [1 1 2*dmd.radius+1 2*dmd.radius+1]; % full FOV
% % % % % % % roi.subsampling = 4;
% % % % % % % numRepetitions = 3;
% % % % % % % 
% % % % % % % roi.maxDMDrate = 22000;
% % % % % % % roi.Mask = zeros(2*roi.radius+1,2*roi.radius+1);
% % % % % % % roi.selectedRate = roi.maxDMDrate ;
% % % % % % % roi=recomputeROI(roi,1);
% % % % % % % 
% % % % % % % 
% % % % % % % dumpVariableToCalibration(roi.selectedSpots, 'selectedSpeedTestSpots');
% % % % % % % abSelectedSpots = ismember(dmd.hologramSpotPos,roi.selectedSpots);
% % % % % % % indicesToHolograms = find(abSelectedSpots);
% % % % % % % 
% % % % % % % dmd.naturalDensityForSweepTest = get(handles.SweepTestFilterWheel473nm, 'value');
% % % % % % %         
% % % % % % % 
% % % % % % % numSpots = length(indicesToHolograms);
% % % % % % % if ~isfield(dmd,'holograms')
% % % % % % %     fprintf('Full reconstruction was not run during calibration...Generating holograms...\n');
% % % % % % %     Sk = dmd.phaseBasisReal* sin(dmd.Kinv_angle(:,dmd.hologramSpotPos)); %Sk=dmd.phaseBasisReal*sin(K);
% % % % % % %     Ck = dmd.phaseBasisReal* cos(dmd.Kinv_angle(:,dmd.hologramSpotPos)); % Ck=dmd.phaseBasisReal*cos(K);
% % % % % % %     Ein=atan2(Sk,Ck);
% % % % % % %     inputPhases=reshape(Ein, dmd.hadamardSize,dmd.hadamardSize,dmd.numSpots);
% % % % % % %     clear Ein
% % % % % % %    dmd.holograms = CudaFastLee(inputPhases,dmd.numReferencePixels, dmd.leeBlockSize, dmd.selectedCarrier(colorChannel), dmd.carrierRotation(colorChannel));
% % % % % % % end
% % % % % % % patternsToPlay = dmd.holograms(:, :,indicesToHolograms);
% % % % % % % 
% % % % % % % FilterWheelModule('SetNaturalDensity',[1 dmd.naturalDensityForSweepTest]);figure(handles.figure1);
% % % % % % % PTwrapper('SetExposure',1/dmd.exposureForSweepTest);
% % % % % % % % Get dark image
% % % % % % % darkImage=getDarkImage(dmd.cameraRate);
% % % % % % % % get values
% % % % % % % 
% % % % % % % PTwrapper('StartAveraging', length(indicesToHolograms),false);
% % % % % % % ALPuploadAndPlay(patternsToPlay, dmd.cameraRate,numRepetitions);
% % % % % % % ALPwrapper('WaitForSequenceCompletion');
% % % % % % % WaitSecs(0.5); % allow all images to reach buffer
% % % % % % % PTwrapper('StopAveraging');
% % % % % % % 
% % % % % % % SpotCalibrationImages=PTwrapper('GetImageBuffer');
% % % % % % % if size(SpotCalibrationImages,3) ~= numSpots
% % % % % % %     displayMessage(handles, 'Failed to calibrate (image mismatch!)');
% % % % % % %     fprintf('Image count mismatch\n');
% % % % % % %     return
% % % % % % % end
% % % % % % % 
% % % % % % % % analyze enhancement factor
% % % % % % % [y,x]=ind2sub(size(binaryDisc),dmd.hologramSpotPos(abSelectedSpots));
% % % % % % % 
% % % % % % % insideHalfRadius = sqrt((x-roi.radius).^2+(y-roi.radius).^2) < roi.radius/2;
% % % % % % % 
% % % % % % % W = 10;
% % % % % % % maxIntensityMapping = zeros(1, sum(abSelectedSpots));
% % % % % % % mapIntensity2D = zeros(size(binaryDisc));
% % % % % % % enhancemnentFactor2D= zeros(size(binaryDisc));
% % % % % % % gaussianFitAmplitude2D= zeros(size(binaryDisc));
% % % % % % % gaussianFitSigma2D= zeros(size(binaryDisc));
% % % % % % % displacementMap = zeros(2, sum(abSelectedSpots));
% % % % % % % enhancemnentFactor  = zeros(1, sum(abSelectedSpots));
% % % % % % % gaussianFitSigma= zeros(1, sum(abSelectedSpots));
% % % % % % % gaussianFitAmplitude = zeros(1, sum(abSelectedSpots));
% % % % % % % [XX,YY]=meshgrid(1:size(SpotCalibrationImages,2),1:size(SpotCalibrationImages,1));
% % % % % % % cent = [ceil(dmd.fiberBox(1)+dmd.fiberBox(3)/2),         ceil(dmd.fiberBox(2)+dmd.fiberBox(4)/2)];
% % % % % % % Idisk = (XX-cent(1)).^2+(YY-cent(2)).^2 <= roi.radius^2;
% % % % % % % numOverExposed = sum(squeeze(max(max(SpotCalibrationImages,[],1),[],2)) > 4090);
% % % % % % % %opt=optimset('MaxFunEvals',1000,'MaxIter',10,'Display','none');
% % % % % % % fprintf('Computing statistics...');
% % % % % % % pValues = zeros(1,size(SpotCalibrationImages,3));
% % % % % % % for k=1:size(SpotCalibrationImages,3)
% % % % % % %     
% % % % % % %     I=single(SpotCalibrationImages(:,:,k))-darkImage;
% % % % % % %     x0 = x(k)+ dmd.fiberBox(1)-1;
% % % % % % %     y0 = y(k)+dmd.fiberBox(2)-1;
% % % % % % %     xrange = min(size(SpotCalibrationImages,2), max(1,x0-W:x0+W));
% % % % % % %     yrange = min(size(SpotCalibrationImages,1),max(1,y0-W:y0+W));
% % % % % % %     values = I(yrange,xrange);
% % % % % % %     
% % % % % % %     Tmp = single(SpotCalibrationImages(:,:,k));
% % % % % % %     Tmp(yrange,xrange)=0;
% % % % % % %     [~,pValues(k)]=ttest(Tmp(Idisk),darkImage(Idisk));
% % % % % % %    
% % % % % % %     
% % % % % % %     % handle edge conditions (also bias
% % % % % % %     values(yrange == 1,:) = 0;
% % % % % % %     values(:,xrange == 1) = 0;
% % % % % % %     values(yrange == size(I,1),:) = 0;
% % % % % % %     values(:,xrange == size(I,2)) = 0;
% % % % % % %     
% % % % % % %     % This is slow, but gives variance in both x and y directions...
% % % % % % %    %  gaussianFit = fitGaussian2D(double(values),opt);
% % % % % % % 
% % % % % % %    % this is fast, but only gives circular variance fit.
% % % % % % %     par_init = [W+1;W+1];
% % % % % % %     result_params = mx_psfFit_Image( double(values), par_init ); % This is the simplest possible call, see psfFit_Image for all options
% % % % % % %     
% % % % % % %     opt_x =result_params(1);
% % % % % % %     opt_y =result_params(2);
% % % % % % %     opt_amp = result_params(3);
% % % % % % %     opt_back = result_params(4);
% % % % % % %     opt_sigma = result_params(5);
% % % % % % % 
% % % % % % % % % plot fit    
% % % % % % % %     N=20;
% % % % % % % %     theta = 2*pi*[0:N]/N;
% % % % % % % %     radius = 3*opt_sigma;
% % % % % % % %     uv = [opt_x+radius * cos(theta); opt_y+radius * sin(theta)];
% % % % % % % %     
% % % % % % % %     figure(11);clf;imagesc(values);hold on;plot(uv(1,:),uv(2,:));
% % % % % % % %     result_params
% % % % % % %     
% % % % % % %     
% % % % % % %     [maxIntensityMapping(k), maxLocalInd]= max(values(:));
% % % % % % %     
% % % % % % %     displacementMap(1,k)= x0  + opt_x-(W+1);
% % % % % % %     displacementMap(2,k)= y0  + opt_y-(W+1);
% % % % % % % 
% % % % % % % 
% % % % % % %     mapIntensity2D(y(k),x(k))=maxIntensityMapping(k);
% % % % % % %     I(yrange,xrange)=0;
% % % % % % %     meanBackgroundValue=mean(I(Idisk));
% % % % % % %     enhancemnentFactor(k) = maxIntensityMapping(k)/meanBackgroundValue;
% % % % % % %     gaussianFitSigma(k) = opt_sigma;
% % % % % % %     gaussianFitSigma2D(y(k),x(k)) = opt_sigma;
% % % % % % %     gaussianFitAmplitude(k) = opt_amp;
% % % % % % %     gaussianFitAmplitude2D(y(k),x(k))=opt_amp;
% % % % % % %     enhancemnentFactor2D(y(k),x(k))=enhancemnentFactor(k);
% % % % % % % end
% % % % % % % if sum(pValues>0.01/sum(Idisk(:))) > 0
% % % % % % %     fprintf('WARNING, background values are quite low. you might want to increase exposure \n'); 
% % % % % % % end
% % % % % % % dumpVariableToCalibration([x(:),y(:)],'sweepTestPositions');
% % % % % % % dumpVariableToCalibration(dmd.hologramSpotPos(abSelectedSpots),'sweepTestPositionsIndices');
% % % % % % % dumpVariableToCalibration(enhancemnentFactor,'enhancemnentFactor');
% % % % % % % dumpVariableToCalibration(enhancemnentFactor2D,'enhancemnentFactor2D');
% % % % % % % dumpVariableToCalibration(displacementMap,'displacementMap');
% % % % % % % dumpVariableToCalibration(maxIntensityMapping,'maxIntensityMapping');
% % % % % % % dumpVariableToCalibration(mapIntensity2D,'mapIntensity2D');
% % % % % % % 
% % % % % % % dumpVariableToCalibration(mapIntensity2D,'gaussianFitAmplitude');
% % % % % % % dumpVariableToCalibration(mapIntensity2D,'gaussianFitAmplitude2D');
% % % % % % % dumpVariableToCalibration(mapIntensity2D,'gaussianFitSigma');
% % % % % % % dumpVariableToCalibration(mapIntensity2D,'gaussianFitSigma2D');
% % % % % % % 
% % % % % % % dumpVariableToCalibration(darkImage,'darkImage')
% % % % % % % dumpVariableToCalibration(SpotCalibrationImages,'SpotCalibrationImages')
% % % % % % % dumpVariableToCalibration(roi.boundingbox,'boundingbox');
% % % % % % % dumpVariableToCalibration(roi.Mask,'RoiMask');
% % % % % % % dmd.sweepTestPositionsIndices = dmd.hologramSpotPos(abSelectedSpots);
% % % % % % % dmd.enhancemnentFactor = enhancemnentFactor;
% % % % % % % dmd.displacementMap = displacementMap;
% % % % % % % dmd.maxIntensityMapping = maxIntensityMapping ;
% % % % % % % 
% % % % % % % % clear SpotCalibrationImages
% % % % % % % fprintf('\nAverage enhancement: %.2f +- %.2f (%.2f +- %.2f) in half radius\n', mean(enhancemnentFactor), std(enhancemnentFactor),...
% % % % % % %     mean(enhancemnentFactor(insideHalfRadius)),std(enhancemnentFactor(insideHalfRadius)));
% % % % % % % 
% % % % % % % fprintf('Average gaussian amplitude: %.2f +- %.2f (%.2f +- %.2f) in half radius\n', mean(gaussianFitAmplitude), std(gaussianFitAmplitude),...
% % % % % % %     mean(gaussianFitAmplitude(insideHalfRadius)),std(gaussianFitAmplitude(insideHalfRadius)));
% % % % % % % 
% % % % % % % fprintf('Average gaussian standard deviation: %.2f +- %.2f (%.2f +- %.2f) in half radius\n', mean(gaussianFitSigma), std(gaussianFitSigma),...
% % % % % % %     mean(gaussianFitSigma(insideHalfRadius)),std(gaussianFitSigma(insideHalfRadius)));
% % % % % % % 
% % % % % % % if numOverExposed > 0
% % % % % % %     fprintf('Warning, overexposure detected in %d spots\n',numOverExposed);
% % % % % % % end
% % % % % % % 
% % % % % % % I1=FastUpSampling(gaussianFitAmplitude2D,roi.offsetX,roi.offsetY, roi.subsampling,roi.subsampling);
% % % % % % % I2=FastUpSampling(gaussianFitSigma2D,roi.offsetX,roi.offsetY, roi.subsampling,roi.subsampling);
% % % % % % % fig=figure;
% % % % % % % clf;
% % % % % % % subplot(1,2,1);imagesc(I1);title('Gaussian Fit Amplitude');myColorbar();axis off
% % % % % % % subplot(1,2,2);imagesc(I2);title('Gaussian Fit Standard Deviation');myColorbar();axis off
% % % % % % % set(fig,'Name',strFigureTitle);
% % % % % % % return;



function numModes_Callback(hObject, eventdata, handles)
% hObject    handle to numModes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numModes as text
%        str2double(get(hObject,'String')) returns contents of numModes as a double


% --- Executes during object creation, after setting all properties.
function numModes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numModes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hFullFOV.
function hFullFOV_Callback(hObject, eventdata, handles)
% hObject    handle to hFullFOV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hFullFOV


% --- Executes on button press in hFullCalibration.
function hFullCalibration_Callback(hObject, eventdata, handles)
% hObject    handle to hFullCalibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hFullCalibration


% --- Executes on button press in hMoveDownDuringZsweep.
function hMoveDownDuringZsweep_Callback(hObject, eventdata, handles)
% hObject    handle to hMoveDownDuringZsweep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hMoveDownDuringZsweep


% --- Executes on button press in hReturnToPos0.
function hReturnToPos0_Callback(hObject, eventdata, handles)
% hObject    handle to hReturnToPos0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hReturnToPos0



function hDepthInterval_Callback(hObject, eventdata, handles)
% hObject    handle to hDepthInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hDepthInterval as text
%        str2double(get(hObject,'String')) returns contents of hDepthInterval as a double


% --- Executes during object creation, after setting all properties.
function hDepthInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDepthInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hDepthMax_Callback(hObject, eventdata, handles)
% hObject    handle to hDepthMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hDepthMax as text
%        str2double(get(hObject,'String')) returns contents of hDepthMax as a double


% --- Executes during object creation, after setting all properties.
function hDepthMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDepthMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hDepthMin_Callback(hObject, eventdata, handles)
% hObject    handle to hDepthMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hDepthMin as text
%        str2double(get(hObject,'String')) returns contents of hDepthMin as a double


% --- Executes during object creation, after setting all properties.
function hDepthMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDepthMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hDepthCalibration.
function hDepthCalibration_Callback(hObject, eventdata, handles)
% hObject    handle to hDepthCalibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hDepthCalibration


% --- Executes on button press in hCalibrateBlue.
function hCalibrateBlue_Callback(hObject, eventdata, handles)
% hObject    handle to hCalibrateBlue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hCalibrateBlue


% --- Executes on button press in hCalibrateGreen.
function hCalibrateGreen_Callback(hObject, eventdata, handles)
% hObject    handle to hCalibrateGreen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hCalibrateGreen


% --- Executes on button press in hSweep532.
function hSweep532_Callback(hObject, eventdata, handles)
% hObject    handle to hSweep532 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hSweep532




% --- Executes on selection change in SegmentationFilterWheel532nm.
function SegmentationFilterWheel532nm_Callback(hObject, eventdata, handles)
% hObject    handle to SegmentationFilterWheel532nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SegmentationFilterWheel532nm contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SegmentationFilterWheel532nm
handles.dmd.naturalDensityForSegmentation(2) = get(handles.SegmentationFilterWheel532nm, 'value');
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function SegmentationFilterWheel532nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SegmentationFilterWheel532nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in CalibrationFilterWheel532nm.
function CalibrationFilterWheel532nm_Callback(hObject, eventdata, handles)
% hObject    handle to CalibrationFilterWheel532nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns CalibrationFilterWheel532nm contents as cell array
%        contents{get(hObject,'Value')} returns selected item from CalibrationFilterWheel532nm
handles.dmd.naturalDensityForCalibration(2) = get(handles.CalibrationFilterWheel532nm, 'value');
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function CalibrationFilterWheel532nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CalibrationFilterWheel532nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SweepTestFilterWheel532nm.
function SweepTestFilterWheel532nm_Callback(hObject, eventdata, handles)
% hObject    handle to SweepTestFilterWheel532nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SweepTestFilterWheel532nm contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SweepTestFilterWheel532nm


% --- Executes during object creation, after setting all properties.
function SweepTestFilterWheel532nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SweepTestFilterWheel532nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in hNumBlocksPopup.
function hNumBlocksPopup_Callback(hObject, eventdata, handles)
% hObject    handle to hNumBlocksPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns hNumBlocksPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from hNumBlocksPopup


% --- Executes during object creation, after setting all properties.
function hNumBlocksPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hNumBlocksPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in hNumMirrorsPerBlock.
function hNumMirrorsPerBlock_Callback(hObject, eventdata, handles)
% hObject    handle to hNumMirrorsPerBlock (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns hNumMirrorsPerBlock contents as cell array
%        contents{get(hObject,'Value')} returns selected item from hNumMirrorsPerBlock


% --- Executes during object creation, after setting all properties.
function hNumMirrorsPerBlock_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hNumMirrorsPerBlock (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in hNumBlocksPopup.
function hNumModesPopup_Callback(hObject, eventdata, handles)
% hObject    handle to hNumBlocksPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns hNumBlocksPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from hNumBlocksPopup


% --- Executes during object creation, after setting all properties.
function hNumModesPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hNumBlocksPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hHDRSweep.
function hHDRSweep_Callback(hObject, eventdata, handles)
% hObject    handle to hHDRSweep (see GCBO)
if ~(get(hObject,'value'))
    set(handles.SweepTestFilterWheel473nm,'enable','on')
    set(handles.SweepTestFilterWheel532nm,'enable','on');
    set(handles.sweepTestExposureEdit,'enable','on');    
else
    set(handles.SweepTestFilterWheel473nm,'enable','off')
    set(handles.SweepTestFilterWheel532nm,'enable','off');
    set(handles.sweepTestExposureEdit,'enable','off');
end



function hCarrierFreq473_Callback(hObject, eventdata, handles)

% handles.dmd.selectedCarrier(1) = str2num(get(hObject,'String'));
% guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function hCarrierFreq473_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hCarrierFreq473 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hCarrierAngle473_Callback(hObject, eventdata, handles)

handles.dmd.carrierRotation(1) = str2num(get(hObject,'String'))/180*pi;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function hCarrierAngle473_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hCarrierAngle473 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hCarrierAngle532_Callback(hObject, eventdata, handles)
% handles.dmd.carrierRotation(2) = str2num(get(hObject,'String'))/180*pi;
% guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function hCarrierAngle532_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hCarrierAngle532 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hCarrierFreq532_Callback(hObject, eventdata, handles)
% handles.dmd.selectedCarrier(2) = str2num(get(hObject,'String'));
% guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function hCarrierFreq532_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hCarrierFreq532 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hOptimizeLee.
function hOptimizeLee_Callback(hObject, eventdata, handles)
FastCarrierOptimization();


% --- Executes on button press in hCircularModes.
function hCircularModes_Callback(hObject, eventdata, handles)
% hObject    handle to hCircularModes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hCircularModes


% --- Executes on button press in hRectModes.
function hRectModes_Callback(hObject, eventdata, handles)
% hObject    handle to hRectModes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hRectModes



function hSpotRadiusPix_Callback(hObject, eventdata, handles)
% hObject    handle to hSpotRadiusPix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hSpotRadiusPix as text
%        str2double(get(hObject,'String')) returns contents of hSpotRadiusPix as a double


% --- Executes during object creation, after setting all properties.
function hSpotRadiusPix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hSpotRadiusPix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in hALPlist.
function hALPlist_Callback(hObject, eventdata, handles)
% hObject    handle to hALPlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns hALPlist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from hALPlist


% --- Executes during object creation, after setting all properties.
function hALPlist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hALPlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
