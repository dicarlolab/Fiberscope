% function FastCarrierOptimization
N = 6;
% freqScan = linspace(0.15, 0.2, N);
% angleScan = linspace(100, 140,N);

freqScan = linspace(0.19, 0.23, N);
angleScan = linspace(170, 200,N);

% N = 3;
% freqScan = linspace(0.14, 0.16, N);
% angleScan = linspace(100, 110,N);

strctParams.numBlocks = 16; % dmd.hadamardSize
strctParams.numModes = 256; %dmd.numBasis
strctParams.numMirrorsPerMode = 40;
strctParams.numReferencePixels = (768 - strctParams.numBlocks*strctParams.numMirrorsPerMode)/2;
strctParams.currentColorChannel = 2;
strctParams.naturalDensityForCalibration = 2;
strctParams.exposureForCalibration = 3000;
strctParams.ND=1:5;
strctParams.testExposure=6000;
strctParams.subSample = 8;
probedInterferencePhases =  [0, pi/2, pi];
walshBasis = fnBuildWalshBasis(strctParams.numBlocks, strctParams.numBlocks*strctParams.numBlocks); % returns hadamardSize x hadamardSize x hadamardSize^2
phaseBasis = single((walshBasis == 1)*pi);
phaseBasisReal = single(reshape(real(exp(1i*phaseBasis)),strctParams.numBlocks*strctParams.numBlocks,strctParams.numModes));

%%
[X,Y]=meshgrid(-64:63,-63:64);
Mask = X.^2+Y.^2 <= 64*64;
SubSampled = zeros(size(Mask));
SubSampled(1:strctParams.subSample:end,1:strctParams.subSample:end) = true;
MaskSubSampled = SubSampled & Mask;
patternsToPlay = find(MaskSubSampled);
[yy,xx]=ind2sub([128,128],patternsToPlay);

%%
[F,A]=meshgrid(freqScan,angleScan);
Fc=F(:);
Ac=A(:);
numCalibs = length(Fc);
interferenceBasisPatterns = zeros(768,128, strctParams.numModes*3,numCalibs,'uint8');
for k=1:numCalibs
    fprintf('Generating Holograms... %d / %d\n',k,numCalibs);
    carrierFreq = Fc(k);
    carrierRot = Ac(k);
    interferenceBasisPatterns(:,:, 1:3:end,k) = CudaFastLee(phaseBasis+0,strctParams.numReferencePixels, strctParams.numMirrorsPerMode, carrierFreq, carrierRot/180*pi);
    interferenceBasisPatterns(:,:, 2:3:end,k) = CudaFastLee(phaseBasis+pi/2,strctParams.numReferencePixels, strctParams.numMirrorsPerMode,carrierFreq, carrierRot/180*pi);
    interferenceBasisPatterns(:,:, 3:3:end,k) = CudaFastLee(phaseBasis+pi,strctParams.numReferencePixels, strctParams.numMirrorsPerMode,carrierFreq, carrierRot/180*pi);
end    

%%
ALPwrapper('Release');
ALPwrapper('Init');
CameraModule('StopLiveView');
FilterWheelModule('SetNaturalDensity',[strctParams.currentColorChannel, strctParams.naturalDensityForCalibration]);  
PTwrapper('SetExposure',1.0/strctParams.exposureForCalibration);
PTwrapper('StopAveraging');
WaitSecs(0.5);
I=PTwrapper('GetImageBuffer');
WaitSecs(0.5);
for k=1:numCalibs
    fprintf('Running calib... %d / %d\n',k,numCalibs);
    ALPuploadAndPlay(interferenceBasisPatterns(:,:,:,k),850,1);
end
WaitSecs(0.5);
numI=PTwrapper('GetBufferSize');
I=PTwrapper('GetImageBuffer');
I=single(reshape(I, 128,128, strctParams.numModes*3, numCalibs));


%% Reconstruct
holograms= zeros(768,128, length(patternsToPlay), numCalibs,'uint8');
for k=1:numCalibs
    fprintf('Reconstructing... %d / %d\n',k,numCalibs);
    carrierFreq = Fc(k);
    carrierRot = Ac(k);
    Kinv_angle=reshape(atan2((I(:,:,2:3:end,k))-(I(:,:,3:3:end,k)), ...
                (I(:,:,1:3:end,k))-(I(:,:,2:3:end,k))), ...
                128*128 ,strctParams.numModes)';
    Sk = phaseBasisReal* sin(Kinv_angle(:,patternsToPlay)); 
    Ck = phaseBasisReal* cos(Kinv_angle(:,patternsToPlay)); 
    Ein=atan2(Sk,Ck);
    inputPhases=reshape(Ein, strctParams.numBlocks,strctParams.numBlocks,  size(Ein,2));
    holograms(:,:,:,k) = CudaFastLee(inputPhases,strctParams.numReferencePixels, strctParams.numMirrorsPerMode, carrierFreq, carrierRot/180*pi);
end
  
%% Sample          
holograms=reshape(holograms, 768,128, length(patternsToPlay)* numCalibs);
HDRimage=HDR(holograms,  strctParams.ND, strctParams.testExposure,strctParams.currentColorChannel);
HDRimage=reshape(HDRimage, 128,128,  length(patternsToPlay), numCalibs);

%% Compute average enhancement
W=5;
for k=1:numCalibs
    avgEnh(k) = getAvgEnhancement(HDRimage(:,:,:,k), xx,yy, W);
end
figure(12);
clf;
imagesc(freqScan, angleScan, reshape(avgEnh,N,N));
[~,iopt]=max(avgEnh);
fprintf('Optimal Frequency: %.2f, Optimal Rotation: %.2f\n',Fc(iopt),Ac(iopt))
