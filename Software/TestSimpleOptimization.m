cd('C:\Users\shayo\OneDrive\Waveform Reshaping code\MEX\x64');
addpath('C:\Users\shayo\OneDrive\Waveform Reshaping code\ALP\ALPwrapper');
addpath('C:\Users\shayo\OneDrive\Waveform Reshaping code\Camera\ISwrapper');
selectedCarrier = 0.1900;
colordef black
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

% location = [3,3];
% numphases = 40;
% numblocks = 4;
% phases = linspace(0,2*pi,numphases);
% sweep = zeros(768,1024,numphases,'uint8')>0;
% for k=1:numphases
%     phaseMask = zeros(numblocks,numblocks);
%     phaseMask(location(2),location(1)) = rand()*2*pi;%phases(k);
%     sweep(:,:,k)=fnPhaseToHologram(phaseMask,selectedCarrier);
% end
% 
% testID=ALPwrapper('UploadPatternSequence',sweep);
% res=ALPwrapper('PlayUploadedSequence',testID,30, true);
% 
% ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
% ALPwrapper('ReleaseSequence',testID);


% Box = zeros(768,1024,'uint8')>0;
% Box(1:768,1:768)=true;
% zeroID=ALPwrapper('UploadPatternSequence',Box);
% res=ALPwrapper('PlayUploadedSequence',zeroID,1, false);
% ALPwrapper('StopSequence'); % Block. Wait for sequence to end.


%% Camera initializations
Hcam=ISwrapper('Init'); % Initialize Camera
if (Hcam)
    fprintf('Initialized Camera successfuly\n');
else
    fprintf('Failed to initialize camera\n');
    return;
end

cameraRate = fnTestMaximalCameraAcqusitionRate();

initialExposure = 300;
maxNumSaturated = 20;
saturationValue = 500;
[optimalExposure,initialI]=fnAutoExposure(selectedCarrier,initialExposure,maxNumSaturated,saturationValue);

