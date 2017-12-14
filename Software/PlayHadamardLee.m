dmd.hadamardSize=64;
dmd.numBasis = 4096;
walshBasis = fnBuildWalshBasis(dmd.hadamardSize, dmd.numBasis); % returns hadamardSize x hadamardSize x hadamardSize^2

phaseBasis = single((walshBasis == 1)*pi);
     dmd.carrierRotation = [125/180*pi, 0/180*pi];
    dmd.selectedCarrier = [0.2 0.200]; % 0.2
%%    
pattern=127;

dmd.leeBlockSize = 8;
dmd.numReferencePixels = (768- dmd.leeBlockSize*dmd.hadamardSize)/2;

    interferenceBasisPatterns = CudaFastLee(phaseBasis+0,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier(1), dmd.carrierRotation(1));
   
    figure(11);
    clf;
    imagesc(walshBasis(:,:,pattern)');
ALPuploadAndPlay(interferenceBasisPatterns(:,:,pattern),1,1);
axis equal
%%
[38,61]*2.8
3700/1280
2800/1024