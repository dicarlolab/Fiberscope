function fnTestSpeckleStability
%% Test target pixel stability under no phase modulation
numZeroSamples = 1000;
% % % zeroSequence = zeros(768,1024,numZeroSamples,'uint8')>0;
% % % zeroPhase = zeros(numModesPerRow,numModesPerRow);
% % % [~,L]=LeeHologram(zeros(768,1024), selectedCarrier);
% % % for phaseIter=1:numPhasesToSample
% % %     zeroSequence(:,:, phaseIter) = L;
% % % end
% % % zeroSeqID=ALPwrapper('UploadPatternSequence',zeroSequence);
ISwrapper('TriggerOFF');
res=ALPwrapper('PlayUploadedSequence',zeroID,100, true);
% wait for things to stabilize?
tic
while toc < 1
end
N=ISwrapper('GetBufferSize');I=ISwrapper('GetImageBuffer');
ISwrapper('TriggerON');
while (ISwrapper('GetBufferSize') <= numZeroSamples)
    tic 
    while toc < 0.5
    end
    fprintf('%d samples are waiting...\n',ISwrapper('GetBufferSize'));
end
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
N=ISwrapper('GetBufferSize');I=ISwrapper('GetImageBuffer');

centerPix = [324,216];%size(meanI)/2;
region = 2;

stabilityTestValues = double(squeeze(mean(mean(I(centerPix(2)-region:centerPix(2)+region, centerPix(1)-region:centerPix(1)+region,:),1),2)));
figure(10);
clf;
subplot(2,2,1);
plot(stabilityTestValues);
subplot(2,2,2);
hist(double(stabilityTestValues),100)
subplot(2,2,3);
hold on;
plot(cumsum(stabilityTestValues(:)')./[1:length(stabilityTestValues)])
hold on;
plot([0, length(stabilityTestValues)], ones(1,2)* mean(stabilityTestValues),'r');
subplot(2,2,4);
imagesc(mean(I,3));
hold on;
plot(centerPix(1),centerPix(2),'ko','linewidth',3);

figure(2);clf;movieZ(I,false)
hold on;
plot(centerPix(1),centerPix(2),'ko','MarkerSize',10,'LineWidth',3);
