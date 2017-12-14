% create a log polar basis
numBlocks = 64;
[X,Y]=meshgrid(1:numBlocks,1:numBlocks);
Xt = (X-1)-numBlocks/2;
Yt = (Y-1)-numBlocks/2;
Rho = sqrt((Xt.^2)+(Yt.^2));
Theta = atan2(Yt,Xt);

walshBasis = fnBuildWalshBasis(numBlocks); 

% Stretch range
RhoS = 1+Rho/max(Rho(:)) * (numBlocks-1);
ThetaS = 1+(1+(Theta/pi))/2  * (numBlocks-1);

pattern = 120;
AAA=reshape(interp2(double(walshBasis(:,:,pattern)), RhoS(:), ThetaS(:)), 64,64);
figure(1);
clf;
subplot(1,2,1);
imagesc(walshBasis(:,:,pattern));
subplot(1,2,2);
imagesc(AAA);
