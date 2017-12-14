function I=blur(I, gaussianWidth)
kernel1D = fspecial('gaussian',[10*gaussianWidth 1],gaussianWidth);
I=convn(convn(double(I),kernel1D,'same'),kernel1D','same');