ISwrapper('SetExposure',1.0/9000.0);
[~,L]=LeeHologram(zeros(768,1024), selectedCarrier);
zeroID=ALPwrapper('UploadPatternSequence',L);
res=ALPwrapper('PlayUploadedSequence',zeroID,1, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.


% 
% stdI = zeros(480,640,10);
% for k=1:10
%     stdI(:,:,k)=fnPlayRandomPhases(selectedCarrier,cameraRate);    
%  
% end
%%

% 
% % Generate a test sequence for this phase block
% while (1)
%     randPhase = rand(numModesPerRow,numModesPerRow) * pi;
%     PadTmp = zeros(768,1024);
%     PadTmp(1:768,1:768) =  Dup*randPhase *Dup';
%     [~,L]=LeeHologram(PadTmp, selectedCarrier);
%     seqIDtmp=ALPwrapper('UploadPatternSequence',L);
%     res=ALPwrapper('PlayUploadedSequence',seqIDtmp, sequenceSpeed,false); % Play sequence at 10 Hz
%     ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
%     N=ISwrapper('GetBufferSize');I=ISwrapper('GetImageBuffer');
%     if N > 0  
%         figure(10);
%         clf;
%         imagesc(I)
%         colormap gray
%         drawnow
%     end
%     res=ALPwrapper('ReleaseSequence',seqIDtmp);
% end

%% 

% set number of pixels per mode
numModesPerRow = 10;
numModes = numModesPerRow*numModesPerRow;
numPixelsPerMode = 768/numModesPerRow;
% duplicate a small phase pattern (16x16) into the large array
Dup = CreateDuplicationMatrix(768, numModesPerRow);

numPhasesToSample = 10; % i.e., every two degrees...
phasesToSample = linspace(0,2*pi,numPhasesToSample);

centerPix = [229,255];%[214,256];
targetY = centerPix(2);
targetX = centerPix(1);
sequenceSpeed = cameraRate; % 100 hz
numRepeats = 20;
% round(4*10^9/(768*1024/8  ))
% 40690 / 256
optimalPhase = zeros(numModesPerRow,numModesPerRow);
region = 0; 
%%
counter = 0;
score = NaN*ones(1,numModes);
enhancementRatio = NaN*ones(1,numModes);
backgroundNoise = 20;
for modeX = 1:numModesPerRow
    for modeY = 1:numModesPerRow
        counter=counter+1;
        fprintf('Round %d: generating phases for mode [%d, %d]\n',counter, modeY,modeX);
        drawnow
        % clear image buffer
        N=ISwrapper('GetBufferSize');I=ISwrapper('GetImageBuffer');

        % Generate a test sequence for this phase block
        testSequence = zeros(768,1024,numPhasesToSample,'uint8')>0;
        for phaseIter=1:numPhasesToSample
            optimalPhase(modeY,modeX) = phasesToSample(phaseIter);
            PadTmp = zeros(768,1024);
            PadTmp(1:768,1:768) =  Dup*optimalPhase*Dup';
            [~,L]=LeeHologram(PadTmp, selectedCarrier);
            testSequence(:,:, phaseIter) = L;
        end
         
        %seqID=ALPwrapper('UploadPatternSequence',testSequence(:,:,1));
        %res=ALPwrapper('PlayUploadedSequence',seqID,50,false); % Play sequence at 10 Hz
        fprintf('Uploading sequence...');
        seqID=ALPwrapper('UploadPatternSequence',testSequence);
        fprintf('Done!\n');
        values = zeros(numRepeats, numPhasesToSample);
        
        I=ISwrapper('GetImageBuffer');
        for iter=1:numRepeats
            ALPwrapper('PlayUploadedSequence',seqID, cameraRate,false); % Play sequence at 100 Hz
            ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
            while (ISwrapper('GetBufferSize') <numPhasesToSample) 
            end
            I=ISwrapper('GetImageBuffer');
            fprintf('Repeat %d, %d images collected\n',iter, size(I,3));
            
            values(iter,:) = squeeze(mean(mean(I(targetY-region:targetY+region,targetX-region:targetX+region,:),1),2));
        end
        
          res=ALPwrapper('ReleaseSequence',seqID);
          avgValues = mean(values,1);
          [localScore, bestPhaseIndex]=max(avgValues);
          optimalPhase(modeY,modeX) = phasesToSample(bestPhaseIndex);
          
          meanI = mean(I,3);
          
          targetMask = zeros(size(meanI),'uint8')>0;
          targetMask(targetY-1:targetY+1,targetX-1:targetX+1) = true;
          enhancementRatio(counter) = mean(meanI(targetMask)) / mean(meanI(~targetMask & meanI>backgroundNoise));
          
          score(counter)=localScore;
         figure(12);
         clf;
         subplot(2,3,1);
         plot(phasesToSample/pi*180,values');hold on;
         plot(phasesToSample/pi*180,mean(values,1),'w','linewidth',3)
         xlabel('Phase');
         ylabel('Intensity');
         set(gca,'xlim',[0 360]);
         subplot(2,3,2);
         plot(score);
         xlabel('Iteration');
         ylabel('Intensity');
         subplot(2,3,3);
         plot(enhancementRatio);
         xlabel('Iteration');
         ylabel('Enhancement ratio');
         subplot(2,3,4);
         scaleBar = ceil(max(max(mean(I,3))));
         imagesc(mean(I,3),[0 scaleBar]);
         title(sprintf('Image at iteration %d',counter))
         hold on;
         plot(targetX,targetY,'wo','markersize',11,'linewidth',2);
         axis off
         
         subplot(2,3,5);
         imagesc(initialI,[0 scaleBar])
         set(gca,'xlim',[targetX-30 targetX+30],'ylim',[targetY-30 targetY+30]);
        hold on;
         plot(targetX,targetY,'wo','markersize',11,'linewidth',2);
        axis off
        title('Before optimization');
      subplot(2,3,6);
         imagesc(mean(I,3),[0 scaleBar]);
         set(gca,'xlim',[targetX-30 targetX+30],'ylim',[targetY-30 targetY+30]);
        hold on;
         plot(targetX,targetY,'wo','markersize',11,'linewidth',2);
        axis off
        title('After optimization');
        drawnow
    end
end

set(gcf,'position',[ 351   552   804   426]);
fprintf('Optimization completed!\n');
figure(111);
clf;
T=mean(I,3);
imagesc(mean(I,3))
title('9/12/2014 - First spot generated. 14x14 modes');
colorbar
figure(10);
hist(T(:),0:4096);

%%

I1=fnUploadMaskAndCapture(zeros(16,16),selectedCarrier);
I2=fnUploadMaskAndCapture(optimalPhase,selectedCarrier);
figure(11);
clf;
h1=subplot(1,2,1);imagesc(I1,[0 4096]);colorbar
hold on;
plot(targetX,targetY,'ko','markersize',11,'linewidth',2);
axis off
h2=subplot(1,2,2);imagesc(I2,[0 4096]);colorbar
hold on;
plot(targetX,targetY,'ko','markersize',11,'linewidth',2);
axis off
drawnow
linkaxes([h1,h2]);
impixelinfo




%%


clear I
Tmp = ISwrapper('GetImageBuffer');
ISwrapper('SetExposure',1/3800);

while (1)
    ISwrapper('SoftwareTrigger');
    tic
    while toc < 0.05
    end
    Tmp = ISwrapper('GetImageBuffer');
    imagesc(Tmp,[0 4500]);
    colorbar
    drawnow
end

figure(11);
imagesc(mean(I,3))
imagesc(std(I,[],3))
colorbar

%%
ALPwrapper('ReleaseSequence',zeroID);

ALPwrapper('Release');

ISwrapper('Release');
