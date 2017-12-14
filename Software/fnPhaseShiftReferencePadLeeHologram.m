function interferenceBasisPatterns = fnPhaseShiftReferencePadLeeHologram(phaseBasis, probedInterferencePhases, numReferencePixels, leeBlockSize,DMDwidth,DMDheight,selectedCarrier, rot)
% This function takes as input a 2D phase basis (hadamard) of size NxNxN^2
% and adds to it a probe interference phase, to generate a NxNxN^2 x M 4D
% array. This array is then expanded such that each entry covers a block of
% leeBlockSize x leeBlockSize pixels in the DMD. Thus, the intermediate
% size is (N*leeBlockSize)x(N*leeBlockSize)xN^2 x M 
% it is then padded with a zero reference.
% finally, the phase matrix is converted to a binary hologram using Lee's
% method (cosine).

N = size(phaseBasis,1);
numBasis = size(phaseBasis,3);
numInterferencePatterns = length(probedInterferencePhases);
% duplicate a small phase pattern (16x16) into the large array
Dup = CreateDuplicationMatrix(N*leeBlockSize, N);
Ref = zeros(DMDheight,DMDwidth);

interferenceBasisPatterns = false(DMDheight,DMDwidth, numBasis * numInterferencePatterns);
fprintf('Converting [%dx%dx%d] to [%dx%dx%dx%d] (%.3f MB) \n',...
    N,N,numBasis,DMDheight,DMDwidth,numBasis,numInterferencePatterns, prod(size(interferenceBasisPatterns))/1e6/8);

Ind = reshape(1:N*N,N,N);
SampleMatrix = Dup*Ind*Dup';


[x,y]=meshgrid(0:DMDwidth-1,0:DMDheight-1);
if ~exist('rot','var')
    rot = 55/180*pi;
end
%P=[cos(rot) sin(rot);-sin(rot) cos(rot)]*[x(:)';y(:)'];
%xt = reshape(P(1,:),size(x));
xt=reshape(cos(rot)*x(:) + sin(rot)*y(:), size(x));
%yt = reshape(P(2,:),size(y));
%carrierWave = 2*single(pi)*(x-y)*selectedCarrier;
carrierWave = 2*single(pi)*(xt)*selectedCarrier;

cnt=1;
for k=1:numBasis
    for j=1:numInterferencePatterns
        %Tmp = Dup*(phaseBasis(:,:,k)+probedInterferencePhases(j))*Dup';
        Tmp2 = phaseBasis(:,:,k);
        Tmp=reshape(Tmp2(SampleMatrix), N*leeBlockSize,N*leeBlockSize)+probedInterferencePhases(j);
        Ref( numReferencePixels+1:N*leeBlockSize+numReferencePixels,numReferencePixels+1:N*leeBlockSize+numReferencePixels) = Tmp;
        interferenceBasisPatterns(:,:,cnt) = (0.5 * (1 + cos(carrierWave - Ref))) > 0.5;
        cnt=cnt+1;
    end
end

return;

