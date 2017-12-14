while (1)
ALPuploadAndPlay(zeros(768,1024)>0,1,1);
ALPuploadAndPlay(ones(768,1024)>0,1,1);
end

Z = zeros(768,1024) > 0;
%Z(1:768/2,:)=true;
Z(768/2:end,:)=true;

f1 = 30;
f2 = 30;
% Z = zeros(768,1024) > 0;
X = [ones(1,f1),zeros(1,f1)];
Y=repmat(X, [1, ceil(1024/length(X))]);
Z1=repmat(Y(1:1024),[768,1])>0;

X = [ones(1,f2),zeros(1,f2)];
Y=repmat(X, [1, ceil(768/length(X))]);
Z2=repmat(Y(1:768)',[1,1024])>0;


while (1)
ALPuploadAndPlay(Z1,1,1);

ALPuploadAndPlay(Z2,1,1);
% ALPuploadAndPlay(zeros(768,1024)>0,1,1);
% ALPuploadAndPlay(ones(768,1024)>0,1,1);

end

while (1)
randPhase=2*pi*rand(64,64);
numReferencePixels = 128;
leeBlockSize = 8;
DMDwidth = 1024;
DMDheight = 768;
selectedCarrier = 0.35;
interferenceBasisPatterns = fnPhaseShiftReferencePadLeeHologram(randPhase, 0, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);

H = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize, selectedCarrier, 55/180*pi);
%ALPuploadAndPlay(interferenceBasisPatterns,1,1);
while(1)
%     
%     ALPuploadAndPlay(ones(768,1024)>0,1,1);
    for kk=linspace(0.05,0.7,10)
        H = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize, kk, 0/180*pi);
        ALPuploadAndPlay(H,5,1);
    end
end

H = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize, 0.2, 0/180*pi);
    ALPuploadAndPlay(H,1,1);

2.4 * 40/4.5
% 40, 2.75 => 35 mm
