randPhase=2*pi*rand(64,64);
numReferencePixels = 128;
leeBlockSize = 8;
selectedCarrier = 0.200;
carrierRotation = 125/180*pi;
interferenceBasisPatterns = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize,selectedCarrier, carrierRotation);
duration = 10;
dmdrate = 0.2; 

strctRun.FAST_DAQ_ID = 0;
        strctRun.SLOW_DAQ_ID = 1;
        
        strctRun.daqRate = 100000;
        strctRun.fastDAQnumSamples = ceil(strctRun.daqRate*duration/(31*256))*31*256;
        
    res=fnDAQusb('Init');
   res=fnDAQusb('Allocate',strctRun.FAST_DAQ_ID, 1, ...
            strctRun.fastDAQnumSamples, ...
            1, 1, 1000);
      res=fnDAQusb('StartContinuousAcqusitionFixedRateTrigger',strctRun.FAST_DAQ_ID, strctRun.daqRate, 10);
fnDAQusb('GetNumSamplesAcquiried',strctRun.FAST_DAQ_ID)
      ALPuploadAndPlay(interferenceBasisPatterns,dmdrate,dmdrate*10);
WaitSecs(0.1);
      buf = fnDAQusb('GetBuffer',strctRun.FAST_DAQ_ID);
      
      buf=buf-mean(buf(:));
%       buf(buf<-1000)=-buf(buf<-1000);
T=(1:length(buf))*1/strctRun.daqRate;
figure(11);
clf;
subplot(1,2,1);
plot(T,squeeze(buf));
set(gca,'xlim',[0 10]);


subplot(1,2,2);
plotFFT(squeeze(buf).*hanning(length(buf)), strctRun.daqRate);
set(gca,'xlim',[0 260],'ylim',[0 1]);