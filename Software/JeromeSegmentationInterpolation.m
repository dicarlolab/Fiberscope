function Ics=JeromeSegmentationInterpolation(M,smallGaussianWidth)
% assume intercore distance is ~ FWHM
FWHM = 2*sqrt(2*log(2))*smallGaussianWidth;
smallKernel1D = fspecial('gaussian',[10*smallGaussianWidth 1],smallGaussianWidth);
numIter = 5;
Ics = M;
for k=1:numIter
Ilp=convn(convn(Ics,smallKernel1D,'same'),smallKernel1D','same');
Mask = Ics > Ilp;
Ics = Mask.*Ics  + (1-Mask).*Ilp;
end
% 
% figure(11);
% clf;
% imagesc(Ics);
% axis off

