 addpath('C:\Users\shayo\Dropbox (MIT)\Code\Waveform Reshaping code\MEX\x64');
ALPwrapper('Init');
 %%
 DMDwidth = 1024;
 DMDheight = 768;
numReferencePixels = 128;
leeBlockSize = 8;
selectedCarrier = 0.19;
%% 
Pat = single(rand(64,64)*pi);

% Pat = single(zeros(64,64)*pi);

T = fnPhaseShiftReferencePadLeeHologram(Pat, 0, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
[testID, packedInput]=ALPwrapper('UploadPatternSequence',T);
figure(1);clf;imagesc(packedInput)

packedFast = FastLeeHologram(Pat, numReferencePixels, leeBlockSize, selectedCarrier);
figure(2);clf;imagesc(packedFast)

D=packedFast-packedInput;
figure(3);clf;imagesc(D)

packedFast2 = zeros(768,128);
cnt=1;
for y=1:768
    for x=1:128
        packedFast2(y,x) = D( cnt);
        cnt=cnt+1;
    end
end

 phaseTest = rand(64,64)*pi;

phaseTest=single(phaseTest);
phaseTestAccurate = fnPhaseShiftReferencePadLeeHologram(phaseTest, 0, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);


[testID, packedInput]=ALPwrapper('UploadPatternSequence',phaseTestAccurate);
res=ALPwrapper('PlayUploadedSequence',testID,10, 1);
ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.


[testID2]=ALPwrapper('UploadPatternSequence',packedInput);
res=ALPwrapper('PlayUploadedSequence',testID2,10, 1);
ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.




phaseTestFast = FastLeeHologram(phaseTest, numReferencePixels, leeBlockSize, selectedCarrier);
testID2=ALPwrapper('UploadPatternSequence',phaseTestFast);
res=ALPwrapper('PlayUploadedSequence',testID2,10, 1);
ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.

 %%
 
 inputPhases = single(rand(64,64,10000));
A=GetSecs();
SweepSequence = FastLeeHologram(inputPhases, numReferencePixels, leeBlockSize, selectedCarrier);
B=GetSecs();
B-A
 
 R = rand(64,64,12000);

A1=GetSecs();
 R1=FastLeeHologram(R, 128, 8, 0.190);
B1=GetSecs();

A2=GetSecs();
 R2 = fnPhaseShiftReferencePadLeeHologram(R, 0, 128, 8,1024,768,0.190);
 B2=GetSecs();
 
 A3=GetSecs();
 R3=CudaLeeHologram(R, 128, 8, 0.190);
 B3=GetSecs();
 
 fprintf('Mex : %.2f\n',B1-A1);
 fprintf('Matlab : %.2f\n',B2-A2);
 fprintf('CUDA: %.2f\n',B3-A3);

sum(abs(R1(:)-R2(:))) 
 sum(abs(R3(:)-R2(:)))
 
 clear diffX
 for k=1:size(R1,3)
    diffX(k)=sum(sum(abs(R1(:,:,k)- R2(:,:,k))));
 end
 diffX
 
B1(129,129)
B2(129,129)

figure(11);
clf;
imagesc(double(B1)-double(B2))
colorbar
figure(1);
clf;
imagesc(double(B1));
figure(2);
clf;
imagesc(double(B2));
