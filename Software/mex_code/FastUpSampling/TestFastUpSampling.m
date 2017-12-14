addpath('C:\Users\shayo\Dropbox (MIT)\Code\Waveform Reshaping code\MEX\x64');

M = zeros(256,256)>0;
oX = 2;
oY = 2;
dX = 4;
dY = 4;

M(oX:dX:end,oY:dY:end) = 1;

indx = find(M);

Z = zeros(size(M));
Z(indx) = rand(1,length(indx));

figure(11);
clf;
imagesc(Z);

I=FastUpSampling(Z, 1, 1,dX,dY);

figure(12);
clf;
imagesc(I);
