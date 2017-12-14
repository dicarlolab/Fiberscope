%function JeromeHiLo
PTwrapper('Release');


Ham=PTwrapper('InitWithResolutionOffset',704,256,640,480);
g=PTwrapper('SetGain',0);
e=PTwrapper('SetExposure',1/20);

g=PTwrapper('GetGain');
e=PTwrapper('GetExposure');
fprintf('Gain : %.2f, Exp : %.2f ms\n',g,1/e);
% init DMD
ALPwrapper('Init');
%%
N=20;
Speed = 1.5;

% clear buffer
I=PTwrapper('GetImageBuffer');
% play zero image
ALPuploadAndPlay(zeros(768,1024)>0, Speed, N);
PTwait(N);
I=PTwrapper('GetImageBuffer');
size(I)

darkImage = mean(single(I),3);
meanValue = median(darkImage(:));
stdValue = mad(darkImage(:));
figure(1);
clf;
imagesc(darkImage,[meanValue-10*stdValue, meanValue+10*stdValue]);
%%
autoFluorescenceImageExposure = 1/20;
Speed = 1.5;
N = 20;

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
EmissionImageExposure = 1/30;
Speed =4;
N = 20;

e=PTwrapper('SetExposure',EmissionImageExposure);

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
%% now wash in water again....

%%  Now put in sample
sampleImageExposure=1/4050;
e=PTwrapper('SetExposure',sampleImageExposure);
Speed =298;
N = Speed;
% now take epi image
I=PTwrapper('GetImageBuffer');

ALPuploadAndPlay(ones(768,1024)>0, Speed, N);
PTwait(N);
I=PTwrapper('GetImageBuffer');
size(I)
epiImage = mean(single(I),3);
figure(21);imagesc(epiImage);myColorbar();

%% now take structured light image
GridIntervals = 15:5:40;
orientation = 5/180*pi;
dutyCycle = 1;
clear gridImage
for i=1:length(GridIntervals)
    for phaseiter=1:3
        fprintf('Measuring grid %d, phase %d\n',GridIntervals(i), phaseiter);
        phase = (phaseiter-1)/3;
        ALPuploadAndPlay(fnBuildGridWithOrientation(GridIntervals(i),phase,orientation,dutyCycle), Speed, N);
        PTwait(N);
        I=PTwrapper('GetImageBuffer');
        gridImage{i,phaseiter} = mean(single(I),3);
        figure(22);imagesc(gridImage{i,phaseiter});myColorbar();drawnow
    end
  
end

fprintf('Dumping to disk...\n');
save('HiLo_Test_13_NoBackgroundIllumination_ND3',...
    'darkImage','epiImage','gridImage','GridIntervals',...
    'dutyCycle');

% save('HiLo_Test_13',...
%     'darkImage','epiImage','Ihf','Iaf','gridImage','GridIntervals',...
%     'dutyCycle','autoFluorescenceImageExposure','sampleImageExposure','EmissionImageExposure');
%%
% Turn off DMD
ALPuploadAndPlay(zeros(768,1024)>0, 20, 1);

%%
%% Plot
figure(1);
clf;
subplot(2,3,1);
imagesc(darkImage);
title('Dark');
subplot(2,3,2);
imagesc(epiImage);
title('Epi');
subplot(2,3,3);
imagesc(gridImage);
title('Grid 1');
subplot(2,3,4);
imagesc(gridImage2);
title('Grid 2');
subplot(2,3,5);
imagesc(gridImage3);
title('Grid 3');

%% Phase stepping algorithm
simImages = reshape([gridImage,gridImage2,gridImage3],480,640,3);

smallGaussianWidth = 3;
smallKernel1D = fspecial('gaussian',[10*smallGaussianWidth 1],smallGaussianWidth);
smooth=convn(convn(simImages,smallKernel1D,'same'),smallKernel1D','same');

smoothEpi=convn(convn(epiImage,smallKernel1D,'same'),smallKernel1D','same');


simReconstruction = 1/(3*sqrt(2))* sqrt( (smooth(:,:,1:3:end)-smooth(:,:,2:3:end)).^2 + ...
                                             (smooth(:,:,1:3:end)-smooth(:,:,3:3:end)).^2 + ...
                                             (smooth(:,:,2:3:end)-smooth(:,:,3:3:end)).^2);


figure(4);
clf;
imagesc(smoothEpi,[300 800]);colormap gray
P=get(gcf,'position');set(gcf,'position',[P(1), P(2), 356, 244]);
title('Smooth Epi');

figure(3);
clf;
imagesc(mean(smooth,3),[300 700]);colormap gray
P=get(gcf,'position');set(gcf,'position',[P(1), P(2), 356, 244]);
title('Smooth mean phase');

figure(2);
clf;
imagesc(simReconstruction,[0 60]);
P=get(gcf,'position');set(gcf,'position',[P(1), P(2), 356, 244]);
title('SIM');


%%
N=5;
Tmp = false(768,1024);
%Tmp(:,1:250)=true;
% Tmp(:,495:500)=true;
% Tmp(:,395:400)=true;
Tmp(:,295:300)=true;
I=PTwrapper('GetImageBuffer');
ALPuploadAndPlay(Tmp, Speed, N);
PTwait(N);
I=PTwrapper('GetImageBuffer');
epiImage = mean(single(I),3);
figure(1);imagesc(epiImage,[500 1000]);myColorbar();