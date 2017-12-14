function stats=SmartSweepTest(deviceID,patternsToPlay,  x,y,roi,strFigureTitle, ND, exposures, cameraRate,fiberBox,colorChannel)
% To get a proper value for enhancement, we need to make sure
% we are not clipping our signal from the camera (over exposure, or under
% exposure).
% To do that, we need to pick both a good natural density filter and
% exposure values, such that the incoming light is within the dynamic range
% of the camera.
% 
% To solution is to capture multiple frames and reconstruct high dynamic
% range image such that pixels represent the number of photons captures,
% taking into account both exposure and natural density transmission
% values.
%
% To calculate approximate number of photons arrived to the camera, given exposure time
% and natural density filter, we use the following equation:
% photons = 10^ND * round(2^(log2(1/exposure)-base_exposure) * value)
% where ND is the value of the natural density filter (i.e., 1.0, 2.0, ...)
% exposure is exposure time in milliseconds (i.e., 1/5000),
% and base exposure gives some baseline for the calculation (i.e.,
% base_exposure = 7, will make 1/128 the base).
% value is the value read by the camera.

% given a set of patterns to play, we play them at 
% 1/2000, 1/6000, and 1/10000 for each of the natural density filters.
% ND3, ND4 and ND5.
[NDm,EXPm]=meshgrid(ND,exposures);


numPatterns = size(patternsToPlay,3);
numRepetitions = 3;
   id = ALPwrapper('UploadPatternSequence',deviceID,patternsToPlay);
darkImage=getDarkImage(deviceID,cameraRate);
Images = zeros(size(darkImage,1),size(darkImage,2),numPatterns,length(ND),length(exposures),'single');
for nd_iter = 1:length(ND)
    FilterWheelModule('SetNaturalDensity',[colorChannel ND(nd_iter)]);

    for ex_iter = 1:length(exposures)
         XimeaWrapper('SetExposure', 1./exposures(ex_iter));
         darkImage=getDarkImage(deviceID,cameraRate);
           
         ok = false;
         cameraRateAdjusted = cameraRate;
         for nAttempt=1:5
                res=ALPwrapper('PlayUploadedSequence',deviceID,id, cameraRateAdjusted, numRepetitions);
                ALPwrapper('WaitForSequenceCompletion',deviceID); % Block. Wait for sequence to end.
                WaitSecs(0.6);
                Tmp=XimeaWrapper('GetImageBuffer');
                if (size(Tmp,3) == numPatterns*numRepetitions)
                    ok=true;
                    break;
                else
                    fprintf('Failed. Trying again...\n');
                    cameraRateAdjusted=round(cameraRateAdjusted*0.6);
                    Tmp=XimeaWrapper('GetImageBuffer');
                    WaitSecs(0.5);
                end
         end
         if (ok == false)
             fprintf('Error capturing!\n');
             return;
         end
          Tmp=reshape(Tmp,size(Tmp,1),size(Tmp,2),numPatterns,numRepetitions);
          Tmp = mean(single(Tmp),4);
%          
         % subtract dark image
         Images(:,:,:,nd_iter,ex_iter) = single(Tmp) - repmat(darkImage,[1,1,numPatterns]);
    end
end
 ALPwrapper('ReleaseSequence',deviceID,id);   
RawImages = Images;
 
Images(1,1:2,:,:,:)= 0; % get rid of timestamps
% Convert multiple exposures to a single high-dynamic-range (HDR) image
% cut off values
if ~(length(exposures) == 1 && length(ND) == 1)
    MinCutOff = 40; %100;
    HighCutOff = 950; %3700;
    Images(Images <MinCutOff | Images>HighCutOff) = NaN;
end

Images=reshape(Images,[size(darkImage,1),size(darkImage,2),numPatterns, length(NDm(:))]);
base_exposure=7;
MultFactor = single(abs( 10.^NDm(:))); % .* abs(2.^( (log2(EXPm(:))-base_exposure)))));
MultFactor4D = shiftdim(repmat(MultFactor,[1,size(darkImage,1),size(darkImage,2),numPatterns]),1);
Photons = Images .* MultFactor4D; 
% HDR: take the first non-nan maximum along the 4th dimension...
HDR = nanmax(Photons,[],4);
% figure; imagesc(squeeze(log(HDR(:,:,50))));colorbar; impixelinfo

%fiberBox = [1,1,size(darkImage,1),size(darkImage,2)];
radius = floor((fiberBox(3)-fiberBox(1))/2);
W = 10;


[XX,YY]=meshgrid(1:size(HDR,2),1:size(HDR,1));
cent = [ceil(fiberBox(1)+fiberBox(3)/2),         ceil(fiberBox(2)+fiberBox(4)/2)];
Idisk = (XX-cent(1)).^2+(YY-cent(2)).^2 <= radius^2;
insideHalfRadius = sqrt((x-radius).^2+(y-radius).^2) < radius/2;

