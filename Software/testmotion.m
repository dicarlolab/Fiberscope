Hcam=ISwrapper('Init'); % Initialize Camera
if (Hcam)
    fprintf('Initialized Camera successfuly\n');
else
    fprintf('Failed to initialize camera\n');
    return;
end

%%
ISwrapper('SetExposure',1/4000.0);
ISwrapper('SoftwareTrigger');
tic
while toc < 0.4;
end
I0=ISwrapper('GetImageBuffer');
figure(3);imagesc(I0(:,:,1))


J=zeros(480,640,1000);
tm=zeros(1,8000);
diffI = zeros(1,8000);
cent = zeros(8000,2);
k=1;
%%
% 
% J=zeros(480,640,8000,'uint16');
% tm=zeros(1,8000);
% diffI = zeros(1,8000);

if ~exist('k','var')
    k0=1;
else
    k0=k;
end
for k=k0:8000
    for x=1:10
        ISwrapper('SoftwareTrigger');
        WaitSecs(0.1);
    end
    I=ISwrapper('GetImageBuffer');
    
    WaitSecs(0.5);
    tm(k)=GetSecs();
    J(:,:,k) = mean(I,3);
    diffI(k) = mean(mean(abs(double(J(:,:,k))-double(J(:,:,1)))));% / mean(mean(J(:,:,1)));
    
    L=bwlabel(J(:,:,k)>30);
    R=regionprops(L);
    [~,maxCC]=max(cat(1,R.Area));
    cent(k,:)=R(maxCC).Centroid;
    
    figure(1);
    clf;
    subplot(2,3,1);
    if k > 6
        imagesc(J(:,:,k)-J(:,:,k-5));
    end
    colorbar
    colormap gray
    set(gca,'xlim',[0 350],'ylim',[0 350]);
     subplot(2,3,2);
    timeSec = (tm(1:k)-tm(1))/60;
    plot(timeSec,diffI(1:k));
    set(gca,'xlim',[0.1 1+timeSec(end)]);
    xlabel('Minutes');
    title(sprintf('%d : %.4f',k,diffI(k)));
    
    subplot(2,3,3);
    imagesc(J(:,:,k));
   subplot(2,3,4);
    plot(timeSec,(cent(1:k,:)-repmat(cent(1,:),k,1)));
    drawnow
 
end


%%
J=J(:,:,1:6200);
tm=tm(1:6200);
diffI=diffI(1:6200);
savefast('E:\LongThermalExperiment','diffI','J','tm');

%%
load('E:\LongThermalExperiment');
MaxTimePoint = 6200;
StartTimeMinutes = 35; % ignore first 40 minutes. That's mirror stabilization issues.
ind = find(tm(1:MaxTimePoint)-tm(1) > StartTimeMinutes*60,1,'first');

t=tm(ind:MaxTimePoint)-tm(1);
f=diffI(ind:MaxTimePoint);
% fit an exponential function of the form s(1)+s(2)*exp(-t/s(3));
s=exp2fit(t,f,1);
fun = @(s,t) s(1)+s(2)*exp(-t/s(3));
tt=linspace(0,2*t(end),200);
ff=fun(s,tt);
figure(1), 
clf;
plot(t/60,f,'k.');
hold on;
plot(tt/60,ff,'r','LineWidth',2);
plot((tm(1:ind)-tm(1))/60,diffI(1:ind),'.','color',[0.5 0.5 0.5]);
xlabel('Minutes');
ylabel('Value proportional to changes in image');
title('Thermal effects on mode coupling');
legend('Data (after mirror settling)','Exponential fit','Data (before mirror settled)');

figure(3);
for k=MaxTimePoint-1000:10:MaxTimePoint
    imagesc(J(:,:,k));
    title(sprintf('%.2f minutes\n',(tm(k)-tm(1))/60));
    drawnow
end

while(1)
    imagesc(J(:,:,2000+randi(4000)));
    drawnow
end
%
% fs=conv(f,fspecial('gaussian',[1 100],15),'same');

%f=s1+s2*exp(-t/s3)
%%
figure(120);clf;
for k=1:1:k-1
    imagesc(double(J(:,:,k)));%-J(:,:,450)),[-100 100])
    title(num2str(k));
    set(gca,'xlim',[100 305],'ylim',[ 1 250]);
    drawnow    
end

figure(12);
clf;
