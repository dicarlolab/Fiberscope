function I=fnUploadMaskAndCapture(PhaseMask,selectedCarrier)

% Generate a test sequence for this phase block
numModesPerRow = 16;
% duplicate a small phase pattern (16x16) into the large array
Dup = CreateDuplicationMatrix(768, numModesPerRow);
PadTmp = zeros(768,1024);
PadTmp(1:768,1:768) =  Dup*PhaseMask*Dup';
[~,testSequence]=LeeHologram(PadTmp, selectedCarrier);

I=ISwrapper('GetImageBuffer');
fprintf('Uploading sequence...');
randID=ALPwrapper('UploadPatternSequence',testSequence);
ALPwrapper('PlayUploadedSequence',randID, 1,false); % Play sequence at 100 Hz
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
fprintf('Done!\n');
ALPwrapper('ReleaseSequence',randID);
I=ISwrapper('GetImageBuffer');

