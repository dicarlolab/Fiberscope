ALPwrapper('Init')
Ham=PTwrapper('InitWithResolutionOffset',1280,512,256,256);

ALPuploadAndPlay(zeros(768,1024)>0,1,1);
PTwrapper('GetBufferSize')

PTwrapper('StartAveraging',3);
ALPuploadAndPlay(zeros(768,1024)>0,1,1);
ALPuploadAndPlay(zeros(768,1024)>0,1,1);
ALPuploadAndPlay(zeros(768,1024)>0,1,1);


ALPuploadAndPlay(zeros(768,1024)>0,1,1);
ALPuploadAndPlay(zeros(768,1024)>0,1,1);
ALPuploadAndPlay(zeros(768,1024)>0,1,1);

ALPuploadAndPlay(zeros(768,1024)>0,1,1);
ALPuploadAndPlay(zeros(768,1024)>0,1,1);
ALPuploadAndPlay(zeros(768,1024)>0,1,1);

A = PTwrapper('GetImageBuffer');
whos A


PTwrapper('getNumTrigs')

figure(1);
clf;
imagesc(A)
