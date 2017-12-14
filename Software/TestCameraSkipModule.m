CameraTriggerWrapper(1);
A=PTwrapper('GetImageBuffer');
ALPuploadAndPlay(zeros(768,1024)>0,850,1000);
WaitSecs(1);
PTwrapper('GetBufferSize')


FreqDMD = 22000;
TargetCameraFrequency = 850;
Skip = ceil(FreqDMD/TargetCameraFrequency);
CameraTriggerWrapper(Skip);
A=PTwrapper('GetImageBuffer');
ALPuploadAndPlay(zeros(768,1024)>0,FreqDMD,50*Skip);
WaitSecs(1);
PTwrapper('GetBufferSize')

floor(FreqDMD / Skip)