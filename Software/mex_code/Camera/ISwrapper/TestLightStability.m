strFile = 'E:\Videos\video0002 14-09-09 11-37-59.avi'

Hc=ISwrapper('Init');
if (H)
    fprintf('Initialized Successfuly\n');
else
    fprintf('Initalization Failed!\n');
end


for k=1:100
    ISwrapper('SoftwareTrigger');
    tic
    while toc < 1/100
    end
end

gain=ISwrapper('GetGain');
exposure=ISwrapper('GetExposure');
fprintf('Gain : %.2f, Exposure Time : 1/%.2f (%.5f Sec) \n',gain,1/exposure,exposure);

ISwrapper('SetExposure',1/5000);

X=ISwrapper('GetImageBuffer');
whos X


N=ISwrapper('GetBufferSize')
% 
% 
% Hc=ISwrapper('Init'); % Initialize Camera
% ISwrapper('SetGain',0);
% ISwrapper('SetExposure',1/250);
% 
% 
% 
% xyloObj = VideoReader(strFile);
% 
% nFrames = xyloObj.NumberOfFrames;
% vidHeight = xyloObj.Height;
% vidWidth = xyloObj.Width;
% 
% I = read(xyloObj,1);
% 
% figure(11);
% clf;
% imagesc(I)
% max(I(:))
% movie(hf, mov, 1, xyloObj.FrameRate);
