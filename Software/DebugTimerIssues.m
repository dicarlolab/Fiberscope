fnDAQusb('IsInitialized')
res=fnDAQusb('Init');
ALPwrapper('Init')

res=fnDAQusb('StopContinuousAcqusition',0);

LengthSec = 60*4;

SamplingRate = 400000;
DMDrate = 10000;
SequenceLength=4000;
TimePerSequence = SequenceLength/DMDrate;
numRepeats = LengthSec/TimePerSequence;
numSamplesToAcquire = ceil(SamplingRate*(10+LengthSec)/256)*256;
res=fnDAQusb('Allocate',0, 1, numSamplesToAcquire, 1, 1);
res=fnDAQusb('StartContinuousAcqusitionFixedRateTrigger',0,SamplingRate);

Seq = false(768,1024,SequenceLength);

ALPuploadAndPlay(Seq,DMDrate,numRepeats);
values=squeeze(fnDAQusb('GetBuffer',0));
  numSamplesCollected = fnDAQusb('GetNumSamplesAcquiried', 0)

fnDAQusb('StopContinuousAcqusition',0);
intervals = fnGetIntervals(values>40000)

intervalStart = cat(1,intervals.m_iStart);
expectedEdge = 2:40:96005560;
figure(1);
clf;
plot( (intervalStart(1:4356255)'-expectedEdge)/20000);
hold on;
plot(expectedEdge);

