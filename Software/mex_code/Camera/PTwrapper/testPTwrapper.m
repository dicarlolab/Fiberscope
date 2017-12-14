% Test PTwrapper
addpath('C:\Users\shayo\Dropbox (MIT)\Code\Github\FiberImaging\Code\mex');
FastUpSampling()

h=PTwrapper('Init');

PTwrapper('CameraStatus');

PTwrapper('SoftwareTrigger')

    Y=PTwrapper('GetBufferSize')
g=PTwrapper('GetGain')

e=PTwrapper('GetExposure')
f=PTwrapper('getFrameRate')
PTwrapper('TriggerOFF');
PTwrapper('TriggerON');
PTwrapper('ClearBuffer');

PTwrapper('SetExposure',1)

PTwrapper('SetGain',0)

while (1)
    X=PTwrapper('GetImageBuffer');
    round(mean(X(:)))
    if ~isempty(X)
        figure(11);
        clf;
        imagesc(mean(X,3),[0 1000]);
        drawnow
    end
end

figure(12);
clf;
plot(histc(double(Z(:)),0:4095));

PTwrapper('Release');
clear  PTwrapper