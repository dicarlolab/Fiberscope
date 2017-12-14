function varargout = XimeaEPIWrapperGUI(varargin)
% XIMEAEPIWRAPPERGUI MATLAB code for XimeaEPIWrapperGUI.fig
%      XIMEAEPIWRAPPERGUI, by itself, creates a new XIMEAEPIWRAPPERGUI or raises the existing
%      singleton*.
%
%      H = XIMEAEPIWRAPPERGUI returns the handle to a new XIMEAEPIWRAPPERGUI or the handle to
%      the existing singleton*.
%
%      XIMEAEPIWRAPPERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in XIMEAEPIWRAPPERGUI.M with the given input arguments.
%
%      XIMEAEPIWRAPPERGUI('Property','Value',...) creates a new XIMEAEPIWRAPPERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before XimeaEPIWrapperGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to XimeaEPIWrapperGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help XimeaEPIWrapperGUI

% Last Modified by GUIDE v2.5 04-Apr-2017 15:20:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @XimeaEPIWrapperGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @XimeaEPIWrapperGUI_OutputFcn, ...
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


% --- Executes just before XimeaEPIWrapperGUI is made visible.
function XimeaEPIWrapperGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to XimeaEPIWrapperGUI (see VARARGIN)

% Choose default command line output for XimeaEPIWrapperGUI
global g_status
handles.output = hObject;
g_status.running = false;

% Update handles structure
handles.timer = timer('BusyMode','Drop','ExecutionMode','fixedRate','Period',1/10);
handles.timer.StartDelay = 0;
handles.timer.UserData = handles;
handles.timer.TimerFcn = @timerRecordFunc;
axis(handles.axes1,'off'); 
set(handles.hFrameRateEdit,'string',10);
ALPwrapper('Init',0);
USB1608_ID = 0;
res= fnDAQusb('Init',USB1608_ID);
setappdata(handles.figure1,'image1', image( zeros(1024,1280,'uint16'),'parent',handles.axes1));
setappdata(handles.figure1,'image3', image( zeros(1024,1280),'parent',handles.axes3));
guidata(hObject, handles);


% UIWAIT makes XimeaEPIWrapperGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function timerRecordFunc(timerObject,A)
global g_prevPath g_lastRead g_status
handles = timerObject.UserData; 
[flipCounter1,flipCounter2] = fnDAQusb('ReadCounters',0);
USB1608_ID = 0;

if (flipCounter1 >= g_status.numFrames)
    stop(timerObject);
    set(handles.hStart,'string','Start');
    WaitSecs(1); % allow the last couple of data frames to arrive to the USB DAQ
    % stop DAQ and dump to disk...
    fnDAQusb('StopContinuousAcqusition',USB1608_ID);
    numSamples = fnDAQusb('GetNumSamplesAcquiried',USB1608_ID);
    numSamplesPerChannel = floor(numSamples/2);
    valuesSlow=fnDAQusb('GetBuffer',USB1608_ID); %SLOW_DAQ_ID);
    PhotoDiodeValues = valuesSlow(1,1:numSamplesPerChannel);
    StimulusON = fnGetIntervals( PhotoDiodeValues > 40000);
    
    
    DMDTrig = fnGetIntervals( valuesSlow(2,1:numSamplesPerChannel) > 40000);
    
    aiStimulusStartTimes = cat(1,StimulusON.m_iStart);
    aiFrameStartTimes = cat(1,DMDTrig .m_iStart);
    if (length(aiFrameStartTimes) == g_status.numFrames)
        fprintf('All Frames recorded properly\n');
    else
        fprintf('Missed some frames?!?!\n');
    end
    fprintf('Dumping data...');
    save([g_prevPath,'/daq.mat'],'StimulusON','DMDTrig','aiStimulusStartTimes','aiFrameStartTimes');
    fprintf('Done!\n');
end



