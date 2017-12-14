randPhase=2*pi*zeros(64,64);
handles.dmd.leeBlockSize = 10;
handles.dmd.hadamardSize = 64;
numReferencePixels = 64;
leeBlockSize = 10;
selectedCarrier =0.19;

carriers = 0.3; %linspace(0.1, 0.3,5);


rotations = 58;%linspace(0,180,20);
while (1)
    
for k=1:length(carriers)
    for j=1:length(rotations)
        selectedCarrier=carriers(k);
        carrierRotation = rotations(j)/ 180*pi
        interferenceBasisPatterns = CudaFastLee(single(randPhase),numReferencePixels, leeBlockSize,selectedCarrier, carrierRotation);
        ALPuploadAndPlay(interferenceBasisPatterns,22000,10);
        pause
    end
end

end