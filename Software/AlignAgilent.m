function AlignAgilent()
CameraModule('StopLiveView');
WaitSecs(0.1);
PTwrapper('GetImageBuffer'); % clear buffer

PTwrapper('SoftwareTrigger'); 
WaitSecs(0.5);
I0=PTwrapper('GetImageBuffer');
I0(1,1:2)=0; % zero timestamp
[~,maxLocation]=max(I0(:));
[yy,xx]=ind2sub(size(I0),maxLocation);

N=150;
[Res,parsedResponse] = AgilisWrapper('RelativeMove',N); % move ~50um down?
WaitSecs(2);

range = round(1.3*N:4*N);

[Res,parsedResponse] = AgilisWrapper('RelativeMove',-range(1));

WaitSecs(1);

for k=1:length(range)
    [Res,parsedResponse] = AgilisWrapper('RelativeMove',-1);
    PTwrapper('SoftwareTrigger'); 
    WaitSecs(0.05);
end

I=PTwrapper('GetImageBuffer');

% Compute correlation with I0
subI0 = double(I0(yy-20:yy+20,xx-20:xx+20));
corrValue = zeros(1, size(I,3));
for k=1:size(I,3)
    Ik = double(I(:,:,k));
    subIk = Ik(yy-20:yy+20,xx-20:xx+20);
    corrValue(k)=corr(subIk(:),subI0(:));
end
smoothCorr = conv2(corrValue,fspecial('gaussian',[1 20],3),'same');
[fMaxCorr, Index]=max(smoothCorr);

figure(12);
clf;
plot(range,corrValue,'k');hold on;
plot(range,smoothCorr,'r');
plot(range([Index, Index]),[0 corrValue(Index)],'g');
fprintf('Best correlation (%.2f) at %d, Ratio = %.5f\n',fMaxCorr, range(Index), range(Index)/N);

AgilisWrapper('SetCorrectionFactor', range(Index)/N);
