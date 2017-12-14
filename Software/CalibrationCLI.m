function [ok,result,CalibSessionFileName]=CalibrationCLI(strctCalibrationParams)
strctBasis = LoadCalibrationPatterns(strctCalibrationParams);

ALPwrapper('Release',strctCalibrationParams.deviceID);
ALPwrapper('Init',strctCalibrationParams.deviceID);
[ok,result,CalibSessionFileName]=RunCalibration(strctCalibrationParams, strctBasis);

function [ok,result,CalibSessionFileName]=RunCalibration(strctCalibrationParams, strctBasis)
result= [];
ok = false;
CalibSessionFileName= [];

cameraInitalized=CameraModule('IsInitialized');
if (~cameraInitalized)
   throwError('Unable to initialize camera module.');
end
CameraModule('StopLiveView');
% CameraTriggerWrapper(1); % Do not skip triggers

if ~FilterWheelModule('IsInitialized')
    displayMessage(handles,'Unable to initialize filter wheel module');
    return
end

if ~MotorControllerWrapper('IsInitialized')
    res = MotorControllerWrapper('Init');
    if ~res
       throwError('Unable to initialize motor stage module');
    end
end

if ~AgilisWrapper('IsInitialized')
    res = AgilisWrapper('Init');
    if ~res
        throwError('Unable to initialize agilis controller module');
        return;
    end
end

%runSweepTest = sum(strctCalibrationParams.sweepTests > 0);
% psfZtest = get(handles.hPSFZtest,'value');
% if runSweepTest || psfZtest
%     set(handles.hFullCalibration,'value',true);
% end    

%% Get Motors position
[~,StageZeroDepth] = MotorControllerWrapper('GetPositionMicrons');
AgilisWrapper('ZeroPosition');

%% Estimate how many calibration iterations we need to run....
if strctCalibrationParams.CalibDepths
    if strctCalibrationParams.CalibrationMotorDirection
        CalibrationDepths = StageZeroDepth + [strctCalibrationParams.DepthMinUm:strctCalibrationParams.DepthIntervalUm:strctCalibrationParams.DepthMaxUm];
    else
        CalibrationDepths = StageZeroDepth - [strctCalibrationParams.DepthMinUm:strctCalibrationParams.DepthIntervalUm:strctCalibrationParams.DepthMaxUm];
    end    
else
    CalibrationDepths= StageZeroDepth ;
end

if strctCalibrationParams.Calib3D
    FineCalibrationDepths = [strctCalibrationParams.FineDepthMinUm:strctCalibrationParams.FineDepthIntervalUm:strctCalibrationParams.FineDepthMaxUm];
else
    FineCalibrationDepths = strctCalibrationParams.FineDepthMinUm;
end

numCalibrationIterations = length(CalibrationDepths);
numFineCalibrationIterations = length(FineCalibrationDepths);
totalColorChannelCount = 2;
colorChannels = strctCalibrationParams.colorChannels;
usedColorChannels = find(colorChannels);
numColorChannels = sum(colorChannels);
colorChannelNames = {'473nm','532nm'};

updateStatus(sprintf('Calibrating at %d depths. At each depth, calibrating %d offsets. %d Color Channel(s), Total calib = %d \n',...
    length(CalibrationDepths), length(FineCalibrationDepths), numColorChannels,numColorChannels*length(CalibrationDepths)*length(FineCalibrationDepths)));

 

if (numColorChannels == 0)
    throwError('Please select at least one color channel');
    return;
end
CalibSessionFileName = SessionWrapper('NewSession');

PTwrapper('SetGain',0); 

[X,Y]=meshgrid(1:2*strctCalibrationParams.radius+1,1:2*strctCalibrationParams.radius+1);
binaryDisc = sqrt((X-(strctCalibrationParams.radius+1)).^2+(Y-(strctCalibrationParams.radius+1)).^2) <= strctCalibrationParams.radius;
% find center pixel coordinates
% get coordinates of binary disc
result.hologramSpotPos = find(binaryDisc(:));


