ALPwrapper('Init');

B=ones(768,1024)>0;

id = ALPwrapper('UploadPatternSequence',B);

res=ALPwrapper('PlayUploadedSequence',id,1, 1);

ALPwrapper('ReleaseSequence',id);



Ham=PTwrapper('InitWithResolutionOffset',0,64*7,640,480);
PTwrapper('SetGain',0);
PTwrapper('SetExposure',1/20);

I=zeros(480,640);
J=PTwrapper('GetImageBuffer');
K = 50;
KK=0;
while KK < K
    PTwrapper('SoftwareTrigger');
    WaitSecs(0.1);
    J=PTwrapper('GetImageBuffer');
    if ~isempty(J)
        I=I+single(J);
        KK=KK+1;
        fprintf('%d\n',KK);
    end
end
I=I/KK;

cleanBiasImage = I;

figure(1);clf;
imagesc(cleanBiasImage)
addpath('C:\Users\shayo\Dropbox (MIT)\Code\Waveform Reshaping code\PublicLib\Bradley');

figure(11);
clf;
innerCircle=segmentCircle(I>706);
imagesc(innerCircle)

segmentedFiber=imfill(bradley(I, [15, 15],0.05) .*innerCircle);
figure(13);
clf;
imagesc(segmentedFiber);


[L,Nc]=bwlabel(segmentedFiber);
AvgResonse = zeros(size(L));
for i=1:Nc
    AvgResonse( L == i) = mean(I(L==i));
end

adjustMult = (max(AvgResonse(:))./AvgResonse) .* segmentedFiber;
adjustMult(~innerCircle)=0;

figure(11);
clf;
imagesc(adjustMult);myColorbar();

figure(11);
clf;
imagesc(I.*adjustMult);
impixelinfo
myColorbar()


save('E:\FiberBundleExperiments\TestingBeadsModel','adjustMult','cleanBiasImage');


% Test (?)



PTwrapper('SetGain',0);
PTwrapper('SetExposure',1/250);

figure(1);
clf;
while (1)
    PTwrapper('SoftwareTrigger');
    WaitSecs(0.5);
    J=mean(PTwrapper('GetImageBuffer'),3);
    if ~isempty(J)
        subplot(1,2,1);
        imagesc(J,[0 4095]);
        title('Raw');
        subplot(1,2,2);
        imagesc(single(J).*adjustMult,[0 6095]);
        title('Corrected');
        myColorbar
        drawnow
        fprintf('Trig\n');
        
    end
end