function varargout = ROIModule(varargin)
% ROIMODULE MATLAB code for ROIModule.fig
%      ROIMODULE, by itself, creates a new ROIMODULE or raises the existing
%      singleton*.
%
%      H = ROIMODULE returns the handle to a new ROIMODULE or the handle to
%      the existing singleton*.
%
%      ROIMODULE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROIMODULE.M with the given input arguments.
%
%      ROIMODULE('Property','Value',...) creates a new ROIMODULE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ROIModule_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ROIModule_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ROIModule

% Last Modified by GUIDE v2.5 25-Oct-2016 10:14:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ROIModule_OpeningFcn, ...
                   'gui_OutputFcn',  @ROIModule_OutputFcn, ...
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
function mouseUpFunc(a,b,handles)
global g_picker
g_picker.down = false;

if (~isempty(g_picker.item))
%     fprintf('Laying down item \n');
end


g_picker.item =[];

function mouseMoveFunc(fig,b,handles)
global g_picker
mousepos=get(handles.hHistogramAxes,'CurrentPoint');
if (~isempty(g_picker.item))
    %fprintf('Moving item to [%.1f,%.1f]\n',mousepos(1,1),mousepos(1,2));
    mousepos(1,2) = min(1, max(0,mousepos(1,2)));
    set(g_picker.item,'xdata',mousepos(1,1),'ydata',mousepos(1,2));
else
    if (g_picker.down)
        x = mousepos(1,1);
        y = mousepos(1,2);
        xlim = get(handles.hHistogramAxes,'xlim');
        ylim = get(handles.hHistogramAxes,'ylim');
        offset = g_picker.downcoord(1)-mousepos(1);
        if (x >= xlim(1) && x <= xlim(2) && y >= ylim(1) && y <= ylim(2))
            set(handles.hHistogramAxes,'xlim', xlim+offset);
        end
        g_picker.prev = mousepos;
    end
end



function curvePicker(a,b, controllerIndex)
global g_picker
g_picker.down = true;
g_picker.item = controllerIndex;
g_picker.coordinate = a;
if (~isempty(g_picker.item))
%     fprintf('Picking up item\n');
else
    mousepos=get(a,'CurrentPoint');   
    x = mousepos(1,1);
    y = mousepos(1,2);
    g_picker.downcoord = [x,y];    
end
% set (fig, 'WindowButtonMotionFcn', {@mouseMove, fig,ax});
% set (fig, 'WindowButtonUpFcn', {@CurveMouseUp, fig,ax});


% --- Executes just before ROIModule is made visible.
function ROIModule_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ROIModule (see VARARGIN)
global g_picker
g_picker.down = false;
g_picker.item = [];

% Choose default command line output for ROIModule
handles.output = hObject;
handles.ALPid = 0;
if ~ALPwrapper('IsInitialized',handles.ALPid)
    ALPwrapper('Init',handles.ALPid)
end
if (~TemperatureSensorWrapper('IsInitialized'))
    TemperatureSensorWrapper('Init');
end
set(handles.hVoltageRangeFastDAQ,'String',{'±1V','±2V','±5V','±10V'},'value',1);

overSampling = 180;
set(handles.hOverSamplingEdit,'String',num2str(overSampling));
set(handles.hPMT1,'value',1);
set(handles.hPMT2,'value',1);


% [Res] = OverClockWrapper(overSampling);
% if ~PTwrapper('IsInitialized')
%     PTwrapper('Init');
% end;


cla(handles.hHistogramAxes);
hold(handles.hHistogramAxes,'on');

handles.pmt1fft = plot(handles.hHistogramAxes,0:1,0:0,'color',[0,0.5,0]);
handles.pmt2fft = plot(handles.hHistogramAxes,0:1,0:0,'color',[0.5,0,0]);
handles.pmt1hist = plot(handles.hHistogramAxes,0:1,0:1,'g');
handles.pmt2hist = plot(handles.hHistogramAxes,0:1,0:1,'r');
handles.pmt1curve = plot(handles.hHistogramAxes,0:1,0:1,'g--');
handles.pmt2curve = plot(handles.hHistogramAxes,0:1,0:1,'r--');
handles.pmt1curveControlLow = plot(handles.hHistogramAxes,0,0,'gd','MarkerSize',11);
handles.pmt1curveControlHigh = plot(handles.hHistogramAxes,0,0,'gd','MarkerSize',11);
handles.pmt2curveControlLow = plot(handles.hHistogramAxes,0,0,'ro','MarkerSize',11);
handles.pmt2curveControlHigh = plot(handles.hHistogramAxes,0,0,'ro','MarkerSize',11);
set(handles.hPMT1MeanSub,'value',0);
set(handles.hPMT2MeanSub,'value',0);
set(handles.hFFT_PMT1,'value',0);
set(handles.hFFT_PMT2,'value',0);

set (handles.figure1, 'WindowButtonMotionFcn', {@mouseMoveFunc,handles});
set (handles.figure1,'WindowButtonUpFcn',{@mouseUpFunc,handles});
set(handles.hHistogramAxes,'ButtonDownFcn',{@curvePicker,[]},'HitTest','on');
set(handles.pmt1curveControlLow,'ButtonDownFcn',{@curvePicker,handles.pmt1curveControlLow},'HitTest','on');
set(handles.pmt1curveControlHigh,'ButtonDownFcn',{@curvePicker,handles.pmt1curveControlHigh},'HitTest','on');
set(handles.pmt2curveControlLow,'ButtonDownFcn',{@curvePicker,handles.pmt2curveControlLow},'HitTest','on');
set(handles.pmt2curveControlHigh,'ButtonDownFcn',{@curvePicker,handles.pmt2curveControlHigh},'HitTest','on');

if ~isfield(handles,'initialized')
  sessionList = SessionWrapper('ListSessions');
  ReloadCalibration(hObject,handles,sessionList,length(sessionList))
end
set(handles.figure1,'CloseRequestFcn',{@CloseROIModule,handles});
 set(handles.figure1,'position',[  3.2000   14.0000  250.4000   64.6154]);
% UIWAIT makes ROIModule wait for user response (see UIRESUME)

% uiwait(handles.figure1);
function handles=AddDepthToActiveList(handles, depthIndex)
if (1+length(handles.usedDepthIndices))*handles.roi.numSpots > 40000
    displayMessage(handles,'Too many spots to store in FPGA memory');
    return;
end

handles.usedDepthIndices = unique([handles.usedDepthIndices, depthIndex]);

set(handles.hUsedDepthListbox,'String',handles.uniqueConfigurationsStrings(handles.usedDepthIndices),'value',length(handles.uniqueConfigurationsStrings(handles.usedDepthIndices)));

handles.roi=recomputeROI(handles.roi, length(handles.usedDepthIndices));
[handles.axes,handles.hImages] = CreateDrawAxes(handles, length(handles.usedDepthIndices));
plotROI(handles);
return;


function handles=RemoveDepthFromActiveList(handles, depthIndex)
handles.usedDepthIndices = setdiff(handles.usedDepthIndices, depthIndex);


if isempty(handles.usedDepthIndices)
    set(handles.hUsedDepthListbox,'String',[],'value',0);
else
    set(handles.hUsedDepthListbox,'String',handles.uniqueConfigurationsStrings(handles.usedDepthIndices),'value',1);
end
handles.roi=recomputeROI(handles.roi, length(handles.usedDepthIndices));
[handles.axes,handles.hImages] = CreateDrawAxes(handles, length(handles.usedDepthIndices));
plotROI(handles);
return;

function C=ArrayToCell(A)
if isempty(A)
    C = {};
    return
end
for k=1:length(A)
    C{k} = sprintf('%.2f',A(k));
end
   
function ReloadCalibration(hObject,handles,sessionList, selectedSession)
set(handles.hCalibrationPopup,'String',sessionList,'value',selectedSession);
% Load depths
try
    Tmp=SessionWrapper('GetSessionDescription',sessionList{selectedSession});
    
    if isempty(Tmp)
        AbsoluteDepthsUm = [];
        RelativeDepthsUm = [];
        RelativeFineDepthsUm = [];
        ColorChannels = {};
    else
        AbsoluteDepthsUm = Tmp{1};
        RelativeDepthsUm = Tmp{2};
        RelativeFineDepthsUm = Tmp{3};
        ColorChannels = Tmp{4};
    end
    
catch
    AbsoluteDepthsUm = [];
    RelativeDepthsUm = [];
    RelativeFineDepthsUm = [];
    ColorChannels = {};
end
if isempty(sessionList)
    fprintf('Cannot run ROI module. You need at least one calibration session\n');
    return;
end
SessionWrapper('SetActiveSession',  sessionList{selectedSession});
h5file= SessionWrapper('GetSession');

% sessionInfo = h5info(h5file);
% if length(sessionInfo.Groups) == 1
%     nScans = 0;
% else
%     nScans = length(sessionInfo.Groups(2).Groups);
% end
% scanNames = cell(1,nScans);
% for k=1:nScans
%     scanNames{k}=num2str(k);
% end
% set(handles.hNormalizationScanPopup,'String',scanNames);

% map color channels names to unique values.
[uniqueColorNames,B,uniqueColorChannelNumbers]= unique(ColorChannels);

