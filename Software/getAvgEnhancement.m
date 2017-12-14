function v = getAvgEnhancement(J, xx,yy,W)
[X,Y]=meshgrid(-64:63,-63:64);
Mask = X.^2+Y.^2 <= 64*64;
enhancement = zeros(1,length(xx));
for i=1:length(xx)
   JJ=J(:,:,i);
   xrange = min(128,max(1,xx(i)-W:xx(i)+W));
   yrange = min(128,max(1,yy(i)-W:yy(i)+W));
   subregion = JJ( yrange,xrange);
   localMask = Mask;
   localMask(yrange,xrange)=0;
   mm = max(subregion(:));
   elsewhere = nanmean(JJ(localMask));
   enhancement(i)=mm/elsewhere;
end
v=nanmean(enhancement);