if (exist(g_prevPath,'dir'))
    astrctFiles = dir([g_prevPath,'/*.tif']);
    if length(astrctFiles) >= 2
        sortedFilesNames = sort({astrctFiles.name});
        lastFileName = sortedFilesNames{end-1};
        if strcmp(g_lastRead,lastFileName) == 0
            try
                
            %strctRun.valuesSlow=squeeze(fnDAQusb('GetBuffer',strctRun.USB1608_ID));
            i=find(lastFileName=='.');
            frameNumber = str2num(lastFileName(1:i-1));
            I=imread([g_prevPath,'/',lastFileName]);
            image1=getappdata(handles.figure1,'image1');
            image3=getappdata(handles.figure1,'image3');
            set(image1,'cdata',I,'cdatamapping','scaled');
            %set(handles.axes1,'CLim',[0 1023]);
            slowDAQsamplesCollected = fnDAQusb('GetNumSamplesAcquiried',USB1608_ID);
           
            set(handles.hTitle,'string',sprintf('Frame: %d, Counter: %d/%d, DAQ: %d',frameNumber,flipCounter1,g_status.numFrames,slowDAQsamplesCollected));
            g_lastRead = sortedFilesNames{end};
            
            
            numSamples = fnDAQusb('GetNumSamplesAcquiried',USB1608_ID);
            numSamplesPerChannel = floor(numSamples/2);
            valuesSlow=fnDAQusb('GetBuffer',USB1608_ID); %SLOW_DAQ_ID);
            PhotoDiodeValues = valuesSlow(1,1:numSamplesPerChannel);
            stimulusOn = fnGetIntervals( PhotoDiodeValues > 40000);
            DMDTrig = fnGetIntervals( valuesSlow(2,1:numSamplesPerChannel) > 40000);
            
            if (PhotoDiodeValues(end) > 40000)
                g_status.posI = (g_status.posN*g_status.posI + double(I))/(g_status.posN+1);
                g_status.posN=g_status.posN+1;
            else
                g_status.negI = (g_status.negN*g_status.negI + double(I))/(g_status.negN+1);
                g_status.negN = g_status.negN + 1;
            end
             set(image3,'cdata', g_status.posI-g_status.negI,'cdatamapping','scaled');
             
            cla(handles.axes2);
              for j=1:length(stimulusOn)
                rectangle('position',[stimulusOn(j).m_iStart,0, ...
                stimulusOn(j).m_iEnd-stimulusOn(j).m_iStart,1023],'facecolor',[0.8 0.8 0.8],'parent',handles.axes2);
                %text(pmtFrameTime(stimulusOn(j).m_iStart),-60,sprintf('%d',1+mod(j-1,8)),'parent',handles.hRealTimeAxes,'color',[1 0 0]);
            end
            catch
                dbg = 1;
            end
        end
    end
    
end

% --- Outputs from this function are returned to the command line.
function varargout = XimeaEPIWrapperGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in hStart.
function hStart_Callback(hObject, eventdata, handles)
% hObject    handle to hStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global g_status
USB1608_ID= 0;
if strcmpi(get(hObject,'string'),'Start')
    set(hObject,'string','Abort')
    strctParams=StimulusClient('GetParams');figure(handles.figure1);
    estTimeSec = OrientationScanScript('EstimatedTime', strctParams);
    
    rate = str2num(get(handles.hFrameRateEdit,'string'));
    % Setup DAQ
    
    fnDAQusb('StopContinuousAcqusition',USB1608_ID);
    fnDAQusb('ResetCounters',USB1608_ID);
    
    slowDAQrateHz = 1000;
    slowDAQnumSamplesPerChannel = slowDAQrateHz*(estTimeSec+10);
    USB1608_BUF = 256;
    slowDAQnumSamplesPerChannel = ceil(slowDAQnumSamplesPerChannel/USB1608_BUF)*USB1608_BUF;
    res=fnDAQusb('Allocate',USB1608_ID, 2, slowDAQnumSamplesPerChannel, 1, 1, slowDAQnumSamplesPerChannel);
    res=res&fnDAQusb('StartContinuousAcqusitionFixedRateTrigger',USB1608_ID,slowDAQrateHz, 5,false ); 
    if (res)
        fprintf('DAQ is now waiting for trigger\n');
    end
    % Setup Stimulus
    StimulusClient('Init');
    WaitSecs(1);
    StimulusClient('Run');
    sweepsequenceID=ALPwrapper('UploadPatternSequence',0,zeros(768,1024)>0);
    res=ALPwrapper('PlayUploadedSequence',0,sweepsequenceID, rate, ceil(rate*estTimeSec));
    g_status.running = true;
    g_status.numFrames = ceil(rate*estTimeSec);
    g_status.posN = 0;
    g_status.negN = 0;
    g_status.posI = zeros(1024,1280);
    g_status.negI = zeros(1024,1280);
    cla(handles.axes2);
    stop(handles.timer );
    start(handles.timer );
else
    set(hObject,'string','Start')
     fnDAQusb('StopContinuousAcqusition',USB1608_ID);
    fnDAQusb('ResetCounters',USB1608_ID);
    ALPwrapper('StopSequence',0);
    StimulusClient('Abort');
    g_status.running = false;
end

% --- Executes on button press in hSetFolder.
function hSetFolder_Callback(hObject, eventdata, handles)
global g_prevPath

tmp = uigetdir(g_prevPath);
if tmp(1) ~= 0
    g_prevPath = tmp;
else
    return;
end




function hFrameRateEdit_Callback(hObject, eventdata, handles)
% hObject    handle to hFrameRateEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hFrameRateEdit as text
%        str2double(get(hObject,'String')) returns contents of hFrameRateEdit as a double


% --- Executes during object creation, after setting all properties.
function hFrameRateEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hFrameRateEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
