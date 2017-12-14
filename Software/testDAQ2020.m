strctRun.USB1608_ID = 0;
strctRun.USB2020_ID = 1;

clear ALPwrapper
ALPwrapper('Init');


      holograms = zeros(768,128,5258,'uint8');
  fprintf('Now uploading to DMD %d patterns\n', size(holograms,3));
      
   sweepsequenceID=ALPwrapper('UploadPatternSequence',holograms);
strctRun.USB2020_ID= 1;
             res=fnDAQusb('Allocate', ...
            strctRun.USB2020_ID,  ...
            2,...
            210321408/2);
        
     
        res=fnDAQusb('StartContinuousAcqusitionExtClock',...
            strctRun.USB2020_ID,...
           0,...
           1,1,0); % no bipolar :(
  
        
res=ALPwrapper('PlayUploadedSequence',sweepsequenceID, 20000, 100);
        
res=ALPwrapper('StopSequence');
%%
es=fnDAQusb('ResetCounters',strctRun.USB1608_ID)
% 178
[a,b]=fnDAQusb('ReadCounters',strctRun.USB1608_ID)

ALPwrapper('Init');
ALPuploadAndPlay(zeros(768,1024)>0,20000,1);

%%

addpath('C:\Users\shayo\Dropbox (MIT)\Code\Github\FiberImaging\Code\mex');
%%

packetSize = 256;
totalDesiredSamples = 2000;
actualNumberSamplesToCollect = packetSize*ceil(totalDesiredSamples/packetSize);

res=fnDAQusb('Init',strctRun.USB1608_ID); % USB-2020: Super fast!
    
res=fnDAQusb('Allocate', ...
            strctRun.USB1608_ID,  ...
            2, ...    
            702208);
        
VoltageRange = 1;        
res=fnDAQusb('StartContinuousAcqusitionExtClock',...
    strctRun.USB1608_ID,...
    0,...
    1,...
    VoltageRange,0);

ALPuploadAndPlay(zeros(768,1024)>0,20000,702208);

fnDAQusb('GetNumSamplesAcquiried',strctRun.USB1608_ID)

%%



% fnDAQusb('Release');
% clear fnDAQusb
strctRun.USB1608_ID = 0;
strctRun.USB2020_ID = 1;
res=fnDAQusb('Init',strctRun.USB2020_ID); % USB-2020: Super fast!

overSample = 200;
    
numSamplesPerChannel = 100*1024*overSample;
res=fnDAQusb('Allocate', ...
            strctRun.USB2020_ID,  ...
            2, ...    
            numSamplesPerChannel);
        
VoltageRange = 1;        
res=fnDAQusb('StartContinuousAcqusitionExtClock',...
    strctRun.USB2020_ID,...
    0,...
    1,...
    VoltageRange,0);

ALPuploadAndPlay(zeros(768,1024)>0,20000,numSamplesPerChannel/overSample);



fnDAQusb('GetNumSamplesAcquiried',strctRun.USB2020_ID)
% 0V => 2048
% +5V => 4096
% -5V => 0
buf=fnDAQusb('GetBuffer',strctRun.USB2020_ID);  
figure(1);clf;hold on;
plot(buf(1,:),'b');
plot(buf(2,:),'r');
figure(2);clf;hold on;
plot((double(buf(1,:))-4096/2)/(4096/2),'b')
plot((double(buf(2,:))-4096/2)/(4096/2),'r');

plotFFT(buf(1,:), 8000000,'b')
plotFFT(buf(2,:), 8000000,'r')
set(gca,'xlim',[0 10000]);
fprintf('%.4f\n',mean(buf(1,:)))

%[ch1-1,ch2-1, ch1-2, ch2-2, ch1-3, ch2-3.... 
% frames x  planes x spots x  oversampling
%[Channels x Frames x Plane/frame x Spots X oversampling    
%     res=res & fnDAQusb('Init',strctRun.FAST_DAQ_ID,256, 0); % USB-2020: Super fast!

% fnDAQusb('ResetCounter', strctRun.FAST_DAQ_ID)
% 
% fnDAQusb('ReadCounter', strctRun.FAST_DAQ_ID)
%206

strctRun.numChannels = 2;
strctRun.numPlanes = 2;
strctRun.numSpotsPerPlane = 100;
strctRun.fastDAQoverSampling = 200;
strctRun.numFrames = 500;
desiredFlips = strctRun.numFrames * strctRun.numPlanes *  strctRun.numSpotsPerPlane;
numSamplesPerFrame = strctRun.numChannels * strctRun.numPlanes *  strctRun.numSpotsPerPlane * strctRun.fastDAQoverSampling;
totalDesiredSamples = strctRun.numFrames * numSamplesPerFrame;
packetSize = 4096;
actualNumberSamplesToCollect = packetSize*ceil(totalDesiredSamples/packetSize);
actualNumberOfFlips = ceil(actualNumberSamplesToCollect / strctRun.numChannels /  strctRun.fastDAQoverSampling);
leftOverFlips = actualNumberOfFlips - desiredFlips;
res=fnDAQusb('AllocateFrames', ...
            strctRun.USB2020_ID,  ...
            strctRun.numChannels, ...
            strctRun.numPlanes,...
            strctRun.numSpotsPerPlane,...
            strctRun.fastDAQoverSampling, ...
            strctRun.numFrames,...
            packetSize);
        
% strctRun.numFrames*strctRun.numPlanes*        strctRun.numSpotsPerPlane * strctRun.fastDAQoverSampling
VoltageRange = 1;        
res=fnDAQusb('StartContinuousAcqusitionExtClock',...
    strctRun.USB2020_ID,...
    0,...
    1,...
    VoltageRange,0);


% ALPwrapper('Init');
ALPuploadAndPlay(zeros(768,1024)>0,20000,actualNumberOfFlips);

%%


% 3280
fnDAQusb('GetNumSamplesAcquiried',strctRun.USB2020_ID)

frames = fnDAQusb('GetFrames',strctRun.USB2020_ID);
% channels  x Spots  x Planes x Frames 
frames(1,:,:,:)
frames(2,:,:,:)
buf=fnDAQusb('GetBuffer',strctRun.SUPER_FAST_DAQ_ID);  
figure(1);clf;hold on;
plot(buf(1,:),'b');
plot(buf(2,:),'r');
buf=fnDAQusb('GetParsedBuffer',strctRun.SUPER_FAST_DAQ_ID);  
        
% numChannels X over sampling X SpotsPerPlane X num Planes X Num Frames


ch1=buf(1,:,:,:,:);
ch2=buf(2,:,:,:,:);

frame1ch1plane1 = squeeze(buf(1,:,:,1,1));
frame1ch2plane1 = squeeze(buf(2,:,:,1,1));

frame1ch1plane2 = squeeze(buf(1,:,:,2,1));
frame1ch2plane2 = squeeze(buf(2,:,:,2,1));

frame2ch1plane1 = squeeze(buf(1,:,:,1,2));
frame2ch2plane2= squeeze(buf(2,:,:,1,2));

figure(2);clf;hold on;
plot(ch1(:),'b');
plot(ch2(:),'r');

vRange = 5;
res=fnDAQusb('StartContinuousAcqusitionExtClock',strctRun.SUPER_FAST_DAQ_ID,0,1,5,0);

fnDAQusb('StopContinuousAcqusition',strctRun.SUPER_FAST_DAQ_ID);


res=fnDAQusb('StartContinuousAcqusitionFixedRate',strctRun.SUPER_FAST_DAQ_ID,8000000,5,0);

 
  fnDAQusb('GetNumSamplesAcquiried',strctRun.SUPER_FAST_DAQ_ID)
                    
parsedbuf=fnDAQusb('GetParsedBuffer',strctRun.SUPER_FAST_DAQ_ID);  

  
figure(11);
clf;
plot(buf(:,1:4096)');

        fnDAQusb('StopContinuousAcqusition',strctRun.SUPER_FAST_DAQ_ID);
        
        fnDAQusb('Release');
    