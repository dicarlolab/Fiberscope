function [initialExposure,meanX]=fnAutoExposure(selectedCarrier,initialExposure,maxNumSaturated,saturationValue)

[~,L]=LeeHologram(zeros(768,1024), selectedCarrier);
testID=ALPwrapper('UploadPatternSequence',L);
res=ALPwrapper('PlayUploadedSequence',testID,1, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
ALPwrapper('ReleaseSequence',testID);


gain=0;
ISwrapper('SetGain',gain);
%gain=ISwrapper('GetGain');
% exposure=ISwrapper('GetExposure');
% fprintf('Gain : %.2f, Exposure Time : 1/%.2f (%.5f Sec) \n',gain,1/exposure,exposure);

initialExposure = 300;
numImagesPerExposure = 10;
maxNumSaturated = 20;
saturationValue = 500;
exposureIncrement = 100;
maxExposure = 5000;
ISwrapper('SetExposure',1.0/initialExposure);

while (1)
    X=ISwrapper('GetImageBuffer');
    for k=1:numImagesPerExposure
        ISwrapper('SoftwareTrigger');
        tic
        while toc < 1/50
        end
    end
    X=ISwrapper('GetImageBuffer');
    meanX=double(mean(X,3));
    figure(1);clf;imagesc(meanX,[0 4096]);colorbar; colormap hot;axis off;drawnow
    numSaturated = sum(meanX(:) > saturationValue);
    if numSaturated > maxNumSaturated 
        fprintf('Tested 1/%d. Num saturated pixels: %d\n',initialExposure,numSaturated);
        initialExposure=initialExposure+exposureIncrement;
        if (initialExposure > maxExposure)
            break;
        end
        ISwrapper('SetExposure',1.0/initialExposure);
    else
        break;
    end
end

ISwrapper('SetExposure',1.0/initialExposure);
fprintf('Gain : %.2f, Exposure Time : 1/%.4f (%.5f Sec) \n',gain,1/initialExposure,initialExposure);


if 0
%%
X=ISwrapper('GetImageBuffer');
for k=1:500
    ISwrapper('SoftwareTrigger');
    tic
    while toc < 1/100
    end
end
X=ISwrapper('GetImageBuffer');
%%
figure(11);
clf;
clear M
for k=1:size(X,3)
    imagesc(X(:,:,k),[0 4096]);drawnow
    M(k)=mean(mean(X(:,:,k)));
end
colorbar
axis equal
% plot noise in individual pixels
meanX = mean(X,3);
stdX = std(double(X),[],3);
figure(2);clf;
h1=subplot(2,1,1);
imagesc(meanX,[0 4096]);
colorbar
h2=subplot(2,1,2);
imagesc(stdX./meanX*100);colorbar
linkaxes([h1,h2]);
impixelinfo
title('percent change (std/mean*100)');

figure(15);
hist(double(X(:)),5000);

figure(12);
clf;
%plot(M)
hist(M,50)
title('mean over time histogram')
figure(13);
plot(M)
end