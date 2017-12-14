PTwrapper('SetGain',0)

PTwrapper('SetExposure',1/1540)
figure(20);clf;
% h=imagesc(zeros(256,256),[00 4095]);
h=imagesc(zeros(1200,1920),[00 4095]);
while (1)
    PTwrapper('SoftwareTrigger');
    WaitSecs(0.1);
    I=PTwrapper('GetImageBuffer');
    if ~isempty(I)
        set(h,'cdata',I(:,:,end));
        title(datestr(now))
        drawnow
    end
end

set(gca,'xlim',[0 256],'ylim',[0 256])
%%
floor([get(gca,'xlim'),get(gca,'ylim')]/64)*64
floor(748/64)*64
floor(470/64)*64



ALPwrapper('Init');

Ham=PTwrapper('InitWithResolutionOffset',0,0,256,256);

PTwrapper('Release')

Ham=PTwrapper('InitWithResolutionOffset',0,0,1920,1200);

[x,y]=ginput(2)

sqrt(diff(x).^2+diff(y).^2)

[~,L]=LeeHologram(zeros(768,1024),0.19);

B=L;
B(200:300,200:300)=false;
B(400:500,200:300)=false;

% B=zeros(768,1024)>0;
% W =768/2;
% yrange = min(768,max(1,768/2-W:768/2+W));
% xrange = min(1024,max(1,1024/2-W:1024/2+W));
% B(yrange, xrange) = L(yrange,xrange);


O=ones(768,1024)>0;
ALPuploadAndPlay(B,1,1);

ALPuploadAndPlay(O,1,1);

figure;imagesc(B)
