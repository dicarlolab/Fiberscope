ALPwrapper('Init')
ISwrapper('Init');
ISwrapper('SetGain',20); 
%%
ISwrapper('SetExposure',1/30.0); 
I=ISwrapper('GetImageBuffer'); % clear buffer
gaussianWidth = 4; % get rid of freqnecies higher than the core size in the raw images...
highPassSigma = 10; % get rid of DC component of SIM image
width = 60; % grid size in pixels
phase = 0;               pat1D=mod(phase+[0:1024-1],width) >= width/2;pad1=repmat(pat1D,768,1);
phase = floor(width/3);  pat1D=mod(phase+[0:1024-1],width) >= width/2;pad2=repmat(pat1D,768,1);
phase = floor(2*width/3);pat1D=mod(phase+[0:1024-1],width) >= width/2;pad3=repmat(pat1D,768,1);
pat_phaseShift=reshape([pad1,pad2,pad3],768,1024,3);



phaseID = ALPwrapper('UploadPatternSequence',pat_phaseShift);

offID = ALPwrapper('UploadPatternSequence',false(768,1024));
onID = ALPwrapper('UploadPatternSequence',true(768,1024));

W=90;
cnt=1;
clear seq
for k=1:5:768-W;
    fprintf('%d\n',k);
    halfPat = false(768,1024);
    halfPat(k+[1:W],:)=true;
    seq(:,:,cnt)=halfPat;
    cnt=cnt+1;
end
halfID = ALPwrapper('UploadPatternSequence',seq);

tmpID = ALPwrapper('UploadPatternSequence',halfPat);
res=ALPwrapper('PlayUploadedSequence',tmpID,3, 0);
res=ALPwrapper('PlayUploadedSequence',halfID,150, 0);
res=ALPwrapper('PlayUploadedSequence',phaseID,3, 0);
res=ALPwrapper('PlayUploadedSequence',onID,3, 1);

res=ALPwrapper('PlayUploadedSequence',offID,3, 1);

    ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
    ALPwrapper('ReleaseSequence',halfID);



res=ALPwrapper('PlayUploadedSequence',onID,10, 1);

res=ALPwrapper('PlayUploadedSequence',offID,10, 1);

%%
res=ALPwrapper('PlayUploadedSequence',onID,10, 1);
ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
tic; while toc < 0.2; end;
Ion=double(ISwrapper('GetImageBuffer')); % clear buffer

res=ALPwrapper('PlayUploadedSequence',phaseID,10, 1);
ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
tic; while toc < 0.2; end;
I=double(ISwrapper('GetImageBuffer')); % clear buffer


res=ALPwrapper('PlayUploadedSequence',offID,10, 1);
ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
tic; while toc < 0.2; end;
Ibase=double(ISwrapper('GetImageBuffer')); % clear buffer


Is=convn(double(I), fspecial('gaussian',[10*gaussianWidth 10*gaussianWidth],gaussianWidth),'same');
IonSmooth=convn(double(Ion), fspecial('gaussian',[10*gaussianWidth 10*gaussianWidth],gaussianWidth),'same');

figure(10);
clf;
for k=1:3
subplot(2,4,k);
imagesc(I(:,:,k)-Ibase); title('Raw');
subplot(2,4,k+4);
imagesc(Is(:,:,k)-Ibase); title('Raw Smoothed');
end
subplot(2,4,4);
imagesc(double(Ion)-Ibase); title('EPI');
subplot(2,4,8);
imagesc(IonSmooth-Ibase); title('EPI smoothed');

Isim = 1/(3*sqrt(2))* sqrt( (Is(:,:,1)-Is(:,:,2)).^2 + (Is(:,:,1)-Is(:,:,3)).^2 + (Is(:,:,2)-Is(:,:,3)).^2);

% Jerome's fix
Phi = 1/3 * (fft2(Is(:,:,1)) + fft2(Is(:,:,2))*exp(i*2*pi/3)+fft2(Is(:,:,3)*exp(i*4*pi/3)));  
PhiFourier = fftshift(Phi);
[X,Y]=meshgrid(1:size(Phi,2),1:size(Phi,1));
Z = (sqrt( (X-size(Phi,2)/2).^2+(Y-size(Phi,1)/2).^2));
Weight=normpdf(Z,0,highPassSigma);
HighPassFilter=1-Weight/max(Weight(:));
Phi_highPass=PhiFourier.*HighPassFilter;
Isim_Jerome = abs( ifft2(Phi_highPass));

figure(13);clf;
h1=subplot(1,3,1);imagesc(log10(abs(fftshift(fft2(Is(:,:,1))))));title('FFT(mean(Raw))');
h2=subplot(1,3,2);imagesc((log10(abs(PhiFourier)))); title('Phi');
h3=subplot(1,3,3);imagesc((log10(abs(Phi_highPass))));title('Phi Filtered');
linkaxes([h1,h2,h3]);

figure(12);
clf;
subplot(1,3,1);imagesc(IonSmooth, [0 4096]);title('EPI');colorbar
subplot(1,3,2);imagesc(Isim,[0 296]);title('SIM');colorbar
subplot(1,3,3);imagesc(Isim_Jerome,[0 296] );title('SIM+Fix');colorbar
%%
figure(11);
clf;
subplot(1,2,1);
imagesc(Isim)
title('Isim');
subplot(1,2,2);
imagesc(mean(Is,3))
title('Iraw');
colorbar
%%

Ix=I(:,:,3);
figure(11);
clf;
subplot(1,3,1);
imagesc(Ix)
If=conv2(double(Ix), fspecial('gaussian',[20 20],2));
subplot(1,3,2);
imagesc(If)
colorbar
F=abs(fftshift(fft2(double(If))));;
subplot(1,3,3);
imagesc((F));
%%

FilterWheelWrapper('Init')    
FilterWheelWrapper('SetNaturalDensity',0)

ISwrapper('Release');
ALPwrapper('Release');
