cd('C:\Users\shayo\OneDrive\Waveform Reshaping code\MEX\x64');
addpath('C:\Users\shayo\OneDrive\Waveform Reshaping code\ALP\ALPwrapper');
addpath('C:\Users\shayo\OneDrive\Waveform Reshaping code\Camera\ISwrapper');

% Define some important constants...
selectedCarrier = 0.1900;
DMDwidth = 1024;
DMDheight = 768;
effectiveDMDsize = min(DMDwidth,DMDheight);
referenceFraction = 0.35; % of area.
hadamardSize = 32; % (needs to be power of 2. Use 8,16,32,64
VERBOSE = 1;
%% DMD initialization
H=ALPwrapper('Init');
if (H)
    fprintf('Initialized Successfuly\n');
else
    fprintf('Initalization Failed!\n');
end
% setup a dummy phase to measure exposure times...
[~,L]=LeeHologram(zeros(768,1024), selectedCarrier);
zeroID=ALPwrapper('UploadPatternSequence',L);
res=ALPwrapper('PlayUploadedSequence',zeroID,1, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.


%% Camera initializations
Hcam=ISwrapper('Init'); % Initialize Camera
if (Hcam)
    fprintf('Initialized Camera successfuly\n');
else
    fprintf('Failed to initialize camera\n');
    return;
end

cameraRate = fnTestMaximalCameraAcqusitionRate();

% 
% initialExposure = 300;
% maxNumSaturated = 200;
% saturationValue = 3800;
% [optimalExposure,initialI]=fnAutoExposure(selectedCarrier,initialExposure,maxNumSaturated,saturationValue);
%% Get fiber mask
res=ALPwrapper('PlayUploadedSequence',zeroID,1, false);
I=ISwrapper('GetImageBuffer');
ISwrapper('SetExposure',1.0/1000.0); 
ISwrapper('SoftwareTrigger');
tic; while toc < 0.2; end;
I=ISwrapper('GetImageBuffer');
backgroundLevel=30;
L=bwlabel(I>backgroundLevel);
R=regionprops(L);
[~,lab]=max(cat(1,R.Area));
fiberBox= 2*ceil(round(R(lab).BoundingBox)/2); %[x0,y0, width, height];
figure(3);clf;imagesc(I(fiberBox(2):fiberBox(2)+fiberBox(4)-1,fiberBox(1):fiberBox(1)+fiberBox(3)-1));colorbar
%% Build basis functions.
% there is a subtle thing here. If we floor the lee block size, we get more
% reference. If we ceil, we get less reference. 
numReferencePixels=ceil((effectiveDMDsize-sqrt(1-referenceFraction)*effectiveDMDsize)/2); % on each side...
%(4*d*effectiveDMDsize-4*d*d) / (effectiveDMDsize*effectiveDMDsize)
leeBlockSize = ceil(((effectiveDMDsize-2*numReferencePixels) / hadamardSize)/2)*2;
numReferencePixels = (effectiveDMDsize-leeBlockSize*hadamardSize)/2;
numModes = hadamardSize*hadamardSize;
fprintf('Using %dx%d basis. Each uses %dx%d mirrors. Reference is %d pixels, which is %.3f of area\n',...
    hadamardSize,hadamardSize,leeBlockSize,leeBlockSize,numReferencePixels, (4*numReferencePixels*effectiveDMDsize-4*numReferencePixels*numReferencePixels)/(effectiveDMDsize*effectiveDMDsize));
% assert(2*numReferencePixels+leeBlockSize*hadamardSize == effectiveDMDsize)
walshBasis = fnBuildWalshBasis(hadamardSize); % returns hadamardSize x hadamardSize x hadamardSize^2
if VERBOSE
    fnPlotWalshBasis(walshBasis);
end;
phaseBasis = (walshBasis == 1)*pi;

% Phase shift the basis and append with a fixed reference.
probedInterferencePhases =  [0, pi/2, -pi/2];
numPhases = length(probedInterferencePhases);
% Generate the phase shifted and reference padded lee holograms.
interferenceBasisPatterns = fnPhaseShiftReferencePadLeeHologram(...
    phaseBasis, probedInterferencePhases, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);

%% upload test patterns to the DMD...
I=ISwrapper('GetImageBuffer'); %clear buffer
hadamardSequenceID=ALPwrapper('UploadPatternSequence',interferenceBasisPatterns);
fprintf('Playing calibration sequence, expected time : %.2f seconds (%.2f min) \n',size(interferenceBasisPatterns,3)/cameraRate,size(interferenceBasisPatterns,3)/cameraRate/60)
res=ALPwrapper('PlayUploadedSequence',hadamardSequenceID,cameraRate, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
I=ISwrapper('GetImageBuffer'); %clear buffer
assert(size(I,3) == size(interferenceBasisPatterns,3));
figure(11);clf;for k=1:size(interferenceBasisPatterns,3),    imagesc(I(:,:,k));    drawnow;end
ALPwrapper('ReleaseSequence',hadamardSequenceID);
% Crop / resize I to make things more compact (?)
quantization = 4;
J = I(fiberBox(2):quantization:fiberBox(2)+fiberBox(4)-1,fiberBox(1):quantization:fiberBox(1)+fiberBox(3)-1,:);
figure(11);clf;for k=1:size(interferenceBasisPatterns,3),    imagesc(J(:,:,k));    drawnow;end
newSize = size(J);

%% reconstruct the complex field
J=double(reshape(J, [newSize(1)*newSize(2), numModes,numPhases]));
K_obs = (2*J(:,:,1) - J(:,:,3)-J(:,:,2))./3 + 1i*(J(:,:,3) - J(:,:,2))./3;
Sval = mean(abs(K_obs),2);
Kinv=K_obs';%(diag(1./Sval)*K_obs)'; %K_obs'

% Generate a spot
SpotScanningSequence = zeros(768,1024,21*21,'uint8')>0;
cnt=1;
Targets = zeros(newSize(1),newSize(2),21*21);
for ii=-10:10
    for jj=-10:10
        
    Etarget = zeros(newSize(1),newSize(2));
    
    Etarget(ii+round(newSize(1)/2),jj+round(newSize(2)/2))=1;
    Targets (:,:,cnt)=Etarget;
    Ein_pre   = Kinv*Etarget(:);%./abs(conj(K_obs')*Etarget');
    Ein_phase =wrapToPi (angle(Ein_pre));
    WeightedInputToGenerateTarget = reshape(exp(1i*reshape(phaseBasis, numModes,numModes))* exp(1i*Ein_phase(:)),hadamardSize,hadamardSize);
    Ein=wrapTo2Pi(angle(WeightedInputToGenerateTarget));
    optimalPattern = fnPhaseShiftReferencePadLeeHologram(...
        Ein, 0, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
    SpotScanningSequence(:,:,cnt)=optimalPattern;
    cnt=cnt+1;
    end
end

Q=ISwrapper('GetImageBuffer'); %clear buffer
spotID=ALPwrapper('UploadPatternSequence',SpotScanningSequence);
res=ALPwrapper('PlayUploadedSequence',spotID,cameraRate, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
Q=ISwrapper('GetImageBuffer'); %clear buffer
ALPwrapper('ReleaseSequence',spotID);

figure(11);
clf;
for k=1:size(interferenceBasisPatterns,3)
    subplot(1,2,1);
    imagesc(Q(:,:,k));    
    subplot(1,2,2);
    imagesc(Targets(:,:,k));
    tic
    while toc < 0.1
    end
    drawnow;
end

% 

%%
ALPwrapper('ReleaseSequence',zeroID);
ALPwrapper('Release');
ISwrapper('Release');
