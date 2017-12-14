function fnPlotWalshBasis(walshBasis)
n=size(walshBasis,1);
%figure(1);
clf;
ahAxis = tight_subplot(n,n,[.01 .01],[.1 .01],[.01 .01]);
for i=1:n
    for j=1:n
        idx = (i-1)*(n)+j;
        imagesc(walshBasis(:,:,idx),'parent',ahAxis(idx));
        axis(ahAxis(idx),'off');
    end
end
colormap gray