[uniqueConfigurations]=unique([uniqueColorChannelNumbers';RelativeFineDepthsUm]','rows');

%uniqueRelativeDepthUm = unique(RelativeFineDepthsUm);
numUniqueConfigurations = size(uniqueConfigurations,1);
listStrings = cell(1,numUniqueConfigurations);
for k=1:numUniqueConfigurations
    colorName = uniqueColorNames{ uniqueConfigurations(k,1) } ;
    uniqueRelativeD = uniqueConfigurations(k,2);
    listStrings{k} = sprintf('%s %d um',colorName,uniqueRelativeD);
end
handles.uniqueColorNames = uniqueColorNames;
handles.uniqueConfigurations = uniqueConfigurations;
handles.uniqueConfigurationsStrings = listStrings;
    set(handles.hAvailDepthListbox,'String',listStrings,'value',1);
    handles.usedDepthIndices = [];
    

radius = h5read(h5file,'/calibrations/calibration1/radius');
% load information about calibration (FOV radius).
% gain = PTwrapper('GetGain');
% expo = PTwrapper('GetExposure');
% set(handles.hCameraGainEdit,'String',num2str(gain));
% initialRate = 2;
% set(handles.hCameraExposureEdit,'String',num2str(1.0/expo));
% set(handles.hCameraRateEdit,'String',initialRate);
% set(handles.hCameraGainSlider,'min',0,'max',32,'value',gain);
% set(handles.hCameraRateSlider,'min',0,'max',850,'value',initialRate);
% set(handles.hCameraExposureSlider,'min',0.1,'max',11000,'value',1.0/expo);
figure(handles.figure1);
roi.radius  =radius ;
roi.boundingbox = [1 1 2*radius+1 2*radius+1]; % full FOV
roi.subsampling = 1 ;
roi.maxDMDrate = 20000;
roi.Mask = zeros(2*roi.radius+1,2*roi.radius+1);
roi.selectedRate = roi.maxDMDrate ;
roi=recomputeROI(roi,1);
roi.numFrames = 100;
roi.durationSec =  roi.numFrames*1/roi.selectedRate;
set(handles.SubsampleX1,'value',1);

roi=recomputeROI(roi,1);
% set(handles.histogramAxes,'xticklabel',[]);
% set(handles.histogramAxes,'yticklabel',[]);
set(handles.ROIbutton,'enable','off');
handles.roi = roi;
handles.usedDepthIndices = [];

handles.AbsoluteDepthsUm = AbsoluteDepthsUm;
handles.RelativeDepthsUm = RelativeDepthsUm;
handles.RelativeFineDepthsUm = RelativeFineDepthsUm;
handles.ColorChannels = ColorChannels;

handles=AddDepthToActiveList(handles,1);

set(handles.hROIbandpassFilt,'value',0);
set(handles.NumFrames,'value',1);
[handles.axes,handles.hImages] = CreateDrawAxes(handles, length(handles.usedDepthIndices));
% set(handles.hDisplayMin,'String','0');
% set(handles.hDisplayMax,'String','30');
 set(handles.hNotSaveWarning,'visible','off');
set(handles.hRunningAverageEditPMT1,'String','0');
set(handles.hRunningAverageEditPMT2,'String','0');
set(handles.hPMT1SigAvg,'value',1);
set(handles.hPMT2SigAvg,'value',1);
% set(handles.hPMTgainEdit,'String',0);
% set(handles.hPMTslider,'min',0,'max',750,'value',0);
% set(handles.hPMTautomation,'value',1);
% %
% warning off
%   CameraRate = 1/15;
%     handles.cameraTimer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period', CameraRate,'TimerFcn',@CameraTimerCallback);
%  warning on
%  set(handles.hFreqAxes,'xlim',[0 500],'ylim',[0 100]);
%  
% Update handles structure
guidata(hObject, handles);
plotROI(handles);
handles.initialized = true;


function fnMouseWheel(obj,eventdata)
handles = guidata(obj);
C = get (handles.hHistogramAxes, 'CurrentPoint');
x=C(1,1);
y=C(1,2);

xlim = get(handles.hHistogramAxes,'xlim');
ylim = get(handles.hHistogramAxes,'ylim');

if (x >= xlim(1) && x <= xlim(2) && y >= ylim(1) && y <= ylim(2))
    
    addedRange = (xlim(2)-xlim(1))/2;
    if (addedRange > 100)
        addedRange = 50;
    else
        addedRange = 10;
    end
    if (eventdata.VerticalScrollCount < 0)
        newrange = [xlim(1)-addedRange, xlim(2)+addedRange];
    else
        newrange = [xlim(1)+addedRange, xlim(2)-addedRange];
    end
     if (newrange(2)-newrange(1) < 1)
         newrange= (newrange(2)-newrange(1))/2 + [-0.5,+0.5];
     end
    if (newrange(2)>newrange(1))
        set(handles.hHistogramAxes,'xlim', newrange);
    end
    return
end

if ~get(handles.hCompactView,'value')  %&& get(handles.slider1,'max') > 1
    if strcmp(get(handles.slider1,'visible'),'on')
        set(handles.slider1,'value', min( get(handles.slider1,'max'),max(0,get(handles.slider1,'value') - eventdata.VerticalScrollCount/3)));
        slider1_Callback(handles.slider1, [], handles);
    end
end
% global g_strctModule g_strctWindows
% strctMouseOp.m_strButton = fnGetClickType(g_strctWindows.m_hFigure);
% strctMouseOp.m_strAction = 'Wheel';
% strctMouseOp.m_hAxes = fnGetActiveAxes(get(g_strctWindows.m_hFigure,'CurrentPoint'));
% strctMouseOp.m_pt2fPos = fnGetMouseCoordinate(strctMouseOp.m_hAxes);
% strctMouseOp.m_pt2fPosScr = fnGetMouseCoordinateScreen();
% strctMouseOp.m_iScroll = eventdata.VerticalScrollCount;
% strctMouseOp.m_hObjectSelected = [];
% feval(g_strctModule.m_hCallbackFunc,'MouseWheel',strctMouseOp);
return;

function [hAxes, hImages] = CreateDrawAxes(handles,N)
set(handles.figure1,'WindowScrollWheelFcn',@fnMouseWheel);
UseCamera = get(handles.hRecordCamera,'value');
if isfield(handles,'cameraTimer')
    stop(handles.cameraTimer);
end
hAxes = [];
hImages = [];
ROIs = getappdata(handles.figure1,'ROIs');

NumPlanes = N;

if UseCamera
    NumPlots = NumPlanes+1;
else
    NumPlots = NumPlanes;
end

if isfield(ROIs,'handles')
    try
        delete(ROIs.handles);
    catch
    end
end
if isfield(handles,'axes')
    try
        delete(handles.axes);
        delete(handles.hImages);
    catch
    end
end
try
    delete(hCameraAxes);
catch
end


if NumPlots == 0
    return;
end
n = ceil(sqrt(NumPlots));
m = ceil(NumPlots/n);
depths= get(handles.hUsedDepthListbox,'String');
compactView = get(handles.hCompactView,'value');

if NumPlots == 1 || compactView
    set(handles.slider1,'visible','off');
else
    set(handles.slider1,'visible','on');
    set(handles.slider1,'min',0,'max',NumPlots-1,'value',NumPlots-1);
end
hAxes = tight_subplot(n, m, 0.05, 0.05, 0.01,handles.hLiveViewPanel);
if length(hAxes) > 1
    if UseCamera
        linkaxes(hAxes(1:end-1),'xy');
    else
        linkaxes(hAxes,'xy');
    end
end
if ~compactView
    for k=1:length(hAxes)
       set( hAxes(k),'Position',[0.01 0.05+(k-1) 0.9 0.9]);
    end
end

[OffsetX, OffsetY, Res] = GetCameraParams();


for k=1:length(hAxes)
    if (k <= NumPlanes)
        hImages(k) = image(zeros(2*handles.roi.radius+1,2*handles.roi.radius+1),'parent',hAxes(k));
        set(hAxes(k),'xlim',[1 2*handles.roi.radius+1],'ylim',[1 2*handles.roi.radius+1]);
        colormap(hAxes(k),'gray');
        axis(hAxes(k),'off');
        axis(hAxes(k),'equal');
        if (k==1)
            hold(hAxes(k),'on');
            ang = linspace(0,2*pi,100);
            circleX = 1+handles.roi.radius + cos(ang)*handles.roi.radius;
            circleY = 1+handles.roi.radius + sin(ang)*handles.roi.radius;
            plot(hAxes(k), circleX, circleY,'r','LineWidth',3);
        end
        if ~isempty(depths)
            text(2,6,depths{k},'parent',hAxes(k),'Color','y','Fontsize',16);
        end
    else
        if UseCamera && k == NumPlanes+1
           hImages(k) = image(zeros(Res,Res),'parent',hAxes(k));
           set(hImages(k),'CDataMapping','scaled');
           set(handles.figure1, 'Colormap', jet(64));
            axis(hAxes(k),'off');
            axis(hAxes(k),'equal')
        else
            axis(hAxes(k),'off');
        end
    end
    
    if (k==1) && isfield(ROIs,'positions')
        for j=1:length(ROIs.handles)
            ROIs.handles(j)=impoly(hAxes(k), ROIs.positions{j});
            ROIs.handles(j).addNewPositionCallback(@updateROIs);
            ROIs.handles(j).setColor(ROIs.colors(j,:));
        end
    end
end
setappdata(handles.figure1,'ROIs',ROIs);
handles.axes = hAxes;
handles.hImages = hImages;

if (UseCamera && isfield(handles,'cameraTimer'))
    % start callbacks using software triggers...
     if strcmpi(handles.cameraTimer.Running,'off')
        handles.cameraTimer.UserData = handles;
        start(handles.cameraTimer );
     end
end


return;

function plotROI(handles)
roi = handles.roi;
% plot the bounding circle
if ~isfield(handles,'hImages') || isempty(handles.hImages)
    return;
end;

if isfield(handles,'axes')
    set(handles.hImages(1),'cdata',roi.Mask);
end
set(handles.axes(1),'clim',[0 1])
if roi.numDepthPlanes*roi.numSpots < 40000
    set(handles.numSpots,'String', sprintf('# Spots: %d (%d per Z)',roi.numDepthPlanes*roi.numSpots,roi.numSpots),'ForegroundColor','k');
else
    set(handles.numSpots,'String', sprintf('# Spots: %d (%d per Z)',roi.numDepthPlanes*roi.numSpots,roi.numSpots),'ForegroundColor','r');
end
set(handles.maxRate,'String', sprintf('max frame rate: %.2f Hz',roi.maxRate));
set(handles.RateEdit,'String', sprintf('%.2f',roi.selectedRate));
set(handles.NumFramesEdit,'String', sprintf('%d',roi.numFrames));
set(handles.DurationEdit,'String', sprintf('%.2f',roi.durationSec));
set(handles.RateLimiter,'String', num2str(roi.maxDMDrate));

overSampling = str2num(get(handles.hOverSamplingEdit,'String'));
numBytesFastChannel = roi.numSpots*roi.numFrames*overSampling*2;
set(handles.hDataSize,'String', sprintf('Data Size: %.1f MB', numBytesFastChannel/ 1e6));
updateROIs([]);

% --- Outputs from this function are returned to the command line.
function varargout = ROIModule_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in FullFOV.
function FullFOV_Callback(hObject, eventdata, handles)
handles.roi.boundingbox = [1 1 2*handles.roi.radius+1 2*handles.roi.radius+1]; % full FOV
handles.roi=recomputeROI(handles.roi, length(handles.usedDepthIndices));
set(handles.axes(1),'clim',[0 1]);
guidata(hObject,handles);

 plotROI(handles);
setMaxFrameRate(hObject,handles)




% --- Executes on button press in LiveView.
function LiveView_Callback(hObject, eventdata, handles)
% hObject    handle to LiveView (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in hRunningAverage.
function hRunningAverage_Callback(hObject, eventdata, handles)
if ~get(hObject,'value')
    
end

% --- Executes on button press in SaveToDisk.
function SaveToDisk_Callback(hObject, eventdata, handles)
% hObject    handle to SaveToDisk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SaveToDisk



function RateEdit_Callback(hObject, eventdata, handles)
newRate = str2num(get(hObject,'String'));
if newRate <= handles.roi.maxRate
    handles.roi.selectedRate = newRate;
else
    handles.roi.selectedRate = handles.roi.maxRate;
end

newDurationSec = str2num(get(handles.DurationEdit,'String'));
handles.roi.numFrames = ceil(newDurationSec/ (1/handles.roi.selectedRate));
handles.roi.durationSec = handles.roi.numFrames*1/handles.roi.selectedRate;
guidata(hObject,handles);
plotROI(handles);

% --- Executes during object creation, after setting all properties.
function RateEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RateEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ShowOnScreen.
function ShowOnScreen_Callback(hObject, eventdata, handles)
% hObject    handle to ShowOnScreen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ShowOnScreen



function NumFramesEdit_Callback(hObject, eventdata, handles)
handles.roi.numFrames = str2num(get(hObject,'String'));
handles.roi.durationSec = handles.roi.numFrames*1/handles.roi.selectedRate;
guidata(hObject,handles);
plotROI(handles);


% --- Executes during object creation, after setting all properties.
function NumFramesEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NumFramesEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DurationEdit_Callback(hObject, eventdata, handles)
newDurationSec = str2num(get(hObject,'String'));
handles.roi.numFrames = ceil(newDurationSec/ (1/handles.roi.selectedRate));
handles.roi.durationSec = handles.roi.numFrames*1/handles.roi.selectedRate;
guidata(hObject,handles);
plotROI(handles);

% --- Executes during object creation, after setting all properties.
function DurationEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DurationEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in NumFrames.
function NumFrames_Callback(hObject, eventdata, handles)
% hObject    handle to NumFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of NumFrames


% --- Executes on button press in Duration.
function Duration_Callback(hObject, eventdata, handles)
% hObject    handle to Duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Duration



% --- Executes during object creation, after setting all properties.
function hROIlist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hROIlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in radiobutton10.
function radiobutton10_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton10


% --- Executes on button press in radiobutton9.
function radiobutton9_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton9



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
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


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in SubSampleChange.
function SubSampleChange_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in SubSampleChange 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch eventdata.NewValue
    case handles.SubsampleX1
        handles.roi.subsampling = 1;
    case handles.SubsampleX2
        handles.roi.subsampling = 2;
    case handles.SubsampleX3
        handles.roi.subsampling = 3;
    case handles.SubsampleX4
        handles.roi.subsampling = 4;
end
handles.roi=recomputeROI(handles.roi,length(handles.usedDepthIndices));

if get(handles.Duration,'Value')
    durationSec = str2num(get(handles.DurationEdit,'String'));
    handles.roi.numFrames = round(durationSec/ (1/handles.roi.selectedRate));
    set(handles.NumFramesEdit,'String',num2str(handles.roi.numFrames));
    handles.roi.durationSec = handles.roi.numFrames*1/handles.roi.selectedRate;
else
    handles.roi.durationSec = handles.roi.numFrames*1/handles.roi.selectedRate;
    set(handles.DurationEdit,'String',num2str(handles.roi.durationSec ));
end

guidata(hObject,handles);
 plotROI(handles);

 setMaxFrameRate(hObject,handles);
 

function mouseMove(obj,A,fig,ax)
global g_handles
C = get (ax, 'CurrentPoint');
x=C(1,1);
y=C(1,2);
g_handles.move = [x,y];
newpos = [min(g_handles.down,g_handles.move) abs(g_handles.down-g_handles.move)];
if (newpos(3) > 0 && newpos(4) > 0)
    set(g_handles.rect,'position',newpos);
end


function mouseDown(obj,A,fig,ax)
global g_handles
C = get (ax, 'CurrentPoint');
x=C(1,1);
y=C(1,2);
mousePos =[x,y];
g_handles.down = [x,y];
g_handles.rect = rectangle('Position',[x,y,1,1],'parent',ax,'EdgeColor','b');
set (fig, 'WindowButtonMotionFcn', {@mouseMove, fig,ax});
set (fig, 'WindowButtonUpFcn', {@mouseUp, fig,ax});

function mouseUp(obj,A,fig,ax)
global g_handles
global g_savedHandles
C = get (ax, 'CurrentPoint');
x=C(1,1);
y=C(1,2);
set (fig, 'WindowButtonDownFcn', g_savedHandles.MouseDown);
set (fig, 'WindowButtonMotionFcn',g_savedHandles.MouseMove);
set (fig, 'WindowButtonUpFcn', g_savedHandles.MouseUp);
set(fig,'Pointer','arrow');
delete(g_handles.rect)
g_handles.move = [x,y];
newpos = round([min(g_handles.down,g_handles.move) abs(g_handles.down-g_handles.move)]);
handles = guidata(fig);
handles.roi.boundingbox = [newpos(1:2), newpos(1:2)+newpos(3:4)];
handles.roi=recomputeROI(handles.roi,length(handles.usedDepthIndices));
 guidata(fig,handles);
 plotROI(handles);
 setMaxFrameRate(obj,handles);

clear global g_handles

function selectBox(fig, ax)
global g_savedHandles
g_savedHandles.MouseDown = get (fig, 'WindowButtonDownFcn');
g_savedHandles.MouseMove = get (fig, 'WindowButtonMotionFcn');
g_savedHandles.MouseUp = get (fig, 'WindowButtonUpFcn');

set(fig,'Pointer','cross');
set (fig, 'WindowButtonDownFcn', {@mouseDown, fig,ax});


function setMaxFrameRate(hObject,handles)
handles.roi.selectedRate = handles.roi.maxRate;
if get(handles.Duration,'Value')
    durationSec = str2num(get(handles.DurationEdit,'String'));
    handles.roi.numFrames = round(durationSec/ (1/handles.roi.selectedRate));
    set(handles.NumFramesEdit,'String',num2str(handles.roi.numFrames));
    handles.roi.durationSec = handles.roi.numFrames*1/handles.roi.selectedRate;
else
    handles.roi.durationSec = handles.roi.numFrames*1/handles.roi.selectedRate;
    set(handles.DurationEdit,'String',num2str(handles.roi.durationSec ));
end
 guidata(hObject,handles);
 plotROI(handles);
 return;
 
% --- Executes on button press in setMaxRate.
function setMaxRate_Callback(hObject, eventdata, handles)
setMaxFrameRate(hObject,handles)



function displayMessage(handles, msg)
set(handles.StatusText,'String',['Status: ',msg]);

function abort=AbortRun(handles)
global g_scanID
% Abort?
abort = false;
if isfield(handles,'strctRun')
    
    if strcmpi(handles.strctRun.timer.Running,'on')
        % Abort run!
        
%         if get(handles.hPMTautomation,'value')
%             %PMTwrapper('setGain',0);
%             PMTwrapper('pmtoff');
%         end
        
        
        timr = handles.strctRun.timer;
        stop(timr);
        %     WaitSecs(0.1);
        %     Tmp = timr.UserData;
        %     strctRun = Tmp{1};
        %     strctRun.state = 4;
        %     strctRun.aborted = true;
        %     timr.UserData = {strctRun,handles} ;
        %     start(timr);
        abort = true;
        
        % User requested to abort the run
        ALPwrapper('StopSequence',handles.ALPid);
        ALPuploadAndPlay(handles.ALPid,zeros(768,1024)>0,20000,1);
        
        strctRun.USB1608_ID= 0;
        strctRun.USB2020_ID= 1;
        strctRun.USB1608_PACKET_SIZE = 256;
        strctRun.USB2020_PACKET_SIZE = 4096;
        
        fnDAQusb('StopContinuousAcqusition',strctRun.USB1608_ID);
        fnDAQusb('StopContinuousAcqusition',strctRun.USB2020_ID);
        fnDAQusb('Release');
        
        if get(handles.hTriggerStimulusMachine,'value')
           StimulusClient('Abort');
        end
        
        set(handles.StartLiveView,'String','Start');
        % Dump raw data to disk
        sessionID = SessionWrapper('GetSessionID');
        set(handles.figure1,'name', sprintf('ROI Module: Finished Session %d, scan %d',sessionID, g_scanID));
        set(handles.hNotSaveWarning,'visible','off');
        
        if get(handles.hRecordCamera,'value');
            CameraTriggerWrapper(1);
        end
        fprintf('Run Aborted!\n');
        return;
    end
end


% --- Executes on button press in StartLiveView.
function StartLiveView_Callback(hObject, eventdata, handles)
if AbortRun(handles)
    return;   
end
%StimulusClient('Init');
% figure(handles.figure1);
% 
% dmd = CalibrationModule('GetCalibration');
% figure(handles.figure1);
% if ~isfield(dmd,'hologramSpotPos')
%     displayMessage(handles,'Cannot run sequence. Run Calibration First!');
%     return;
% end
if handles.roi.numDepthPlanes*handles.roi.numSpots > 40000
    displayMessage(handles,'Too many spots to store in FPGA memory. Remove Z Planes.');
    return;
end

if (handles.roi.numFrames == 0)
    displayMessage(handles,'Cannot run sequence. Select longer duration!');
    return;
end
set(handles.StartLiveView,'String','Abort');
GenerateAndUploadSequence(hObject,handles,false);




function RateLimiter_Callback(hObject, eventdata, handles)
handles.roi.maxDMDrate = str2num(get(hObject,'String'));
handles.roi=recomputeROI(handles.roi,length(handles.usedDepthIndices));


rate = handles.roi.maxDMDrate;
delay = 14;
pulse = 2.1;
window = 1/rate*1e6 - delay;
%max_pulses_per_trigger = floor(window / pulse);
%set(handles.hOverSamplingEdit,'String',num2str(max_pulses_per_trigger));
%[Res] = OverClockWrapper(max_pulses_per_trigger);


guidata(hObject,handles);
 plotROI(handles);


% --- Executes during object creation, after setting all properties.
function RateLimiter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RateLimiter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function strctRun = GenerateAndUploadSequence(hObject,handles,repeatScan)
updateROIs([]);
roi = handles.roi;
scanID=CreateNewScan();
sessionID = SessionWrapper('GetSessionID');
fprintf('Starting a new scan (ID %d)\n',scanID);
set(handles.figure1,'name', sprintf('ROI Module: Running Session %d, scan %d',sessionID,scanID));

% Read the first Z calibration to get a sense where the spots are...
h5file= SessionWrapper('GetSession');
hologramSpotPos = h5read(h5file,'/calibrations/calibration1/hologramSpotPos');



% convert the indices to indices corresponding to computed holograms
abSelectedSpots = ismember(hologramSpotPos,roi.selectedSpots);
indicesToHolograms = find(abSelectedSpots);



strctRun.fastDAQoverSampling = str2num(get(handles.hOverSamplingEdit,'String'));
strctRun.USB1608_ID = 0;
strctRun.USB2020_ID = 1;
strctRun.USB1608_PACKET_SIZE = 256;
strctRun.USB2020_PACKET_SIZE = 4096;

strctRun.photodiodeChannel = 1;
strctRun.PMTdescription = {'Hamamatsu 7422-20','ThorLabs PMTSS'};
strctRun.PMTfilterSetting = {'FF605-Di02-25x36','FF01-593/LP-25'};
strctRun.PMTused = [get(handles.hPMT1,'value')>0,get(handles.hPMT2,'value')>0];
strctRun.PMTtoDAQChannelMapping = [0,1]; % PMT1 goes to CH0, PMT2 goes to CH1.
strctRun.numChannels = sum(strctRun.PMTused);
strctRun.firstChannelToAcquire = find(strctRun.PMTused,1,'first')-1;
strctRun.lastChannelToAcquire = find(strctRun.PMTused,1,'last')-1;
strctRun.fastDAQchannels = [strctRun.firstChannelToAcquire,strctRun.lastChannelToAcquire];
strctRun.Depths = handles.uniqueConfigurations(handles.usedDepthIndices,2);
strctRun.depthIndices = handles.usedDepthIndices;
strctRun.numPlanes = roi.numDepthPlanes;
strctRun.numFrames = roi.numFrames;
strctRun.numSpotsPerPlane = length(indicesToHolograms);
strctRun.numSpots = strctRun.numPlanes*strctRun.numSpotsPerPlane;
strctRun.numFramesAcquired = 0;

strctRun.desiredFlips = strctRun.numFrames * strctRun.numPlanes *  strctRun.numSpotsPerPlane;
strctRun.numSamplesPerFrame = strctRun.numChannels * strctRun.numPlanes *  strctRun.numSpotsPerPlane * strctRun.fastDAQoverSampling;
strctRun.totalDesiredSamples = strctRun.numFrames * strctRun.numSamplesPerFrame;
strctRun.actualNumberSamplesToCollect = strctRun.USB2020_PACKET_SIZE*ceil(strctRun.totalDesiredSamples/strctRun.USB2020_PACKET_SIZE);
strctRun.fastDAQnumSamples = strctRun.actualNumberSamplesToCollect;
strctRun.actualNumberOfFlips = ceil(strctRun.actualNumberSamplesToCollect / strctRun.numChannels /  strctRun.fastDAQoverSampling);
strctRun.missingDMDflips = strctRun.actualNumberOfFlips - strctRun.desiredFlips;

strctRun.prevMotorPos = 0;

if ~MotorControllerWrapper('IsInitialized')
    MotorControllerWrapper('Init');
end

[~,A]=MotorControllerWrapper('GetPositionMicrons');
    if A ~= 0
        strctRun.motorPositionUm = [0, A];
    else
        strctRun.motorPositionUm = [0, NaN];
    end

if ~FilterWheelWrapper('IsInitialized')
    FilterWheelWrapper('Init');
end

[Res,pos1]=FilterWheelWrapper('GetFilterWheelPosition',1);
[Res,pos2]=FilterWheelWrapper('GetFilterWheelPosition',2);
strctRun.FilterWheelND473nm =  FilterWheelWrapper('GetPostionName',pos1);
strctRun.FilterWheelND532nm =  FilterWheelWrapper('GetPostionName',pos2);
fprintf('Scanning at depth %.0f (relative %.0f)\n',strctRun.motorPositionUm(1,2));
fprintf('Uploading Sequence: %d spots (%d per Z, %d planes)...\n',strctRun.numSpots,roi.numSpots,roi.numDepthPlanes);
strctRun.PMTgain = [];
if repeatScan
    strctRun.sweepsequenceID = handles.prev_sweepsequenceID ;
else

    ALPwrapper('ReleaseAllSequences',handles.ALPid);


    numReferencePixels= h5read(h5file,'/calibrations/calibration1/numReferencePixels');
    leeBlockSize= h5read(h5file,'/calibrations/calibration1/leeBlockSize');
    
    holograms = zeros(768,128, strctRun.numSpots,'uint8');
    fprintf('Current motor position is %.2f um\n',strctRun.motorPositionUm(1,2))
    % iterate over the fine motor depths.
    % for each one, find the nearest coarse calibration (they all should be
    % the same....)
    [uniqueColorNames,B,calibrationColorChannelMapping]= unique(handles.ColorChannels);
    
    existingCalibrations = [handles.AbsoluteDepthsUm;    handles.RelativeFineDepthsUm;    calibrationColorChannelMapping'];  
    selectedConfigurations = handles.uniqueConfigurations(strctRun.depthIndices,:)';
        
    numPlanes = length(strctRun.depthIndices);
    
    for planeIter=1:numPlanes
        % find the closest calibration (Aboslute coordinates) that matches
        % in fine depth and color channel....
        
        relevantCalibrations = find( selectedConfigurations(1,planeIter) == existingCalibrations(3,:) & ...
            selectedConfigurations(2,planeIter)== existingCalibrations(2,:));
        
        [fDistToCalib,indx]=min(abs(handles.AbsoluteDepthsUm(relevantCalibrations)-strctRun.motorPositionUm(1,2)));
        selectedCalibration = relevantCalibrations(indx);
        fprintf('Nearest calibration is %.2f um away (Calibration %d)\n',fDistToCalib,selectedCalibration);
        
        ind = 1:strctRun.numSpotsPerPlane;
        selectedCarrier= h5read(h5file,sprintf('/calibrations/calibration%d/selectedCarrier',selectedCalibration));
        carrierRotation= h5read(h5file,sprintf('/calibrations/calibration%d/carrierRotation',selectedCalibration));
        
        try
            inputPhases = h5read(h5file,sprintf('/calibrations/calibration%d/inputPhases',selectedCalibration));
            
        catch
            fprintf('Phases were not computed during calibration, recomputing from angles...\n');
            
            Kinv_angle= h5read(h5file,sprintf('/calibrations/calibration%d/Kinv_angle',selectedCalibration));
            hadamardSize = h5read(h5file,sprintf('/calibrations/calibration%d/hadamardSize',selectedCalibration));
            hologramSpotPos = h5read(h5file,sprintf('/calibrations/calibration%d/hologramSpotPos',selectedCalibration));
            walshBasis = fnBuildWalshBasis(hadamardSize);
            numModes = size(walshBasis ,3);
            phaseBasis = single((walshBasis == 1)*pi);
            phaseBasisReal = single(reshape(real(exp(1i*phaseBasis)),hadamardSize*hadamardSize,numModes));
            Sk = CudaFastMult(phaseBasisReal, sin(Kinv_angle)); %Sk=dmd.phaseBasisReal*sin(K);
            Ck = CudaFastMult(phaseBasisReal, cos(Kinv_angle)); % Ck=dmd.phaseBasisReal*cos(K);
            Ein_all=atan2(Sk,Ck);
            inputPhases=reshape(Ein_all(:,hologramSpotPos), hadamardSize,hadamardSize,length(hologramSpotPos));
            clear Ein_all phaseBasisReal phaseBasis Kinv_angle
        end
        
        fprintf('Generating holograms for plane %d/%d\n',planeIter,strctRun.numPlanes);
        ind = 1+(planeIter-1)*strctRun.numSpotsPerPlane:planeIter*strctRun.numSpotsPerPlane;
        
        
        holograms(:,:, ind) = CudaFastLee(inputPhases(:,:,indicesToHolograms),numReferencePixels, leeBlockSize, selectedCarrier,carrierRotation);
    end
  
    fprintf('Now uploading to DMD %d patterns\n', size(holograms,3));
    strctRun.sweepsequenceID=ALPwrapper('UploadPatternSequence',handles.ALPid,holograms);
    if (strctRun.sweepsequenceID == -1)
        fprintf('CRITICAL ERROR!\n');
        return;
    end
     
    handles.prev_indicesToHolograms = indicesToHolograms;
    handles.prev_sweepsequenceID = strctRun.sweepsequenceID;
end

strctRun.lastID=ALPwrapper('UploadPatternSequence',handles.ALPid,zeros(768,1024)>0);




%% DAQ Setup
strctRun.slowDAQchannels = [0 1]; % 0 = screen photodiode, 1 = laser stability, 2 = accelerometer
strctRun.numSlowChannels =strctRun.slowDAQchannels(2)-strctRun.slowDAQchannels(1)+1;

strctRun.TemperatureReading = [];
% 
% DAQ2020pacletSize = 4096;
% DAQ1608packetSize = 256*strctRun.fastDAQoverSampling;
% DAQ1208packetSize = 31;

% strctRun.
% strctRun.missingDMDflips = (ceil(numFastDAQsamplesNotPacketSize / CombinedPacketSize)*CombinedPacketSize-numFastDAQsamplesNotPacketSize)/strctRun.fastDAQoverSampling;
% strctRun.missingSamplesFastDAQ = strctRun.missingDMDflips*strctRun.fastDAQoverSampling;
% strctRun.fastDAQnumSamples= numFastDAQsamplesNotPacketSize+strctRun.missingSamplesFastDAQ;
strctRun.dmdRate = roi.selectedRate * strctRun.numSpots;
strctRun.durationSec = (strctRun.actualNumberOfFlips)/ strctRun.dmdRate;
strctRun.slowDAQrateHz = strctRun.dmdRate; % used to be 2000....
strctRun.slowDAQnumDesiredSamplesPerChannel = strctRun.desiredFlips; % one sample per flip per channel
strctRun.slowDAQnumSamplesPerChannel  =strctRun.USB1608_PACKET_SIZE*ceil(strctRun.slowDAQnumDesiredSamplesPerChannel/strctRun.USB1608_PACKET_SIZE);
strctRun.missingDMDflips = max(strctRun.missingDMDflips, strctRun.slowDAQnumSamplesPerChannel-strctRun.slowDAQnumDesiredSamplesPerChannel);
strctRun.slowDAQtotalSamplesToCollect = strctRun.slowDAQnumSamplesPerChannel * strctRun.numSlowChannels;
strctRun.slowDAQnumSamples = strctRun.slowDAQtotalSamplesToCollect;
strctRun.slowDAQratePerChannelHz = strctRun.dmdRate; %/strctRun.numSlowChannels;


strctRun.highPassCutOff = min(0.9999,max(0, [80]*2/strctRun.dmdRate));
[strctRun.HighPass_b,strctRun.HighPass_a]=butter(2,strctRun.highPassCutOff,'high');

fprintf('DMD: playing %d patterns (%d spots, %d frames) at %.0f Hz, for a total duration of %.2f seconds (+ %d flips at the end for missing samples)\n',...
    strctRun.desiredFlips,strctRun.numSpots, strctRun.numFrames, strctRun.dmdRate, strctRun.durationSec,strctRun.missingDMDflips);
fprintf('Fast DAQ: Collecting %d channels, %d planes, %d samples/ch/frame. Total: %d samples (x%d over sampling)\n',strctRun.numChannels,strctRun.numPlanes, strctRun.numSamplesPerFrame,...
    strctRun.actualNumberSamplesToCollect,  strctRun.fastDAQoverSampling);
fprintf('Slow DAQ: Collecting %d channels, %d samples/channel at %d Hz (%.2f Seconds)\n',...
    strctRun.numSlowChannels,strctRun.slowDAQnumSamplesPerChannel, strctRun.slowDAQratePerChannelHz, strctRun.durationSec);


strctRun.planeRate = strctRun.dmdRate/strctRun.numPlanes/strctRun.numSpotsPerPlane;
%strctRun.frameRate = strctRun.dmdRate/(strctRun.numPlanes*strctRun.numSpotsPerPlane);

% strctRun.frameSizeFastDAQ = (strctRun.numPlanes*strctRun.numSpotsPerPlane*strctRun.fastDAQoverSampling);
% strctRun.frameSizeSlowDAQ = strctRun.numPlanes*strctRun.numSpotsPerPlane;
% 
lowPassRange = min(0.9999,max(0, [0.05 30]*2/strctRun.planeRate));
[strctRun.realTimeFiltering.b,strctRun.realTimeFiltering.a]=butter(2,lowPassRange);

%fprintf('Checking DAQ status...\n');
if (~fnDAQusb('IsInitialized'))
    
    res= fnDAQusb('Init',strctRun.USB1608_ID);
    res=res & fnDAQusb('Init',strctRun.USB2020_ID);
    if (res ~= 1) 
        fprintf('Failed to initialize boards!\n');
        return;
    end
end


%
% UseCamera = get(handles.hRecordCamera,'value');
% 
% if UseCamera
%     % Make sure that module isn't working...
%     CameraModule('StopLiveView');
%     figure(handles.figure1);
%     
%     stop(handles.cameraTimer); % Stop live view...
%     
%     DMDRate = roi.selectedRate * strctRun.numSpots;
%     strctRun.TargetCameraFrequency = str2num(get(handles.hCameraRateEdit,'String'));
%     strctRun.CameraTriggerSkip = ceil(DMDRate/strctRun.TargetCameraFrequency);
%     strctRun.CameraGain = str2num(get(handles.hCameraGainEdit,'String'));
%     strctRun.CameraExposure = 1.0/str2num(get(handles.hCameraExposureEdit,'String'));
%     CameraTriggerWrapper(strctRun.CameraTriggerSkip);
%     Dummy = PTwrapper('GetImageBuffer'); % Clear Buffer;
% end
% A=PTwrapper('GetImageBuffer');
% ALPuploadAndPlay(zeros(768,1024)>0,FreqDMD,50*Skip);
% WaitSecs(1);
% PTwrapper('GetBufferSize')

% if get(handles.hPMTautomation,'value')
%     if ~PMTwrapper('IsInitialized')
%         PMTwrapper('Init');
%     end
%     
%     PMTwrapper('PMTon');
%     WaitSecs(0.5); % allow some time for PMT gain to stabilize...
%   %  PMTwrapper('RampGain', get(handles.hPMTslider,'value'));
% end



% ISwrapper('TriggerOFF'); 
% FilterWheelModule('SetNaturalDensity',0); % ND0 = max intensity
%WaitSecs(1); % allow time for the filter wheel to settle?
strctRun.roi = roi;
strctRun.state = 1;

strctRun.smartAvgPMT1 = SmartAveraging('Init',[strctRun.numSpotsPerPlane,strctRun.numPlanes], str2num(get(handles.hRunningAverageEditPMT1,'String')));
strctRun.smartAvgPMT2 = SmartAveraging('Init',[strctRun.numSpotsPerPlane,strctRun.numPlanes], str2num(get(handles.hRunningAverageEditPMT2,'String')));

strctRun.prevRunsNumFrames = 0;
strctRun.numFramesAcquired =0;
strctRun.ROIs = getappdata(handles.figure1,'ROIs');
strctRun.startROIdisplay = 1;
strctRun.warningTimer = GetSecs();
setappdata(handles.figure1,'resetROI',false);
warning off
strctRun.timer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period',max(1/60,1/(max(6,roi.selectedRate))),'TimerFcn',@RunTimerCallback);
warning on
strctRun.timer.UserData = {strctRun, handles};

if get(handles.hTriggerStimulusMachine,'value')
    try
        strctRun.strctStimulusParams = StimulusClient('Init');
    catch
    end
end



handles.strctRun = strctRun;
guidata(hObject,handles);

set (handles.figure1, 'WindowButtonDownFcn', {@clearROI, handles});

start(strctRun.timer);

function vRange = getVoltageRange(handles)
voltageRangeSelection = get(handles.hVoltageRangeFastDAQ,'value');
switch voltageRangeSelection
    case 1
        vRange = 1;
    case 2 
        vRange = 2;
    case 3
        vRange = 5;
    case 4
        vRange = 10;
    otherwise
        vRange = 1;
end

return

% --- Executes on button press in clearRunningAverage.
function clearRunningAverage_Callback(hObject, eventdata, handles)
% hObject    handle to clearRunningAverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)





function scanID=CreateNewScan()

global g_scanID
hdf5File = SessionWrapper('GetSession');
% find how many calibrations are there...
hdf5FileInfo = h5info(hdf5File);
scanID = 1;
if isempty(hdf5FileInfo.Groups)
    % no calibrations done yet.
else
    scanGroup = find(ismember({hdf5FileInfo.Groups.Name},'/scans'));
    if isempty(scanGroup)
        % no calibrations done yet.
    else
        Tmp = hdf5FileInfo.Groups(scanGroup);
        scanID = length(Tmp.Groups)+1;
    end
end
try
    h5create(hdf5File,sprintf('/scans/scan%d/dummy',scanID),[1 1])
catch
    fprintf('Failed to create a new scan group\n');

end

g_scanID = scanID;

return;

function scanID=GetCurrentScan()
hdf5File = SessionWrapper('GetSession');
% find how many calibrations are there...
hdf5FileInfo = h5info(hdf5File);
scanID = [];
if isempty(hdf5FileInfo.Groups)
    % no calibrations done yet.
else
    scanGroup = find(ismember({hdf5FileInfo.Groups.Name},'/scans'));
    if isempty(scanGroup)
        % no calibrations done yet.
    else
        Tmp = hdf5FileInfo.Groups(scanGroup);
        scanID = length(Tmp.Groups);
    end
end
return;

function dumpStructureToScan(var,subField)
if ~exist('subField','var')
    subField = '';
end

names = fieldnames(var);
for k=1:length(names)
    Tmp = getfield(var, names{k});
    if isnumeric(Tmp)
        if ~isempty(Tmp)
            dumpVariableToScan(Tmp, names{k},subField);
        else
            dumpVariableToScan(0, names{k},subField);
        end
    elseif isstruct(Tmp) && ~strcmpi(names{k},'handles')
        dumpStructureToScan(Tmp,names{k});
    end
end


function dumpVariableToScan(var, name, subfield)
global g_scanID
if isempty(g_scanID)
    g_scanID = 1;
else
    scanID = g_scanID;
end
%scanID=GetCurrentScan();
if ~exist('name','var')
    name = inputname(1);
end
hdf5File = SessionWrapper('GetSession');

if ~exist('subfield','var')
    scanPath = sprintf('/scans/scan%d/%s',scanID,name);
else
 scanPath = sprintf('/scans/scan%d/%s/%s',scanID,subfield,name);    
end
if islogical(var)
    var = uint8(var);
end
if size(var,1) > 50 && size(var,2) > 80
    if size(var,3) > 50
        h5create(hdf5File,scanPath,size(var),'Deflate',0,'ChunkSize',[50 80 50],'Datatype',class(var));
    else
        if size(var,3) >= 2
            h5create(hdf5File,scanPath,size(var),'Deflate',0,'ChunkSize',[50 80 1],'Datatype',class(var));
        else
            h5create(hdf5File,scanPath,size(var),'Deflate',0,'ChunkSize',[50 80],'Datatype',class(var));
        end
    end
else
    try
        h5create(hdf5File,scanPath,size(var),'Datatype',class(var));
    catch
        dbg = 1;
    end
end
%fprintf('Dumping variable %s\n',name);
h5write(hdf5File,scanPath, var);
return;



function hDisplayMin_Callback(hObject, eventdata, handles)
% hObject    handle to hDisplayMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hDisplayMin as text
%        str2double(get(hObject,'String')) returns contents of hDisplayMin as a double


% --- Executes during object creation, after setting all properties.
function hDisplayMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDisplayMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hDisplayMax_Callback(hObject, eventdata, handles)
% hObject    handle to hDisplayMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hDisplayMax as text
%        str2double(get(hObject,'String')) returns contents of hDisplayMax as a double


% --- Executes during object creation, after setting all properties.
function hDisplayMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hDisplayMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hDisplayJet.
function hDisplayJet_Callback(hObject, eventdata, handles)
% hObject    handle to hDisplayJet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hDisplayJet
if get(hObject,'value')
    set(handles.figure1, 'Colormap', jet(64));
else
    set(handles.figure1, 'Colormap', gray(64));
end


% --- Executes on button press in hAutoRangePMT1.
function hAutoRangePMT1_Callback(hObject, eventdata, handles)
% hObject    handle to hAutoRangePMT1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hAutoRangePMT1



function hRunningAverageCountPMT1_Callback(hObject, eventdata, handles)
%% TODO.. modifu strctRun ?!?!?

% --- Executes during object creation, after setting all properties.
function hRunningAverageCountPMT1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hRunningAverageCountPMT1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in hReloadCalibButton.
function hReloadCalibButton_Callback(hObject, eventdata, handles)
% ReloadCalibration(hObject,handles,sessionList,length(sessionList))
% 
% ReloadCalibration(hObject,handles);
% 
% WeightMatrix = zeros(numSpots,numSpots,'single');
% for k=1:numSpots
%     Tmp = single(SpotCalibrationImages(:,:,k))-darkImage;
%     WeightMatrix(k,:)=Tmp(roi.selectedSpots);
% end
% 
% SparseWeight = WeightMatrix;
% SparseWeight(SparseWeight < 100) = 0;
% SparseWeight=sparse(SparseWeight);
% [U,S,V]=svds(SparseWeight,15);
% handles.ReconstructionMatrix=U*S^-1*V';
% guidata(hObject,handles);



% --- Executes on button press in hIntensityNormalization.
function hIntensityNormalization_Callback(hObject, eventdata, handles)
% hObject    handle to hIntensityNormalization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hIntensityNormalization


% --- Executes on button press in hLoop.
function hLoop_Callback(hObject, eventdata, handles)
% hObject    handle to hLoop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hLoop


% --- Executes on selection change in hUsedDepthListbox.
function hUsedDepthListbox_Callback(hObject, eventdata, handles)
% hObject    handle to hUsedDepthListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns hUsedDepthListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from hUsedDepthListbox


% --- Executes during object creation, after setting all properties.
function hUsedDepthListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hUsedDepthListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hRemoveDepth.
function hRemoveDepth_Callback(hObject, eventdata, handles)
depthIndex = get(handles.hUsedDepthListbox,'value');
if depthIndex == 0
    return;
end;
handles=RemoveDepthFromActiveList(handles, handles.usedDepthIndices(depthIndex));
guidata(hObject,handles);
setMaxFrameRate(hObject,handles);

% --- Executes on selection change in hAvailDepthListbox.
function hAvailDepthListbox_Callback(hObject, eventdata, handles)
% hObject    handle to hAvailDepthListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns hAvailDepthListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from hAvailDepthListbox


% --- Executes during object creation, after setting all properties.
function hAvailDepthListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hAvailDepthListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hAddDepth.
function hAddDepth_Callback(hObject, eventdata, handles)
confIndex = get(handles.hAvailDepthListbox,'value');
handles=AddDepthToActiveList(handles, confIndex);
Depths = get(handles.hAvailDepthListbox,'String');
set(handles.hAvailDepthListbox,'value',min( confIndex+1, length(Depths)));
guidata(hObject,handles);
setMaxFrameRate(hObject,handles);


% --- Executes on selection change in hCalibrationPopup.
function hCalibrationPopup_Callback(hObject, eventdata, handles)
sessionList = SessionWrapper('ListSessions');
selectedCalib = get(hObject,'value');
ReloadCalibration(hObject,handles,sessionList,selectedCalib);

% set(handles.hCalibrationPopup,'String',sessionList,'value',selectedCalib);
% % Load depths
% Depths = SessionWrapper('LoadSession',sessionList{selectedCalib});
% h5file= SessionWrapper('GetSession');
% set(handles.hAvailDepthListbox,'String',Depths,'value',1);


% --- Executes during object creation, after setting all properties.
function hCalibrationPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hCalibrationPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hSpatialSmoothingPMT1.
function hSpatialSmoothingPMT1_Callback(hObject, eventdata, handles)
% hObject    handle to hSpatialSmoothingPMT1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hSpatialSmoothingPMT1


function updateROIs(pos)
ROIs = getappdata(gcf,'ROIs');
if ~isfield(ROIs,'handles')
    return;
end;

nROIs=length(ROIs.handles);
G = gcbo;
if isempty(G)
    return;
end;
handles = guidata(G);
ROIs.ind= cell(1,nROIs);
for j=1:nROIs
    M = ROIs.handles(j).createMask();
    ROIs.positions{j} = ROIs.handles(j).getPosition();
    ROIs.ind{j}=find(ismember(handles.roi.selectedSpots, find(M)));
    ROIs.colors(j,:) = ROIs.handles(j).getColor();
%     fprintf('ROI %d : %d points\n',j, length(ROIs_ind{j}));
end
setappdata(gcf,'ROIs',ROIs);
%fprintf('ROIs changed\n');

% --- Executes on button press in hAddROI.
function hAddROI_Callback(hObject, eventdata, handles)
h = impoly(handles.axes(1));
if isempty(h)
    return;
end;
ROIs=getappdata(handles.figure1,'ROIs');

h.addNewPositionCallback(@updateROIs); 


ROImouseCallback = get (handles.figure1, 'WindowButtonMotionFcn');

% h.removeNewPositionCallback(@updateROIs);
newColor = [    0    0.4470    0.7410];
if ~isfield(ROIs,'handles')
    ROIs.handles = [];
    ROIs.IDs = [];
end

if ~isempty(ROIs.handles)
    
    usedColors = zeros(length(ROIs.handles),3);
    for k=1:length(ROIs.handles)
        usedColors(k,:)=ROIs.handles(k).getColor();
    end
    NewColors = lines(20);
    % find a new color that isn't used already
    for j=1:size(NewColors,1)
        if min(sum((usedColors - repmat(NewColors(j,:),size(usedColors,1),1)).^2,2)) > 0.01
            % found an unsed color!
            newColor = NewColors(j,:);
            break;
        end
    end
end

% find unused ID
newID = 1;
for k=1:20
    if sum(ROIs.IDs == k) == 0
        newID = k;
        break;
    end
end

h.setColor(newColor);
ROIs.handles = [ROIs.handles, h];
ROIs.IDs = [ROIs.IDs, newID];
setappdata(handles.figure1,'ROIs',ROIs);
updateROIlist(handles);


function updateROIlist(handles)
ROIs=getappdata(handles.figure1,'ROIs');
nROIs = length(ROIs.handles);
ROInames = cell(1,nROIs);
for k=1:nROIs
    ROInames{k} = sprintf('ROI %d', ROIs.IDs(k));
end
set(handles.hROIlist,'String', ROInames,'value',nROIs);
updateROIs([]);


% --- Executes on button press in hDeleteROI.
function hDeleteROI_Callback(hObject, eventdata, handles)
ROIs=getappdata(handles.figure1,'ROIs');
selectedROI = get(handles.hROIlist,'value');
if selectedROI > 0
    delete(ROIs.handles(selectedROI));
    ROIs.handles(selectedROI) = [];
    ROIs.IDs(selectedROI) = [];
    ROIs.positions(selectedROI) = [];
    ROIs.ind(selectedROI) = [];
    ROIs.colors(selectedROI,:) = [];
    setappdata(handles.figure1,'ROIs',ROIs);
    updateROIlist(handles);
end


% --- Executes on selection change in hROIlist.
function hROIlist_Callback(hObject, eventdata, handles)
ROIs=getappdata(handles.figure1,'ROIs');
selectedROI = get(handles.hROIlist,'value');
c=ROIs.handles(selectedROI).getColor;
for j=1:5
    ROIs.handles(selectedROI).setColor(0.5*c);
    drawnow
    ROIs.handles(selectedROI).setColor(c);
    drawnow
end



% % % % 
% % % % 
% % % % function strctRun=drawRealTimeFrames(handles,strctRun,...
% % % %                         FramesFastDAQ, FramesFastDAQIndex,...
% % % %                         FramesSlowDAQ, FramesSlowDAQIndex)
% % % % %% Step 1: Update slow channels stats
% % % % global g_fft
% % % % if ~isempty(FramesSlowDAQ)
% % % %     for frameIter=1:size( FramesSlowDAQ,2)
% % % %         strctRun.SlowChannelValues(:,FramesSlowDAQIndex+frameIter) = FramesSlowDAQ(:,frameIter);
% % % %     end
% % % % end
% % % % 
% % % % if isempty(FramesFastDAQ)
% % % %     return;
% % % % end
% % % % if get(handles.hFFT,'value')
% % % %     
% % % %     g_fft = [g_fft;FramesFastDAQ(:)];
% % % %     if length(g_fft) > 40000
% % % %         Tmp = g_fft;
% % % %         Tmp = Tmp.*hanning(length(g_fft));
% % % %         Fs = strctRun.dmdRate;            % Sampling frequency
% % % %         L = length(Tmp);             % Length of signal
% % % %         f = Fs*(0:(L/2))/L;
% % % %         Af = log10(abs(fft(Tmp)));
% % % %         plot(handles.hRealTimeAxes,f, Af(1:length(f)));
% % % %         set(handles.hRealTimeAxes,'ylim',[0 7]);
% % % %         set(handles.hRealTimeAxes,'xlim',[0 4600]);
% % % %         g_fft =[];
% % % %     end
% % % % end
% % % % 
% % % % %     Tmp=squeeze(mean(strctRun.valuesFast,1));
% % % % %                 Tmp=Tmp(1: round(0.2*strctRun.fastDAQnumSamples/10));
% % % % %                 Tmp = Tmp.*hanning(length(Tmp))';
% % % % %                 Fs = strctRun.dmdRate;            % Sampling frequency
% % % % %                 L = length(Tmp);             % Length of signal
% % % % %                 f = Fs*(0:(L/2))/L;
% % % % %                 Af = log10(abs(fft(Tmp)));
% % % % %                 figure(1);hold on;plot(f,Af(1:length(f)));
% % % % %                 xlabel('Freq');ylabel('Power Spectrum');
% % % % 
% % % % 
% % % % 
% % % % 
% % % % % plot on screen the last frame (?)
% % % % Frames=32767-FramesFastDAQ;
% % % % 
% % % % if get(handles.hSpatialHPFCheckBox,'value')
% % % %     
% % % %     strctRun.highPassCutOff = min(0.9999,max(0, str2num(get(handles.hSpatialHPFedit,'String'))*2/strctRun.dmdRate));
% % % %     [strctRun.HighPass_b,strctRun.HighPass_a]=butter(2,strctRun.highPassCutOff,'high');
% % % % 
% % % %     Frames = reshape(filtfilt(strctRun.HighPass_b,strctRun.HighPass_a,Frames(:)),size(Frames));
% % % % end
% % % % 
% % % % 
% % % % 
% % % % 
% % % % roi = strctRun.roi;
% % % % 
% % % % %% update the average.
% % % % newAvgFrames = str2num(get(handles.hRunningAverageCountPMT1,'String'));
% % % % 
% % % % resetAvg = false;
% % % % if strcmpi(get(handles.hResetAveragePMT1,'FontWeight'),'bold')
% % % %     resetAvg = true;
% % % %     set(handles.hResetAveragePMT1,'FontWeight','normal');
% % % % end
% % % % 
% % % % saveMean = false;
% % % % if strcmpi(get(handles.hSaveMeanPMT1,'FontWeight'),'bold')
% % % %     saveMean = true;
% % % %     set(handles.hSaveMeanPMT1,'FontWeight','normal');
% % % % end
% % % % if saveMean
% % % %     strctRun.meanBackground = strctRun.smartAvg;
% % % %     fprintf('Background saved\n');
% % % % end
% % % % 
% % % % if newAvgFrames ~= strctRun.smartAvg.numSamplesToAverage || resetAvg
% % % %     % reset
% % % %     strctRun.smartAvg = SmartAveraging('Init',[strctRun.numSpots,1], newAvgFrames);
% % % % end
% % % % 
% % % % strctRun.smartAvg = SmartAveraging('AddSamples',strctRun.smartAvg, Frames);
% % % % %plotFFT(strctRun.smartAvg.data(:), strctRun.dmdRate)
% % % % 
% % % % % % % 
% % % % % % % %
% % % % % % % Fs= strctRun.dmdRate;
% % % % % % % y = strctRun.smartAvg.data(:);
% % % % % % % %y=y.*hanning(length(y));
% % % % % % % T = 1/Fs;                     % Sample time
% % % % % % % L = length(y);                  % Length of signal
% % % % % % % NFFT = 2^nextpow2(L); % Next power of 2 from length of y
% % % % % % % Y = fft(y,NFFT)/L;
% % % % % % % f = Fs/2*linspace(0,1,NFFT/2+1);
% % % % % % % % Plot single-sided amplitude spectrum.
% % % % % % %  plot(f,2*abs(Y(1:NFFT/2+1)),'parent',handles.hFreqAxes);
% % % % % % % set(handles.hFreqAxes,'xlim',[0 100],'ylim',[0 550]);
% % % % % % %   
% % % % 
% % % % 
% % % % %
% % % % 
% % % % 
% % % % if get(handles.hRunningAverage,'value')
% % % %     if get(handles.hShowStd,'value')
% % % %         % show std
% % % %         signalToDisplay = strctRun.smartAvg.stddata;
% % % %     else
% % % %         % show mean
% % % %         signalToDisplay = strctRun.smartAvg.avgdata;
% % % %     end
% % % % else
% % % %     signalToDisplay = strctRun.smartAvg.lastdata;
% % % % end
% % % % 
% % % % 
% % % % 
% % % % if get(handles.hSubtractMean,'value') >0 && isfield(strctRun,'meanBackground')
% % % %     signalToDisplay = signalToDisplay -  strctRun.meanBackground.avgdata;
% % % % end
% % % % %%
% % % % 
% % % % if get(handles.hInverse,'value')
% % % %     signalToDisplay=-signalToDisplay;
% % % % end
% % % % 
% % % % 
% % % % minObserved = min(signalToDisplay);
% % % % maxObserved = max(signalToDisplay);
% % % % minVal = min(Frames(:));
% % % % maxVal = max(Frames(:));
% % % % set(handles.hMinValue,'String',sprintf('%.0f',minVal));
% % % % set(handles.hMaxValue,'String',sprintf('%.0f',maxVal));
% % % % if minVal < -32000
% % % %     set(handles.hMinValue,'ForegroundColor','r');
% % % % else
% % % %     set(handles.hMinValue,'ForegroundColor','k');
% % % % end
% % % % 
% % % % if maxVal > 32000
% % % %     set(handles.hMaxValue,'ForegroundColor','r');
% % % % else
% % % %     set(handles.hMaxValue,'ForegroundColor','k');
% % % % end
% % % % 
% % % % 
% % % % bStretch = get(handles.hAutoRangePMT1,'value');
% % % % minDisplay = str2num(get(handles.hDisplayMin,'String'));
% % % % maxDisplay = str2num(get(handles.hDisplayMax,'String'));
% % % % 
% % % % % Update ROIs
% % % % strctRun.ROIs = getappdata(handles.figure1,'ROIs');
% % % % if ~isempty(strctRun.ROIs) && isfield(strctRun.ROIs,'ind')
% % % %     nROIs=length(strctRun.ROIs.IDs);
% % % %     nNewFrames = size(Frames, 2);
% % % %     startUpdateInd = FramesFastDAQIndex; %1+strctRun.numFramesAcquired-size(Frames, 2);
% % % %     for frameIter=1:nNewFrames
% % % %         CurrentFrame = Frames(:,frameIter);
% % % %         % do only the first depth plane at the moment...
% % % %         depthIter=1;
% % % %         %for depthIter=1:strctRun.numPlanes
% % % %         signalInd = 1+(depthIter-1)*strctRun.numSpotsPerPlane:depthIter*strctRun.numSpotsPerPlane;
% % % %         signal = CurrentFrame(signalInd);
% % % %         for k=1:nROIs
% % % %             strctRun.ROIvalues(strctRun.ROIs.IDs(k),startUpdateInd+frameIter) =  nanmean(signal(strctRun.ROIs.ind{k}));
% % % %         end
% % % %     end
% % % %     
% % % %     % now plot ROIs?
% % % %     cla(handles.hRealTimeAxes);
% % % %     hold(handles.hRealTimeAxes,'on');
% % % %     
% % % %     if 1
% % % %     if ~isempty(strctRun.SlowChannelValues)
% % % %         stimulusOn = fnGetIntervals(strctRun.SlowChannelValues(1,:) > 2155);
% % % %         %plot(handles.hRealTimeAxes, 1:size(strctRun.SlowChannelValues,2), strctRun.SlowChannelValues(1,:),'g','LineWidth',2);
% % % %         pmtFrameTime = 1:size(strctRun.SlowChannelValues,2);
% % % %         for j=1:length(stimulusOn)
% % % %             rectangle('position',[pmtFrameTime(stimulusOn(j).m_iStart),-strctRun.DAQvoltageRange*1000, ...
% % % %                 pmtFrameTime(stimulusOn(j).m_iEnd)-pmtFrameTime(stimulusOn(j).m_iStart),2*1000*strctRun.DAQvoltageRange],'facecolor',[0.8 0.8 0.8],'parent',handles.hRealTimeAxes);
% % % %             %text(pmtFrameTime(stimulusOn(j).m_iStart),2000,sprintf('%d',1+mod(j-1,8)),'parent',handles.hRealTimeAxes);
% % % %         end
% % % %     end
% % % %     
% % % %     for k=1:nROIs
% % % %         idx = find(strctRun.ROIvalues(strctRun.ROIs.IDs(k),:) ~= 0,1,'first');
% % % %         x = idx:strctRun.numFramesAcquired;
% % % %         y = strctRun.ROIvalues(strctRun.ROIs.IDs(k), x);
% % % %         if length(y) > 12 && get(handles.hROIbandpassFilt,'value')>0
% % % %             yfilt= filtfilt(strctRun.realTimeFiltering.b,strctRun.realTimeFiltering.a,y);
% % % %         else
% % % %             yfilt = y;
% % % %         end
% % % %         
% % % % %         v=y-nanmedian(y);
% % % %             yfilt_mV = (yfilt) / (65535/2) * strctRun.DAQvoltageRange *1000;
% % % %             meanROI = mean(yfilt_mV);
% % % %             stdROI = std(yfilt_mV);
% % % %             
% % % %         plot(handles.hRealTimeAxes,x,yfilt_mV,'color',strctRun.ROIs.colors(k,:));
% % % %         text(strctRun.startROIdisplay+1,meanROI,sprintf('%.3f +- %.3f',meanROI,stdROI),'parent',handles.hRealTimeAxes);
% % % %     end
% % % %         for j=1:length(stimulusOn)
% % % %         text(pmtFrameTime(stimulusOn(j).m_iStart),-15,sprintf('%d',1+mod(j-1,8)),'parent',handles.hRealTimeAxes,'color','r','fontweight','bold');
% % % %         text(pmtFrameTime(stimulusOn(j).m_iStart),-0,sprintf('%d',1+mod(j-1,8)),'parent',handles.hRealTimeAxes,'color','r','fontweight','bold');
% % % %     end    
% % % % 
% % % %     else
% % % %        
% % % %         idx = find(strctRun.ROIvalues(strctRun.ROIs.IDs(1),:) ~= 0,1,'first');
% % % %         x = idx:strctRun.numFramesAcquired;
% % % %         y1 = strctRun.ROIvalues(strctRun.ROIs.IDs(1), x);
% % % %         y2 = strctRun.ROIvalues(strctRun.ROIs.IDs(2), x);
% % % %         plot(handles.hRealTimeAxes,x, abs(y2-y1)./abs(y2));
% % % %     end
% % % %         
% % % %     
% % % %     
% % % %     resetROI = getappdata(handles.figure1,'resetROI');
% % % %     if resetROI
% % % %         strctRun.ROIvalues(:,1:strctRun.numFramesAcquired)=0;
% % % %         strctRun.startROIdisplay = strctRun.numFramesAcquired;
% % % %         setappdata(handles.figure1,'resetROI',false);
% % % %     end
% % % %     
% % % %     set(handles.hRealTimeAxes,'xlim',[strctRun.startROIdisplay 1+strctRun.numFramesAcquired]);
% % % % end
% % % % 
% % % % 
% % % % % Now update display with last frame/avg signal (?)
% % % % for depthIter=1:strctRun.numPlanes
% % % %     signalInd = 1+(depthIter-1)*strctRun.numSpotsPerPlane:depthIter*strctRun.numSpotsPerPlane;
% % % %     
% % % %   
% % % %     Z = ones(size(roi.Mask));
% % % %     Z(roi.selectedSpots)=signalToDisplay(signalInd);
% % % %     I=FastUpSampling(Z,roi.offsetX,roi.offsetY, roi.subsampling,roi.subsampling);
% % % %     
% % % %     
% % % %     if get(handles.hIntensityNormalization,'value')
% % % %         I = I + strctRun.intensityNormalization(:,:,depthIter);
% % % %             if (bStretch)
% % % %                  minObserved = min(I(:));
% % % %                  maxObserved = max(I(:));
% % % %             end
% % % %     end
% % % %     
% % % %     if get(handles.hSpatialSmoothingPMT1,'value')
% % % %         gaussianWidth = 1;
% % % %         kernel1D = fspecial('gaussian',[10*gaussianWidth 1],gaussianWidth);
% % % %         I=convn(convn(double(I),kernel1D,'same'),kernel1D','same');
% % % %     end
% % % %     
% % % %     rng= [minDisplay maxDisplay];    
% % % %     UnderExposure = I < -32000;
% % % %     OverExposure = I > 32000;
% % % %     
% % % %     if (bStretch)
% % % %         Inorm = (I - minObserved) / (maxObserved+1-minObserved);
% % % %     else
% % % %         Inorm = (I - min(rng)) / (maxDisplay-minDisplay );
% % % %     end
% % % %     Inorm(Inorm > 1)=1;
% % % %     Inorm(Inorm<0)=0;
% % % %     
% % % %     planeR = Inorm;
% % % %     planeG = Inorm;
% % % %     planeB = Inorm;
% % % %     
% % % %         
% % % %     planeR(UnderExposure) = 0;
% % % %     planeG(UnderExposure) = 0;
% % % %     planeB(UnderExposure) = 1;
% % % % 
% % % %     planeR(OverExposure) = 1;
% % % %     planeG(OverExposure) = 0;
% % % %     planeB(OverExposure) = 0;    
% % % %     planeR(~roi.InnerDisk) = 0;
% % % %     planeG(~roi.InnerDisk) = 0;
% % % %     planeB(~roi.InnerDisk) = 0;
% % % %     
% % % %     Irgb = cat(3,planeR,planeG,planeB);
% % % %     set(handles.hImages(depthIter),'cdata',Irgb);
% % % % %  
% % % % %     if (bStretch)
% % % % %         set(handles.axes(depthIter),'clim',[minObserved maxObserved+1]);
% % % % %     else
% % % % %         set(handles.axes(depthIter),'clim', [min(rng), max(rng)+1]);
% % % % %     end
% % % % end
% % % % 
% % % % % Try to update video feed ?
% % % % UseCamera = get(handles.hRecordCamera,'value');
% % % % if UseCamera
% % % %     [I, index]=PTwrapper('PokeLastImageTuple',1);
% % % %     if ~isempty(I)
% % % %         set(handles.hImages(end),'cdata',I);
% % % %     end
% % % % end
% % % % 
% % % % drawnow
% % % % return;


function clearROI(obj,event, handles)
C = get (handles.hRealTimeAxes, 'CurrentPoint');
xlim=get(handles.hRealTimeAxes,'xlim');
ylim=get(handles.hRealTimeAxes,'ylim');

if strcmp(obj.SelectionType,'alt') && C(1,1) >= xlim(1) && C(1,1) <= xlim(2) && C(1,2) >=ylim(1) && C(1,2) <= ylim(2)
    setappdata(handles.figure1,'resetROI',true);
end


% --- Executes on button press in hTriggerStimulusMachine.
function hTriggerStimulusMachine_Callback(hObject, eventdata, handles)
% hObject    handle to hTriggerStimulusMachine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hTriggerStimulusMachine


% --- Executes on button press in hRescanDisk.
function hRescanDisk_Callback(hObject, eventdata, handles)
id=SessionWrapper('GetSessionID');
  sessionList = SessionWrapper('ListSessions');
  ReloadCalibration(hObject,handles,sessionList,length(sessionList))


% --- Executes on button press in hPartialFOV.
function hPartialFOV_Callback(hObject, eventdata, handles)
if all(handles.roi.boundingbox == [1 1 2*handles.roi.radius+1 2*handles.roi.radius+1])
    set(handles.axes(1),'clim',[0 1]);
    selectBox(handles.figure1,handles.axes(1));
else
handles.roi.boundingbox = [1 1 2*handles.roi.radius+1 2*handles.roi.radius+1]; % full FOV
handles.roi=recomputeROI(handles.roi, length(handles.usedDepthIndices));
set(handles.axes(1),'clim',[0 1]);
end
guidata(hObject,handles);

 plotROI(handles);
setMaxFrameRate(hObject,handles)




% --- Executes on button press in hRepeatScan.
function hRepeatScan_Callback(hObject, eventdata, handles)
% hObject    handle to hRepeatScan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.StartLiveView,'String','Abort');
GenerateAndUploadSequence(hObject,handles,true);


% --- Executes on button press in ROIbutton.
function ROIbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ROIbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ROIbutton


% --- Executes on button press in ContrastButton.
function ContrastButton_Callback(hObject, eventdata, handles)
% hObject    handle to ContrastButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ContrastButton



function hOverSamplingEdit_Callback(hObject, eventdata, handles)
overSampling = str2num(get(handles.hOverSamplingEdit,'String'));
[Res] = OverClockWrapper(overSampling);

% --- Executes during object creation, after setting all properties.
function hOverSamplingEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hOverSamplingEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
%[handles.axes,handles.hImages] = CreateDrawAxes(handles, length(handles.usedDepthIndices));
v=get(handles.slider1,'max')-get(handles.slider1,'value');
for k=1:length(handles.axes)
    P=get(handles.axes(k),'Position');
    P(2) =  v-(k-1);
    set(handles.axes(k),'Position',P);
end


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in hCompactView.
function hCompactView_Callback(hObject, eventdata, handles)

if isfield(handles,'strctRun') && strcmpi(handles.strctRun.timer.Running,'on')
    updateAxesPosition(handles);
else
    [handles.axes,handles.hImages] = CreateDrawAxes(handles, length(handles.usedDepthIndices));
    plotROI(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in hFullScreenView.
function hFullScreenView_Callback(hObject, eventdata, handles)

if isfield(handles,'strctRun') && strcmpi(handles.strctRun.timer.Running,'on')
    updateAxesPosition(handles);
else
    [handles.axes,handles.hImages] = CreateDrawAxes(handles, length(handles.usedDepthIndices));
    plotROI(handles);
    guidata(hObject, handles);
end

% 
% function hCameraGainEdit_Callback(hObject, eventdata, handles)
% gain=str2num(get(handles.hCameraGainEdit,'String'));
% set(handles.hCameraGainSlider,'Value',gain);
% PTwrapper('SetGain', gain);
% 
% % --- Executes during object creation, after setting all properties.
% function hCameraGainEdit_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to hCameraGainEdit (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end


% --- Executes on slider movement.
function slider2_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% 
% function hCameraExposureEdit_Callback(hObject, eventdata, handles)
% expo=str2num(get(handles.hCameraExposureEdit,'String'));
% set(handles.hCameraExposureSlider,'Value',expo);
% PTwrapper('SetExposure', 1.0/expo);
% fprintf('Setting Exposure to 1/%d\n',round(expo));

% % --- Executes during object creation, after setting all properties.
% function hCameraExposureEdit_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to hCameraExposureEdit (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end

% 
% % --- Executes on slider movement.
% function hCameraExposureSlider_Callback(hObject, eventdata, handles)
% SliderValue = get(handles.hCameraExposureSlider,'Value');
% expo=1.0/SliderValue;
% set(handles.hCameraExposureEdit,'String',num2str(SliderValue));
% PTwrapper('SetExposure', expo);

% 
% % --- Executes during object creation, after setting all properties.
% function hCameraExposureSlider_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to hCameraExposureSlider (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: slider controls usually have a light gray background.
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[.9 .9 .9]);
% end
% 
% 
% % --- Executes on slider movement.
% function hCameraGainSlider_Callback(hObject, eventdata, handles)
% SliderValue = get(handles.hCameraGainSlider,'Value');
% set(handles.hCameraGainEdit,'String',num2str(SliderValue));
% PTwrapper('SetGain',SliderValue);
% 
% % --- Executes during object creation, after setting all properties.
% function hCameraGainSlider_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to hCameraGainSlider (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: slider controls usually have a light gray background.
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[.9 .9 .9]);
% end
% 
% 
% function CameraTimerCallback(tm, b)
% handles = tm.UserData;
% PTwrapper('SoftwareTrigger');
% X=PTwrapper('GetImageBuffer');
% if ~isempty(X)
%     X(1,1,end) = 0;
%     X(1,2,end) = 4095;
%     set(handles.hImages(end),'cdata',X(:,:,end));
%     set(handles.axes(end),'Clim',[0 4095]);
% end
% 
% function hRecordCamera_Callback(hObject, eventdata, handles)
% [handles.axes,handles.hImages] = CreateDrawAxes(handles, length(handles.usedDepthIndices));
% plotROI(handles);
% guidata(hObject, handles);
% 
% 
% 
% function hCameraRateEdit_Callback(hObject, eventdata, handles)
% Value = str2num(get(handles.hCameraRateEdit,'String'));
% set(handles.hCameraRateSlider,'value',Value);
% 
% % --- Executes during object creation, after setting all properties.
% function hCameraRateEdit_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to hCameraRateEdit (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% 
% 
% % --- Executes on slider movement.
% function hCameraRateSlider_Callback(hObject, eventdata, handles)
% Value = get(handles.hCameraRateSlider,'value');
% set(handles.hCameraRateEdit,'String',num2str(Value));
% 
% % --- Executes during object creation, after setting all properties.
% function hCameraRateSlider_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to hCameraRateSlider (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: slider controls usually have a light gray background.
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[.9 .9 .9]);
% end
% 



function CloseROIModule(src,evnt,handles)

selection = questdlg('Close ROI Module?',...
    'Close Request Function',...
    'Yes','No','Yes');
switch selection,
    case 'Yes',
        myhandles = guidata(gcbo);
        AbortRun(myhandles);
%         if isfield(myhandles,'cameraTimer') && strcmp(myhandles.cameraTimer.Running,'on')
%             stop(myhandles.cameraTimer);
%             Dummy=PTwrapper('GetImageBuffer');
%         end
%         
%  
%         if PMTwrapper('IsInitialized')
%             PMTwrapper('Release');
%         end
       
        
%         if ALPwrapper('IsInitialized')
%             ALPwrapper('Release');
%         end
        delete(myhandles.figure1)
    case 'No'
        return
end


function updateAxesPosition(handles)
NumPlots = length(handles.axes);
n = ceil(sqrt(NumPlots));
m = ceil(NumPlots/n);
compactView = get(handles.hCompactView,'value');

if NumPlots == 1 || compactView
    set(handles.slider1,'visible','off');
else
    set(handles.slider1,'visible','on');
    set(handles.slider1,'min',0,'max',NumPlots-1,'value',NumPlots-1);
end

positions = tight_subplot_positions(n, m, 0.05, 0.05, 0.01);

if ~compactView
    for k=1:length(handles.axes)
       set( handles.axes(k),'Position',[0.01 0.05+(k-1) 0.9 0.9]);
    end
else
    for k=1:length(handles.axes)
        set(handles.axes(k),'Position',positions(k,:));
    end
end



% % --- Executes on button press in hPMTautomation.
% function hPMTautomation_Callback(hObject, eventdata, handles)


% --- Executes on slider movement.
function hPMTslider_Callback(hObject, eventdata, handles)
value = round(get(handles.hPMTslider,'value'));
set(handles.hPMTslider,'value',value);
set(handles.hPMTgainEdit,'String',num2str(value));

if ~PMTwrapper('IsInitialized')
    PMTwrapper('Init');
end
PMTwrapper('RampGain',value);

% --- Executes during object creation, after setting all properties.
function hPMTslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hPMTslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function hPMTgainEdit_Callback(hObject, eventdata, handles)
value = min(750,max(0,str2num(get(handles.hPMTgainEdit,'String'))));
set(handles.hPMTgainEdit,'String',num2str(value));
set(handles.hPMTslider,'value', value);

if ~PMTwrapper('IsInitialized')
    PMTwrapper('Init');
end
PMTwrapper('RampGain',value);

% --- Executes during object creation, after setting all properties.
function hPMTgainEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hPMTgainEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hShowStd.
function hShowStd_Callback(hObject, eventdata, handles)
% hObject    handle to hShowStd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hShowStd


% --- Executes on button press in hROIbandpassFilt.
function hROIbandpassFilt_Callback(hObject, eventdata, handles)
% hObject    handle to hROIbandpassFilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hROIbandpassFilt
% 
% 
% % --- Executes on selection change in hNormalizationScanPopup.
% function hNormalizationScanPopup_Callback(hObject, eventdata, handles)
% % hObject    handle to hNormalizationScanPopup (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: contents = cellstr(get(hObject,'String')) returns hNormalizationScanPopup contents as cell array
% %        contents{get(hObject,'Value')} returns selected item from hNormalizationScanPopup
% 
% 
% % --- Executes during object creation, after setting all properties.
% function hNormalizationScanPopup_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to hNormalizationScanPopup (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: popupmenu controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end


% --- Executes on button press in hResetAveragePMT1.
function hResetAveragePMT1_Callback(hObject, eventdata, handles)
set(handles.hResetAveragePMT1,'FontWeight','bold');


% --- Executes on button press in SubsampleX3.
function SubsampleX3_Callback(hObject, eventdata, handles)
% hObject    handle to SubsampleX3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SubsampleX3


% --- Executes on selection change in hVoltageRangeFastDAQ.
function hVoltageRangeFastDAQ_Callback(hObject, eventdata, handles)
% hObject    handle to hVoltageRangeFastDAQ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
d=1;
% Hints: contents = cellstr(get(hObject,'String')) returns hVoltageRangeFastDAQ contents as cell array
%        contents{get(hObject,'Value')} returns selected item from hVoltageRangeFastDAQ


% --- Executes during object creation, after setting all properties.
function hVoltageRangeFastDAQ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hVoltageRangeFastDAQ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function RunTimerCallback(timr,b)
global g_scanID g_debug
% this function is called every X ms to update things on screen
% while the DAQ and DMD are working.
% it also checks whether sequence has completed, and starts the next one.
if isempty(g_debug)
    g_debug = 1;
end

UserData = timr.UserData;
strctRun = UserData{1};
handles = UserData{2};
    


switch strctRun.state
    case 1
        % start the main sweep sequence.
        
        res=fnDAQusb('StopContinuousAcqusition',strctRun.USB2020_ID);
        res=fnDAQusb('StopContinuousAcqusition',strctRun.USB1608_ID);
        
        res=fnDAQusb('ResetCounters',strctRun.USB1608_ID);
        
        res=fnDAQusb('AllocateFrames', ...
            strctRun.USB2020_ID,  ...
            strctRun.numChannels, ...
            strctRun.numPlanes,...
            strctRun.numSpotsPerPlane,...
            strctRun.fastDAQoverSampling, ...
            strctRun.numFrames,...
            strctRun.USB2020_PACKET_SIZE);
        
    res=fnDAQusb('AllocateFrames', ...
            strctRun.USB1608_ID,  ...
            strctRun.numSlowChannels, ...
            strctRun.numPlanes,...
            strctRun.numSpotsPerPlane,...
            1, ...
            strctRun.numFrames,...
            strctRun.USB1608_PACKET_SIZE); %//strctRun.slowDAQnumSamplesPerChannel);
        
        
     
        
        vRange = getVoltageRange(handles);
        strctRun.DAQvoltageRange = vRange;
        res=fnDAQusb('StartContinuousAcqusitionExtClock',...
            strctRun.USB2020_ID,...
            strctRun.fastDAQchannels(1),...
            strctRun.fastDAQchannels(2),vRange,0); % no bipolar :(
        
        res=fnDAQusb('StartContinuousAcqusitionExtClock',...
            strctRun.USB1608_ID,...
            strctRun.slowDAQchannels(1),strctRun.slowDAQchannels(2),1,0); % not bipolar, 1V
        
        res=ALPwrapper('PlayUploadedSequence',handles.ALPid,strctRun.sweepsequenceID, strctRun.roi.selectedRate * strctRun.numSpots, strctRun.roi.numFrames);
        strctRun.state = 2;
         
        
        if get(handles.hTriggerStimulusMachine,'value')
            try
                StimulusClient('Run');
            catch
            end
        end
        figure(handles.figure1);
    case 2
        
        % chekc whether the main sweep sequence is done
            if ALPwrapper('HasSequenceCompleted',handles.ALPid)
                if get(handles.hLoop,'value')
                    strctRun.state = 1;
                    strctRun.prevRunsNumFrames = strctRun.prevRunsNumFrames + fnDAQusb('GetNumFramesAcquiried',strctRun.USB2020_ID);
                else
                    
                    strctRun.state = 3;
                    fprintf('Now playing the missing samples sequence to match USB packet size\n');
                    if (strctRun.missingDMDflips > 0)
                        res=ALPwrapper('PlayUploadedSequence',handles.ALPid,strctRun.lastID, strctRun.roi.selectedRate * strctRun.roi.numSpots, strctRun.missingDMDflips);
                    end
                end
            else
                try
                 strctRun=handleRealTimeDataVisualization(strctRun,handles);
                catch
                    fprintf('Crashed on handleRealTimeDataVisualization\n');
                    dbg = 1;
                end
            end
            
          if get(handles.SaveToDisk,'value') == 0
              if GetSecs()-strctRun.warningTimer > 1
                set(handles.hNotSaveWarning,'visible','off');
                strctRun.warningTimer=GetSecs();
              else 
                   set(handles.hNotSaveWarning,'visible','on');
              end
          end
          
    case 3
         if ALPwrapper('HasSequenceCompleted',handles.ALPid)
           
             strctRun.state = 0;
             stop(timr);
             
%              if get(handles.hPMTautomation,'value')
%                  %PMTwrapper('setGain',0);
%                  PMTwrapper('pmtoff');
%              end
%              
        strctRun.numFramesAcquired =  fnDAQusb('GetNumFramesAcquiried',strctRun.USB2020_ID);
        strctRun.fastDAQsamplesCollected = fnDAQusb('GetNumSamplesAcquiried',strctRun.USB2020_ID);
        strctRun.slowDAQsamplesCollected = fnDAQusb('GetNumSamplesAcquiried',strctRun.USB1608_ID);
        [strctRun.flipCounter1,strctRun.flipCounter2] = fnDAQusb('ReadCounters',strctRun.USB1608_ID);
        
        strStatus=sprintf('%d/%d DMD TRIG, %d/%d EXT CLK. Collected %d/%d frames (%.2f%%), [FAST_DAQ: %d/%d (%.2f%%), SLOW_DAQ: %d/%d (%.2f%%)]\n',...
            strctRun.flipCounter1,strctRun.desiredFlips+strctRun.missingDMDflips,...
             strctRun.flipCounter2,strctRun.fastDAQoverSampling*(strctRun.desiredFlips+strctRun.missingDMDflips),...
    strctRun.numFramesAcquired,strctRun.numFrames,strctRun.numFramesAcquired/strctRun.numFrames*100,...
             strctRun.fastDAQsamplesCollected,strctRun.fastDAQnumSamples,strctRun.fastDAQsamplesCollected/strctRun.fastDAQnumSamples*100,...
             strctRun.slowDAQsamplesCollected, strctRun.slowDAQnumSamples,strctRun.slowDAQsamplesCollected/strctRun.slowDAQnumSamples*100);
             fprintf('%s',strStatus);
            
            set(handles.StatusText,'String',strStatus);

            
            if (strctRun.fastDAQnumSamples ==strctRun.fastDAQsamplesCollected && ...
                            strctRun.slowDAQnumSamples ==strctRun.slowDAQsamplesCollected)
                        fprintf('Sequence completed successfuly (all samples collected)!\n');
                        strctRun.valuesFast=fnDAQusb('GetBuffer',strctRun.USB2020_ID);
                        strctRun.valuesSlow=fnDAQusb('GetBuffer',strctRun.USB1608_ID); %SLOW_DAQ_ID);
                        fnDAQusb('StopContinuousAcqusition',strctRun.USB2020_ID);
                        fnDAQusb('StopContinuousAcqusition',strctRun.USB1608_ID);
             elseif (strctRun.fastDAQnumSamples ==strctRun.fastDAQsamplesCollected) && (  strctRun.slowDAQnumSamples ==strctRun.slowDAQsamplesCollected + 256)
                 fprintf('Sequence completed semi-successfuly (slow DAQ missed one trigger. All is well...)!\n');
                 % sometimes slow DAQ misses one trigger (probably the
                 % first... This leads to missing 31 values (slow DAQ packet
                 % size)
                  strctRun.valuesFast=fnDAQusb('GetBuffer',strctRun.USB2020_ID);
                  fnDAQusb('StopContinuousAcqusition',strctRun.USB2020_ID);
                  
                  res=ALPwrapper('PlayUploadedSequence',handles.ALPid,strctRun.lastID, strctRun.roi.selectedRate * strctRun.roi.numSpots, 1);
                  strctRun.valuesSlow=fnDAQusb('GetBuffer',strctRun.USB1608_ID);
                  fnDAQusb('StopContinuousAcqusition',strctRun.USB1608_ID);
                     
             else
                    fprintf('ERROR!!!! number of samples mismatch (user aborted?)!\n');
            end
            
                %
%                 UseCamera = get(handles.hRecordCamera,'value');
%                 if UseCamera
%                     numVideoFrames = PTwrapper('GetBufferSize');
%                     fprintf('%d Camera frames captured!\n',numVideoFrames);
%                     strctRun.cameraVideo = PTwrapper('GetImageBuffer');
%                     CameraTriggerWrapper(1); % make sure camera doesn't skip...
%                     handles.cameraTimer.UserData = handles;
%                     start(handles.cameraTimer );
%                     
%                 end
        
                if get(handles.SaveToDisk,'value') > 0
                    
                    
                    hdf5File = SessionWrapper('GetSession');
                    fprintf('Dumping scan %d to %s...\n',g_scanID,hdf5File);
                    dumpStructureToScan(strctRun);
                end
                fprintf('Done!\n');
           
            
             fnDAQusb('Release');
               
            set(handles.StartLiveView,'String','Start');
            % Dump raw data to disk
            sessionID = SessionWrapper('GetSessionID');
            set(handles.figure1,'name', sprintf('ROI Module: Finished Session %d, scan %d',sessionID, g_scanID));
            set(handles.hNotSaveWarning,'visible','off');
            
            
            h5file= SessionWrapper('GetSession');
            sessionInfo = h5info(h5file);
            nScans = length(sessionInfo.Groups(2).Groups);
            scanNames = cell(1,nScans);
            for k=1:nScans
                scanNames{k}=num2str(k);
            end
%             set(handles.hNormalizationScanPopup,'String',scanNames);
%             
            
         end
         
        
            
end

timr.UserData = {strctRun, handles};
return;


% --- Executes on button press in hSpatialHPFCheckBox.
function hSpatialHPFCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to hSpatialHPFCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hSpatialHPFCheckBox



function hSpatialHPFedit_Callback(hObject, eventdata, handles)
% hObject    handle to hSpatialHPFedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hSpatialHPFedit as text
%        str2double(get(hObject,'String')) returns contents of hSpatialHPFedit as a double


% --- Executes during object creation, after setting all properties.
function hSpatialHPFedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hSpatialHPFedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hFFT.
function hFFT_Callback(hObject, eventdata, handles)
% hObject    handle to hFFT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hFFT


% --- Executes on button press in hSaveMeanPMT1.
function hSaveMeanPMT1_Callback(hObject, eventdata, handles)
set(handles.hSaveMeanPMT1,'FontWeight','bold');


% --- Executes on button press in hSubtractMean.
function hSubtractMean_Callback(hObject, eventdata, handles)
% hObject    handle to hSubtractMean (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hSubtractMean

% % --- Executes on button press in hInverse.
% function hInverse_Callback(hObject, eventdata, handles)
% a=get(handles.pmt1curveControlLow,'ydata');
% b=get(handles.pmt1curveControlHigh,'ydata');
% 
% set(handles.pmt1curveControlLow,'ydata',1-a);
% set(handles.pmt1curveControlHigh,'ydata',1-b);
% 
% 
% a=get(handles.pmt2curveControlLow,'ydata');
% b=get(handles.pmt2curveControlHigh,'ydata');
% 
% set(handles.pmt2curveControlLow,'ydata',1-a);
% set(handles.pmt2curveControlHigh,'ydata',1-b);

function updateHistogramDisplay(handles)

showPMT1 = get(handles.hVisPMT1,'value') > 0  && strcmp(get(handles.hVisPMT1,'enable'),'on');
showPMT2 = get(handles.hVisPMT2,'value') > 0  && strcmp(get(handles.hVisPMT2,'enable'),'on');
if (showPMT1)
    set(handles.pmt1hist,'visible','on');
    set(handles.pmt1curve,'visible','on');
    set(handles.pmt1curveControlLow,'visible','on');
    set(handles.pmt1curveControlHigh,'visible','on');
else
    set(handles.pmt1hist,'visible','off');
    set(handles.pmt1curve,'visible','off');  
    set(handles.pmt1curveControlLow,'visible','off');
    set(handles.pmt1curveControlHigh,'visible','off');
end

if (showPMT2)
    set(handles.pmt2hist,'visible','on');  
    set(handles.pmt2curve,'visible','on');
    set(handles.pmt2curveControlLow,'visible','on');
    set(handles.pmt2curveControlHigh,'visible','on');
else
    set(handles.pmt2hist,'visible','off');  
    set(handles.pmt2curve,'visible','off');
    set(handles.pmt2curveControlLow,'visible','off');    
    set(handles.pmt2curveControlHigh,'visible','off');
end    
% 

% --- Executes on button press in hPMT2.
function hPMT2_Callback(hObject, eventdata, handles)
pmtState = get(handles.hPMT2,'value');
if (pmtState)
    set(handles.hVisPMT2,'enable', 'on');
 else
    set(handles.hVisPMT2,'enable', 'off');
end
updateHistogramDisplay(handles)

% --- Executes on button press in hPMT1.
function hPMT1_Callback(hObject, eventdata, handles)
pmtState = get(handles.hPMT1,'value');

if (pmtState)
    set(handles.hVisPMT1,'enable', 'on');
else
    set(handles.hVisPMT1,'enable', 'off');
end
updateHistogramDisplay(handles)


% --- Executes when selected object is changed in PMtVisGroup.
function PMtVisGroup_SelectionChangedFcn(hObject, eventdata, handles)

updateHistogramDisplay(handles);


% --- Executes on button press in hVisPMT1.
function hVisPMT1_Callback(hObject, eventdata, handles)
updateHistogramDisplay(handles);


% --- Executes on button press in hVisPMT2.
function hVisPMT2_Callback(hObject, eventdata, handles)
updateHistogramDisplay(handles);


% --- Executes on button press in hSpatialSmoothingPMT2.
function hSpatialSmoothingPMT2_Callback(hObject, eventdata, handles)
% hObject    handle to hSpatialSmoothingPMT2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hSpatialSmoothingPMT2


% --- Executes on button press in checkbox27.
function checkbox27_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox27


% --- Executes on button press in checkbox28.
function checkbox28_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox28


% --- Executes on button press in hPMT1MeanSub.
function hPMT1MeanSub_Callback(hObject, eventdata, handles)
% hObject    handle to hPMT1MeanSub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hPMT1MeanSub


% --- Executes on button press in hPMT2MeanSub.
function hPMT2MeanSub_Callback(hObject, eventdata, handles)
% hObject    handle to hPMT2MeanSub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hPMT2MeanSub


function hPMT1SigAvg_Callback(hObject, eventdata, handles)
set(handles.hPMT1SigStd,'value',0);

function hPMT1SigStd_Callback(hObject, eventdata, handles)
set(handles.hPMT1SigAvg,'value',0);

function hPMT2SigAvg_Callback(hObject, eventdata, handles)
set(handles.hPMT2SigStd,'value',0);

function hPMT2SigStd_Callback(hObject, eventdata, handles)
set(handles.hPMT2SigAvg,'value',0);


% --- Executes on button press in hSaveMeanPMT2.
function hSaveMeanPMT2_Callback(hObject, eventdata, handles)
% hObject    handle to hSaveMeanPMT2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in hRunningAveragePMT1.
function hRunningAveragePMT1_Callback(hObject, eventdata, handles)
% hObject    handle to hRunningAveragePMT1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hRunningAveragePMT1


% --- Executes on button press in checkbox30.
function checkbox30_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox30



function hRunningAverageEditPMT1_Callback(hObject, eventdata, handles)
% hObject    handle to hRunningAverageEditPMT1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hRunningAverageEditPMT1 as text
%        str2double(get(hObject,'String')) returns contents of hRunningAverageEditPMT1 as a double


% --- Executes during object creation, after setting all properties.
function hRunningAverageEditPMT1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hRunningAverageEditPMT1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hRunningAveragePMT2.
function hRunningAveragePMT2_Callback(hObject, eventdata, handles)
% hObject    handle to hRunningAveragePMT2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hRunningAveragePMT2


% --- Executes on button press in hResetAveragePMT2.
function hResetAveragePMT2_Callback(hObject, eventdata, handles)
set(handles.hResetAveragePMT2,'FontWeight','bold');



function hRunningAverageEditPMT2_Callback(hObject, eventdata, handles)
% hObject    handle to hRunningAverageEditPMT2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hRunningAverageEditPMT2 as text
%        str2double(get(hObject,'String')) returns contents of hRunningAverageEditPMT2 as a double


% --- Executes during object creation, after setting all properties.
function hRunningAverageEditPMT2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hRunningAverageEditPMT2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hVisPMT1.
function checkbox32_Callback(hObject, eventdata, handles)
% hObject    handle to hVisPMT1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hVisPMT1


% --- Executes on button press in hVisPMT2.
function checkbox33_Callback(hObject, eventdata, handles)
% hObject    handle to hVisPMT2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hVisPMT2


% --- Executes on button press in hAutoRangePMT2.
function hAutoRangePMT2_Callback(hObject, eventdata, handles)
% hObject    handle to hAutoRangePMT2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hAutoRangePMT2


% --- Executes on button press in hFFT_PMT1.
function hFFT_PMT1_Callback(hObject, eventdata, handles)
if (get(hObject,'value')>0)
    if get(handles.hRunningAveragePMT1,'value') == 0
        % turn on data collection
        set(handles.hRunningAveragePMT1,'value',1);
    end
    
    if (str2num(get(handles.hRunningAverageEditPMT1,'string'))==0)
        set(handles.hRunningAverageEditPMT1,'string',10);
    end
    
end


% --- Executes on button press in hFFT_PMT2.
function hFFT_PMT2_Callback(hObject, eventdata, handles)
if (get(hObject,'value')>0)
    if get(handles.hRunningAveragePMT2,'value') == 0
        % turn on data collection
        set(handles.hRunningAveragePMT2,'value',1);
    end
 if (str2num(get(handles.hRunningAverageEditPMT2,'string'))==0)
        set(handles.hRunningAverageEditPMT2,'string',10);
    end    
end






function [strctRun, pmt1ProtectionWarning,pmt2ProtectionWarning] = UpdateDataStructures(strctRun,handles,FramesSlowDAQ,FramesSlowDAQIndex,FramesFastDAQ, FramesFastDAQIndex)
if ~isempty(FramesSlowDAQ)
    for frameIter=1:size( FramesSlowDAQ,4)
        photodiodeValues = FramesSlowDAQ(strctRun.photodiodeChannel,:,:,frameIter);
        strctRun.photoDiode(FramesSlowDAQIndex+frameIter) = mean(photodiodeValues(:));
    end
end
  %PMT1Values = reshape(FramesFastDAQ(1,:,:,:), [sz(2:end),1]);
  resetAvgPMT1 = false;
if strcmpi(get(handles.hResetAveragePMT1,'FontWeight'),'bold')
    resetAvgPMT1 = true;
    set(handles.hResetAveragePMT1,'FontWeight','normal');
end

resetAvgPMT2 = false;
if strcmpi(get(handles.hResetAveragePMT2,'FontWeight'),'bold')
    resetAvgPMT2 = true;
    set(handles.hResetAveragePMT2,'FontWeight','normal');
end

saveMeanPMT1 = false;
if strcmpi(get(handles.hSaveMeanPMT1,'FontWeight'),'bold')
    saveMeanPMT1 = true;
    set(handles.hSaveMeanPMT1,'FontWeight','normal');
end


saveMeanPMT2 = false;
if strcmpi(get(handles.hSaveMeanPMT2,'FontWeight'),'bold')
    saveMeanPMT2 = true;
    set(handles.hSaveMeanPMT2,'FontWeight','normal');
end

if saveMeanPMT1
    strctRun.smartAvgPMT1.savedMean = strctRun.smartAvgPMT1.avgdata;
    fprintf('Background saved fot PMT1\n');
end
if saveMeanPMT2
    strctRun.smartAvgPMT2.savedMean = strctRun.smartAvgPMT2.avgdata;
    fprintf('Background saved for PMT2\n');
end

newAvgFramesPMT1 = str2num(get(handles.hRunningAverageEditPMT1,'String'));
newAvgFramesPMT2 = str2num(get(handles.hRunningAverageEditPMT2,'String'));

if newAvgFramesPMT1 ~= strctRun.smartAvgPMT1.numSamplesToAverage || resetAvgPMT1
    % reset
    strctRun.smartAvgPMT1 = SmartAveraging('Init',[strctRun.numSpotsPerPlane,strctRun.numPlanes], newAvgFramesPMT1);
end
if newAvgFramesPMT2 ~= strctRun.smartAvgPMT2.numSamplesToAverage || resetAvgPMT2
    % reset
    strctRun.smartAvgPMT2 = SmartAveraging('Init',[strctRun.numSpotsPerPlane,strctRun.numPlanes], newAvgFramesPMT2);
end
pmt1ProtectionWarning = false;
pmt2ProtectionWarning = false;
 
if ~isempty(FramesFastDAQ)
    sz = size(FramesFastDAQ);
    offset=0;
    
    
    MAX_SAFE_VALUE  =0.8;
    MIN_SAFE_VALUE = -0.8;
    if strctRun.PMTused(1)
        PMT1Values = reshape(FramesFastDAQ(1,:,:,:), [sz(2:end),1]);
        
        PMT1Values_mV =((2^12/2)-PMT1Values)/(2^12/2) *  strctRun.DAQvoltageRange * 1000;
         
        pmt1ProtectionWarning = max(PMT1Values_mV) > MAX_SAFE_VALUE | min(PMT1Values_mV) < MIN_SAFE_VALUE;
        strctRun.smartAvgPMT1 = SmartAveraging('AddSamples',strctRun.smartAvgPMT1, PMT1Values_mV);
        offset=1;
    end
    
    if strctRun.PMTused(2)
        PMT2Values = reshape(FramesFastDAQ(1+offset,:,:,:), [sz(2:end),1]);
        PMT2Values_mV =((2^12/2)-PMT2Values)/(2^12/2) *  strctRun.DAQvoltageRange * 1000;
        
        strctRun.smartAvgPMT2 = SmartAveraging('AddSamples',strctRun.smartAvgPMT2, PMT2Values_mV);
        pmt2ProtectionWarning = max(PMT2Values_mV) > MAX_SAFE_VALUE | min(PMT2Values_mV) < MIN_SAFE_VALUE;
    end
end
return;



function [ImageProcessed, outputSignal] = RealTimeSignalProcessingPipeline(handles,roi,DAQvoltageRange,smartAvg, bSignalTypeMean, bRunningAverage,bSubtractMean, bSpatialSmoothing)
  if (bSignalTypeMean)
       % Anatomical
       if (bRunningAverage)
            inputSignal = smartAvg.avgdata; 
       else
           inputSignal = smartAvg.lastdata; 
       end
  else
       % Functional (Std)
        inputSignal = smartAvg.stddata; 
   end
outputSignal = inputSignal;

if bSubtractMean && isfield(smartAvg,'savedMean')
    outputSignal = inputSignal -  smartAvg.savedMean;
end

numPlanes = size(outputSignal,2);
numSpotsPerPlane = size(outputSignal,1);
ImageProcessed = zeros([size(roi.Mask),numPlanes]);
gaussianWidth = 1;
kernel1D = fspecial('gaussian',[10*gaussianWidth 1],gaussianWidth);

 if isempty(outputSignal)
     dbg = 1;
 end
for depthIter=1:numPlanes
    Z = ones(size(roi.Mask));
    Z(roi.selectedSpots)=outputSignal(:,depthIter);
    I=FastUpSampling(Z,roi.offsetX,roi.offsetY, roi.subsampling,roi.subsampling);
    
    
    if bSpatialSmoothing
        upsampled = convn(convn(I,kernel1D,'same'),kernel1D','same');
    else
        upsampled = I;
    end
    ImageProcessed(:,:,depthIter)=upsampled;
end

return;



function [minValue,maxValue]=plotChannelHistogram(handles,roi,DAQvoltageRange,chValuesmV, bAutoRange, pmtTextHandle, hHistHandle,hCurveHandle, hLow,hHigh, bWarning)
    
maxValue = max(chValuesmV(:));
minValue = min(chValuesmV(:));
meanValue = median(chValuesmV(:));
stdValue = mad(chValuesmV(:));

if (bAutoRange)
    lowStretch = meanValue - 3*stdValue;
    highStretch = meanValue + 4*stdValue;
    
    set(hCurveHandle,'xdata',[lowStretch,highStretch],'ydata',[0 1]);
    set(hLow,'xdata',lowStretch,'ydata',0);
    set(hHigh,'xdata',highStretch,'ydata',1);
    
else
    x0=get(hLow,'xdata');
    y0=get(hLow,'ydata');
    x1=get(hHigh,'xdata');
    y1=get(hHigh,'ydata');
    set(hCurveHandle,'xdata',[x0,x1],'ydata',[y0,y1]);
    
end

if bWarning
    color = [1 0 0];
else
    color = [0,0,0];
end
set(pmtTextHandle,'String',sprintf('[%d,%d]',round(minValue),round(maxValue)),'ForegroundColor',color);

maxValue50 = ceil(maxValue/50)*50;
minValue50 =  floor(minValue/50)*50;

pmtCenter = linspace(minValue50, maxValue50, 80);
pmtHist = histc(chValuesmV(:),pmtCenter);
pmtHist=pmtHist/max(pmtHist);
% pmtHist(pmtHist==0)=NaN;


set(hHistHandle, 'xdata',pmtCenter, 'ydata',pmtHist);

function Stretched = ContrastTransfer(contrastTransfer,roi,RAW)
if (contrastTransfer(1) < contrastTransfer(3))
    % 1 before 2
    Stretched = (RAW - contrastTransfer(1)) / (contrastTransfer(3)-contrastTransfer(1)) * (contrastTransfer(4)-contrastTransfer(2)) + contrastTransfer(2);
    Stretched(RAW < contrastTransfer(1)) = contrastTransfer(2);
    Stretched(RAW > contrastTransfer(3)) = contrastTransfer(4);
else
    % 2 before 1
    Stretched = (RAW - contrastTransfer(2)) / (contrastTransfer(1)-contrastTransfer(3)) * (contrastTransfer(2)-contrastTransfer(4)) + contrastTransfer(4);
    Stretched(RAW < contrastTransfer(3)) = contrastTransfer(4);
    Stretched(RAW > contrastTransfer(1)) = contrastTransfer(2);
end
Stretched(~roi.InnerDisk) = 0;

return;

function fnPlotFFT(hCurveHandle, smartAvg )
y= smartAvg.data(:);
y = y .* hanning(length(y));
Fs = 20000;  
T = 1/Fs;                     % Sample time
L = length(y);                  % Length of signal
% t = (0:L-1)*T;                % Time vector
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);
set(hCurveHandle,'xdata',f,'ydata',(2*abs(Y(1:NFFT/2+1))));

      

function strctRun=handleRealTimeDataVisualization(strctRun,handles)
% PMT Channel x Spots per plane x planes x unread frames
[FramesFastDAQ, FramesFastDAQIndex, numNewFastFrames] = fnDAQusb('GetFrames',strctRun.USB2020_ID);
[FramesSlowDAQ, FramesSlowDAQIndex, numNewSlowFrames] = fnDAQusb('GetFrames',strctRun.USB1608_ID);

[strctRun,pmt1ProtectionWarning,pmt2ProtectionWarning] = UpdateDataStructures(strctRun,handles,FramesSlowDAQ,FramesSlowDAQIndex,FramesFastDAQ, FramesFastDAQIndex);

if ~isempty(FramesFastDAQIndex)
    roi = strctRun.roi;
    if strctRun.PMTused(1)
        
        
        [PMT1ProcessedSignal, outputSignal] = RealTimeSignalProcessingPipeline(handles,roi,strctRun.DAQvoltageRange,strctRun.smartAvgPMT1,...
                get(handles.hPMT1SigAvg,'value'), get(handles.hRunningAveragePMT1,'value'),...
                get(handles.hPMT1MeanSub,'value'),get(handles.hSpatialSmoothingPMT1,'value'));
        
            if get(handles.hFFT_PMT1,'value')
                fnPlotFFT(handles.pmt1fft,strctRun.smartAvgPMT1);
                set(handles.pmt1fft,'visible','on');
            else
                set(handles.pmt1fft,'visible','off');
            end
            
            bAutoRangePMT1 = get(handles.hAutoRangePMT1,'value');
            plotChannelHistogram(handles,roi,strctRun.DAQvoltageRange,outputSignal(:),bAutoRangePMT1,handles.hPMT1MinMax,handles.pmt1hist, handles.pmt1curve,...
                    handles.pmt1curveControlLow,handles.pmt1curveControlHigh,pmt1ProtectionWarning);  
            
        
        pmt1_x0 = get(handles.pmt1curveControlLow,'xdata');
        pmt1_y0 = get(handles.pmt1curveControlLow,'ydata');
        pmt1_x1 = get(handles.pmt1curveControlHigh,'xdata');
        pmt1_y1 = get(handles.pmt1curveControlHigh,'ydata');
        contrastTransfer1 = [pmt1_x0,pmt1_y0,pmt1_x1,pmt1_y1];
        
        strctRun=updateAndPlotROIs(strctRun,handles, FramesFastDAQ,FramesFastDAQIndex);
        
    else 
        PMT1ProcessedSignal = [];
    end
   
    if strctRun.PMTused(2)
       
        [PMT2ProcessedSignal,outputSignal] = RealTimeSignalProcessingPipeline(handles,roi,strctRun.DAQvoltageRange,strctRun.smartAvgPMT2,...
                get(handles.hPMT2SigAvg,'value'), get(handles.hRunningAveragePMT2,'value'),...
                get(handles.hPMT2MeanSub,'value'),get(handles.hSpatialSmoothingPMT2,'value'));
            
            if get(handles.hFFT_PMT2,'value')
                fnPlotFFT(handles.pmt2fft,strctRun.smartAvgPMT2);
                set(handles.pmt2fft,'visible','on');
            else
                set(handles.pmt2fft,'visible','off');
            end
                bAutoRangePMT2 = get(handles.hAutoRangePMT2,'value');
                plotChannelHistogram(handles,roi,strctRun.DAQvoltageRange,outputSignal(:),bAutoRangePMT2,handles.hPMT2MinMax, handles.pmt2hist,handles.pmt2curve,...
                    handles.pmt2curveControlLow,handles.pmt2curveControlHigh,pmt2ProtectionWarning);               
          

        pmt2_x0 = get(handles.pmt2curveControlLow,'xdata');
        pmt2_y0 = get(handles.pmt2curveControlLow,'ydata');
        pmt2_x1 = get(handles.pmt2curveControlHigh,'xdata');
        pmt2_y1 = get(handles.pmt2curveControlHigh,'ydata');
        contrastTransfer2 = [pmt2_x0,pmt2_y0,pmt2_x1,pmt2_y1];
        
        
    else 
        PMT2ProcessedSignal = [];                    
    end

    
    showPMT1 = get(handles.hVisPMT1,'value') > 0 && strctRun.PMTused(1) ;
    showPMT2 = get(handles.hVisPMT2,'value') > 0 && strctRun.PMTused(2);
    showBoth = showPMT2  && showPMT1;
    Irgb = zeros(size(roi.Mask,1),size(roi.Mask,2),3);
    for plane=1:strctRun.numPlanes
        
        
        if (showBoth)
            stretch1 = ContrastTransfer(contrastTransfer1,roi,PMT1ProcessedSignal(:,:,plane));
            stretch2 = ContrastTransfer(contrastTransfer2,roi,PMT2ProcessedSignal(:,:,plane));
            Irgb(:,:,1)=stretch2;
            Irgb(:,:,2)=stretch1;
        else if (showPMT1 || showPMT2)
                if (showPMT1)
                    stretch = ContrastTransfer(contrastTransfer1,roi,PMT1ProcessedSignal(:,:,plane));
                else
                    stretch = ContrastTransfer(contrastTransfer2,roi,PMT2ProcessedSignal(:,:,plane));
                end
                Irgb(:,:,1)=stretch;
                Irgb(:,:,2)=stretch;
                Irgb(:,:,3)=stretch;
            end
        end
        
        
        set(handles.hImages(plane),'cdata',Irgb);
    end
    
    set(handles.hHistogramAxes,'ylim',[0 1]);
    
    
     t = TemperatureSensorWrapper('GetTemperature');
     
    if ~isempty(t) && ~isnan(mean(t))
        fprintf('Temp is: %.2f\n', mean(t));
        strctRun.TemperatureReading(end+1,:) =  [FramesFastDAQIndex, mean(t)];
    end
    
    PMTgain = [];
    if ~isempty(PMTgain)
        strctRun.PMTgain(end+1,:) =  [FramesFastDAQIndex, PMTgain];
    end
    [~,motorPosition] = MotorControllerWrapper('GetPositionMicronsNonBlocking');
    if ~isempty(motorPosition) && ~isempty(strctRun.prevMotorPos) && (abs(strctRun.prevMotorPos -  motorPosition)) > 10 && (abs(strctRun.prevMotorPos -  motorPosition)) < 500
        fprintf('Motor moved by %.2f - resetting average\n',(abs(strctRun.prevMotorPos -  motorPosition)));
        set(handles.hResetAveragePMT1,'FontWeight','bold');
    end
    
    strctRun.prevMotorPos = motorPosition;
     if ~isempty(motorPosition)
        set(handles.hMotorPositionText,'String', sprintf('Motor: %.4f',motorPosition));
        strctRun.motorPositionUm(end+1,:) =  [FramesFastDAQIndex, motorPosition];
     end
     strctRun.numFramesAcquired = strctRun.prevRunsNumFrames + FramesFastDAQIndex+numNewFastFrames;
end


    strctRun.fastDAQsamplesCollected = fnDAQusb('GetNumSamplesAcquiried',strctRun.USB2020_ID);
    strctRun.slowDAQsamplesCollected = fnDAQusb('GetNumSamplesAcquiried',strctRun.USB1608_ID);
    [strctRun.flipCounter1,strctRun.flipCounter2] = fnDAQusb('ReadCounters',strctRun.USB1608_ID);
    
    strStatus=sprintf('%d/%d DMD TRIG, %d/%d EXT CLK., Collected %d/%d frames (%.2f%%), [FAST_DAQ: %d/%d (%.2f%%), SLOW_DAQ: %d/%d (%.2f%%)]\n',...
        strctRun.flipCounter1,(strctRun.desiredFlips+strctRun.missingDMDflips),...
        strctRun.flipCounter2,strctRun.fastDAQoverSampling*(strctRun.desiredFlips+strctRun.missingDMDflips),...
        strctRun.numFramesAcquired,strctRun.numFrames,strctRun.numFramesAcquired/strctRun.numFrames*100,...
        strctRun.fastDAQsamplesCollected,strctRun.fastDAQnumSamples,strctRun.fastDAQsamplesCollected/strctRun.fastDAQnumSamples*100,...
        strctRun.slowDAQsamplesCollected, strctRun.slowDAQnumSamples,strctRun.slowDAQsamplesCollected/strctRun.slowDAQnumSamples*100);
    set(handles.StatusText,'String',strStatus);

try
    %                     strctRun=drawRealTimeFrames(handles,strctRun,...
    %                         FramesFastDAQ, strctRun.prevRunsNumFrames +FramesFastDAQIndex,...
    %                         FramesSlowDAQ, strctRun.prevRunsNumFrames +FramesSlowDAQIndex);
catch
    fprintf('Error. Delted object?!\n');
end


return




function strctRun=updateAndPlotROIs(strctRun,handles, Frames,FramesFastDAQIndex)
% Update ROIs
strctRun.ROIs = getappdata(handles.figure1,'ROIs');
if ~isempty(strctRun.ROIs) && isfield(strctRun.ROIs,'ind')
    % PMT Channel x Spots per plane x planes x unread frames
    nROIs=length(strctRun.ROIs.IDs);
    nNewFrames = size(Frames, 4);
    startUpdateInd = FramesFastDAQIndex; 
    selectedPMT = 1;
    selectedPlane = 1;
    for frameIter=1:nNewFrames
        signal = squeeze(Frames(selectedPMT,:,selectedPlane,frameIter));
        for k=1:nROIs
            strctRun.ROIvalues(strctRun.ROIs.IDs(k),startUpdateInd+frameIter) =  nanmean(signal(strctRun.ROIs.ind{k}));
        end
    end
    
    % now plot ROIs?
    cla(handles.hRealTimeAxes);
    hold(handles.hRealTimeAxes,'on');
    
    
    if isfield(strctRun,'photoDiode') && ~isempty(strctRun.photoDiode)
        threshold = 54000;%mean(round([min(strctRun.photoDiode), max(strctRun.photoDiode)]));
        stimulusOn = fnGetIntervals(strctRun.photoDiode > threshold);
        
        %plot(handles.hRealTimeAxes, 1:size(strctRun.SlowChannelValues,2), strctRun.SlowChannelValues(1,:),'g','LineWidth',2);
        pmtFrameTime = 1:strctRun.photoDiode;
        for j=1:length(stimulusOn)
            rectangle('position',[pmtFrameTime(stimulusOn(j).m_iStart),-strctRun.DAQvoltageRange*1000, ...
                pmtFrameTime(stimulusOn(j).m_iEnd)-pmtFrameTime(stimulusOn(j).m_iStart),2*1000*strctRun.DAQvoltageRange],'facecolor',[0.8 0.8 0.8],'parent',handles.hRealTimeAxes);
            text(pmtFrameTime(stimulusOn(j).m_iStart),-60,sprintf('%d',1+mod(j-1,8)),'parent',handles.hRealTimeAxes,'color',[1 0 0]);
        end
        
        for k=1:nROIs
            idx = find(strctRun.ROIvalues(strctRun.ROIs.IDs(k),:) ~= 0,1,'first');
         
            x = idx:min(size(strctRun.ROIvalues,2),strctRun.numFramesAcquired);
            y = strctRun.ROIvalues(strctRun.ROIs.IDs(k), x);
           
            if (get(handles.hFlipPolarity,'value'))
                y = -y;
            end
            if length(y) > 12 && get(handles.hROIbandpassFilt,'value')>0
                yfilt= filtfilt(strctRun.realTimeFiltering.b,strctRun.realTimeFiltering.a,y);
            else
                yfilt = y;
            end
            
            %         v=y-nanmedian(y);
            yfilt_mV = (yfilt) / (65535/2) * strctRun.DAQvoltageRange *1000;
            meanROI = mean(yfilt_mV);
            stdROI = std(yfilt_mV);
            
            plot(handles.hRealTimeAxes,x,yfilt_mV,'color',strctRun.ROIs.colors(k,:));
            text(strctRun.startROIdisplay+1,meanROI,sprintf('%.3f +- %.3f',meanROI,stdROI),'parent',handles.hRealTimeAxes);
        end
        
        for j=1:length(stimulusOn)
            text(pmtFrameTime(stimulusOn(j).m_iStart),-15,sprintf('%d',1+mod(j-1,8)),'parent',handles.hRealTimeAxes,'color','r','fontweight','bold');
            text(pmtFrameTime(stimulusOn(j).m_iStart),-0,sprintf('%d',1+mod(j-1,8)),'parent',handles.hRealTimeAxes,'color','r','fontweight','bold');
        end
    end
    
    
  
    resetROI = getappdata(handles.figure1,'resetROI');
    if resetROI
        strctRun.ROIvalues(:,1:strctRun.numFramesAcquired)=0;
        strctRun.startROIdisplay = strctRun.numFramesAcquired;
        setappdata(handles.figure1,'resetROI',false);
    end
    if (strctRun.numFramesAcquired > 1)
        set(handles.hRealTimeAxes,'xlim',[strctRun.startROIdisplay 1+strctRun.numFramesAcquired]);
    end
end


% --- Executes on button press in hFlipPolarity.
function hFlipPolarity_Callback(hObject, eventdata, handles)
% hObject    handle to hFlipPolarity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hFlipPolarity
