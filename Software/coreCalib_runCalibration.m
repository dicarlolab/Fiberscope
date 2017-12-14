function dmd = coreCalib_runCalibration(dmd, opt,fiberBox, radius) 
sweepTest = opt.sweepTest;
SweepZ = opt.SweepZ;
psfZtest = opt.psfZtest;
fullReconstruction = opt.fullReconstruction;
DepthMinUm = opt.DepthMinUm;
DepthMaxUm = opt.DepthMaxUm;
DepthIntervalUm = opt.DepthIntervalUm;
numCalibrationAverages = opt.numCalibrationAverages;
naturalDensityForSegmentation = opt.naturalDensityForSegmentation;
naturalDensityForCalibration = opt.naturalDensityForCalibration;
naturalDensityForSweepTest = opt.naturalDensityForSweepTest;
samplingStepUm = opt.samplingStepUm;
samplingRangeUm = opt.samplingRangeUm;
exposureForCalibration = opt.exposureForCalibration;
exposureForSweepTest = opt.exposureForSweepTest;

dmd.fiberBox = fiberBox;
dmd.radius = radius;

cameraInitalized=CameraModule('IsInitialized');
if (~cameraInitalized)
    fprintf('Unable to initialize camera module\n');
    return
end
CameraModule('StopLiveView');

CameraTriggerWrapper(1); % Do not skip triggers

if ~FilterWheelModule('IsInitialized')
    fprintf('Unable to initialize filter wheel module\n');
    return
end
FilterWheelWrapper('ShutterOFF');

if ~MotorControllerWrapper('IsInitialized')
    res = MotorControllerWrapper('Init');
    if ~res
        fprintf('Unable to initialize motor stage module\n');
        return;
    end
end
if sweepTest || psfZtest
    fullReconstruction = true;
end    

% assume user focused on fiber tip!
[~,StageZeroDepth] = MotorControllerWrapper('GetPositionMicrons');

if SweepZ
    CalibrationDepths = StageZeroDepth - [DepthMinUm:DepthIntervalUm:DepthMaxUm];
else
    CalibrationDepths= StageZeroDepth ;
end

numCalibrationIterations = length(CalibrationDepths);

SessionWrapper('NewSession');

dmd.numCalibrationAverages = numCalibrationAverages;
PTwrapper('SetGain',0); 

[X,Y]=meshgrid(1:2*dmd.radius+1,1:2*dmd.radius+1);
binaryDisc = sqrt((X-(dmd.radius+1)).^2+(Y-(dmd.radius+1)).^2) <= dmd.radius;
% find center pixel coordinates
% get coordinates of binary disc
dmd.hologramSpotPos = find(binaryDisc(:));

dmd.naturalDensityForSegmentation = naturalDensityForSegmentation;
dmd.naturalDensityForCalibration = naturalDensityForCalibration;
dmd.naturalDensityForSweepTest = naturalDensityForSweepTest;

dmd.numSpots = length(dmd.hologramSpotPos);
roi.radius  =dmd.radius ;
roi.boundingbox = [1 1 2*dmd.radius+1 2*dmd.radius+1]; % full FOV
roi.subsampling = 2;
roi.maxDMDrate = 22000;
roi.Mask = zeros(2*roi.radius+1,2*roi.radius+1);
roi.selectedRate = roi.maxDMDrate ;
roi=recomputeROI(roi,1);

ALPwrapper('Release');
ALPwrapper('Init');

fprintf('Uploading Calibration patterns');
reupload = size(dmd.interferenceBasisPatterns,3) > 40000;
if ~reupload
    dmd.hadamardSequenceID=ALPwrapper('UploadPatternSequence',dmd.interferenceBasisPatterns);
end
fprintf('Done!\n');

