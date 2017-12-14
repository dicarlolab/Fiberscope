ISwrapper('Init');
ISwrapper('SetGain',0);
ISwrapper('SetExposure',20);


Baseline = zeros(480,640,5);
for k=1:5
    fprintf('Image %d\n',k);
    ISwrapper('SoftwareTrigger');
    while ISwrapper('GetBufferSize') == 0
    end
    Baseline(:,:,k)=ISwrapper('GetImageBuffer');
end

maxIntensity = 1450;
BaselineIntensity = mean(Baseline,3);
BaselineIntensity = medfilt2(BaselineIntensity,[2,2]);
BaselineIntensity(BaselineIntensity>maxIntensity) = maxIntensity;
BaselineIntensity=BaselineIntensity/maxIntensity;
innerCircle = imerode(BaselineIntensity>0.1,ones(2,2));
BaselineIntensity(~innerCircle)=0;

R=regionprops(innerCircle > 0);
CroppedCircle = BaselineIntensity(round(R.BoundingBox(2)):round(R.BoundingBox(2))+round(R.BoundingBox(4)+1),...
                                  round(R.BoundingBox(1)):round(R.BoundingBox(1))+round(R.BoundingBox(3)+2));


HighThres = CroppedCircle>0.5;
L=bwlabel(HighThres);
R=regionprops(L,'MajorAxis','Centroid','PixelIdxList');

% figure(11);
% clf;
% hist(cat(1,R.MajorAxisLength),100)

%% Simulate tissue under fiber


load('E:\0312_ZoomRight_20130212_125743_Tile');
PixelToUm = 1270/1024;
fiberDiamUm=140;

fiberImagedWidthPixels = size(CroppedCircle,2);
CameraPixelToUm = fiberDiamUm / fiberImagedWidthPixels;

averageCoreDiameterPix = mean(cat(1,R.MajorAxisLength));
averageCoreDiameterUm = averageCoreDiameterPix*CameraPixelToUm;
fprintf('Average core diameter in um:%.3f\n',averageCoreDiameterUm);

CenterY = 2420;
CenterX = 1495;

w=fiberDiamUm/2;
rangeMicrons = (-w:w)*PixelToUm;
Slab = sum(a4fTile(CenterY-w:CenterY+w, CenterX-w:CenterX+w,2,:),4);
ResampledRangeMicron = fiberDiamUm/2;
ResampledRange = -ResampledRangeMicron:CameraPixelToUm:ResampledRangeMicron;
[X,Y]=meshgrid(ResampledRange,ResampledRange);
ResampledMicrons = reshape(interp2(rangeMicrons,rangeMicrons,Slab,X(:),Y(:)),size(X));

Reconstruction = zeros(size(CroppedCircle));
for k=1:length(R)
    Reconstruction(R(k).PixelIdxList) = mean(ResampledMicrons(R(k).PixelIdxList));
end
figure(100);
clf;
subplot(1,2,1);
imagesc(ResampledMicrons);axis off
subplot(1,2,2);
imagesc(Reconstruction.*CroppedCircle);axis off
colormap gray
