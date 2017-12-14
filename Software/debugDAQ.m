clear fnDAQusb
res=fnDAQusb('Init');

strctRun.FAST_DAQ_ID = 0;
strctRun.SLOW_DAQ_ID = 1;

strctRun.fastDAQnumSamples = 4856832
res=fnDAQusb('StopContinuousAcqusition',strctRun.FAST_DAQ_ID);


numFrames = 20;
numSpots = 4096;
numSamplesPerChannel = ceil(numSpots*numFrames/256)*256;
strctRun.fastDAQchannels = [0,0];
ALPuploadAndPlay(zeros(768,1024)>0, 20000, 100000,false)

Fs=20000;
res=fnDAQusb('Allocate',strctRun.FAST_DAQ_ID, 1, numSamplesPerChannel, numSpots, 1, numSpots);
res=fnDAQusb('StartContinuousAcqusitionFixedRate',strctRun.FAST_DAQ_ID,Fs, 1); % 20kS/s, 1 channel


WaitSecs(numFrames*numSpots/Fs)
fnDAQusb('GetNumSamplesAcquiried',strctRun.FAST_DAQ_ID)

valuesFast=fnDAQusb('GetBuffer',strctRun.FAST_DAQ_ID);

fnDAQusb('Release');
figure(11);
clf;
plot(valuesFast(:))

  Tmp = valuesFast(1:40000)';
    Tmp = Tmp.*hanning(length(Tmp));
    L = length(Tmp);             % Length of signal
    f = Fs*(0:(L/2))/L;
    Af = log10(abs(fft(Tmp)));
    figure(1);clf;
    plot(f, Af(1:length(f)));
 
%%
%bool allocate(long numSamplesPerChannel, int NumChannels, int NumSpots, int OverSampling, long FrameSize);
res=fnDAQusb('Allocate',strctRun.FAST_DAQ_ID, 1, ...
    numSamplesPerChannel, ...
    numSpots, 10, numSpots*10);

res=fnDAQusb('StartContinuousAcqusitionExtClock',strctRun.FAST_DAQ_ID,strctRun.fastDAQchannels(1),strctRun.fastDAQchannels(2),1);
    
ALPuploadAndPlay(zeros(768,1024,1)>0,20000,numSamplesPerChannel)

fprintf('Expected to get %d samples\n',numSamplesPerChannel*10);
fprintf('Received %d samples\n',fnDAQusb('GetNumSamplesAcquiried',strctRun.FAST_DAQ_ID));

ALPuploadAndPlay(zeros(768,1024,1)>0,22000,2)