fprintf('Averaging over %d repetitions\n',dmd.numCalibrationAverages);
for CalibrationIteration=1:numCalibrationIterations
    calibrationID=CreateNewCalibration();

    relativeDepth = CalibrationDepths(CalibrationIteration)-StageZeroDepth;
    dumpVariableToCalibration(relativeDepth,'relativeDepth');
    if numCalibrationIterations > 1
        fprintf('Motorized Stage to relative depth %.0f um\n',relativeDepth);
        MotorControllerWrapper('SetSpeed',20);
        MotorControllerWrapper('SetAbsolutePositionMicrons', CalibrationDepths(CalibrationIteration));
    end
    
    [~,actualEncoderLocation] = MotorControllerWrapper('GetPositionMicrons');
    dumpVariableToCalibration(actualEncoderLocation,'actualEncoderLocation');    

    FilterWheelModule('SetNaturalDensity',[1,dmd.naturalDensityForCalibration]);  

    fprintf('Depth: %.0f um, %.2f seconds (%.2f min)\n',relativeDepth,dmd.expTime*dmd.numCalibrationAverages,dmd.expTime*dmd.numCalibrationAverages/60);
    PTwrapper('SetExposure',1.0/exposureForCalibration);
    
    onTheFlyReconstruction = false;
    if onTheFlyReconstruction
        PTwrapper('StartAveraging',dmd.numPatterns/3,true);
    else
        PTwrapper('StartAveraging',dmd.numPatterns,false);
    end

    if reupload
        ALPuploadAndPlay(dmd.interferenceBasisPatterns,dmd.cameraRate, dmd.numCalibrationAverages);
    else
        res=ALPwrapper('PlayUploadedSequence',dmd.hadamardSequenceID,dmd.cameraRate, dmd.numCalibrationAverages);
    end
    ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
    WaitSecs(0.5); % allow all images to reach buffer
    PTwrapper('StopAveraging');
    numI=PTwrapper('getNumTrigs');
    if numI ~= dmd.numPatterns*dmd.numCalibrationAverages
        fprintf('Images mismatch. Trying again with reduced rate (%.2f min)\n',dmd.expTime*dmd.numCalibrationAverages/60/0.6);
        Z=PTwrapper('GetImageBuffer');
        onTheFlyReconstruction = false;
        if onTheFlyReconstruction
            PTwrapper('StartAveraging',dmd.numPatterns/3,true);
        else
            PTwrapper('StartAveraging',dmd.numPatterns,false);
        end

        % trying again....
        if reupload
            ALPuploadAndPlay(dmd.interferenceBasisPatterns,ceil(0.6*dmd.cameraRate), dmd.numCalibrationAverages);
        else
            res=ALPwrapper('PlayUploadedSequence',dmd.hadamardSequenceID,ceil(0.6*dmd.cameraRate), dmd.numCalibrationAverages);
        end
        ALPwrapper('WaitForSequenceCompletion'); % Block. Wait for sequence to end.
        WaitSecs(2); % allow all images to reach buffer
        PTwrapper('StopAveraging');
        numI=PTwrapper('getNumTrigs');
        if numI ~= dmd.numPatterns*dmd.numCalibrationAverages
            fprintf('Number of collected images does not match number of calibration patterns (%d/%d)\n',numI,dmd.numPatterns*dmd.numCalibrationAverages);
            fprintf('Going back to position 0\n');
            MotorControllerWrapper('SetAbsolutePositionMicrons', StageZeroDepth);
            return;
        end
    end
    fprintf( 'Transferring images from camera memory...\n');
    calibrationImages=PTwrapper('GetImageBuffer');
    maxIntensity = squeeze(max(max(calibrationImages,[],1),[],2));
    fprintf('Mean of max intensity: %.2f. Number of images overexposed: %d\n',mean(maxIntensity),sum(maxIntensity>=4094));
    
    J = single(calibrationImages(dmd.fiberBox(2):opt.quantization:dmd.fiberBox(2)+dmd.fiberBox(4)-1, ...
            dmd.fiberBox(1):opt.quantization:dmd.fiberBox(1)+dmd.fiberBox(3)-1,:)); 

    clear calibrationImages
    % fast method for all pixels!
    dmd.newSize = size(J);
    dumpVariableToCalibration(dmd.newSize,'newSize');
    
    % reconstruct the phase (!) of the complex field
    % Three phases:
    % I[0]-I[pi/2] +i*I[pi/2]-I[pi]
    % Four phases:
    % I[0]-I[pi]   +i*I[3*pi/2]-I[pi/2])
