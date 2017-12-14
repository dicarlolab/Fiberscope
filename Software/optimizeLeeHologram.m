N = 50;

freqScan = linspace(0.11,0.23,N);
angleScan = linspace(85,150,N);

[F,A]=meshgrid(freqScan,angleScan);
Fc=F(:);
Ac=A(:);


numReferencePixels = 64;
leeBlockSize = 10;
zeroPhase=zeros(64,64, length(Fc));
% prepare holograms
interferenceBasisPatterns = CudaFastLee(single(zeroPhase),numReferencePixels, leeBlockSize,Fc, Ac/180*pi);   

CameraModule('StopLiveView')

I=PTwrapper('GetImageBuffer');

ALPuploadAndPlay(interferenceBasisPatterns,400,1);
WaitSecs(.5);
I=PTwrapper('GetImageBuffer');
if size(I,3) == N*N
    
    M = squeeze(mean(mean(I,1),2));
    M2D=reshape(M, size(F));
    figure(11);clf;imagesc(freqScan, angleScan,M2D);
    xlabel('Carrier Frequency');
    ylabel('Rotation Angle');
    colorbar
    [MM,index]=max(M(:));
    fprintf('Max: %.2f , Optimal frequency: %.2f, Optimal Rotation : %.2f\n', MM,Fc(index),Ac(index));
else
    fprintf('Error. Image Mismatch\n');
end

