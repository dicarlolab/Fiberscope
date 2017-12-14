function [fiberBox, radius] = coreCalib_segmentFiber(opt)
cameraInitalized=CameraModule('IsInitialized');
if (~cameraInitalized)
    fprintf('Unable to initialize camera module\n');
    return
end
CameraModule('StopLiveView');

if ~FilterWheelModule('IsInitialized')
    fprintf('Unable to initialize filter wheel module\n');
    %return
end
FilterWheelWrapper('ShutterOFF');
CameraTriggerWrapper(1);

PTwrapper('SetExposure',1.0/opt.exposureForSegmtation); 
FilterWheelModule('SetNaturalDensity',[1,opt.naturalDensityForSegmentation]);

I=PTwrapper('GetImageBuffer'); % clear buffer
ALPuploadAndPlay(zeros(opt.height,opt.width)>0,200,100);
darkImages=PTwrapper('GetImageBuffer'); % clear buffer
%backgroundLevel = 1.1*mean(darkImages(:));
[~,L]=LeeHologram(zeros(opt.height,opt.width), opt.selectedCarrier, opt.carrierRotation);
zeroID=ALPwrapper('UploadPatternSequence',L);

I=PTwrapper('GetImageBuffer'); % clear buffer
res=ALPwrapper('PlayUploadedSequence',zeroID,1, 1);
WaitSecs(0.2);
I=PTwrapper('GetImageBuffer');
if isempty(I)
    fprintf('Camera driver error (no image). Is triggering cable connected?!?!?\n');
    return;
end

figure(1);clf;
image(I,'CDataMapping','scaled');
set(gca,'xlim',[0 size(I,2)],'ylim',[0 size(I,1)]);
set(gca,'clim',[0 4095]);
axis(gca,'off')
colormap(gca,'jet');

L=bwlabel(I>opt.backgroundLevel);
R=regionprops(L,{'MajorAxisLength','Area','Centroid','BoundingBox'});
if length(R) == 0
    fprintf('Unable to find a single connected component\n');
    return;
end
[maxArea,lab]=max(cat(1,R.Area));

fiberCenter = round(R(lab).Centroid);
radius = min(size(I,1)/2,round(min(R(lab).BoundingBox(3:4))/2));
  


% we try to keep the number of spots reasonable (i.e., ~40,000
% for things to fit later in memory. Crop radius if it is larger than
%maxSpotsAllowed = 40000;
maxRadiusAllowed = 113;
cropped = radius > maxRadiusAllowed;

radius = min(radius,maxRadiusAllowed);

if fiberCenter(1)+radius+1 > size(I,2) ||   fiberCenter(2)+radius+1 > size(I,1)
    radius = min(size(I,2)-fiberCenter(1)-1, size(I,1)-fiberCenter(2)-1);
end

if fiberCenter(1)-radius < 1 ||   fiberCenter(2)-radius < 1
    radius = min(fiberCenter(1)-1, fiberCenter(2)-1);
end

x0 = fiberCenter(1)-radius;
y0 = fiberCenter(2)-radius;
width = 2*radius+1;
height = 2*radius+1;

fiberBox= [x0,y0,width,height];% 2*ceil(round(R(lab).BoundingBox)/2); %[x0,y0, width, height];

[X,Y]=meshgrid(1:2*radius+1,1:2*radius+1);
binaryDisc = sqrt((X-(radius+1)).^2+(Y-(radius+1)).^2) <= radius;
afAngle = linspace(0,2*pi,50);
hold on;
plot(fiberCenter(1)+cos(afAngle)*radius,fiberCenter(2)+sin(afAngle)*radius,'g');
overExposed = sum(I(:) >= 4000) ;
if overExposed > 0
    fprintf('OVER EXPOSED (%d)! Fiber segmented. %d Spots. \n ', overExposed,sum(binaryDisc(:)));
else
    fprintf('Fiber segmented. %d Spots. \n ', sum(binaryDisc(:)));
end

