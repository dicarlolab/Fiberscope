strDropBoxFolder = 'C:\Users\shayo\Dropbox';

cd([strDropBoxFolder,'\Code\Waveform Reshaping code\MEX\x64']);
addpath([strDropBoxFolder,'\Code\Waveform Reshaping code\ALP\ALPwrapper']);
addpath([strDropBoxFolder,'\Code\Waveform Reshaping code\Camera\ISwrapper']);

% Define some important constants...
selectedCarrier = 0.1900;
DMDwidth = 1024;
DMDheight = 768;
cameraWidth = 640;
cameraHeight = 480;
effectiveDMDsize = min(DMDwidth,DMDheight);
hadamardSize = 64; % (needs to be power of 2. Use 8,16,32,64
fiberDiameterUm = 100; % um

VERBOSE = 0;
spotID = -1;
FORCE_BASIS = 0;
STABILITY_TEST = 0;
USE_DAQ = 0;
hadamardSequenceID = -1;
SweepSequenceID = -1;
%% DMD initialization
H=ALPwrapper('Init');
if (H)
    fprintf('Initialized DMD Successfuly\n');
else
    fprintf('Failed to initialize DMD!\n');
end
%% DAQ initialization
if (USE_DAQ )
    res = fnDAQusb('Init',0,20000);
    if (res == 0)
        fprintf('Initialized DAQ Successfuly\n');
    else
        fprintf('Failed to initialize DAQ!\n');
    end
end

%% Camera initializations
Hcam=ISwrapper('Init'); % Initialize Camera
if (Hcam)
    fprintf('Initialized Camera successfuly\n');
else
    fprintf('Failed to initialize camera\n');
    return;
end
%%
% cameraRate=fnTestMaximalCameraAcqusitionRate();
cameraRate = 95;%
exposureForSegmtation = 1.0/1000.0;
exposureForCalibration = 1.0/1000.0;
ISwrapper('SetGain',0); 

%% Measure read-out noise (baseline)
% 
% for measuring enhancement (subtract baseline)
offID=ALPwrapper('UploadPatternSequence',false(768,1024));

% setup a dummy phase to measure exposure times...
[~,L]=LeeHologram(zeros(DMDheight,DMDwidth), selectedCarrier);
zeroID=ALPwrapper('UploadPatternSequence',L);
res=ALPwrapper('PlayUploadedSequence',zeroID,1, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.

%%
if 0
    for k=1:100
        ALPwrapper('PlayUploadedSequence',zeroID,1, false);
        WaitSecs(0.2);
        ALPwrapper('PlayUploadedSequence',offID,1, false);
        WaitSecs(0.2);
    end
end


%% automatic segmentation of a bounding box around the fiber
%    while (1)

ISwrapper('SetExposure',exposureForSegmtation); 
I=ISwrapper('GetImageBuffer'); % clear buffer
res=ALPwrapper('PlayUploadedSequence',zeroID,1, false);
% ISwrapper('SoftwareTrigger');
while (ISwrapper('GetBufferSize') == 0), end;
I=ISwrapper('GetImageBuffer');


    figure(3);
    clf;
    imagesc(I,[0 4096]);
    drawnow
%   
%    end

backgroundLevel=50;
L=bwlabel(I>backgroundLevel);
R=regionprops(L,{'MajorAxisLength','Area','Centroid','BoundingBox'});
[~,lab]=max(cat(1,R.Area));
fiberBox= 2*ceil(round(R(lab).BoundingBox)/2); %[x0,y0, width, height];
if fiberBox(2)+fiberBox(4) > size(I,1)
    fiberBox(4) = size(I,1)-fiberBox(2);
end
if fiberBox(1)+fiberBox(3) > size(I,2)
    fiberBox(3) = size(I,1)-fiberBox(1);
end
numPixels = mean(fiberBox(3:4));
pixelSizeUm = fiberDiameterUm/numPixels;
fiberCenter = R(lab).Centroid;
fiberDiameterPix = R(lab).MajorAxisLength;

figure(3);clf;set(3,'position',[177         528        1496         450]);
subplot(1,2,1);imagesc(I(fiberBox(2):fiberBox(2)+fiberBox(4)-1,fiberBox(1):fiberBox(1)+fiberBox(3)-1),[0 4096]);colorbar;drawnow;
subplot(1,2,2);
imagesc(I,[0 4096]);
afAngle = linspace(0,2*pi,50);
hold on;
plot(fiberCenter(1)+cos(afAngle)*fiberDiameterPix/2,fiberCenter(2)+sin(afAngle)*fiberDiameterPix/2,'g');
fprintf('1 Pixel = %.2f microns\n ', fiberDiameterUm/fiberDiameterPix)

%% Measure stability
if (STABILITY_TEST)
    ISwrapper('SetExposure',1/2000.0);
    
    I=ISwrapper('GetImageBuffer'); % clear buffer
    %res=ALPwrapper('PlayUploadedSequence',zeroID,1, false);
    ISwrapper('SoftwareTrigger');
    while (ISwrapper('GetBufferSize') == 0), end;
    I0=ISwrapper('GetImageBuffer');
    aiYrange = [fiberBox(2):fiberBox(2)+fiberBox(4)-1];
    aiXrange = [fiberBox(1):fiberBox(1)+fiberBox(3)-1];
    figure(2);
    clf;
    clear diffI maxDiffI
    samples = zeros(fiberBox(4),fiberBox(3),1000,'uint16');
    for k=1:1000
        WaitSecs(0.5);
        I=ISwrapper('GetImageBuffer'); % clear buffer
        %     res=ALPwrapper('PlayUploadedSequence',zeroID,1, false);
        ISwrapper('SoftwareTrigger');
        while (ISwrapper('GetBufferSize') == 0), end;
        I=ISwrapper('GetImageBuffer');
        samples(:,:,k) = I(aiYrange,aiXrange);
        diffI(k)=mean(mean(single(I(aiYrange,aiXrange)-I0(aiYrange,aiXrange))));
        maxDiffI(k)=max(max(abs(single(I(aiYrange,aiXrange)-I0(aiYrange,aiXrange)))));
        subplot(2,2,1);
        imagesc(I0);
        set(gca,'xlim',[fiberBox(1),fiberBox(1)+fiberBox(3)],'ylim',[fiberBox(2),fiberBox(2)+fiberBox(4)]);
        title('I0');
        subplot(2,2,2);
        imagesc(I);
        set(gca,'xlim',[fiberBox(1),fiberBox(1)+fiberBox(3)],'ylim',[fiberBox(2),fiberBox(2)+fiberBox(4)]);
        title('I');
        subplot(2,2,3);
        imagesc(single(I-I0))
        set(gca,'xlim',[fiberBox(1),fiberBox(1)+fiberBox(3)],'ylim',[fiberBox(2),fiberBox(2)+fiberBox(4)]);
        title('diff');
        subplot(2,2,4);
        plot(diffI);
        title(num2str(k))
        %     hold on;
        %     plot(maxDiffI,'r');
        drawnow
    end
    
    S=std(single(samples),[],3);
    figure(1);
    subplot(2,2,1);
    imagesc(mean(samples,3));colorbar;impixelinfo
    title('average intensity over 1000 images');
    subplot(2,2,2);
    imagesc(S);colorbar;impixelinfo
    title('standard deviation over 1000 images');
    subplot(2,2,3);
    imagesc(S./mean(samples,3)*100);
    title('std/mean over 1000 images');colorbar;impixelinfo
end
%% Build basis functions.
% there is a subtle thing here. If we floor the lee block size, we get more
% reference. If we ceil, we get less reference. 
if hadamardSize == 32
    leeBlockSize = 16;
    numReferencePixels = (768-32*leeBlockSize)/2;
    
elseif hadamardSize == 64
    numReferencePixels = 128;
    leeBlockSize = 8;
else
    referenceFraction = 0.35; % of area.
    numReferencePixels=ceil((effectiveDMDsize-sqrt(1-referenceFraction)*effectiveDMDsize)/2); % on each side...
    %(4*d*effectiveDMDsize-4*d*d) / (effectiveDMDsize*effectiveDMDsize)
    leeBlockSize = ceil(((effectiveDMDsize-2*numReferencePixels) / hadamardSize)/2)*2;
    numReferencePixels = (effectiveDMDsize-leeBlockSize*hadamardSize)/2;
end

load('randomBasis');
% randomBasis = (rand(hadamardSize,hadamardSize, 1000)-0.5);
% randomBasis(randomBasis>=0) = 1;
% randomBasis(randomBasis<0) = -1;
% save('randomBasis','randomBasis');

walshBasis = fnBuildWalshBasis(hadamardSize); % returns hadamardSize x hadamardSize x hadamardSize^2
basisUsed = walshBasis;
basisUsed(:,:, size(walshBasis,3)+1:size(walshBasis,3)+size(randomBasis,3))=randomBasis;

numModes = size(basisUsed ,3);
fprintf('Using %dx%d basis. Each uses %dx%d mirrors. Reference is %d pixels, which is %.3f of area\n',...
    hadamardSize,hadamardSize,leeBlockSize,leeBlockSize,numReferencePixels, (4*numReferencePixels*effectiveDMDsize-4*numReferencePixels*numReferencePixels)/(effectiveDMDsize*effectiveDMDsize));
phaseBasis = (basisUsed == 1)*pi;
phaseBasisReal = reshape(real(exp(1i*phaseBasis)),hadamardSize*hadamardSize,numModes);

clear basisUsed walshBasis randomBasis
% Phase shift the basis and append with a fixed reference.
%probedInterferencePhases =  [0, pi/2, -pi/2];
probedInterferencePhases =  [0, pi/2, pi];
numPhases = length(probedInterferencePhases);
% Generate the phase shifted and reference padded lee holograms.
cacheFile = ['interferenceBasisPatternsWithRandom',num2str(hadamardSize),'.mat'];
if exist(cacheFile,'file') && ~FORCE_BASIS
    fprintf('Loading from cache...');
    load(cacheFile);
    fprintf('Done!\n');
else
    interferenceBasisPatterns = fnPhaseShiftReferencePadLeeHologram(...
        phaseBasis, probedInterferencePhases, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
    savefast(cacheFile,'interferenceBasisPatterns');
end
numPatterns = size(phaseBasis,3) * numPhases;

%% upload test patterns to the DMD...
if (hadamardSequenceID > 0)
    ALPwrapper('ReleaseSequence',hadamardSequenceID);
end
fprintf('Uploading calibration sequence...');
hadamardSequenceID=ALPwrapper('UploadPatternSequence',interferenceBasisPatterns);
fprintf('Done!\n');
expTime = size(interferenceBasisPatterns,3)/cameraRate;
clear interferenceBasisPatterns
%% Calibrate!
clear Ein_all
fprintf('Playing calibration sequence (%d), expected time : %.2f seconds (%.2f min) \n',numPatterns,expTime,expTime/60)
ISwrapper('SetExposure',exposureForCalibration);
I=ISwrapper('GetImageBuffer'); %clear camera buffer
fprintf('Running sequence...');
res=ALPwrapper('PlayUploadedSequence',hadamardSequenceID,cameraRate, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
%ALPwrapper('ReleaseSequence',hadamardSequenceID);
calibrationImages=ISwrapper('GetImageBuffer');
assert(size(calibrationImages,3) == numPatterns); % make sure we acquired the correct number of images
quantization = 1; % Crop / resize I to make things more compact (?)
J = calibrationImages(fiberBox(2):quantization:fiberBox(2)+fiberBox(4)-1,fiberBox(1):quantization:fiberBox(1)+fiberBox(3)-1,:);
clear calibrationImages
fprintf('Done!\n');

% fast method for all pixels!
fprintf('Computing inverse...');
newSize = size(J);
K=zeros(numModes,newSize(1)*newSize(2));
for k=1:numModes
    K(k,:) = reshape(atan2( -(double(J(:,:, 3*(k-1)+3))-double(J(:,:, 3*(k-1)+2))) , (double(J(:,:, 3*(k-1)+1))-double(J(:,:, 3*(k-1)+2)))), 1,newSize(1)*newSize(2));
end
clear J
Ein_all=angle(phaseBasisReal* exp(1i*K));
clear K
fprintf('Done\n');
% old, slow method.
if 0
    fprintf('Computing K...\n');
    newSize = size(J);
    J2=double(J);
    K=zeros(newSize(1),newSize(2),numModes);
    for k=1:numModes
        K(:,:,k) = (J2(:,:, 3*(k-1)+1)-J2(:,:, 3*(k-1)+2)) - 1i * (J2(:,:, 3*(k-1)+3)-J2(:,:, 3*(k-1)+2));
    end
    K_obs=reshape(K, newSize(1)*newSize(2), numModes); % K2(:, x) is the x'th output mode
    Kinv=conj(K_obs');%(diag(1./Sval)*K_obs)'; %K_obs'
    clear K_obs K
    Etarget = zeros(newSize(1),newSize(2));
    Etarget(round(220/quantization),round(240/quantization))=1;
    Ein_pre   = Kinv  *Etarget(:);
    Ein_phase =angle(Ein_pre);
    WeightedInputToGenerateTarget = reshape(exp(1i*(reshape(phaseBasis, hadamardSize*hadamardSize,numModes)))* exp(1i*Ein_phase), hadamardSize,hadamardSize);
end
% faster more efficient way to compute this?
% fast method for a specific pixel
if 0
    fprintf('Computing K...\n');
    newSize = size(J);
    K=zeros(newSize(1),newSize(2),numModes);
    for k=1:numModes
        K(:,:,k) = atan2( -(double(J(:,:, 3*(k-1)+3))-double(J(:,:, 3*(k-1)+2))) , (double(J(:,:, 3*(k-1)+1))-double(J(:,:, 3*(k-1)+2))));
    end
    Ein_pre1   =exp(1i*squeeze(K(120,122,:)));
    Ein = angle(reshape(phaseBasisReal* Ein_pre1, hadamardSize,hadamardSize));
end
%% Generate a scanning sequence (50x50) pixels:
ONLY_CENTRAL_REGION = true;
if ONLY_CENTRAL_REGION
    aiRangeY = round(newSize(1)/2)-25:round(newSize(1)/2)+25;
    aiRangeX = round(newSize(2)/2)-25:round(newSize(2)/2)+25;
else
    aiRangeY = 1:3:newSize(1);
    aiRangeX = 1:3:newSize(2);
end
[XX,YY]=meshgrid(aiRangeX,aiRangeY);
aiInd = sub2ind([newSize(1),newSize(2)],YY(:),XX(:));
inputPhases=reshape(Ein_all(:,aiInd), hadamardSize,hadamardSize,length(aiInd));
fprintf('Generating and Uploading sweep sequence...');
SweepSequence = fnPhaseShiftReferencePadLeeHologram(inputPhases, 0, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
if (SweepSequenceID > 0)
    ALPwrapper('ReleaseSequence',SweepSequenceID);
end
SweepSequenceID=ALPwrapper('UploadPatternSequence',SweepSequence);
fprintf('Done!\n');
%% Sweep experiment

USE_MOTOR = false;
MotoSpeedUmSec = 10;
if (USE_MOTOR )
    
    MotorControllerWrapper('Release');    
    MotorControllerWrapper('Init');
%    MotorControllerWrapper('ResetPosition');    
    
    
    
    MotorControllerWrapper('SetSpeed',MotoSpeedUmSec);
    MotorControllerWrapper('SetStepSize',5);
end
SAVE_EXP = true;
SAVE_CALIB = false;

strExperimentFolder = 'E:\100um_GradedIndex_Experiment24EnahcnemtWithRandom\';
if (SAVE_EXP)
    mkdir(strExperimentFolder);
    if (SAVE_CALIB)
        fprintf('Saving calibration matrix...');
        savefast([strExperimentFolder,'CalibBefore.mat'],'Ein_all');
        fprintf('Done!\n');
    end
end
exposureForScanning = 1/3000.0;
ISwrapper('SetExposure',exposureForScanning);

iteration=1;

if 0
NumIterations = 100;
motorIncrement = zeros(1,NumIterations);
motorIncrement(5:5:NumIterations/2) = -100;
motorIncrement(5+NumIterations/2:5:NumIterations) = +100;
end

if 0
NumIterations = 100;
motorIncrement = zeros(1,NumIterations);
motorIncrement(1) = 0;
motorIncrement(2:2:end)=-500;
motorIncrement(3:2:end)=500;
end


NumIterations =4;
motorIncrement = zeros(1,NumIterations);
motorIncrement(1) = 0;
motorIncrement([3:3:end])=-400;


for iteration=1:NumIterations

    I=ISwrapper('GetImageBuffer'); % clear buffer
    res=ALPwrapper('PlayUploadedSequence',offID,cameraRate, false);
    WaitSecs(0.2+1/cameraRate);
    Baseline=ISwrapper('GetImageBuffer');
    
    if (USE_MOTOR && abs(motorIncrement(iteration)) > 0)
        fprintf('Moving motor %.2f micros\n',motorIncrement(iteration));
        MotorControllerWrapper('SetRelativePositionSteps', motorIncrement(iteration));
        WaitSecs(10);
        [~,MotorPosition] = MotorControllerWrapper('GetPositionSteps');
    end    
    if (USE_MOTOR)
        [~,MotorPosition] = MotorControllerWrapper('GetPositionSteps');
        if isempty(MotorPosition)
            MotorPosition = NaN;
        end
    else
        MotorPosition = 0;
    end
    
    fprintf('Iteration %d, motor position is %.4f\n',iteration,MotorPosition);

    if (USE_DAQ )
        res = fnDAQusb('StopAndResetBuffer',0);   
    end
    Q=ISwrapper('GetImageBuffer'); %clear buffer
    res=ALPwrapper('PlayUploadedSequence',SweepSequenceID,cameraRate, false);
    ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
    Q=ISwrapper('GetImageBuffer');
    if (USE_DAQ)
        LaserNoise=fnDAQusb('GetBuffer',0);
    end
    
    Qr = Q(fiberBox(2):fiberBox(2)+fiberBox(4)-1,fiberBox(1):fiberBox(1)+fiberBox(3),:);
    time = GetSecs();
     figure(11);
    clf;
     colormap gray
    maxQr = max(Qr(:));
    for k=1:5:size(Q,3)
        imagesc(Q(:,:,k),[0 1+maxQr*1.1])
        hold on;
        plot(fiberCenter(1)+cos(afAngle)*fiberDiameterPix/2,fiberCenter(2)+sin(afAngle)*fiberDiameterPix/2,'g');
        set(gca,'ylim',[fiberBox(2),fiberBox(2)+fiberBox(4)-1],'xlim',[fiberBox(1),fiberBox(1)+fiberBox(3)]);
        drawnow
        hold off;
    end
    impixelinfo
   
   if (SAVE_EXP)
          if (USE_DAQ)
                savefast(sprintf('%sExp%04d.mat',strExperimentFolder,iteration),'Qr','fiberBox','aiRangeX','aiRangeY','time','LaserNoise','MotorPosition','Baseline')
          else
              savefast(sprintf('%sExp%04d.mat',strExperimentFolder,iteration),'Qr','fiberBox','aiRangeX','aiRangeY','time','MotorPosition','Baseline');
          end
    end
    
end
% if (SAVE_EXP)
%     strExperimentFolder = 'E:\50um_Experiment2\';
%     save([strExperimentFolder,'CalibAfter.mat'],'Ein_all');
% end

%%

clear SpotSequence
targetPixel = [199,185];
targetPixelInd = sub2ind([newSize(1),newSize(2)],targetPixel(2),targetPixel(1));
Ein = reshape(Ein_all(:,targetPixelInd), hadamardSize,hadamardSize);
SpotSequence(:,:,1) = fnPhaseShiftReferencePadLeeHologram(Ein, 0, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
% Duplicate spot sequence to measure multiple samples
fprintf('Generating spot sequence...\n');
numSamples = 30;
numSpots = size(SpotSequence,3);

MultipleSpotSequence = false(size(SpotSequence,1),size(SpotSequence,2),numSamples*numSpots);
for k=1:numSamples
    for j=1:numSpots
        MultipleSpotSequence(:,:,(k-1)*numSpots+j) = SpotSequence(:,:,j);
    end
end

if (spotID > 0)
    ALPwrapper('ReleaseSequence',spotID);
end
spotID=ALPwrapper('UploadPatternSequence',MultipleSpotSequence);

exposureForScanning = 1/1000.0;
ISwrapper('SetExposure',exposureForScanning); 

    Q=ISwrapper('GetImageBuffer'); %clear buffer
    res=ALPwrapper('PlayUploadedSequence',spotID,cameraRate, false);
    ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
    Q=ISwrapper('GetImageBuffer');

figure(11);clf;
meanQ=mean(Q(:,:,1:1:end),3);
imagesc(meanQ,[0 1+1.1*max(meanQ(:))]);colormap gray;impixelinfo; colorbar

I=ISwrapper('GetImageBuffer'); % clear buffer
res=ALPwrapper('PlayUploadedSequence',offID,1, false);
% ISwrapper('SoftwareTrigger');
while (ISwrapper('GetBufferSize') == 0), end;
Baseline=double(ISwrapper('GetImageBuffer'));


[maxAtSpot,ind]=max(meanQ(:));
[y,x]=ind2sub(size(meanQ),ind);
% Compute enhancement
% First, fit a 2D gaussian
yy = y-5:y+5;
xx = x-5:x+5;
[XX,YY]=meshgrid(xx,yy);
vv=meanQ(yy,xx)-Baseline(yy,xx);
fitresult = fmgaussfit(XX(:),YY(:),vv(:));
aspectRatio = min(fitresult(3:4))/max( fitresult(3:4));
rotationbiasDeg = fitresult(2);
peak = fitresult(1);

% par(1) : peak
% par(2) : rotation (deg)
% par(3) : sigma X
% par(4) : sigma Y
% par(5) : x0
% par(6) : y0
% par(7) : bias


Tmp=meanQ-Baseline;
Tmp(y-5:y+5,x-5:x+5)=NaN;
TmpCropped = Tmp(fiberBox(2):fiberBox(2)+fiberBox(4)-1,fiberBox(1):fiberBox(1)+fiberBox(3)-1);
fprintf('Enhancement is : %.2f\n',peak/nanmean(TmpCropped(:)));
fprintf('peak location : %.2f %.2f\n',fitresult(5),fitresult(6));

%%
fnLiveCamera()
%% Two spots correlation.
if 0
    clear maxAtSpot stdAtSpot  enhancement
    k=0;
    %for k=1:100000
    while (1)
        k=k+1;
        Q=ISwrapper('GetImageBuffer'); %clear buffer
        res=ALPwrapper('PlayUploadedSequence',spotID,cameraRate, false);
        ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
        Q=ISwrapper('GetImageBuffer');
        meanQ1=mean(Q(:,:,1:2:end),3);
        meanQ2=mean(Q(:,:,2:2:end),3);
        
        figure(11);
        subplot(2,2,1);
        imagesc(meanQ1);
        subplot(2,2,2);
        imagesc(meanQ2);
        
        [~,ind]=max(meanQ1(:));
        [y1,x1]=ind2sub(size(meanQ1),ind);
        
        [~,ind]=max(meanQ2(:));
        [y2,x2]=ind2sub(size(meanQ2),ind);
        
        maxAtSpot1(k) = mean(single(squeeze(Q(y1,x1,1:2:end))));
        stdAtSpot1(k) = std(single(squeeze(Q(y1,x1,1:2:end))));
        maxAtSpot2(k) = mean(single(squeeze(Q(y2,x2,2:2:end))));
        stdAtSpot2(k) = std(single(squeeze(Q(y2,x2,2:2:end))));
        
        %     plot(x,y,'g+');
        subplot(2,2,3);cla;hold on;
        errorbar(maxAtSpot1,stdAtSpot1,'b');
        errorbar(maxAtSpot2,stdAtSpot2,'r');
        drawnow
    end
    [maxAtSpot(k),ind]=max(meanQ(:));
    [y,x]=ind2sub(size(meanQ),ind);
    spotPosition = [x,y];
end


%% single spot calibration.
clear maxAtSpot stdAtSpot  enhancement tm meanLaser stdLaser

for k=1:100000
    
    Q=ISwrapper('GetImageBuffer'); %clear buffer stdLaser
    if (USE_DAQ )
        res = fnDAQusb('StopAndResetBuffer',0);
    end

    res=ALPwrapper('PlayUploadedSequence',spotID,cameraRate, false);
    ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
    Q=ISwrapper('GetImageBuffer');
    if (USE_DAQ )
        Laser=fnDAQusb('GetBuffer',0);
    end
    meanLaser(k) = mean(Laser(1:numSamples-1));
    stdLaser(k) = std(Laser(1:numSamples-1));
    
    tm(k) = GetSecs();
    meanQ=mean(Q,3);
    figure(12);
     subplot(2,3,1);
    imagesc(meanQ);
    impixelinfo
    
    [~,ind]=max(meanQ(:));
    [y,x]=ind2sub(size(meanQ),ind);
    
    maxAtSpot(k) = mean(single(squeeze(Q(y,x,:))));
    stdAtSpot(k) = std(single(squeeze(Q(y,x,:))));
    
    % Compute enhancement
    % First, fit a 2D gaussian
    yy = y-5:y+5;
    xx = x-5:x+5;
    [XX,YY]=meshgrid(xx,yy);
    vv=meanQ(yy,xx)-Baseline(yy,xx);
    fitresult = fmgaussfit(XX(:),YY(:),vv(:));
    aspectRatio = min(fitresult(3:4))/max( fitresult(3:4));
    rotationbiasDeg = fitresult(2);
    peak = fitresult(1);
    % par(1) : peak
    % par(2) : rotation (deg)
    % par(3) : sigma X
    % par(4) : sigma Y
    % par(5) : x0
    % par(6) : y0
    % par(7) : bias
    Tmp=meanQ-Baseline;
    Tmp(y-5:y+5,x-5:x+5)=NaN;
    TmpCropped = Tmp(fiberBox(2):fiberBox(2)+fiberBox(4)-1,fiberBox(1):fiberBox(1)+fiberBox(3)-1);
    enhancement(k) = peak/nanmean(TmpCropped(:));    
    
%     plot(x,y,'g+');
    subplot(2,3,2);
    errorbar(maxAtSpot,stdAtSpot);
    title('Maximum intensity');
    set(gca,'xlim',[0 length(maxAtSpot)]);
    xlabel('samples');
    subplot(2,3,3);    
    plot(tm-tm(1),maxAtSpot);
    if k > 1
        set(gca,'xlim',[0 tm(end)-tm(1)]);
    end
    xlabel('seconds');
   subplot(2,3,4);
   plot(tm-tm(1),enhancement);
   if k>1
   set(gca,'xlim',[0 tm(end)-tm(1)]);
   end
   xlabel('seconds');
 subplot(2,3,5);
     plot(tm-tm(1),meanLaser);
     if k>1
   set(gca,'xlim',[0 tm(end)-tm(1)]);
   end
     title('Laser intensity');
     subplot(2,3,6);
     plot(meanLaser, maxAtSpot,'.');
    drawnow
end
[maxAtSpot(k),ind]=max(meanQ(:));
[y,x]=ind2sub(size(meanQ),ind);
spotPosition = [x,y];

%%
%         1 2  3  4  5  6  7  8 9  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39
depths = [0,5,10,15,20,25,30,35,40,45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45, 40, 35, 30, 25, 20, 15, 10, 5, 0]*10;
MeanValue = [];
StdValue = [];
a3fAvgImage = zeros(cameraHeight,cameraWidth,'uint16');

%%
iter = 39;
Q=ISwrapper('GetImageBuffer'); %clear buffer
res=ALPwrapper('PlayUploadedSequence',spotID,cameraRate, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
Q=ISwrapper('GetImageBuffer');
values = double(squeeze(Q(spotPosition(2)-1:spotPosition(2)+1,spotPosition(1)-1:spotPosition(1)+1,:)));

MeanValue(iter) = mean(values(:));
StdValue(iter) = std(values(:));
a3fAvgImage(:,:,iter) = mean(Q,3);
figure(11);
clf;
subplot(2,1,1);hold on;
if iter > 20
    plot(depths(1:20),MeanValue(1:20),'*');
    plot(depths(21:iter),MeanValue(21:iter),'r*');
else
    plot(depths(1:min(20,iter)),MeanValue(1:min(20,iter)),'*');
end
legend('Forward','Backward');
% subplot(2,1,2);

for k=1:iter
    h=axes;
    dx = mod(k,8);
    dy = floor(k/8);
    set(h,'position',[0.1313+(dx-1)*0.1061*1.1    0.3648-(dy-1)*1.1*0.0881    0.1061    0.0881])
    a2fTmp = a3fAvgImage(spotPosition(2)-10:spotPosition(2)+10,spotPosition(1)-10:spotPosition(1)+10,k);
    
    hi=imagesc(a2fTmp,[0 4096]);
    set(hi,'parent',h);
    hold on;
    text(2,4,num2str(depths(k)),'color','w');
    axis off;
end

% 
% imagesc(a3fAvgImage(:,:,iter),[0 4096]);
% hold on;
% plot(spotPosition(1),spotPosition(2),'g+');

%%

ALPwrapper('ReleaseSequence',spotID);


cnt=1;
while(1)
     for k=1:size(Q,3)
        imagesc(Q(:,:,k));
        title(num2str(cnt));
        cnt=cnt+1;
        drawnow
    end
end

meanValues = squeeze(mean(mean(Values(9-2:9+2,6-2:6+2,1:cnt),1),2));
figure(11);
clf;
plot(meanValues);
title(sprintf('Mean: %.4f, std: %.4f',mean(meanValues),std(meanValues)));



figure(11);
clf;
imagesc(Q(:,:,2))
impixelinfo


Q=ISwrapper('GetImageBuffer'); % get images
    
    

%%
% Generate a moving spot around the center of the fiber
aiRangeX = 1:5:newSize(2);
aiRangeY = 1:5:newSize(1);
NumPatterns = length(aiRangeX)*length(aiRangeY);
cnt=1;
OptimalPhases = zeros(hadamardSize,hadamardSize,NumPatterns);
for ii=1:length(aiRangeY)
    for jj=1:length(aiRangeX)
    Etarget = zeros(newSize(1),newSize(2));
    Etarget(aiRangeY(ii),aiRangeX(jj))=1;%ii+round(newSize(1)/2),jj+round(newSize(2)/2))=1;
    Ein_pre   = Kinv*Etarget(:);
    Ein_phase =wrapToPi (angle(Ein_pre));
    WeightedInputToGenerateTarget = reshape(exp(1i*reshape(phaseBasis, numModes,numModes))* exp(1i*Ein_phase(:)),hadamardSize,hadamardSize);
    Ein=wrapTo2Pi(angle(WeightedInputToGenerateTarget));
    OptimalPhases(:,:,cnt) = Ein;
    Pos(:,cnt) = [aiRangeY(ii),aiRangeX(jj)]';
    cnt=cnt+1;
    end
end

SpotScanningSequence = fnPhaseShiftReferencePadLeeHologram(...
        OptimalPhases, 0, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
  
Q=ISwrapper('GetImageBuffer'); %clear buffer
spotID=ALPwrapper('UploadPatternSequence',SpotScanningSequence);
res=ALPwrapper('PlayUploadedSequence',spotID,cameraRate, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
Q=ISwrapper('GetImageBuffer'); % get images
ALPwrapper('ReleaseSequence',spotID);

%save('E:\FocusingExperimentResult_RandBasis','Q','aiRangeX','aiRangeY','K_obs');

% Characterize performance?
% Spot size
% enhancment, secondary spots?
% Simulate reconstruction
%%
% Generate a moving spot around the center of the fiber
numCircles = 20;
radii = linspace(10, newSize(1)/2-5, numCircles);
numPatterns = sum(ceil(2*pi*radii / 20));
cnt=1;
OptimalPhases = zeros(hadamardSize,hadamardSize,numPatterns);
Pos = zeros(2,numPatterns);
centY = ceil(newSize(1)/2);
centX = ceil(newSize(2)/2);
for ii=1:numCircles
    rad = radii(ii);
    circum = 2*pi*rad;
    numpoints = ceil(circum / 10);
    ang = linspace(0, 2*pi- 2*pi/numpoints, numpoints);
    for jj=1:length(ang)
    Etarget = zeros(newSize(1),newSize(2));
    Etarget(round(centY + sin(ang(jj))*rad), round(centX + cos(ang(jj))*rad)) = 1;
    Etarget(round(centY + sin(ang(jj))*rad), round(centX - cos(ang(jj))*rad)) = 1;
    Ein_pre   = Kinv*Etarget(:);
    Ein_phase =wrapToPi (angle(Ein_pre));
    WeightedInputToGenerateTarget = reshape(exp(1i*reshape(phaseBasis, numModes,numModes))* exp(1i*Ein_phase(:)),hadamardSize,hadamardSize);
    Ein=wrapTo2Pi(angle(WeightedInputToGenerateTarget));
    OptimalPhases(:,:,cnt) = Ein;
    Pos(:,cnt) = [round(centY + cos(sin(jj))*rad),round(centX + cos(ang(jj))*rad)]';
    cnt=cnt+1;
    end
end

SpotScanningSequence = fnPhaseShiftReferencePadLeeHologram(...
        OptimalPhases, 0, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
  
Q=ISwrapper('GetImageBuffer'); %clear buffer
spotID=ALPwrapper('UploadPatternSequence',SpotScanningSequence);
res=ALPwrapper('PlayUploadedSequence',spotID,cameraRate, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
Q=ISwrapper('GetImageBuffer'); % get images
ALPwrapper('ReleaseSequence',spotID);


%%
figure(11);
clf;
colormap jet
writeVideo = false;
if (writeVideo)
    vidObj = VideoWriter('Spot.mp4');
    open(vidObj);
end
for k=1:size(Q,3)
    imagesc(Q(:,:,k),[20 4096]);
    colorbar
    
    title('First successful spot scanning experiment. 19/9/2014');
    drawnow;
    if (writeVideo)
        frame = getframe(11);
        writeVideo(vidObj,frame);
        if (k == size(Q,3))
            close(vidObj)
        end
    else
        tic, while toc < 0.05; end
    end
end


%

%%
ALPwrapper('ReleaseSequence',zeroID); zeroID  = -1;
ALPwrapper('ReleaseSequence',offID); offID = -1;
ALPwrapper('ReleaseSequence',hadamardSequenceID); hadamardSequenceID = -1;
ALPwrapper('ReleaseSequence',SweepSequenceID);
ALPwrapper('Release');
if (USE_DAQ )
    res = fnDAQusb('Release',0);
end
ISwrapper('Release');

