function Y=HP(X, gaussianWidth)
if gaussianWidth == 0
    Y = X;
    return;
end
kernel2D = padarray(2,[10*gaussianWidth/2 10*gaussianWidth/2]) - fspecial('gaussian',[1+10*gaussianWidth 1+10*gaussianWidth],gaussianWidth);
Y=convn(single(X),kernel2D,'same');

