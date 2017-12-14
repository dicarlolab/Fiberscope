function writeVideo(name, I, range,imageTime, stimulus,circle)
writerObj = VideoWriter(name);
writerObj.FrameRate = 30;
open(writerObj);
figure(1000);
clf;
set(gca,'nextplot','replacechildren');
set(gcf,'Renderer','zbuffer');
th=linspace(0,2*pi,100);
x=circle.Centroid(1)+cos(th)*circle.MajorAxisLength/2;
y=circle.Centroid(2)+sin(th)*circle.MajorAxisLength/2;
for k = 1:1:size(I,3)
  
   hold off;
    %imagesc(strctRun.images(:,:,k),[0 2000]);
    imagesc(I(:,:,k),range);
   %imagesc(imagesCorrected(:,:,k),[-50 300]);
   hold on;
   text(40,30, sprintf('%.2f sec',imageTime(k)),'color','w');
   if (stimulus(k))
       %rectangle('Position',[0 0 20 20],'facecolor','w');
       plot(x,y,'w','LineWidth',2);
   end
   axis off
   frame = getframe;
   writeVideo(writerObj,frame);
end

close(writerObj);
