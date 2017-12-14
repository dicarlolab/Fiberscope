ISwrapper('Init');
ISwrapper('SetGain',16);
ISwrapper('SetExposure',8.0);

I=zeros(480,640);
for k=1:10
    fprintf('%d\n',k);
    ISwrapper('SoftwareTrigger');
    while ISwrapper('GetBufferSize') == 0,
    end
    I=I+single(ISwrapper('GetImageBuffer'));
end
I=I/10;

cleanBiasImage = I;

figure(11);
clf;
innerCircle=segmentCircle(I>340);
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
imagesc(adjustMult);colorbar

figure(11);
clf;
imagesc(I.*adjustMult);
impixelinfo
colorbar

save('E:\FiberBundleExperiments\GCaMP6s Mouse 7b\fiberModel','adjustMult','cleanBiasImage');
