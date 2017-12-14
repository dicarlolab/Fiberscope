function walshBasisCirc=fnBuildWalshBasisCircular(numBlocks, maxPatterns)
if ~exist('maxPatterns','var')
    maxPatterns = numBlocks*numBlocks;
end
walshBasis = (1+fnBuildWalshBasis(numBlocks,maxPatterns))/2; 
% create a log polar basis
[X,Y]=meshgrid(1:numBlocks,1:numBlocks);
Xt = (X-1)-numBlocks/2;
Yt = (Y-1)-numBlocks/2;
Rho = sqrt((Xt.^2)+(Yt.^2));
Theta = atan2(Yt,Xt);

% Stretch range
RhoS = 1+Rho/max(Rho(:)) * (numBlocks-1);
ThetaS = 1+(1+(Theta/pi))/2  * (numBlocks-1);

walshBasisCirc = zeros(size(walshBasis),'int8');
for pattern = 1:maxPatterns
    walshBasisCirc(:,:,pattern) = reshape(interp2(double(walshBasis(:,:,pattern)), RhoS(:), ThetaS(:)), 64,64) > 0.5;
end
walshBasisCirc=int8(2*walshBasisCirc-1);