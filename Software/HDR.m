function HDRimage=HDR(patternsToPlay,  ND, exposure,selectedColorWheel)
cameraRate= 850;
numPatterns = size(patternsToPlay,3);
numRepetitions = 3;
id = ALPwrapper('UploadPatternSequence',patternsToPlay);

darkImage=getDarkImage(cameraRate);
Images = zeros(size(darkImage,1),size(darkImage,2),numPatterns,length(ND),'single');
PTwrapper('SetExposure', 1./exposure);

for nd_iter = 1:length(ND)
    fprintf('Scanning with ND %d\n',ND(nd_iter));
    FilterWheelModule('SetNaturalDensity',[selectedColorWheel ND(nd_iter)]);
    darkImage=getDarkImage(cameraRate);

    PTwrapper('StartAveraging', numPatterns,false);
    res=ALPwrapper('PlayUploadedSequence',id, cameraRate, numRepetitions);
    ALPwrapper('WaitForSequenceCompletion');
    WaitSecs(0.2); % allow all images to reach buffer
    PTwrapper('StopAveraging');
    Tmp=PTwrapper('GetImageBuffer');
    % subtract dark image
    Images(:,:,:,nd_iter) = single(Tmp) - repmat(darkImage,[1,1,numPatterns]);
end
ALPwrapper('ReleaseSequence',id);   
 
Images(1,1:2,:,:,:)= 0; % get rid of timestamps
% Convert multiple exposures to a single high-dynamic-range (HDR) image
% cut off values
    MinCutOff = 100; %100;
    HighCutOff = 3700; %3700;
    Images(Images <MinCutOff | Images>HighCutOff) = NaN;

Images=reshape(Images,[size(darkImage,1),size(darkImage,2),numPatterns, length(ND(:))]);
MultFactor = single(abs( 10.^ND(:))); % .* abs(2.^( (log2(EXPm(:))-base_exposure)))));
MultFactor4D = shiftdim(repmat(MultFactor,[1,size(darkImage,1),size(darkImage,2),numPatterns]),1);
Photons = Images .* MultFactor4D; 
% HDR: take the first non-nan maximum along the 4th dimension...
HDRimage = nanmax(Photons,[],4);
