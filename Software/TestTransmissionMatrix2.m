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
referenceFraction = 0.35; % of area.
hadamardSize = 32; % (needs to be power of 2. Use 8,16,32,64
VERBOSE = 1;
spotID = -1;

hadamardSequenceID = -1;
%% DAQ initialization
res = fnDAQusb('Init',0,20000);


%% DMD initialization
H=ALPwrapper('Init');
if (H)
    fprintf('Initialized Successfuly\n');
else
    fprintf('Initalization Failed!\n');
end
% setup a dummy phase to measure exposure times...
[~,L]=LeeHologram(zeros(DMDheight,DMDwidth), selectedCarrier);
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

cameraRate = 90;%fnTestMaximalCameraAcqusitionRate();
exposureForSegmtation = 1.0/1000.0;
exposureForCalibration = 1.0/500.0;

%% automatic segmentation of a bounding box around the fiber
ISwrapper('SetExposure',exposureForSegmtation); 
I=ISwrapper('GetImageBuffer'); % clear buffer
res=ALPwrapper('PlayUploadedSequence',zeroID,1, false);
ISwrapper('SoftwareTrigger');
while (ISwrapper('GetBufferSize') == 0), end;
I=ISwrapper('GetImageBuffer');
% figure(11);
% clf;
% imagesc(I,[0 4096]);

backgroundLevel=30;
L=bwlabel(I>backgroundLevel);
R=regionprops(L);
[~,lab]=max(cat(1,R.Area));
fiberBox= 2*ceil(round(R(lab).BoundingBox)/2); %[x0,y0, width, height];
if fiberBox(2)+fiberBox(4) > size(I,1)
    fiberBox(4) = size(I,1)-fiberBox(2);
end
if fiberBox(1)+fiberBox(3) > size(I,2)
    fiberBox(3) = size(I,1)-fiberBox(1);
end
figure(3);clf;imagesc(I(fiberBox(2):fiberBox(2)+fiberBox(4)-1,fiberBox(1):fiberBox(1)+fiberBox(3)-1),[0 4096]);colorbar


%% Build basis functions.
% there is a subtle thing here. If we floor the lee block size, we get more
% reference. If we ceil, we get less reference. 
numReferencePixels=ceil((effectiveDMDsize-sqrt(1-referenceFraction)*effectiveDMDsize)/2); % on each side...
%(4*d*effectiveDMDsize-4*d*d) / (effectiveDMDsize*effectiveDMDsize)
leeBlockSize = ceil(((effectiveDMDsize-2*numReferencePixels) / hadamardSize)/2)*2;
numReferencePixels = (effectiveDMDsize-leeBlockSize*hadamardSize)/2;
walshBasis = fnBuildWalshBasis(hadamardSize); % returns hadamardSize x hadamardSize x hadamardSize^2
numModes = size(walshBasis ,3);
fprintf('Using %dx%d basis. Each uses %dx%d mirrors. Reference is %d pixels, which is %.3f of area\n',...
    hadamardSize,hadamardSize,leeBlockSize,leeBlockSize,numReferencePixels, (4*numReferencePixels*effectiveDMDsize-4*numReferencePixels*numReferencePixels)/(effectiveDMDsize*effectiveDMDsize));

if VERBOSE
    figure(10);clf;fnPlotWalshBasis(walshBasis);
end;
phaseBasis = (walshBasis == 1)*pi;
%phaseBasis = (rand(32,32,1024) > 0.5)*pi;

% Phase shift the basis and append with a fixed reference.
%probedInterferencePhases =  [0, pi/2, -pi/2];
probedInterferencePhases =  [0, pi/2, pi];
numPhases = length(probedInterferencePhases);
% Generate the phase shifted and reference padded lee holograms.
interferenceBasisPatterns = fnPhaseShiftReferencePadLeeHologram(...
    phaseBasis, probedInterferencePhases, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
numPatterns = size(phaseBasis,3) * numPhases;
%% upload test patterns to the DMD...
if (hadamardSequenceID > 0)
    ALPwrapper('ReleaseSequence',hadamardSequenceID);
end

hadamardSequenceID=ALPwrapper('UploadPatternSequence',interferenceBasisPatterns);


fprintf('Playing calibration sequence, expected time : %.2f seconds (%.2f min) \n',size(interferenceBasisPatterns,3)/cameraRate,size(interferenceBasisPatterns,3)/cameraRate/60)
%% Calibrate!
numCalibrations = 1;
clear KinvRepeat
for calibIter=1:numCalibrations
    fprintf('Calibration %d out of %d\n',calibIter,numCalibrations);
    ISwrapper('SetExposure',exposureForCalibration); 
    I=ISwrapper('GetImageBuffer'); %clear camera buffer
    fprintf('Running sequence...\n');
    res=ALPwrapper('PlayUploadedSequence',hadamardSequenceID,cameraRate, false);
    ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
    %ALPwrapper('ReleaseSequence',hadamardSequenceID);
    calibrationImages=ISwrapper('GetImageBuffer'); 
    assert(size(calibrationImages,3) == numPatterns); % make sure we acquired the correct number of images
    quantization = 2; % Crop / resize I to make things more compact (?)
    J = calibrationImages(fiberBox(2):quantization:fiberBox(2)+fiberBox(4)-1,fiberBox(1):quantization:fiberBox(1)+fiberBox(3)-1,:);
    clear calibrationImages
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
    KinvRepeat(:,:,calibIter) = Kinv;
end
%AvgKInv =mean(KinvRepeat,3);
AvgKInv = KinvRepeat(:,:,1);%+KinvRepeat(:,:,3))/2;
%w=0.48;
%AvgKInv = (KinvRepeat(:,:,1)*w+(1-w)*KinvRepeat(:,:,3))/2;

Etarget = zeros(newSize(1),newSize(2));
Etarget(round(130/quantization),round(130/quantization))=1;%ii+round(newSize(1)/2),jj+round(newSize(2)/2))=1;


