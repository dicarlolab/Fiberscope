  

if dmd.hadamardSize == 32
    dmd.leeBlockSize = 16;
    dmd.numReferencePixels = (768-32*leeBlockSize)/2;
    
elseif dmd.hadamardSize == 64
    dmd.numReferencePixels = 128;
    dmd.leeBlockSize = 8;
else
    referenceFraction = 0.35; % of area.
    numReferencePixels=ceil((dmd.effectiveDMDsize-sqrt(1-referenceFraction)*dmd.effectiveDMDsize)/2); % on each side...
    %(4*d*effectiveDMDsize-4*d*d) / (effectiveDMDsize*effectiveDMDsize)
    dmd.leeBlockSize = ceil(((dmd.effectiveDMDsize-2*numReferencePixels) / dmd.hadamardSize)/2)*2;
    dmd.numReferencePixels = (dmd.effectiveDMDsize-dmd.leeBlockSize*dmd.hadamardSize)/2;
end
walshBasis = fnBuildWalshBasis(dmd.hadamardSize); % returns hadamardSize x hadamardSize x hadamardSize^2
dmd.numModes = size(walshBasis ,3);
% fprintf('Using %dx%d basis. Each uses %dx%d mirrors. Reference is %d pixels, which is %.3f of area\n',...
%     dmd.hadamardSize,dmd.hadamardSize,dmd.leeBlockSize,dmd.leeBlockSize,dmd.numReferencePixels, ...
%     (4*dmd.numReferencePixels*dmd.effectiveDMDsize-4*dmd.numReferencePixels*dmd.numReferencePixels)/(dmd.effectiveDMDsize*dmd.effectiveDMDsize));

dmd.phaseBasis = single((walshBasis == 1)*pi);
dmd.phaseBasisReal = single(reshape(real(exp(1i*dmd.phaseBasis)),dmd.hadamardSize*dmd.hadamardSize,dmd.numModes));

clear walshBasis
% Phase shift the basis and append with a fixed reference.
%probedInterferencePhases =  [0, pi/2, -pi/2];
probedInterferencePhases =  [0, pi/2, pi];
dmd.numPhases = length(probedInterferencePhases);
% Generate the phase shifted and reference padded lee holograms.
cacheFile = ['packedInterferenceBasisPatterns',num2str(dmd.hadamardSize),'.mat'];
if exist(cacheFile,'file') && ~FORCE_BASIS
    displayMessage(handles,'Loading interference basis patterns from cache...');
    load(cacheFile);
else
%    interferenceBasisPatterns = fnPhaseShiftReferencePadLeeHologram(...
%        phaseBasis, probedInterferencePhases, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
        interferenceBasisPatterns0 = CudaFastLee(dmd.phaseBasis+0,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier);
        interferenceBasisPatterns1 = CudaFastLee(dmd.phaseBasis+pi/2,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier);
        interferenceBasisPatterns2 = CudaFastLee(dmd.phaseBasis+pi,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier);
        interferenceBasisPatterns = cat(3,interferenceBasisPatterns0,interferenceBasisPatterns1,interferenceBasisPatterns2);
        clear interferenceBasisPatterns0  interferenceBasisPatterns1 interferenceBasisPatterns2
%        phaseBasis, probedInterferencePhases, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier);
    savefast(cacheFile,'interferenceBasisPatterns');
end
dmd.numPatterns = size(dmd.phaseBasis,3) * dmd.numPhases;