%% Now compute enhancement and gaussian statistics
fprintf('Computing statistics...');drawnow
for k=1:numPatterns
    I=HDR(:,:,k);
    x0 = x(k);%+ fiberBox(1)-1;
    y0 = y(k);%+fiberBox(2)-1;
    xrange = min(size(I,2), max(1,x0-W:x0+W));
    yrange = min(size(I,1),max(1,y0-W:y0+W));
    values = I(yrange,xrange);
    values(isnan(values)) = nanmedian(values(:));
    
    par_init = [W+1;W+1];
    result_params = mx_psfFit_Image( double(values), par_init ); % This is the simplest possible call, see psfFit_Image for all options
    
    opt_x =result_params(1);
    opt_y =result_params(2);
    opt_amp = result_params(3);
    opt_back = result_params(4);
    opt_sigma = result_params(5);

% % plot fit    
%     N=20;
%     theta = 2*pi*[0:N]/N;
%     radius = 3*opt_sigma;
%     uv = [opt_x+radius * cos(theta); opt_y+radius * sin(theta)];
%     
%     figure(11);clf;imagesc(values);hold on;plot(uv(1,:),uv(2,:));
%     result_params
    
    
    [maxIntensityMapping(k), maxLocalInd]= max(values(:));
    
    displacementMap(1,k)= x0  + opt_x-(W+1);
    displacementMap(2,k)= y0  + opt_y-(W+1);


    mapIntensity2D(y(k),x(k))=maxIntensityMapping(k);
    Idisk_withoutSpot = Idisk;
    Idisk_withoutSpot(yrange,xrange) = false;
    
    meanBackgroundValue=nanmean(I(Idisk_withoutSpot));
    enhancemnentFactor(k) = maxIntensityMapping(k)/meanBackgroundValue;
    gaussianFitSigma(k) = opt_sigma;
    gaussianFitSigma2D(y(k),x(k)) = opt_sigma;
    gaussianFitAmplitude(k) = opt_amp;
    gaussianFitAmplitude2D(y(k),x(k))=opt_amp;
    enhancemnentFactor2D(y(k),x(k))=enhancemnentFactor(k);
end
fprintf('Done!\n');

% clear SpotCalibrationImages
fprintf('\nAverage enhancement: %.2f +- %.2f (%.2f +- %.2f) in half radius\n', nanmean(enhancemnentFactor), nanstd(enhancemnentFactor),...
    nanmean(enhancemnentFactor(insideHalfRadius)),nanstd(enhancemnentFactor(insideHalfRadius)));

fprintf('Average gaussian amplitude: %.2f +- %.2f (%.2f +- %.2f) in half radius\n', nanmean(log10(gaussianFitAmplitude)), nanstd(log10(gaussianFitAmplitude)),...
    nanmean(log10(gaussianFitAmplitude(insideHalfRadius))),nanstd(log10(gaussianFitAmplitude(insideHalfRadius))));

fprintf('Average gaussian standard deviation: %.2f +- %.2f (%.2f +- %.2f) in half radius\n', mean(gaussianFitSigma), nanstd(gaussianFitSigma),...
    nanmean(gaussianFitSigma(insideHalfRadius)),nanstd(gaussianFitSigma(insideHalfRadius)));

stats.RawImages = RawImages;
stats.ND = ND;
stats.exposures = exposures;
stats.enhancemnentFactor = enhancemnentFactor;
stats.enhancemnentFactor2D = enhancemnentFactor2D;
stats.displacementMap = displacementMap;
stats.maxIntensityMapping = maxIntensityMapping;
stats.mapIntensity2D = mapIntensity2D;
stats.meanEnhancement = nanmean(enhancemnentFactor);
stats.meanEnhancementHalfRadius = nanmean(enhancemnentFactor(insideHalfRadius));


stats.gaussianFitAmplitude = gaussianFitAmplitude;
stats.gaussianFitAmplitude2D = gaussianFitAmplitude2D;
stats.gaussianFitSigma = gaussianFitSigma;
stats.gaussianFitSigma2D = gaussianFitSigma2D;

maxV = 0;
for i=0:4
    for j=0:4
        I1=FastUpSampling(enhancemnentFactor2D,i+roi.offsetX,j+roi.offsetY, roi.subsampling,roi.subsampling);
        if sum(I1(:)) > maxV
            maxV=sum(I1(:));
            offsetI =i;
            offsetJ = j;
        end
    end
end

I1=FastUpSampling(enhancemnentFactor2D,offsetI+roi.offsetX,offsetJ+roi.offsetY, roi.subsampling,roi.subsampling);
stats.enhancement2D = I;

I2=FastUpSampling(gaussianFitSigma2D,offsetI+roi.offsetX,offsetJ+roi.offsetY, roi.subsampling,roi.subsampling);
fig=figure;
clf;
subplot(1,2,1);imagesc(I1);title(sprintf('Enhancement Factor: %.2f +- %.2f', mean(enhancemnentFactor), std(enhancemnentFactor) ));myColorbar();axis off
subplot(1,2,2);imagesc(I2);title(sprintf('PSF: %.2f +- %.2f',mean(gaussianFitSigma), std(gaussianFitSigma)));myColorbar();axis off
set(fig,'Name',strFigureTitle);
