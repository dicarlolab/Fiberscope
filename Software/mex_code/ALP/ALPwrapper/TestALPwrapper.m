cd('C:\Users\shayo\OneDrive\Waveform Reshaping code\MEX\x64');
addpath('C:\Users\shayo\OneDrive\Waveform Reshaping code\ALP\ALPwrapper');
addpath('C:\Users\shayo\OneDrive\Waveform Reshaping code\Camera\ISwrapper');
%%
Hc=ISwrapper('Init'); % Initialize Camera

if (Hc)
    fprintf('Initialized Camera successfuly');
else
    fprintf('Failed to initialize camera');
    return;
end
% Run auto exposure procedure...
[optimalExposure,meanI]=fnAutoExposure();
centerPix = size(meanI)/2;
%%
H=ALPwrapper('Init');
if (H)
    fprintf('Initialized DMD Successfuly\n');
else
    fprintf('DMD Initalization Failed!\n');
    return
end

% selectedCarrier = 0.1900;
% [t,h]=LeeHologram(zeros(768,1024),selectedCarrier);
% seqID=ALPwrapper('UploadPatternSequence',h);
% res=ALPwrapper('PlayUploadedSequence',seqID,1,false);
% res=ALPwrapper('ReleaseSequence',seqID);
% ALPwrapper('StopSequence');
% ALPwrapper('Release');


% 
% Seq = zeros(768,1024,768,'uint8');
% for k=1:768-10
%     Tmp=zeros(768,1024,'uint8');
%     Tmp(k:k+10,:) = true;
%     Seq(:,:,k) = Tmp;
% end
% 
% tic
% seqID=ALPwrapper('UploadPatternSequence',Seq);
% toc
% if (seqID < 0)
%     fprintf('Failed to upload pattern\n');
% end
% 
% res=ALPwrapper('PlayUploadedSequence',seqID,2000);
% 
% ALPwrapper('ClearWhite');
% 
% squarePattern=zeros(768,1024,'uint8');
% squarePattern(1:768,1:768) = true;
% res=ALPwrapper('ShowPattern',uint8(squarePattern));

% set number of pixels per mode
numModesPerRow = 16;
numModes = numModesPerRow*numModesPerRow;
numPixelsPerMode = 768/numModesPerRow;
% duplicate a small phase pattern (16x16) into the large array
Dup = CreateDuplicationMatrix(768, numModesPerRow);

numPhasesToSample = 90; % i.e., every two degrees...
phasesToSample = linspace(0,180,numPhasesToSample)/180*pi;

optimalPhase = zeros(numModesPerRow,numModesPerRow);
for modeX = 1:numModesPerRow
    for modeY = 1:numModesPerRow
        
        
        % Generate a test sequence for this phase block
        testSequence = zeros(768,1024,numPhasesToSample,'uint8')>0;
        
        for phaseIter=1:numPhasesToSample
            optimalPhase(modeY,modeX) = phasesToSample(phaseIter);
            PadTmp = zeros(768,1024);
            PadTmp(1:768,1:768) =  Dup*optimalPhase*Dup';
            [~,L]=LeeHologram(PadTmp, selectedCarrier);
            testSequence(:,:, phaseIter) = L;
        end
        seqID=ALPwrapper('UploadPatternSequence',testSequence);
        res=ALPwrapper('PlayUploadedSequence',seqID,10,false); % Play sequence at 10 Hz

        
    end
end




res=ALPwrapper('ShowPattern',uint8(h));
% generate random phase masks...
numPatterns = 1;
Seq = zeros(768,1024,numPatterns,'uint8');
for i=1:numPatterns
    X=rand(numModesPerRow,numModesPerRow)*pi/2;
    Z=zeros(768,1024);
    Z(1:768,1:768) = Dup*X*Dup';
    [t,h]=LeeHologram(Z,selectedCarrier);
    Seq(:,:,i) = h;
end

[t,h]=LeeHologram(zeros(768,1024),selectedCarrier);

seqID=ALPwrapper('UploadPatternSequence',h);
res=ALPwrapper('PlayUploadedSequence',seqID,1,false);

res=ALPwrapper('ReleaseSequence',seqID);

ALPwrapper('StopSequence');
ALPwrapper('Release');

carriers = 0.05:0.01:0.6;

%for sep=1:length(carriers)
sep = 15;
% Construct a Lee hologram
[t,h]=LeeHologram(zeros(768,1024),carriers(sep));
figure(1);
clf;
subplot(1,2,1);
imagesc(t);
subplot(1,2,2);
imagesc(h);
colormap gray

res=ALPwrapper('ShowPattern',uint8(h));
tic
while toc < 0.4
end



res=ALPwrapper('ShowPattern',ones(768,1024,'uint8'));

while (1)
    ALPwrapper('ClearBlack');
    tic
    while toc < 1
    end
    ALPwrapper('ClearWhite');
    tic
    while toc < 1
    end
end

ALPwrapper('Release');

ISwrapper('Release');

%%
ISwrapper('SetExposure',1/500);
while (1)
    X=ISwrapper('GetImageBuffer');
    ISwrapper('SoftwareTrigger');
    figure(11);
    clf;
    for k=1:size(X,3)
        imagesc(X(:,:,k),[0 4096]);drawnow
    end
end

ISwrapper('Release');
