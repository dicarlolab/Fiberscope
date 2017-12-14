% 
addpath('E:\Dropbox (MIT)\Code\Waveform Reshaping code\MEX\x64');
[OffsetX, OffsetY, Res] = GetCameraParams();

Hcam=PTwrapper('InitWithResolutionOffset',OffsetX,OffsetY,Res,Res);
r=PTwrapper('StartAveraging',4096,true);

ALPwrapper('Init');

ALPuploadAndPlay(zeros(768,1024)>0,800,4095);

ALPuploadAndPlay(zeros(768,1024)>0,100,1);

PTwrapper('Release');

ALPwrapper('Release');
