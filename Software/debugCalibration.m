% Fiber Calibration procedure.

ALPwrapper('Init');

Ham=PTwrapper('Release');

Ham=PTwrapper('InitWithResolutionOffset',704,256,640,480);
g=PTwrapper('SetGain',0);

%% Dark Image (Ibg)

darkImageExposure = 1/20;
Speed = 1.5;
N = 100;

e=PTwrapper('SetExposure',darkImageExposure);

I=PTwrapper('GetImageBuffer');
% play zero image
ALPuploadAndPlay(zeros(768,1024)>0, Speed, N);
PTwait(N);
I=PTwrapper('GetImageBuffer');
Ibg = mean(single(I),3);
meanValue = median(Ibg(:));
stdValue = mad(Ibg(:));
figure(1);
clf;
imagesc(Ibg,[meanValue-10*stdValue, meanValue+10*stdValue]);myColorbar();

%% Iaf - auto fluorescence image
autoFluorescenceImageExposure = 1/20;
Speed = 1.5;
N = 100;

e=PTwrapper('SetExposure',autoFluorescenceImageExposure);

I=PTwrapper('GetImageBuffer');
% play zero image
ALPuploadAndPlay(ones(768,1024)>0, Speed, N);
PTwait(N);
I=PTwrapper('GetImageBuffer');
Iaf = mean(single(I),3);
meanValue = median(Iaf(:));
stdValue = mad(Iaf(:));
figure(1);
clf;
imagesc(Iaf,[meanValue-10*stdValue, meanValue+10*stdValue]);myColorbar();
%% Ihf - Now put in fluorescin
autoFluorescenceImageExposure = 1/250;
Speed =10;
N = 100;

e=PTwrapper('SetExposure',autoFluorescenceImageExposure);

I=PTwrapper('GetImageBuffer');
% play zero image
ALPuploadAndPlay(ones(768,1024)>0, Speed, N);
PTwait(N);
I=PTwrapper('GetImageBuffer');
Ihf = mean(single(I),3);
meanValue = median(Ihf(:));
stdValue = mad(Ihf(:));
figure(1);
clf;
imagesc(Ihf,[max(0,meanValue-10*stdValue), min(4095,meanValue+10*stdValue)]);myColorbar();
%%
save('FiberCalibrationTest','Ihf','Ibg','Iaf');

%% Now put in sample
sampleImageExposure = 1/240;
Speed = 20;
N = 100;
e=PTwrapper('SetExposure',sampleImageExposure);
I=PTwrapper('GetImageBuffer');
% play zero image
ALPuploadAndPlay(ones(768,1024)>0, Speed, N);
PTwait(N);
I=PTwrapper('GetImageBuffer');
Iraw = mean(single(I),3);
meanValue = median(Iraw(:));
stdValue = mad(Iraw(:));
figure(1);
clf;
imagesc(Iraw,[meanValue-10*stdValue, meanValue+10*stdValue]);
imagesc(Ihf,[max(0,meanValue-10*stdValue), min(4095,meanValue+10*stdValue)]);myColorbar();

%% 
save('FiberCalibrationTest2','Ihf','Ibg','Iaf','Iraw');
%%

figure(11);
clf;
imagesc(Iaf);myColorbar();

smallGaussianWidth = 4;
Ics = Iraw; %(Iraw);

% Ics=JeromeSegmentationInterpolation(Iraw,smallGaussianWidth);
dP=sampleImageExposure/autoFluorescenceImageExposure;
% pixelweights = Ihf - Ibg - (Iaf-Ibg)*dP;
% pixelweights=pixelweights/max(pixelweights(:));
Ipp_Jerome = (Ics - Ibg - (Iaf-Ibg)*dP ) ./ (Ihf - Ibg - (Iaf-Ibg)*dP);
figure(20);
clf;
imagesc(Ipp_Jerome,[0 2]);

normalization = Ihf - Ibg - (Iaf-Ibg)*dP;
normalization=1-normalization/max(normalization(:));

Ipp = (Ics - Ibg - (Iaf-Ibg)*dP );% ./ (Ihf - Ibg - (Iaf-Ibg)*dP);
figure(11);clf;imagesc(Ics - Ibg - (Iaf-Ibg)*dP,[0 4095]);myColorbar();
figure(13);imagesc(normalization);myColorbar();
figure(14);clf;imagesc(Ipp.*normalization );myColorbar();
figure(17);clf;imagesc(Ihf);
figure(16);clf;imagesc(Ics);

% 
% figure(12);clf;imagesc((Ics - (Iaf-Ibg)*dP - Ibg)); myColorbar()
% figure(13);clf;imagesc(Ihf - (Iaf-Ibg)*dP - Ibg);myColorbar()
% figure(14);clf;imagesc((Ics- Ibg)./(Ihf- Ibg),[0 3]); myColorbar()
% figure(15);clf;imagesc((Ics)./(Ihf),[0 2]); myColorbar()
% figure(16);imagesc(Ics - Ibg);myColorbar()
% figure(17);imagesc(Ics - Ibg- (Iaf-Ibg)*dP);myColorbar()

