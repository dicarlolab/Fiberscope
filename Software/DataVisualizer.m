function varargout = DataVisualizer(varargin)
% DATAVISUALIZER MATLAB code for DataVisualizer.fig
%      DATAVISUALIZER, by itself, creates a new DATAVISUALIZER or raises the existing
%      singleton*.
%
%      H = DATAVISUALIZER returns the handle to a new DATAVISUALIZER or the handle to
%      the existing singleton*.
%
%      DATAVISUALIZER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DATAVISUALIZER.M with the given input arguments.
%
%      DATAVISUALIZER('Property','Value',...) creates a new DATAVISUALIZER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DataVisualizer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DataVisualizer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DataVisualizer

% Last Modified by GUIDE v2.5 21-Dec-2015 11:55:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DataVisualizer_OpeningFcn, ...
                   'gui_OutputFcn',  @DataVisualizer_OutputFcn, ...
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


% --- Executes just before DataVisualizer is made visible.
function DataVisualizer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DataVisualizer (see VARARGIN)

% Choose default command line output for DataVisualizer
handles.output = hObject;
handles.strctScan = varargin{1};
% Update handles structure
set (handles.figure1, 'WindowButtonMotionFcn', {@mouseMove, handles.figure1});
Z = mean(handles.strctScan.data,3);
handles.hImage = image(Z,'parent',handles.axes1);
set(handles.hImage,'CDataMapping','scaled');

stimulusON=fnIntervalsToBinary(handles.strctScan.stimulusOn, length(handles.strctScan.photodiodeResampledFrameTime));
stimulusOFF=fnIntervalsToBinary(handles.strctScan.stimulusOff, length(handles.strctScan.photodiodeResampledFrameTime));


%
intervals = fnGetIntervals(handles.strctScan.photodiodeResampledFrameTime > 2080);
minL = min(cat(1,intervals.m_iLength));
range = (-minL:minL) * 1/handles.strctScan.frameRate * 1000;
Q = zeros(size(handles.strctScan.upsampledData,1),size(handles.strctScan.upsampledData,2),2*minL+1);
for k=1:length(intervals)
    Q = Q + handles.strctScan.upsampledData(:,:,intervals(k).m_iStart-minL:intervals(k).m_iStart+minL);
end
Q=Q/length(intervals);
figure(11);
clf;
plot(range,squeeze(mean(mean(Q,1),2)));
xlabel('time (ms)');
%

for i=1:size(handles.strctScan.data,1)
    for j=1:size(handles.strctScan.data,2)
        D=double(squeeze(handles.strctScan.data(i,j,:)));
        
        % first analysis: visually responsiveness.
        % most straight forward way, run a t-test between blank
        % and stimulus period. 
        [h, pTestVisuallyResponsive(i,j)]=ttest(D(stimulusON),D(stimulusOFF));
        % for direction selectivity, we use one-way anova with 8 groups
        %
        % construct the anova table
        minStimulusDuration = min(cat(1,handles.strctScan.stimulusOn.m_iLength));
        numStimuli = length(handles.strctScan.stimulusOn);
        table = zeros(minStimulusDuration,numStimuli);
        for k=1:numStimuli
            differentialResponse = D(handles.strctScan.stimulusOn(k).m_iStart:handles.strctScan.stimulusOn(k).m_iEnd)-...
                D(handles.strctScan.stimulusOff(k).m_iStart:handles.strctScan.stimulusOff(k).m_iEnd);
            table(:,k) = differentialResponse(1:minStimulusDuration);
            group(k) = 1+mod(k-1,8);
        end
        for direction=1:8
            avgResponse(i,j,direction)=mean(mean(table(:,group==direction)));
        end
        % directions are:
        [~,preferredDirection(i,j)] = max(avgResponse(i,j,:));
        
        pTestDirectionSelective(i,j)=anova1(table,group,'off');
        [corrToStimulus(i,j), pvalue(i,j)]=corr(double(D), handles.strctScan.photodiodeResampledFrameTime(:));
    end
end
visuallyResponsivePixels = ~isnan(pTestVisuallyResponsive) & pTestVisuallyResponsive<0.01;
DirectionSelectivePixels = visuallyResponsivePixels & pTestDirectionSelective < 0.01;
SignificantPreferredDirection = preferredDirection;
SignificantPreferredDirection(~DirectionSelectivePixels) = NaN;

% tmp=reshape(avgResponse,size(avgResponse,1)*size(avgResponse,2),size(avgResponse,3));
% 
% figure;
% imagesc(tmp(DirectionSelectivePixels,:))
% 

figure(120);clf;
subplot(2,2,1);imagesc(visuallyResponsivePixels);impixelinfo; title('Visually Responsive (p<0.01)');
subplot(2,2,2);imagesc(DirectionSelectivePixels);impixelinfo; title('Direction Responsive (p<0.01)');
subplot(2,2,4);imagesc(SignificantPreferredDirection);title('Preferred Direction');

figure(20);
for k=1:size(handles.strctScan.upsampledData,3)
    J=conv2(handles.strctScan.upsampledData(:,:,k), fspecial('gaussian',[30 30],1),'same');
    imagesc(J,[000 5000]);
    drawnow
end

% plot highest correlation
% tmp =  corrToStimulus;
% tmp(isnan(tmp))=0;
% [S,ind]=sort(abs(tmp(:)),'descend');
% [yy,xx]=ind2sub(size(tmp),ind(1:20));
% hold(handles.axes1,'on');
% plot(handles.axes1,xx,yy,'r+');

guidata(hObject, handles);

% UIWAIT makes DataVisualizer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DataVisualizer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get deault command line output from handles structure
varargout{1} = handles.output;


function mouseMove(obj,A,fig)
handles = guidata(fig);
C = get (handles.axes1, 'CurrentPoint');
x=C(1,1);
y=C(1,2);
cla(handles.axes2);
hold(handles.axes2,'on');
 lowPassRange = min(0.9999,max(0, [0.04 120]*2/handles.strctScan.frameRate));
 [b,a]=butter(2,lowPassRange);
% dd=filtfilt(b,a,d);

m=filtfilt(b,a, double(squeeze(mean(mean(handles.strctScan.data,1),2))));
plot(handles.axes2,m,'k');
if x >= 1 && y >= 1 && x <= size(handles.strctScan.data,2) && y <= size(handles.strctScan.data,1)
    rawdata = squeeze(handles.strctScan.data(round(y),round(x),:));
    g = fspecial('gaussian',[1 50],1)';
    d = conv2(double(rawdata),g,'same');
    
%     frameRate = 8;
 dd=filtfilt(b,a,d);

    
    
    %plot(handles.axes2,rawdata,'b');
    %plot(handles.axes2,d);
    plot(handles.axes2,dd);
    %plot(handles.axes2,handles.strctScan.photodiodeResampledFrameTime);
    


stimulusON=fnIntervalsToBinary(handles.strctScan.stimulusOn, length(handles.strctScan.photodiodeResampledFrameTime));
stimulusOFF=fnIntervalsToBinary(handles.strctScan.stimulusOff, length(handles.strctScan.photodiodeResampledFrameTime));

cla(handles.axes3);
hold(handles.axes3,'on');
histogram(dd(stimulusON),'parent',handles.axes3);
histogram(dd(stimulusOFF),'parent',handles.axes3);

    
    
end
set(handles.axes2,'ylim',[-10000 20000]);

