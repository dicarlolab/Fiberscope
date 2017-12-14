fnDAQusb('Init')
%%
V = 4;
D = round( max(0, min(2^16-1, (V-(-10))/20 * (2^16-1))));
fnDAQusb('OutputVoltage',0,0,D)
FAST_DAQ_ID = 0;
SLOW_DAQ_ID = 1;

fnDAQusb('StopContinuousAcqusition',FAST_DAQ_ID);
fnDAQusb('StopContinuousAcqusition',SLOW_DAQ_ID);

fnDAQusb('Allocate',FAST_DAQ_ID,1,256*2,16,1)
fnDAQusb('Allocate',SLOW_DAQ_ID,2,31*3,1,1)

[fnDAQusb('GetNumSamplesAcquiried',0),fnDAQusb('GetNumSamplesAcquiried',1)]

fnDAQusb('StartContinuousAcqusitionExtClock',0);
fnDAQusb('StartContinuousAcqusitionFixedRateTrigger',1,100);

ALPwrapper('Init')
testID = ALPwrapper('UploadPatternSequence',zeros(768,128, 512,'uint8'));
res=ALPwrapper('PlayUploadedSequence',testID,500, 1);
 
bufA=fnDAQusb('GetBuffer',0);
bufB=fnDAQusb('GetBuffer',1);


fnDAQusb('Allocate',0,256*1000,1,1)
fnDAQusb('StartContinuousAcqusitionFixedRateTrigger',0,4,1000)

fnDAQusb('Allocate',1,31*1000,1,1)
fnDAQusb('StartContinuousAcqusitionFixedRateTrigger',1,4,1000)


fnDAQusb('Allocate',0,256*1000,16,16)
fnDAQusb('StartContinuousAcqusitionExtClock',0,0)

F=fnDAQusb('GetFrames',0)

Volts = (F-2^15)/(2^15)*2



fnDAQusb('Release')
clear fnDAQusb