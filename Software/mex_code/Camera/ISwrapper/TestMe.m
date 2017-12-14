cd('C:\Users\shayo\Dropbox (MIT)\Code\Waveform Reshaping code\MEX\x64');
H=ISwrapper('Init');
if (H)
    fprintf('Initialized Successfuly\n');
else
    fprintf('Initalization Failed!\n');
end

ISwrapper('Release');

ISwrapper('getNumTrigs')
ISwrapper('getFrameRate')
ISwrapper('setFrameRate',120)

for k=1:100
    ISwrapper('SoftwareTrigger');
    tic
    while toc < 0.1
    end
end

gain=ISwrapper('GetGain');
exposure=ISwrapper('GetExposure');
fprintf('Gain : %.2f, Exposure Time : 1/%.2f (%.5f Sec) \n',gain,1/exposure,exposure);

ISwrapper('SetExposure',1/5000);

X=ISwrapper('GetImageBuffer');
whos X


N=ISwrapper('GetBufferSize')

figure(1);
clf;
for k=1:size(X,3)
subplot(2,1,1);
imagesc(X(:,:,k))
colormap jet
colorbar
subplot(2,1,2);
Tmp=double(X(:,:,k));
hist(Tmp(:),0:4096);
drawnow
end



figure(3);
clf;

for g=1:700
    fprintf('Setting gain to %d\n',g);
    ISwrapper('SetGain',g);
    ISwrapper('SoftwareTrigger');
    while (1)
        N=ISwrapper('GetBufferSize');
        if N > 0
            break;
        end
    end
    X=ISwrapper('GetImageBuffer');
    for k=1:size(X,3)
        imagesc(((X(:,:,k))))
        title(num2str(g));
        drawnow
        tic
        while toc < 0.1
        end
    end
end




E=ISwrapper('GetExposure');

ISwrapper('Release');
