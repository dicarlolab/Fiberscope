try
PTwrapper('Release');
catch
end
    
PTwrapper('InitWithResolutionOffset',0,0,1920,1200,0,0);
while (1)
PTwrapper('SoftwareTrigger');
WaitSecs(0.2);
I=PTwrapper('GetImageBuffer');
if ~isempty(I)
    figure(11);
    clf;
    imagesc(I)
    drawnow
end
WaitSecs(0.2);
end
thres = 300;
imagesc(I>thres)
R=regionprops(bwlabel(I>thres),'Centroid','Area')
[~,maxRegion]=max(cat(1,R.Area));
round(R(maxRegion).Centroid)
PTwrapper('Release');
