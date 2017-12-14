function Dup=CreateDuplicationMatrix(height, numModesPerRow)
% Given a small matrix of size [numModesPerRow x numModesPerRow],
% duplicate it such that it will fit a larger array (height x height)
numPixelsPerMode = height / numModesPerRow;
% construct the duplication matrix
Dup = zeros(height, numModesPerRow);
for k=1:height
    Tmp = zeros(1,numModesPerRow);
    Tmp(1+floor((k-1)/numPixelsPerMode)) = 1;
    Dup(k,:) = Tmp;
end

return;