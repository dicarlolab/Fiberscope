function stdI=fnPlayRandomPhases(selectedCarrier,cameraRate)    
% Generate a test sequence for this phase block
numModesPerRow = 16;
% duplicate a small phase pattern (16x16) into the large array
Dup = CreateDuplicationMatrix(768, numModesPerRow);


numPhases = 120;
testSequence = zeros(768,1024,numPhases,'uint8')>0;
for phaseIter=1:numPhases
    randPhase = rand(numModesPerRow,numModesPerRow) * pi;
    PadTmp = zeros(768,1024);
    PadTmp(1:768,1:768) =  Dup*randPhase*Dup';
    [~,L]=LeeHologram(PadTmp, selectedCarrier);
    testSequence(:,:, phaseIter) = L;
end

I=ISwrapper('GetImageBuffer');
fprintf('Uploading sequence...');
randID=ALPwrapper('UploadPatternSequence',testSequence);
ALPwrapper('PlayUploadedSequence',randID, cameraRate,false); % Play sequence at 100 Hz
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
fprintf('Done!\n');
ALPwrapper('ReleaseSequence',randID);
I=ISwrapper('GetImageBuffer');
figure(101);clf;
for k=1:size(I,3)
    imagesc(I(:,:,k),[0 4096]);
    drawnow
end
stdI = std(double(I),[],3);
