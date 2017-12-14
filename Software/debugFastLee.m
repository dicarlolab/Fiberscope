addpath('C:\Users\shayo\Dropbox (MIT)\Code\Github\FiberImaging\Code\mex');

A = rand(64,64,100,'single');
dmd.numReferencePixels = 64;
dmd.width = 1024;
dmd.height = 768;
dmd.leeBlockSize = 10;
dmd.selectedCarrier = 0.2;% [0.2, ones(1,99)*0.19];
dmd.carrierRotation = 125/180*pi; %ones(1,100)*125/180*pi;

% R2=FastLeeHologram(A, dmd.numReferencePixels, dmd.leeBlockSize, dmd.selectedCarrier);

R1= CudaFastLee(A,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier, dmd.carrierRotation);

figure(1);
clf;
subplot(1,3,1);
imagesc(R1)
subplot(1,3,2);
imagesc(R2)
subplot(1,3,3);
imagesc(R2-R1)
