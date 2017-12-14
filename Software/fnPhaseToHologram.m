function L=fnPhaseToHologram(phases,selectedCarrier)
numModesPerRow = size(phases,1);
% numModes = numModesPerRow*numModesPerRow;
% numPixelsPerMode = 768/numModesPerRow;
% duplicate a small phase pattern (16x16) into the large array
Dup = CreateDuplicationMatrix(768, numModesPerRow);
PadTmp = zeros(768,1024);
PadTmp(1:768,1:768) =  Dup*phases*Dup';
[~,L]=LeeHologram(PadTmp, selectedCarrier);