result.numSpots = length(result.hologramSpotPos);
roi.radius  =strctCalibrationParams.radius ;
roi.boundingbox = [1 1 2*strctCalibrationParams.radius+1 2*strctCalibrationParams.radius+1]; % full FOV
roi.subsampling = 2;
roi.maxDMDrate = 22000;
roi.Mask = zeros(2*roi.radius+1,2*roi.radius+1);
roi.selectedRate = roi.maxDMDrate ;
roi=recomputeROI(roi,1);

expTime = size(strctBasis.interferenceBasisPatterns,3)/strctCalibrationParams.cameraRate;

MAX_DMD_PATTERNS = 40000;
reupload = (sum(usedColorChannels)*size(strctBasis.interferenceBasisPatterns,3)) > MAX_DMD_PATTERNS;
if ~reupload
    updateStatus( 'Uploading Calibration patterns');
    % upload only the ones we actually need...
    hadamardSequenceID = zeros(1, totalColorChannelCount);
    for k=1:length(usedColorChannels)
        hadamardSequenceID(usedColorChannels(k))=ALPwrapper('UploadPatternSequence',strctCalibrationParams.deviceID,strctBasis.interferenceBasisPatterns(:,:,:,usedColorChannels(k)));
    end
end
updateStatus(sprintf('Averaging over %d repetitions\n',strctCalibrationParams.numCalibrationAverages));
for CalibrationIteration=1:numCalibrationIterations
    
    relativeDepth = CalibrationDepths(CalibrationIteration)-StageZeroDepth;
    
    if numCalibrationIterations > 1
        updateStatus(sprintf('Moving coarse Z Stage to relative depth %.0f um',relativeDepth));
        MotorControllerWrapper('SetSpeed',250);
        MotorControllerWrapper('SetAbsolutePositionMicrons', CalibrationDepths(CalibrationIteration));
    end
    [~,actualEncoderLocation] = MotorControllerWrapper('GetPositionMicrons');
    
    for FineCalibrationIteration=1:numFineCalibrationIterations
        % Move agilis to the first scan position (probably 0?)
        AgilisWrapper('MoveToPositionUm',FineCalibrationDepths(FineCalibrationIteration)); % Blocking...
        AgilisWrapper('WaitForMotionToEnd');
        
        for ColorChannelIteration=1:numColorChannels
            
            calibrationID=CreateNewCalibration();
            
            currentColorChannel = usedColorChannels(ColorChannelIteration);
            dumpVariableToCalibration(currentColorChannel,'colorChannel');
            dumpVariableToCalibration(colorChannelNames{currentColorChannel},'colorChannelName');
            
            dumpVariableToCalibration(relativeDepth,'relativeDepth');
            dumpVariableToCalibration(actualEncoderLocation,'actualEncoderLocation');
            dumpVariableToCalibration(FineCalibrationDepths(FineCalibrationIteration),'fineEncoderLocation');
            
            
            
            % Set the natural filter needed
            if (currentColorChannel== 1)
                FilterWheelWrapper('ShutterOFF',1);
                FilterWheelWrapper('ShutterON',2);
            else
                FilterWheelWrapper('ShutterOFF',2);
                FilterWheelWrapper('ShutterON',1);
            end
            
            FilterWheelModule('SetNaturalDensity',[currentColorChannel, strctCalibrationParams.naturalDensityForCalibration(currentColorChannel)]); 
            
            updateStatus(sprintf('Channel %s, Depth: %.0f um + %.0f um, %.2f seconds (%.2f min). Running sequence...',...
                colorChannelNames{currentColorChannel},relativeDepth,FineCalibrationDepths(FineCalibrationIteration), expTime*strctCalibrationParams.numCalibrationAverages,expTime*strctCalibrationParams.numCalibrationAverages/60));
            PTwrapper('SetExposure',1.0/strctCalibrationParams.exposureForCalibration);
            
            PTwrapper('StartAveraging',strctBasis.numPatterns,false);
            if reupload
                ALPuploadAndPlay(strctCalibrationParams.deviceID,strctBasis.interferenceBasisPatterns(:,:,:,currentColorChannel),...
                strctCalibrationParams.cameraRate, strctCalibrationParams.numCalibrationAverages);
            else
                res=ALPwrapper('PlayUploadedSequence',strctCalibrationParams.deviceID,hadamardSequenceID(currentColorChannel),strctCalibrationParams.cameraRate, strctCalibrationParams.numCalibrationAverages);
            end
            ALPwrapper('WaitForSequenceCompletion',strctCalibrationParams.deviceID); % Block. Wait for sequence to end.
            WaitSecs(0.5); % allow all images to reach buffer
            PTwrapper('StopAveraging');
            numI=PTwrapper('getNumTrigs');
            if numI ~= strctBasis.numPatterns*strctCalibrationParams.numCalibrationAverages
                updateStatus(sprintf('Images mismatch. Trying again with reduced rate (%.2f min)',expTime*strctCalibrationParams.numCalibrationAverages/60/0.6));
                Z=PTwrapper('GetImageBuffer');
                PTwrapper('StartAveraging',strctBasis.numPatterns,false);
                
                % trying again....
                if reupload
                    ALPuploadAndPlay(strctBasis.interferenceBasisPatterns,ceil(0.6*strctCalibrationParams.cameraRate), strctCalibrationParams.numCalibrationAverages);
                else
                    res=ALPwrapper('PlayUploadedSequence',strctCalibrationParams.deviceID,hadamardSequenceID(currentColorChannel),ceil(0.6*strctCalibrationParams.cameraRate), strctCalibrationParams.numCalibrationAverages);
                end
                ALPwrapper('WaitForSequenceCompletion',strctCalibrationParams.deviceID); % Block. Wait for sequence to end.
                WaitSecs(2); % allow all images to reach buffer
                PTwrapper('StopAveraging');
                numI=PTwrapper('getNumTrigs');
                if numI ~= strctBasis.numPatterns*strctCalibrationParams.numCalibrationAverages
                    MotorControllerWrapper('SetAbsolutePositionMicrons', StageZeroDepth);
                    updateStatus(sprintf('Number of collected images does not match number of calibration patterns (%d/%d)',numI,strctBasis.numPatterns*strctCalibrationParams.numCalibrationAverages));
                    throwError('Incorrect number of images obtained.');
                    return;
                end
            end
            updateStatus( 'Transferring images from camera memory...');
            calibrationImages=PTwrapper('GetImageBuffer');
            calibrationImages(1,1:2,:) = 0; % get rid of timestamp ?
            maxIntensity = squeeze(max(max(calibrationImages,[],1),[],2));
            updateStatus(sprintf('Mean of max intensity: %.2f. Number of images overexposed: %d\n',mean(maxIntensity),sum(maxIntensity>=4094)));
            
            J = single(calibrationImages(strctCalibrationParams.fiberBox(2):strctCalibrationParams.quantization:strctCalibrationParams.fiberBox(2)+strctCalibrationParams.fiberBox(4)-1, ...
                strctCalibrationParams.fiberBox(1):strctCalibrationParams.quantization:strctCalibrationParams.fiberBox(1)+strctCalibrationParams.fiberBox(3)-1,:));
            
            clear calibrationImages
            % fast method for all pixels!
            result.newSize = size(J);
            dumpVariableToCalibration(result.newSize,'newSize');
            
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
            
            
            I0 = J(:,:,1:3:end);
            Ipi_2 = J(:,:,2:3:end);
            Ipi = J(:,:,3:3:end);
            Kobs_conj =  (reshape( ((I0-Ipi_2) + 1i*(Ipi_2-Ipi)) / (2*(1+1i)), result.newSize(1)*result.newSize(2), strctBasis.numModes))';
            clear I0  Ipi_2  Ipi              
            