%     I0 = J(:,:,1:dmd.numModes);
%     Ipi_2 = J(:,:,dmd.numModes+1:2*dmd.numModes);
%     Ipi = J(:,:,2*dmd.numModes+1:3*dmd.numModes);
%     I3pi_2 = J(:,:,3*dmd.numModes+1:end);
    
%     Kinv_angle=reshape(atan2(Ipi_2-Ipi, ...
%                              I0-Ipi_2), ...
%                     dmd.newSize(1)*dmd.newSize(2),dmd.numModes)';
    
%    Kinv_angle=reshape(atan2(I3pi_2-Ipi_2, ...
%                              I0-Ipi), ...
%                     dmd.newSize(1)*dmd.newSize(2),dmd.numModes)';
%                  
%           


% K=zeros(dmd.newSize(1),dmd.newSize(2),dmd.numModes);
% for k=1:dmd.numModes
%     K(:,:,k) = (J(:,:, 3*(k-1)+1)-J(:,:, 3*(k-1)+2)) - 1i * (J(:,:, 3*(k-1)+3)-J(:,:, 3*(k-1)+2));
% end
% K_obs=reshape(K, dmd.newSize(1)*dmd.newSize(2), dmd.numModes); % K2(:, x) is the x'th output mode

    if onTheFlyReconstruction
        Kinv_angle = reshape(J/4095 * 2*pi - pi,dmd.newSize(1)*dmd.newSize(2),dmd.numModes)';
    else

    Kinv_angle=reshape(atan2((J(:,:,2:3:end))-(J(:,:,3:3:end)), ...
                             (J(:,:,1:3:end))-(J(:,:,2:3:end))), ...
                    dmd.newSize(1)*dmd.newSize(2),dmd.numModes)';
        
    end
    
    dumpVariableToCalibration(dmd.hadamardSize, 'hadamardSize');
    dumpVariableToCalibration(Kinv_angle,'Kinv_angle');
    
%     Kinv_angle=reshape(atan2((J(:,:,dmd.numModes+1:2*dmd.numModes))-(J(:,:,2*dmd.numModes+1:end)), ...
%                              (J(:,:,1:dmd.numModes))-(J(:,:,dmd.numModes+1:2*dmd.numModes))), ...
%                     dmd.newSize(1)*dmd.newSize(2),dmd.numModes)';
%     end
    % Analysis of K
    Variance2D=reshape(1-abs(mean(exp(i*Kinv_angle),1)),dmd.newSize(1:2)); 
    dumpVariableToCalibration(Variance2D);
