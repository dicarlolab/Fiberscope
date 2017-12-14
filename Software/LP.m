function Y=LP(X, gaussianWidth)
if gaussianWidth == 0
    Y = X;
    return;
end
kernel1D = fspecial('gaussian',[10*gaussianWidth 1],gaussianWidth);
Y=convn(convn(single(X),kernel1D,'same'),kernel1D','same');
