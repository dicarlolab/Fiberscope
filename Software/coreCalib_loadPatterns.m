function dmd=coreCalib_loadPatterns(opt)
dmd.hadamardSize = opt.hadamardSize;
dmd.cameraRate = opt.cameraRate;
dmd.height = 768;
dmd.width = 1024;
FORCE_BASIS = false;

if dmd.hadamardSize == 16
    dmd.leeBlockSize = 48;%16;
    dmd.numReferencePixels = 0;%128; %(768-32*leeBlockSize)/2;
    
elseif dmd.hadamardSize == 32
    dmd.leeBlockSize = 24;%16;
    dmd.numReferencePixels = 0;%128; %(768-32*leeBlockSize)/2;
    
elseif dmd.hadamardSize == 64
    dmd.numReferencePixels = 64;%64;%128;
    dmd.leeBlockSize = 10;%10;%8;
elseif dmd.hadamardSize == 128
    dmd.numReferencePixels = 128;
    dmd.leeBlockSize = 4;    
else
    referenceFraction = 0.35; % of area.
    numReferencePixels=ceil((dmd.effectiveDMDsize-sqrt(1-referenceFraction)*dmd.effectiveDMDsize)/2); % on each side...
    %(4*d*effectiveDMDsize-4*d*d) / (effectiveDMDsize*effectiveDMDsize)
    dmd.leeBlockSize = ceil(((dmd.effectiveDMDsize-2*numReferencePixels) / dmd.hadamardSize)/2)*2;
    dmd.numReferencePixels = (dmd.effectiveDMDsize-dmd.leeBlockSize*dmd.hadamardSize)/2;
end
walshBasis = fnBuildWalshBasis(dmd.hadamardSize); % returns hadamardSize x hadamardSize x hadamardSize^2
% if get(handles.hFullFOV,'value')
%     walshBasisRotated =fnBuildWalshBasisRotated(dmd.hadamardSize, pi/4);
%     walshBasis = cat(3,walshBasis,walshBasisRotated);
%   
% end

dmd.numModes = size(walshBasis ,3);
% fprintf('Using %dx%d basis. Each uses %dx%d mirrors. Reference is %d pixels, which is %.3f of area\n',...
%     dmd.hadamardSize,dmd.hadamardSize,dmd.leeBlockSize,dmd.leeBlockSize,dmd.numReferencePixels, ...
%     (4*dmd.numReferencePixels*dmd.effectiveDMDsize-4*dmd.numReferencePixels*dmd.numReferencePixels)/(dmd.effectiveDMDsize*dmd.effectiveDMDsize));

dmd.phaseBasis = single((walshBasis == 1)*pi);
dmd.phaseBasisReal = single(reshape(real(exp(1i*dmd.phaseBasis)),dmd.hadamardSize*dmd.hadamardSize,dmd.numModes));

clear walshBasis
% Phase shift the basis and append with a fixed reference.
probedInterferencePhases =  [0, pi/2, pi];
%probedInterferencePhases =  [0, pi/2, pi, 3*pi/2];

dmd.numPhases = length(probedInterferencePhases);
% Generate the phase shifted and reference padded lee holograms.
% 
% if get(handles.hFullFOV,'value')
%     cacheFile = ['packedInterferenceBasisPatternsRotated',num2str(dmd.hadamardSize),'.mat'];
% else
    cacheFile = ['./cache/packedInterferenceBasisPatterns',num2str(dmd.hadamardSize),'.mat'];
% end



if exist(cacheFile,'file') && ~FORCE_BASIS
     load(cacheFile);
else
%     interferenceBasisPatternsSlowButAccurate = fnPhaseShiftReferencePadLeeHologram(...
%         dmd.phaseBasis(:,:,1:100:end), probedInterferencePhases, dmd.numReferencePixels, dmd.leeBlockSize,dmd.width,dmd.height,dmd.selectedCarrier);
%     interferenceBasisPatterns0 = CudaFastLee(dmd.phaseBasis(:,:,1:100:end),dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier);
fprintf('Recomputing lee holograms and saving to disk...\n');
    if ~exist('./cache','dir')
        mkdir('./cache');
    end

    interferenceBasisPatterns = zeros(768,128, dmd.numModes*3,'uint8');
    interferenceBasisPatterns(:,:, 1:3:end) = CudaFastLee(dmd.phaseBasis+0,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier, dmd.carrierRotation);
    interferenceBasisPatterns(:,:, 2:3:end) = CudaFastLee(dmd.phaseBasis+pi/2,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier, dmd.carrierRotation);
    interferenceBasisPatterns(:,:, 3:3:end) = CudaFastLee(dmd.phaseBasis+pi,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier, dmd.carrierRotation);
%       interferenceBasisPatterns = cat(3,interferenceBasisPatterns0,interferenceBasisPatterns1,interferenceBasisPatterns2);
% 
%         interferenceBasisPatterns0 = CudaFastLee(dmd.phaseBasis+0,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier);
%         interferenceBasisPatterns1 = CudaFastLee(dmd.phaseBasis+pi/2,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier);
%         interferenceBasisPatterns2 = CudaFastLee(dmd.phaseBasis+pi,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier);
%         interferenceBasisPatterns3 = CudaFastLee(dmd.phaseBasis+3*pi/2,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier);
%        interferenceBasisPatterns = cat(3,interferenceBasisPatterns0,interferenceBasisPatterns1,interferenceBasisPatterns2,interferenceBasisPatterns3);
        clear interferenceBasisPatterns0  interferenceBasisPatterns1 interferenceBasisPatterns2
%        phaseBasis, probedInterferencePhases, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
    savefast(cacheFile,'interferenceBasisPatterns');
end
dmd.numPatterns = size(dmd.phaseBasis,3) * dmd.numPhases;

dmd.expTime = size(interferenceBasisPatterns,3)/dmd.cameraRate;
dmd.patternsLoadedAndUploaded = false;
dmd.interferenceBasisPatterns = interferenceBasisPatterns;
