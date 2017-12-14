function innerCircle=segmentCircle(bin)
[L,Nc]=bwlabel(bin);
aiHist=histc(L(:),1:Nc);
[~,indx]=max(aiHist);
bin=L==indx;
R=regionprops(bin,'ConvexImage','BoundingBox');
R.BoundingBox=round(R.BoundingBox);
innerCircle=zeros(size(bin))>0;
innerCircle(R.BoundingBox(2):R.BoundingBox(2)+R.BoundingBox(4)-1,...
    R.BoundingBox(1):R.BoundingBox(1)+R.BoundingBox(3)-1) = R.ConvexImage;