S=sum(abs(AvgKInv),2);
[~,componentStrength]=sort(S,'descend');
[~, componentStrength]=sort(abs(KinvRepeat(:,find(Etarget(:)))),'descend');

MultipleSpotSequence = false(DMDheight,DMDwidth,length(componentStrength));
for ii=1:length(componentStrength)
    Ein_pre   = AvgKInv  *Etarget(:);
    Ein_phase =wrapToPi (angle(Ein_pre));
    %WeightedInputToGenerateTarget = reshape(exp(1i*reshape(phaseBasis, hadamardSize*hadamardSize,numModes))* exp(1i*Ein_phase(:)),hadamardSize,hadamardSize);
    WeightedInputToGenerateTarget = reshape(exp(1i*reshape(phaseBasis(:,:,componentStrength(1:ii)), ...
        hadamardSize*hadamardSize, ii))* exp(1i*Ein_phase(componentStrength(1:ii))),hadamardSize,hadamardSize);
    
    Ein=wrapTo2Pi(angle(WeightedInputToGenerateTarget));
    SpotSequence = fnPhaseShiftReferencePadLeeHologram(Ein, 0, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
    MultipleSpotSequence(:,:,ii) = SpotSequence;
end

if (spotID > 0)
    ALPwrapper('ReleaseSequence',spotID);
end
spotID=ALPwrapper('UploadPatternSequence',MultipleSpotSequence);

exposureForScanning = 1/3000.0;
ISwrapper('SetExposure',exposureForScanning); 

    Q=ISwrapper('GetImageBuffer'); %clear buffer
    res=ALPwrapper('PlayUploadedSequence',spotID,cameraRate, false);
    ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
    Q=ISwrapper('GetImageBuffer');
    
    Tmp=Q(:,:,end);
    [maxAtSpot(k),ind]=max(Tmp(:));
    [y,x]=ind2sub(size(meanQ),ind);
    spotPosition = [x,y];

    figure(11);
    clf;
    for jj=1:size(Q,3)
        imagesc(Q(:,:,jj),[0 4096]);
        title(num2str(jj));
        drawnow
    end
    figure(11);
    clf;
    plot(    squeeze(Q(y,x,:)))
    xlabel('number of input modes used to generate the spot');
    ylabel('Intensity');
    
    impixelinfo
    [maxAtSpot(k),ind]=max(meanQ(:));
    [y,x]=ind2sub(size(meanQ),ind);
    hold on;
%     plot(x,y,'g+');
    subplot(1,2,2);
     plot(maxAtSpot);
    drawnow


%%
%         1 2  3  4  5  6  7  8 9  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39
depths = [0,5,10,15,20,25,30,35,40,45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45, 40, 35, 30, 25, 20, 15, 10, 5, 0]*10;
MeanValue = [];
StdValue = [];
a3fAvgImage = zeros(cameraHeight,cameraWidth,'uint16');

%%
iter = 30;
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
end


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
ALPwrapper('ReleaseSequence',zeroID);
ALPwrapper('ReleaseSequence',hadamardSequenceID);
ALPwrapper('Release');
ISwrapper('Release');