%             XX=reshape(dmd.phaseBasisReal,64,64,4096);
%             figure(12);clf;imagesc(XX(:,:,66))
%             figure(11);clf;plot(abs(sum(abs(Z'),2)));
            
            
            
            if 0
            Kinv_angle=reshape(atan2((J(:,:,2:3:end))-(J(:,:,3:3:end)), ...
                (J(:,:,1:3:end))-(J(:,:,2:3:end))), ...
                result.newSize(1)*result.newSize(2),strctBasis.numModes)';
            end
            
% % %           Kinv_angle=reshape(atan2((J(:,:,dmd.numModes+1:2*dmd.numModes))-(J(:,:,2*dmd.numModes+1:end)), ...
% % %                                          (J(:,:,1:dmd.numModes))-(J(:,:,dmd.numModes+1:2*dmd.numModes))), ...
% % %                                 dmd.newSize(1)*dmd.newSize(2),dmd.numModes)';
% % %             %     end
      
            dumpVariableToCalibration(strctCalibrationParams.hadamardSize, 'hadamardSize');
            if ~strctCalibrationParams.fullReconstruction
                 Kinv_angle = angle(Kobs_conj);
                dumpVariableToCalibration(Kinv_angle,'Kinv_angle');
                clear Kinv_angle
            end
            
            %     Kinv_angle=reshape(atan2((J(:,:,dmd.numModes+1:2*dmd.numModes))-(J(:,:,2*dmd.numModes+1:end)), ...
            %                              (J(:,:,1:dmd.numModes))-(J(:,:,dmd.numModes+1:2*dmd.numModes))), ...
            %                     dmd.newSize(1)*dmd.newSize(2),dmd.numModes)';
            %     end
            % Analysis of K
            %     Variance2D=reshape(1-abs(mean(exp(i*Kinv_angle),1)),dmd.newSize(1:2));
            %     dumpVariableToCalibration(Variance2D);
            %
            dumpVariableToCalibration(strctCalibrationParams.fiberBox,'fiberBox');
            dumpVariableToCalibration(strctCalibrationParams.radius,'radius');
            
            clear J
            
            dumpVariableToCalibration(binaryDisc);
            dumpVariableToCalibration(result.hologramSpotPos,'hologramSpotPos');
            
            dumpVariableToCalibration(strctCalibrationParams.numReferencePixels, 'numReferencePixels');
            dumpVariableToCalibration(strctCalibrationParams.leeBlockSize, 'leeBlockSize');
            dumpVariableToCalibration(strctCalibrationParams.selectedCarrier(currentColorChannel), 'selectedCarrier');
            dumpVariableToCalibration(strctCalibrationParams.carrierRotation(currentColorChannel), 'carrierRotation');
            
            if strctCalibrationParams.fullReconstruction
                updateStatus('Computing inverse transform...');
                % reconstruct Kinv from Kobs_conj
                
                %X=(A+B*i), Y=(C+D*i) => X*Y = A*C-B*D + 1i*(A*D+B*C)
                % => B=0 => X*Y= A*C + 1i*(A*D)
               Sk = CudaFastMult(strctBasis.phaseBasisReal, real(Kobs_conj));
               Ck = CudaFastMult(strctBasis.phaseBasisReal, imag(Kobs_conj));
               % Kinv = Sk + i*Ck
               
                % To convert 
                % This step essentially computes phaseBasisReal * K. We are only interested in the final phase.
                % But since K and the GPU matrix multiplication is defined for real numbers
                % we split K into K = exp(i*phi) = cos(phi)+ i*sin(phi)
                % Then, B * K = B*cos(phi) + i*B*sin(phi)
                % and then we extract the phase (Ein_all)
                A=GetSecs();
               % Sk = CudaFastMult(dmd.phaseBasisReal, sin(Kinv_angle)); %Sk=dmd.phaseBasisReal*sin(K);
%                Ck = CudaFastMult(dmd.phaseBasisReal, cos(Kinv_angle)); % Ck=dmd.phaseBasisReal*cos(K);



                if strctCalibrationParams.spotRadiusPixels == 1
                    % single pixel spots
                    Ein_all=atan2(Sk,Ck);
                    inputPhases=reshape(Ein_all(:,result.hologramSpotPos), strctCalibrationParams.hadamardSize,strctCalibrationParams.hadamardSize,result.numSpots);

                else 
                    % multi pixel spots
                    inputPhases = zeros( strctCalibrationParams.hadamardSize,strctCalibrationParams.hadamardSize,result.numSpots,'single');
                     [spotY,spotX]=ind2sub(size(binaryDisc),result.hologramSpotPos);
                    

                    
                    
%                     [spotX,spotY]=find(binaryDisc(:));


                    for k=1:length(result.hologramSpotPos)
                        % find neighbors
                        neighInd =  find(sqrt((spotX(k)-spotX).^2+ (spotY(k)-spotY).^2) <= strctCalibrationParams.spotRadiusPixels);
                        inputPhases(:,:, k) = reshape(atan2(sum(Sk(:,result.hologramSpotPos(neighInd)),2), sum(Ck(:,result.hologramSpotPos(neighInd)),2)),  strctCalibrationParams.hadamardSize,strctCalibrationParams.hadamardSize);
                    end
                   

                end
                
                % Sk=phaseBasisReal*sin(K);
                % Ck=phaseBasisReal*cos(K);
                % Ein_all=atan2(Sk,Ck);
                % Ein_all2 = FastInverseTransform(dmd.phaseBasisReal', K);
                % clear J
                % dmd.Ein_all=angle(dmd.phaseBasisReal* exp(1i*K));
                
                
                %% generate holograms for
                % Find all pixels inside the fiber
                
                updateStatus(sprintf('Generating holograms for %d patterns',result.numSpots));
                % Generate a dummy disc to get pixel coordinates inside the disc
                %[dmd.spotY,dmd.spotX]=ind2sub(dmd.newSize(1:2),insideInd);
                % Generate all lee holograms for all spots
                clear Ein_all
                dumpVariableToCalibration(inputPhases,'inputPhases');
                result.holograms = CudaFastLee(inputPhases,strctCalibrationParams.numReferencePixels, strctCalibrationParams.leeBlockSize, strctCalibrationParams.selectedCarrier(currentColorChannel), strctCalibrationParams.carrierRotation(currentColorChannel));
                clear inputPhases
            else
                result.Kinv_angle = Kinv_angle;
            end
            
            clear Kinv_angle
            
            
            %% now run a sweep test
            if strctCalibrationParams.sweepTests(currentColorChannel)
                strTitle=sprintf('Session %d, Depth :  %.0f um + %.0f um', SessionWrapper('GetSessionID'), relativeDepth,FineCalibrationDepths(FineCalibrationIteration));
%                 dmd = sweepTest(dmd,handles,strTitle, currentColorChannel);
%                 stats = dmd.stats;
            end
            
            if strctCalibrationParams.psfZtest
                % Set center spot
                samplingStepUm = str2num(get(handles.hPSF_Z_Step,'String'));
                samplingRangeUm = str2num(get(handles.hPSF_Z_Range,'String'));
                FilterWheelModule('SetNaturalDensity',[1, dmd.naturalDensityForSweepTest]);figure(handles.figure1);
                PTwrapper('SetExposure',1/dmd.exposureForSweepTest);
                
                Z=PTwrapper('GetImageBuffer');
                ALPuploadAndPlay(dmd.deviceID,zeros(768,1024)>0,dmd.cameraRate,100);
                ALPwrapper('WaitForSequenceCompletion',dmd.deviceID);
                WaitSecs(1); % allow all images to reach buffer
                baseline=PTwrapper('GetImageBuffer');
                darkImageForPSF = mean(single(baseline),3);
                
                
                [Ay,Ax]=ind2sub(dmd.newSize(1:2), result.hologramSpotPos);
                % find closest point...
                x0=dmd.fiberBox(3)/2;
                y0=dmd.fiberBox(4)/2;
                [~, centralPixelIndex]=min( sqrt ((Ax-x0).^2+ (Ay-y0).^2));
                
                %         centralPixelIndex = sub2ind(size(binaryDisc), dmd.radius,dmd.radius);
                ALPuploadAndPlay(result.holograms(:, :,centralPixelIndex), dmd.cameraRate,1);
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
                    updateStatus('%d) Going to %.2f, Reached %.2f. Error: %.2f um\n',k,Fiber_tip_position_um+(samplingPlanesUm(k)),reachedLocation, Fiber_tip_position_um+(samplingPlanesUm(k))-reachedLocation);
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
                updateStatus('PSF Z test finished\n');
                MotorControllerWrapper('SetSpeed',initialSpeed);
                
                MotorControllerWrapper('SetAbsolutePositionMicrons',Fiber_tip_position_um);
            end
        end
    end
end
ALPwrapper('ReleaseSequence',strctCalibrationParams.deviceID,hadamardSequenceID);



updateStatus('Finished all calibration procedures\n');

if strctCalibrationParams.returnToZero 
    MotorControllerWrapper('SetSpeed',450);
    MotorControllerWrapper('SetAbsolutePositionMicrons', StageZeroDepth);
    AgilisWrapper('MoveToPositionUm',0);

end
updateStatus('Finished Calibration!');
return




function strctBasis=LoadCalibrationPatterns(strctCalibrationParams)
% FORCE_BASIS = true;
% SAVE = false;
if ~exist('C:/cache','dir')
    mkdir('C:/cache');
end

% walshBasis1 = fnBuildWalshBasisCircular(dmd.hadamardSize, dmd.numBasis);
% walshBasis2 = fnBuildWalshBasis(dmd.hadamardSize, dmd.numBasis); % returns hadamardSize x hadamardSize x hadamardSize^2
% walshBasis = cat(3,walshBasis1(:,:,1:2048),walshBasis2(:,:,1:2048));
walshBasis = fnBuildWalshBasis(strctCalibrationParams.hadamardSize, strctCalibrationParams.numBasis); % returns hadamardSize x hadamardSize x hadamardSize^2

strctBasis.numModes = size(walshBasis ,3);
% fprintf('Using %dx%d basis. Each uses %dx%d mirrors. Reference is %d pixels, which is %.3f of area\n',...
%     dmd.hadamardSize,dmd.hadamardSize,dmd.leeBlockSize,dmd.leeBlockSize,dmd.numReferencePixels, ...
%     (4*dmd.numReferencePixels*dmd.effectiveDMDsize-4*dmd.numReferencePixels*dmd.numReferencePixels)/(dmd.effectiveDMDsize*dmd.effectiveDMDsize));

phaseBasis = single((walshBasis == 1)*pi);
strctBasis.phaseBasisReal = single(reshape(real(exp(1i*phaseBasis)),strctCalibrationParams.hadamardSize*strctCalibrationParams.hadamardSize,strctBasis.numModes));

clear walshBasis 
% Phase shift the basis and append with a fixed reference.
probedInterferencePhases =  [0, pi/2, pi];
%probedInterferencePhases =  [0, pi/2, pi, 3*pi/2];

strctBasis.numPhases = length(probedInterferencePhases);

% cacheFile = sprintf('C:/cache/packedInterferenceBasisPatterns_%d_%d_%d.mat',dmd.hadamardSize,dmd.leeBlockSize,dmd.numBasis);


% if exist(cacheFile,'file') && ~FORCE_BASIS
%     displayMessage(handles, sprintf('Loading interference basis patterns from cache file %s...',cacheFile));
%     A=GetSecs();
%     load(cacheFile);
%     B=GetSecs();
%     fprintf('Loaded in %.2f Sec\n',(B-A));
% else
%     interferenceBasisPatternsSlowButAccurate = fnPhaseShiftReferencePadLeeHologram(...
%         dmd.phaseBasis(:,:,1:100:end), probedInterferencePhases, dmd.numReferencePixels, dmd.leeBlockSize,dmd.width,dmd.height,dmd.selectedCarrier);
%     interferenceBasisPatterns0 = CudaFastLee(dmd.phaseBasis(:,:,1:100:end),dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier);
fprintf('Computing lee holograms of basis functions:  473nm: f=%.2f, theta = %.2f,  532nm: f=%.2f, theta = %.2f\n', ...
    strctCalibrationParams.selectedCarrier(1),strctCalibrationParams.carrierRotation(1)/pi*180,strctCalibrationParams.selectedCarrier(2),strctCalibrationParams.carrierRotation(2)/pi*180);
     numColorChannels = 2;%sum(colorChannels);
    strctBasis.interferenceBasisPatterns = zeros(768,128, strctBasis.numModes*3,numColorChannels,'uint8');
    strctBasis.interferenceBasisPatterns(:,:, 1:3:end,1) = CudaFastLee(phaseBasis+0,strctCalibrationParams.numReferencePixels, strctCalibrationParams.leeBlockSize,strctCalibrationParams.selectedCarrier(1), strctCalibrationParams.carrierRotation(1));
    strctBasis.interferenceBasisPatterns(:,:, 2:3:end,1) = CudaFastLee(phaseBasis+pi/2,strctCalibrationParams.numReferencePixels, strctCalibrationParams.leeBlockSize,strctCalibrationParams.selectedCarrier(1), strctCalibrationParams.carrierRotation(1));
    strctBasis.interferenceBasisPatterns(:,:, 3:3:end,1) = CudaFastLee(phaseBasis+pi,strctCalibrationParams.numReferencePixels, strctCalibrationParams.leeBlockSize,strctCalibrationParams.selectedCarrier(1), strctCalibrationParams.carrierRotation(1));
    strctBasis.interferenceBasisPatterns(:,:, 1:3:end,2) = CudaFastLee(phaseBasis+0,strctCalibrationParams.numReferencePixels, strctCalibrationParams.leeBlockSize,strctCalibrationParams.selectedCarrier(2), strctCalibrationParams.carrierRotation(2));
    strctBasis.interferenceBasisPatterns(:,:, 2:3:end,2) = CudaFastLee(phaseBasis+pi/2,strctCalibrationParams.numReferencePixels, strctCalibrationParams.leeBlockSize,strctCalibrationParams.selectedCarrier(2), strctCalibrationParams.carrierRotation(2));
    strctBasis.interferenceBasisPatterns(:,:, 3:3:end,2) = CudaFastLee(phaseBasis+pi,strctCalibrationParams.numReferencePixels, strctCalibrationParams.leeBlockSize,strctCalibrationParams.selectedCarrier(2), strctCalibrationParams.carrierRotation(2));
    
    
%       interferenceBasisPatterns = cat(3,interferenceBasisPatterns0,interferenceBasisPatterns1,interferenceBasisPatterns2);

%         interferenceBasisPatterns0 = CudaFastLee(phaseBasis+0,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier(1), dmd.carrierRotation(1));
%         interferenceBasisPatterns1 = CudaFastLee(phaseBasis+pi/2,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier(1), dmd.carrierRotation(1));
%         interferenceBasisPatterns2 = CudaFastLee(phaseBasis+pi,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier(1), dmd.carrierRotation(1));
%        interferenceBasisPatterns = cat(3,interferenceBasisPatterns0,interferenceBasisPatterns1,interferenceBasisPatterns2);
%         clear interferenceBasisPatterns0  interferenceBasisPatterns1 interferenceBasisPatterns2
%     if SAVE
%         savefast(cacheFile,'interferenceBasisPatterns');
%     end
% end
strctBasis.numPatterns = size(phaseBasis,3) * strctBasis.numPhases;
clear phaseBasis
%% upload test patterns to the DMD...


% if (dmd.hadamardSequenceID > 0)
%     ALPwrapper('ReleaseSequence',dmd.hadamardSequenceID);
% end
% displayMessage(handles, sprintf('Uploading calibration sequence (%d patterns)...',size(interferenceBasisPatterns,3)));
% dmd.hadamardSequenceID=ALPwrapper('UploadPatternSequence',interferenceBasisPatterns);
% dmd.patternsLoadedAndUploaded = false;

% % clear interferenceBasisPatterns
% handles.dmd = dmd;
% guidata(hObject,handles);
% return;
% 

function updateStatus(message)
fprintf([message,'\n']);
return

function throwError(message)
fprintf([message,'\n']);
assert(false);
return;