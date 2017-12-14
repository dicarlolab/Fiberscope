function timeAverage=TimeAverageMask(I, innerCircle)
nImages=size(I,3);
timeAverage=zeros(1,nImages);
for k=1:nImages
    II=double(I(:,:,k));
    timeAverage(k) = mean(II(innerCircle));
end
