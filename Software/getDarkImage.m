function darkImage=getDarkImage(devID,cameraRate)
Z=XimeaWrapper('GetImageBuffer');
ALPuploadAndPlay(devID,zeros(768,1024)>0,cameraRate,100);
ALPwrapper('WaitForSequenceCompletion',devID);
WaitSecs(0.5); % allow all images to reach buffer
baseline=XimeaWrapper('GetImageBuffer');
darkImage = mean(single(baseline),3);
darkImage(1,1:2)=median(darkImage(:));% get rid of timestamp
