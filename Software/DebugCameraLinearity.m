[OffsetX, OffsetY, Res] = GetCameraParams();
Hcam=PTwrapper('InitWithResolutionOffset',OffsetX,OffsetY,Res,Res, 0);

PTwrapper('SoftwareTrigger');WaitSecs(0.5);
I=PTwrapper('GetImageBuffer');
figure(1);
clf;
imagesc(I)
colorbar
impixelinfo

PTwrapper('GetImageBuffer');

PTwrapper('SetGain',0);
Exposures = [500:100:8000];

figure(10);
clf;
plot(log2([500,1000,2000,4000,8000]),log2([4000 2000 1000 500 250]));
% 500 -> 4000
% 1000 -> 2000
% 2000 -> 1000
% 4000 -> 500
% 8000 -> 250



N = 10;
meanI = zeros(128,128,length(Exposures));
for iter=1:length(Exposures)
    PTwrapper('SetExposure',1./Exposures(iter));
    for k=1:N
        PTwrapper('SoftwareTrigger');
        WaitSecs(1/250);
    end
    I=PTwrapper('GetImageBuffer');
    meanI(:,:,iter)=mean(single(I),3);
end

firstImage = meanI(:,:,1);
ind = find(firstImage > 3995 & firstImage <4005);
res = zeros(1,size(meanI,3));
for k=1:size(meanI,3)
    Tmp = meanI(:,:,k);
    res(k)=mean(Tmp(ind));
end
figure(2);clf;
hold on;
plot(log2(Exposures),log2(res));

plot(Exposures,linearCurve);

% 
exposure=1000, value=500
base_exposure = 14; % 1/128
ND = 2;
photons = 10^ND * round(2^(log2(exposure)-base_exposure) * value)


figure(10);clf;
X = [125/2,125,250,500,1000,2000,4000];
plot(log2(X),[4,3,2,1,0,-1,-2],'.');
axis equal
hold on;
plot(-10:20, [-10:20 ]* (-1) + 10)

log2([250,500,1000,2000,4000])





hold on;
plot(1./Exposures,(squeeze(meanI(55,k,:))));
end
xlabel('1 / Exposure time (ms)');
ylabel('Intensity value');

./ squeeze(meanI(45,45,:)))
plot(squeeze(meanI(55,55,:)))
figure(11);
clf;
imagesc(meanI(:,:,1))