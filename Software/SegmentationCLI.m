function [ok, strctSegmentation]=SegmentationCLI(segmentationParams, hAxesForPlottingResult)

ok = false;
cameraInitalized=CameraModule('IsInitialized');
if (~cameraInitalized)
    fprintf('Unable to initialize camera module');
    return
end
CameraModule('StopLiveView');
% figure(handles.figure1);

if ~FilterWheelModule('IsInitialized')
    fprintf('Unable to initialize filter wheel module');
    %return
end
bGreen = segmentationParams.hCalibrateGreen;
bBlue= segmentationParams.hCalibrateBlue;
UseBlue = (bBlue && bGreen) || bBlue;
FilterWheelWrapper('ShutterON',1);
FilterWheelWrapper('ShutterON',2);
CameraTriggerWrapper(1);
%dmd = handles.dmd;
XimeaWrapper('SetExposure',1.0/segmentationParams.exposureForSegmtation); 
if (UseBlue)
    FilterWheelModule('SetNaturalDensity',[1, segmentationParams.naturalDensityForSegmentation(1)]);
    FilterWheelWrapper('ShutterOFF',1);
else
    FilterWheelModule('SetNaturalDensity',[2, segmentationParams.naturalDensityForSegmentation(2)]);
    FilterWheelWrapper('ShutterOFF',2);
end
% figure(handles.figure1);
I=XimeaWrapper('GetImageBuffer'); % clear buffer
ALPuploadAndPlay(segmentationParams.ALPID,zeros(segmentationParams.dmdHeight,segmentationParams.dmdWidth)>0,200,100);
WaitSecs(0.2);
darkImages=XimeaWrapper('GetImageBuffer'); % clear buffer
backgroundLevel = 1.1*mean(darkImages(:));




randPhase=2*pi*rand(64,64);
if (UseBlue)
    L = CudaFastLee(single(randPhase),segmentationParams.numReferencePixels, segmentationParams.leeBlockSize,segmentationParams.selectedCarrier(1), segmentationParams.carrierRotation(1));
    %[~,L]=LeeHologram(zeros(segmentationParams.dmdHeight,segmentationParams.dmdWidth), segmentationParams.selectedCarrier(1), segmentationParams.carrierRotation(1)); 
else
    L = CudaFastLee(single(randPhase),segmentationParams.numReferencePixels, segmentationParams.leeBlockSize, segmentationParams.selectedCarrier(2), segmentationParams.carrierRotation(2)); 
    %[~,L]=LeeHologram(pi*ones(segmentationParams.dmdHeight,segmentationParams.dmdWidth), segmentationParams.selectedCarrier(2), segmentationParams.carrierRotation(2)); 
end
zeroID=ALPwrapper('UploadPatternSequence',segmentationParams.ALPID,L);
I=XimeaWrapper('GetImageBuffer'); % clear buffer
res=ALPwrapper('PlayUploadedSequence',segmentationParams.ALPID,zeroID,1, 1);
WaitSecs(0.2);
I=XimeaWrapper('GetImageBuffer');
if isempty(I)
    fprintf('Camera driver error (no image). Check that 1) triggering cable is connected. 2) Camera trigger module is ON.\n');
    return;
end
ALPwrapper('ReleaseSequence',segmentationParams.ALPID,zeroID);

if ~isempty(hAxesForPlottingResult)
    cla(hAxesForPlottingResult)
    hImage = image(I,'parent',hAxesForPlottingResult,'CDataMapping','scaled');
    set(hAxesForPlottingResult,'xlim',[0 size(I,2)],'ylim',[0 size(I,1)]);
    set(hAxesForPlottingResult,'clim',[0 1024]);
    axis(hAxesForPlottingResult,'off')
    colormap(hAxesForPlottingResult,'jet');
end

L=bwlabel(I>backgroundLevel);
R=regionprops(L,{'MajorAxisLength','Area','Centroid','BoundingBox'});
if length(R) == 0
    fprintf('Unable to find a single connected component');
    return;
end
[maxArea,lab]=max(cat(1,R.Area));

if 0
    
    fiberCenter = [size(I,1)/2, size(I,2)/2];
    radius = 63;
else
fiberCenter = round(R(lab).Centroid);
radius = min(size(I,1)/2,round(min(R(lab).BoundingBox(3:4))/2));
    
end

% we try to keep the number of spots reasonable (i.e., ~40,000
% for things to fit later in memory. Crop radius if it is larger than
%maxSpotsAllowed = 40000;
maxRadiusAllowed = 128;
cropped = radius > maxRadiusAllowed;

if get(segmentationParams.hFullFOV,'value')
    fiberCenter(1) = size(I,1)/2;
    fiberCenter(2) = size(I,2)/2;
    radius =  size(I,1)/2 -1;
end

strctSegmentation.radius = min(radius,maxRadiusAllowed);

if fiberCenter(1)+strctSegmentation.radius+1 > size(I,2) ||   fiberCenter(2)+strctSegmentation.radius+1 > size(I,1)
    strctSegmentation.radius = min(size(I,2)-fiberCenter(1)-1, size(I,1)-fiberCenter(2)-1);
end

if fiberCenter(1)-strctSegmentation.radius < 1 ||   fiberCenter(2)-strctSegmentation.radius < 1
    strctSegmentation.radius = min(fiberCenter(1)-1, fiberCenter(2)-1);
end

% fiberCenter(2)+handles.dmd.radius

% [X,Y]=meshgrid(1:2*handles.dmd.radius+1,1:2*handles.dmd.radius+1);
% binaryDisc = sqrt((X-(handles.dmd.radius+1)).^2+(Y-(handles.dmd.radius+1)).^2) <= handles.dmd.radius;
% sum(binaryDisc(:))

x0 = fiberCenter(1)-strctSegmentation.radius;
y0 = fiberCenter(2)-strctSegmentation.radius;
width = 2*strctSegmentation.radius+1;
height = 2*strctSegmentation.radius+1;

fiberBox= [x0,y0,width,height];% 2*ceil(round(R(lab).BoundingBox)/2); %[x0,y0, width, height];

[X,Y]=meshgrid(1:2*strctSegmentation.radius+1,1:2*strctSegmentation.radius+1);
binaryDisc = sqrt((X-(strctSegmentation.radius+1)).^2+(Y-(strctSegmentation.radius+1)).^2) <= strctSegmentation.radius;
%pixelSizeUm = dmd.fiberDiameterUm/(2*strctSegmentation.radius+1);
afAngle = linspace(0,2*pi,50);

if ~isempty(hAxesForPlottingResult)
    hold(hAxesForPlottingResult,'on');
    plot(hAxesForPlottingResult,fiberCenter(1)+cos(afAngle)*strctSegmentation.radius,fiberCenter(2)+sin(afAngle)*strctSegmentation.radius,'g');
end
% if (cropped)
%     displayMessage(handles,sprintf('Cropping max region to allow no more than 40k spots'));
% else
overExposed = sum(I(:) >= 1020) ;
if overExposed > 0
    fprintf('OVER EXPOSED (%d)! Fiber segmented. %d Spots. \n ', overExposed,sum(binaryDisc(:)));
else
    fprintf('Fiber segmented. %d Spots. \n ', sum(binaryDisc(:)));
end
% end

strctSegmentation.fiberBox = fiberBox;
strctSegmentation.fiberCenter = fiberCenter;
strctSegmentation.rawImage= I;
strctSegmentation.binaryDisc= binaryDisc;
strctSegmentation.overExposed = overExposed;
ok=true;
return