%
    dumpVariableToCalibration(dmd.fiberBox,'fiberBox');
    dumpVariableToCalibration(dmd.radius,'radius');

    clear J

     dumpVariableToCalibration(binaryDisc);
    dumpVariableToCalibration(dmd.hologramSpotPos,'hologramSpotPos');
   
         dumpVariableToCalibration(dmd.numReferencePixels, 'numReferencePixels');
        dumpVariableToCalibration(dmd.leeBlockSize, 'leeBlockSize');
        dumpVariableToCalibration(opt.selectedCarrier, 'selectedCarrier');
        dumpVariableToCalibration(opt.carrierRotation, 'carrierRotation');
    if opt.keepAngles
         dmd.Kinv_angle = Kinv_angle;
    end
    
    if fullReconstruction 
        fprintf('Computing inverse transform...\n');
        
        % This step essentially computes phaseBasisReal * K. We are only interested in the final phase.
        % But since K and the GPU matrix multiplication is defined for real numbers
        % we split K into K = exp(i*phi) = cos(phi)+ i*sin(phi)
        % Then, B * K = B*cos(phi) + i*B*sin(phi)
        % and then we extract the phase (Ein_all)
        A=GetSecs();
        Sk = CudaFastMult(dmd.phaseBasisReal, sin(Kinv_angle)); %Sk=dmd.phaseBasisReal*sin(K);
        Ck = CudaFastMult(dmd.phaseBasisReal, cos(Kinv_angle)); % Ck=dmd.phaseBasisReal*cos(K);
        Ein_all=atan2(Sk,Ck);
        B=GetSecs();
        
        % Sk=phaseBasisReal*sin(K);
        % Ck=phaseBasisReal*cos(K);
        % Ein_all=atan2(Sk,Ck);
        % Ein_all2 = FastInverseTransform(dmd.phaseBasisReal', K);
        % clear J
        % dmd.Ein_all=angle(dmd.phaseBasisReal* exp(1i*K));
        
        
        %% generate holograms for
        % Find all pixels inside the fiber
        
        fprintf('Generating holograms for %d patterns\n',dmd.numSpots);
        % Generate a dummy disc to get pixel coordinates inside the disc
        %[dmd.spotY,dmd.spotX]=ind2sub(dmd.newSize(1:2),insideInd);
        % Generate all lee holograms for all spots
        inputPhases=reshape(Ein_all(:,dmd.hologramSpotPos), dmd.hadamardSize,dmd.hadamardSize,dmd.numSpots);
        clear Ein_all
        dumpVariableToCalibration(inputPhases,'inputPhases');
        dmd.holograms = CudaFastLee(inputPhases,dmd.numReferencePixels, dmd.leeBlockSize, opt.selectedCarrier, opt.carrierRotation);
        clear inputPhases
    else
        dmd.Kinv_angle = Kinv_angle;
    end
    
    clear Kinv_angle
    
    
    %% now run a sweep test
    if sweepTest
        fprintf('Now Running a spot test\n');
        
        dumpVariableToCalibration(roi.selectedSpots, 'selectedSpeedTestSpots');
        abSelectedSpots = ismember(dmd.hologramSpotPos,roi.selectedSpots);
        indicesToHolograms = find(abSelectedSpots);
        
        FilterWheelModule('SetNaturalDensity',[1,dmd.naturalDensityForSweepTest]);
        PTwrapper('SetExposure',1/exposureForSweepTest);
        
        numSpots = length(indicesToHolograms);
        Z=PTwrapper('GetImageBuffer');
        ALPuploadAndPlay(zeros(768,1024)>0,dmd.cameraRate,100);
        ALPwrapper('WaitForSequenceCompletion');
        WaitSecs(1); % allow all images to reach buffer
        baseline=PTwrapper('GetImageBuffer');
        darkImage = mean(single(baseline),3);
        fprintf('Now Uploading %d patterns\n',length(indicesToHolograms));
        numRepetitions = 3;
        PTwrapper('StartAveraging', length(indicesToHolograms),false);
        ALPuploadAndPlay(dmd.holograms(:, :,indicesToHolograms), dmd.cameraRate,numRepetitions);
        ALPwrapper('WaitForSequenceCompletion');
        WaitSecs(0.5); % allow all images to reach buffer
        PTwrapper('StopAveraging');        
        SpotCalibrationImages=PTwrapper('GetImageBuffer');
        if size(SpotCalibrationImages,3) ~= numSpots
            fprintf('Failed to calibrate (image mismatch!)\n');
            return
        end
        
        % analyze enhancement factor
        [y,x]=ind2sub(size(binaryDisc),dmd.hologramSpotPos(abSelectedSpots));
        
        insideHalfRadius = sqrt((x-roi.radius).^2+(y-roi.radius).^2) < roi.radius/2;
        
        W = 10;
        maxIntensityMapping = zeros(1, sum(abSelectedSpots));
        mapIntensity2D = zeros(size(binaryDisc));
        enhancemnentFactor2D= zeros(size(binaryDisc));
        displacementMap = zeros(2, sum(abSelectedSpots));
        enhancemnentFactor  = zeros(1, sum(abSelectedSpots));
        [XX,YY]=meshgrid(1:size(SpotCalibrationImages,2),1:size(SpotCalibrationImages,1));
        cent = [ceil(dmd.fiberBox(1)+dmd.fiberBox(3)/2),         ceil(dmd.fiberBox(2)+dmd.fiberBox(4)/2)];
        Idisk = (XX-cent(1)).^2+(YY-cent(2)).^2 <= roi.radius^2;
        numOverExposed = sum(squeeze(max(max(SpotCalibrationImages,[],1),[],2)) > 4000);
        for k=1:size(SpotCalibrationImages,3)
            I=single(SpotCalibrationImages(:,:,k))-darkImage;
            x0 = x(k)+ dmd.fiberBox(1)-1;
            y0 = y(k)+dmd.fiberBox(2)-1;
            xrange = min(size(SpotCalibrationImages,2), max(1,x0-W:x0+W));
            yrange = min(size(SpotCalibrationImages,1),max(1,y0-W:y0+W));
            values = I(yrange,xrange);
            [maxIntensityMapping(k), maxLocalInd]= max(values(:));
            
            [my,mx]=ind2sub(size(values), maxLocalInd);
            displacementMap(1,k)= xrange(mx);
            displacementMap(2,k)= yrange(my);
            mapIntensity2D(y(k),x(k))=maxIntensityMapping(k);
            I(yrange,xrange)=0;
            enhancemnentFactor(k) = maxIntensityMapping(k)/mean(I(Idisk));
            enhancemnentFactor2D(y(k),x(k))=enhancemnentFactor(k);
        end
        dumpVariableToCalibration([x(:),y(:)],'sweepTestPositions');
        dumpVariableToCalibration(dmd.hologramSpotPos(abSelectedSpots),'sweepTestPositionsIndices');
        dumpVariableToCalibration(enhancemnentFactor,'enhancemnentFactor');
        dumpVariableToCalibration(enhancemnentFactor2D,'enhancemnentFactor2D');
        dumpVariableToCalibration(displacementMap,'displacementMap');
        dumpVariableToCalibration(maxIntensityMapping,'maxIntensityMapping');
        dumpVariableToCalibration(mapIntensity2D,'mapIntensity2D');
        dumpVariableToCalibration(darkImage,'darkImage')
        dumpVariableToCalibration(SpotCalibrationImages,'SpotCalibrationImages')
        dumpVariableToCalibration(roi.boundingbox,'boundingbox');
        dumpVariableToCalibration(roi.Mask,'RoiMask');
        dmd.sweepTestPositionsIndices = dmd.hologramSpotPos(abSelectedSpots);
        dmd.enhancemnentFactor = enhancemnentFactor;
        dmd.displacementMap = displacementMap;
        dmd.maxIntensityMapping = maxIntensityMapping ;
        
        clear SpotCalibrationImages
        fprintf('Spot sweep test finished. Average enhancement: %.2f +- %.2f (%.2f +- %.2f) in half radius\n', mean(enhancemnentFactor), std(enhancemnentFactor),...
        mean(enhancemnentFactor(insideHalfRadius)),std(enhancemnentFactor(insideHalfRadius)));
        if numOverExposed > 0
            fprintf('Warning, overexposure detected in %d spots\n',numOverExposed);
        end
        
    end
    
   if psfZtest
        % Set center spot
        FilterWheelModule('SetNaturalDensity',[1,dmd.naturalDensityForSweepTest]);
        PTwrapper('SetExposure',1/exposureForSweepTest);
        
        Z=PTwrapper('GetImageBuffer');
        ALPuploadAndPlay(zeros(768,1024)>0,dmd.cameraRate,100);
        ALPwrapper('WaitForSequenceCompletion');
        WaitSecs(1); % allow all images to reach buffer
        baseline=PTwrapper('GetImageBuffer');
        darkImageForPSF = mean(single(baseline),3);
        
        
        [Ay,Ax]=ind2sub(dmd.newSize(1:2), dmd.hologramSpotPos);
        % find closest point...
        x0=dmd.fiberBox(3)/2;
        y0=dmd.fiberBox(4)/2;
        [~, centralPixelIndex]=min( sqrt ((Ax-x0).^2+ (Ay-y0).^2));

%         centralPixelIndex = sub2ind(size(binaryDisc), dmd.radius,dmd.radius);
        ALPuploadAndPlay(dmd.holograms(:, :,centralPixelIndex), dmd.cameraRate,1);
        % sample PSF along the Z direction (only for the center spot).
        [~,Fiber_tip_position_um]= MotorControllerWrapper('GetPositionMicrons'); 
        [~,initialSpeed] = MotorControllerWrapper('GetSpeed');
        MotorControllerWrapper('SetSpeed',10);
        samplingPlanesUm = [-samplingRangeUm:samplingStepUm:samplingRangeUm];
        sampledPlanesUm = zeros(1, length(samplingPlanesUm));
        images = zeros(size(darkImageForPSF,1),size(darkImageForPSF,2), length(samplingPlanesUm));
        for k=1:length(samplingPlanesUm)
            %fprintf('%d) Going to %.2f\n',k,Fiber_tip_position_um+(samplingPlanesUm(k)));
            MotorControllerWrapper('SetAbsolutePositionMicrons',Fiber_tip_position_um+(samplingPlanesUm(k)));
            [~,reachedLocation] = MotorControllerWrapper('GetPositionMicrons');
            sampledPlanesUm(k) = reachedLocation-Fiber_tip_position_um; 
            fprintf('%d) Going to %.2f, Reached %.2f. Error: %.2f um\n',k,Fiber_tip_position_um+(samplingPlanesUm(k)),reachedLocation, Fiber_tip_position_um+(samplingPlanesUm(k))-reachedLocation);
            I=PTwrapper('GetImageBuffer');
            ALPuploadAndPlay(dmd.holograms(:, :,centralPixelIndex), dmd.cameraRate,10);
            WaitSecs(0.2);
            I=PTwrapper('GetImageBuffer');
            images(:,:,k) = mean(single(I),3);
        end
        dumpVariableToCalibration(images,'PSF_Z');
        dumpVariableToCalibration(samplingPlanesUm,'samplingPlanesUm');
        dumpVariableToCalibration(sampledPlanesUm,'sampledPlanesUm');
        dumpVariableToCalibration(darkImageForPSF,'darkImageForPSF');
        fprintf('PSF Z test finished\n');
        MotorControllerWrapper('SetSpeed',initialSpeed);
      
        MotorControllerWrapper('SetAbsolutePositionMicrons',Fiber_tip_position_um);
    end    
    
    
end

% MotorControllerWrapper('SetAbsolutePositionMicrons', StageZeroDepth);
ALPwrapper('ReleaseSequence',dmd.hadamardSequenceID);

%%

% Form a spot on the center pixel
% % % 
% % % centerPixel = [dmd.radius+1,dmd.radius+1];
% % % centerPixelInd = sub2ind([dmd.newSize(1),dmd.newSize(2)],centerPixel(2),centerPixel(1));
% % % EinCenterPixel = reshape(dmd.Ein_all(:,centerPixelInd), dmd.hadamardSize,dmd.hadamardSize);
% % % SpotPhases = fnPhaseShiftReferencePadLeeHologram(EinCenterPixel, 0, dmd.numReferencePixels, dmd.leeBlockSize,dmd.width,dmd.height,dmd.selectedCarrier);
% % % if dmd.spotSequenceID > 0
% % %     ALPwrapper('ReleaseSequence',dmd.spotSequenceID);
% % % end
% % % dmd.spotSequenceID = ALPwrapper('UploadPatternSequence',SpotPhases);
% clear up memory!
dmd.hadamardSequenceID = -1;
dmd.patternsLoadedAndUploaded = false;
dmd.calibrationFinished = true;

fprintf('Finished all calibration procedures\n');
