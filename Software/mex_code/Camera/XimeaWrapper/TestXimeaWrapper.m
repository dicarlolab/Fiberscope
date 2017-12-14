% Test PTwrapper
addpath('C:\Users\shayo\Dropbox (MIT)\Code\Github\FiberImaging\Code\mex');

h=XimeaWrapper('InitWithResolutionOffset',0,0,128,128);
%h=XimeaWrapper('Init');

e=XimeaWrapper('GetBufferSize') % e*1e6 = exposure in usec


CalibrationModule();

ex=XimeaWrapper('GetExposure') % e*1e6 = exposure in usec

ex=XimeaWrapper('GetExposure') % e*1e6 = exposure in usec

 X=XimeaWrapper('GetImageBuffer');
  size(X)
 
figure(2);clf;
while(1)
    
     X=XimeaWrapper('GetImageBuffer');
     if (size(X,3) > 0)
        imagesc(X(:,:,end),[0 1024])
     end
     title(num2str(XimeaWrapper('getNumTrigs')));
     drawnow
 end


  XimeaWrapper('Release')

  %%
 
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