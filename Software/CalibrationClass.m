classdef CalibrationClass  < handle
    properties
        strctCalibrationParams = [];
        strctResult = [];
        strctBasis = [];
    end
    
    methods
        function setCalibrationParams(obj, params)
            obj.strctCalibrationParams = params;
            obj.init();
            return;
        end
        
        function Calibrate(obj)
            obj.strctResult = obj.Run();
        end
            
        function init(obj)
            obj.strctBasis = obj.LoadCalibrationPatterns();
        end
       
        
        function obj = CalibrationClass(val1,strctSegmentationResult)
            if (isstring(val1))
                obj=initializeFromFile(val1);
            else
                strctParams = val1;
                strctParams.fiberBox = strctSegmentationResult.fiberBox;
                strctParams.radius= strctSegmentationResult.radius;
                obj.setCalibrationParams(strctParams);
            end
            
        end
        
         % Forms a spot at a given position (x,y) 
         function P=generateHolorgramSpot(obj, x,y)
            if isempty(obj.strctResult)
                throwError('Run calibration first!');
                return
            end
            [Ay,Ax]=ind2sub(obj.strctResult.newSize(1:2), obj.strctResult.hologramSpotPos);
            % find closest point...
            [~, indx]=min( sqrt ((Ax-x).^2+ (Ay-y).^2));
            
            if (isfield(obj.strctResult,'holograms'))
                P=obj.strctResult.holograms(:,:,indx);
               
            else
                % find closest point...
                Sk = obj.strctBasis.phaseBasisReal.phaseBasisReal* sin(obj.strctResult.Kinv_angle(:,obj.strctResult.hologramSpotPos(indx))); %Sk=dmd.phaseBasisReal*sin(K);
                Ck = obj.strctBasis.phaseBasisReal.phaseBasisReal* cos(obj.strctResult.Kinv_angle(:,obj.strctResult.hologramSpotPos(indx))); % Ck=dmd.phaseBasisReal*cos(K);
                inputPhases=reshape(atan2(Sk,Ck), strctCalibrationParams.hadamardSize,strctCalibrationParams.hadamardSize);
                P = CudaFastLee(inputPhases,strctCalibrationParams.numReferencePixels, strctCalibrationParams.leeBlockSize, strctCalibrationParams.selectedCarrier, strctCalibrationParams.carrierRotation);
            end
        end
        
        % Forms a spot at a given position (x,y) 
        function formSpot(obj, x,y)
            if isempty(obj.strctResult)
                throwError('Run calibration first!');
                return
            end
            [Ay,Ax]=ind2sub(obj.strctResult.newSize(1:2), obj.strctResult.hologramSpotPos);
            % find closest point...
            [~, indx]=min( sqrt ((Ax-x).^2+ (Ay-y).^2));
            
            if (isfield(obj.strctResult,'holograms'))
                P=obj.strctResult.holograms(:,:,indx);
               
            else
                % find closest point...
                Sk = obj.strctBasis.phaseBasisReal.phaseBasisReal* sin(obj.strctResult.Kinv_angle(:,obj.strctResult.hologramSpotPos(indx))); %Sk=dmd.phaseBasisReal*sin(K);
                Ck = obj.strctBasis.phaseBasisReal.phaseBasisReal* cos(obj.strctResult.Kinv_angle(:,obj.strctResult.hologramSpotPos(indx))); % Ck=dmd.phaseBasisReal*cos(K);
                inputPhases=reshape(atan2(Sk,Ck), strctCalibrationParams.hadamardSize,strctCalibrationParams.hadamardSize);
                P = CudaFastLee(inputPhases,strctCalibrationParams.numReferencePixels, strctCalibrationParams.leeBlockSize, strctCalibrationParams.selectedCarrier, strctCalibrationParams.carrierRotation);
            end
            ALPuploadAndPlay(obj.strctCalibrationParams.deviceID,P,200,1);
            
        end
        
        function obj=initializeFromFile(calibFile)
            inf=h5info(calibFile);
            try
                numReferencePixels= h5read(calibFile,sprintf('/calibrations/calibration%d/numReferencePixels',selectedCalibration));
                leeBlockSize= h5read(calibFile,sprintf('/calibrations/calibration%d/leeBlockSize',selectedCalibration));
                selectedCarrier= h5read(calibFile,sprintf('/calibrations/calibration%d/selectedCarrier',selectedCalibration));
                try
                    inputPhases= h5read(calibFile,sprintf('/calibrations/calibration%d/inputPhases',selectedCalibration));
                catch
                    inputPhases=GenerateInputPhasesFromNonFullCalibration(calibFile, selectedCalibration);
                end
                
                obj.strctResult.hologramSpotPos = h5read(calibFile,sprintf('/calibrations/calibration%d/hologramSpotPos',selectedCalibration));
                obj.strctResult.fiberBox = h5read(calibFile,sprintf('/calibrations/calibration%d/fiberBox',selectedCalibration));
                obj.strctResult.newSize= h5read(calibFile,sprintf('/calibrations/calibration%d/newSize',selectedCalibration));
                carrierRotation = h5read(calibFile,sprintf('/calibrations/calibration%d/carrierRotation',selectedCalibration));
                fprintf('Now generating holograms...');
                obj.strctResult.holograms = CudaFastLee(inputPhases,numReferencePixels, leeBlockSize, selectedCarrier, carrierRotation);
                
%                 try
%                     handles.dmd.sweepTestPositionsIndices  = h5read(calibFile,sprintf('/calibrations/calibration%d/sweepTestPositionsIndices',selectedCalibration));
%                     handles.dmd.enhancemnentFactor = h5read(calibFile,sprintf('/calibrations/calibration%d/enhancemnentFactor',selectedCalibration));
%                     handles.dmd.displacementMap = h5read(calibFile,sprintf('/calibrations/calibration%d/displacementMap',selectedCalibration));
%                     handles.dmd.maxIntensityMapping = h5read(calibFile,sprintf('/calibrations/calibration%d/maxIntensityMapping',selectedCalibration));
%                 catch
%                     fprintf('No spot sweep test available in this calibraiton file.\n');
%                     handles.dmd.sweepTestPositionsIndices  = [];
%                     handles.dmd.enhancemnentFactor  = [];
%                     handles.dmd.displacementMap  = [];
%                     handles.dmd.maxIntensityMapping  = [];
%                 end
            end
        end
        
        function strctBasis=LoadCalibrationPatterns(obj)
            % FORCE_BASIS = true;
            % SAVE = false;
            if ~exist('C:/cache','dir')
                mkdir('C:/cache');
            end
            
            % walshBasis1 = fnBuildWalshBasisCircular(dmd.hadamardSize, dmd.numBasis);
            % walshBasis2 = fnBuildWalshBasis(dmd.hadamardSize, dmd.numBasis); % returns hadamardSize x hadamardSize x hadamardSize^2
            % walshBasis = cat(3,walshBasis1(:,:,1:2048),walshBasis2(:,:,1:2048));
            walshBasis = fnBuildWalshBasis(obj.strctCalibrationParams.hadamardSize, obj.strctCalibrationParams.numBasis); % returns hadamardSize x hadamardSize x hadamardSize^2
            
            strctBasis.numModes = size(walshBasis ,3);
            % fprintf('Using %dx%d basis. Each uses %dx%d mirrors. Reference is %d pixels, which is %.3f of area\n',...
            %     dmd.hadamardSize,dmd.hadamardSize,dmd.leeBlockSize,dmd.leeBlockSize,dmd.numReferencePixels, ...
            %     (4*dmd.numReferencePixels*dmd.effectiveDMDsize-4*dmd.numReferencePixels*dmd.numReferencePixels)/(dmd.effectiveDMDsize*dmd.effectiveDMDsize));
            
            phaseBasis = single((walshBasis == 1)*pi);
            strctBasis.phaseBasisReal = single(reshape(real(exp(1i*phaseBasis)),obj.strctCalibrationParams.hadamardSize*obj.strctCalibrationParams.hadamardSize,strctBasis.numModes));
            
            clear walshBasis
            % Phase shift the basis and append with a fixed reference.
            probedInterferencePhases =  [0, pi/2, pi];
            %probedInterferencePhases =  [0, pi/2, pi, 3*pi/2];
            
            strctBasis.numPhases = length(probedInterferencePhases);
            
            % cacheFile = sprintf('C:/cache/packedInterferenceBasisPatterns_%d_%d_%d.mat',dmd.hadamardSize,dmd.leeBlockSize,dmd.numBasis);
            
            fprintf('Computing lee holograms of basis functions:  473nm: f=%.2f, theta = %.2f,  532nm: f=%.2f, theta = %.2f\n', ...
                obj.strctCalibrationParams.selectedCarrier(1),obj.strctCalibrationParams.carrierRotation(1),obj.strctCalibrationParams.selectedCarrier(2),obj.strctCalibrationParams.carrierRotation(2));
            numColorChannels = 2;%sum(colorChannels);
            strctBasis.interferenceBasisPatterns = zeros(768,128, strctBasis.numModes*3,numColorChannels,'uint8');
            strctBasis.interferenceBasisPatterns(:,:, 1:3:end,1) = CudaFastLee(phaseBasis+0,obj.strctCalibrationParams.numReferencePixels, obj.strctCalibrationParams.leeBlockSize,obj.strctCalibrationParams.selectedCarrier(1), obj.strctCalibrationParams.carrierRotation(1));
            strctBasis.interferenceBasisPatterns(:,:, 2:3:end,1) = CudaFastLee(phaseBasis+pi/2,obj.strctCalibrationParams.numReferencePixels, obj.strctCalibrationParams.leeBlockSize,obj.strctCalibrationParams.selectedCarrier(1), obj.strctCalibrationParams.carrierRotation(1));
            strctBasis.interferenceBasisPatterns(:,:, 3:3:end,1) = CudaFastLee(phaseBasis+pi,obj.strctCalibrationParams.numReferencePixels, obj.strctCalibrationParams.leeBlockSize,obj.strctCalibrationParams.selectedCarrier(1), obj.strctCalibrationParams.carrierRotation(1));
            strctBasis.interferenceBasisPatterns(:,:, 1:3:end,2) = CudaFastLee(phaseBasis+0,obj.strctCalibrationParams.numReferencePixels, obj.strctCalibrationParams.leeBlockSize,obj.strctCalibrationParams.selectedCarrier(2), obj.strctCalibrationParams.carrierRotation(2));
            strctBasis.interferenceBasisPatterns(:,:, 2:3:end,2) = CudaFastLee(phaseBasis+pi/2,obj.strctCalibrationParams.numReferencePixels, obj.strctCalibrationParams.leeBlockSize,obj.strctCalibrationParams.selectedCarrier(2), obj.strctCalibrationParams.carrierRotation(2));
            strctBasis.interferenceBasisPatterns(:,:, 3:3:end,2) = CudaFastLee(phaseBasis+pi,obj.strctCalibrationParams.numReferencePixels, obj.strctCalibrationParams.leeBlockSize,obj.strctCalibrationParams.selectedCarrier(2), obj.strctCalibrationParams.carrierRotation(2));
            strctBasis.numPatterns = size(phaseBasis,3) * strctBasis.numPhases;
            fprintf('Now ready to run a calibration.\n');
        end
        
        
        function result=Run(obj)
            ALPwrapper('Release',obj.strctCalibrationParams.deviceID);
            ALPwrapper('Init',obj.strctCalibrationParams.deviceID);
            
            result.CalibSessionFileName= [];
            
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
            
            %runSweepTest = sum(obj.strctCalibrationParams.sweepTests > 0);
            % psfZtest = get(handles.hPSFZtest,'value');
            % if runSweepTest || psfZtest
            %     set(handles.hFullCalibration,'value',true);
            % end
            
            %% Get Motors position
            [~,StageZeroDepth] = MotorControllerWrapper('GetPositionMicrons');
            AgilisWrapper('ZeroPosition');
            
            %% Estimate how many calibration iterations we need to run....
            if obj.strctCalibrationParams.CalibDepths
                if obj.strctCalibrationParams.CalibrationMotorDirection
                    CalibrationDepths = StageZeroDepth + [obj.strctCalibrationParams.DepthMinUm:obj.strctCalibrationParams.DepthIntervalUm:obj.strctCalibrationParams.DepthMaxUm];
                else
                    CalibrationDepths = StageZeroDepth - [obj.strctCalibrationParams.DepthMinUm:obj.strctCalibrationParams.DepthIntervalUm:obj.strctCalibrationParams.DepthMaxUm];
                end
            else
                CalibrationDepths= StageZeroDepth ;
            end
            
            if obj.strctCalibrationParams.Calib3D
                FineCalibrationDepths = [obj.strctCalibrationParams.FineDepthMinUm:obj.strctCalibrationParams.FineDepthIntervalUm:obj.strctCalibrationParams.FineDepthMaxUm];
            else
                FineCalibrationDepths = obj.strctCalibrationParams.FineDepthMinUm;
            end
            
            numCalibrationIterations = length(CalibrationDepths);
            numFineCalibrationIterations = length(FineCalibrationDepths);
            totalColorChannelCount = 2;
            colorChannels = obj.strctCalibrationParams.colorChannels;
            usedColorChannels = find(colorChannels);
            numColorChannels = sum(colorChannels);
            colorChannelNames = {'473nm','532nm'};
            
            obj.updateStatus(sprintf('Calibrating at %d depths. At each depth, calibrating %d offsets. %d Color Channel(s), Total calib = %d \n',...
                length(CalibrationDepths), length(FineCalibrationDepths), numColorChannels,numColorChannels*length(CalibrationDepths)*length(FineCalibrationDepths)));
            
            
            
            if (numColorChannels == 0)
                throwError('Please select at least one color channel');
                return;
            end
            result.CalibSessionFileName = SessionWrapper('NewSession');
            
            XimeaWrapper('SetGain',0);
            
            [X,Y]=meshgrid(1:2*obj.strctCalibrationParams.radius+1,1:2*obj.strctCalibrationParams.radius+1);
            binaryDisc = sqrt((X-(obj.strctCalibrationParams.radius+1)).^2+(Y-(obj.strctCalibrationParams.radius+1)).^2) <= obj.strctCalibrationParams.radius;
            % find center pixel coordinates
            % get coordinates of binary disc
            result.hologramSpotPos = find(binaryDisc(:));
            
            
            result.numSpots = length(result.hologramSpotPos);
            roi.radius  =obj.strctCalibrationParams.radius ;
            roi.boundingbox = [1 1 2*obj.strctCalibrationParams.radius+1 2*obj.strctCalibrationParams.radius+1]; % full FOV
            roi.subsampling = 2;
            roi.maxDMDrate = 22000;
            roi.Mask = zeros(2*roi.radius+1,2*roi.radius+1);
            roi.selectedRate = roi.maxDMDrate ;
            roi=recomputeROI(roi,1);
            
            expTime = size(obj.strctBasis.interferenceBasisPatterns,3)/obj.strctCalibrationParams.cameraRate;
            
            MAX_DMD_PATTERNS = 40000;
            reupload = (sum(usedColorChannels)*size(obj.strctBasis.interferenceBasisPatterns,3)) > MAX_DMD_PATTERNS;
            if ~reupload
                obj.updateStatus( 'Uploading Calibration patterns');
                % upload only the ones we actually need...
                hadamardSequenceID = zeros(1, totalColorChannelCount);
                for k=1:length(usedColorChannels)
                    hadamardSequenceID(usedColorChannels(k))=ALPwrapper('UploadPatternSequence',obj.strctCalibrationParams.deviceID,obj.strctBasis.interferenceBasisPatterns(:,:,:,usedColorChannels(k)));
                end
            end
            obj.updateStatus(sprintf('Averaging over %d repetitions\n',obj.strctCalibrationParams.numCalibrationAverages));
            for CalibrationIteration=1:numCalibrationIterations
                
                relativeDepth = CalibrationDepths(CalibrationIteration)-StageZeroDepth;
                
                if numCalibrationIterations > 1
                    obj.updateStatus(sprintf('Moving coarse Z Stage to relative depth %.0f um',relativeDepth));
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
                        
                        FilterWheelModule('SetNaturalDensity',[currentColorChannel, obj.strctCalibrationParams.naturalDensityForCalibration(currentColorChannel)]);
                        
                        obj.updateStatus(sprintf('Channel %s, Depth: %.0f um + %.0f um, %.2f seconds (%.2f min). Running sequence...',...
                            colorChannelNames{currentColorChannel},relativeDepth,FineCalibrationDepths(FineCalibrationIteration), expTime*obj.strctCalibrationParams.numCalibrationAverages,expTime*obj.strctCalibrationParams.numCalibrationAverages/60));
                        XimeaWrapper('SetExposure',1.0/obj.strctCalibrationParams.exposureForCalibration);
                        
                        XimeaWrapper('StartAveraging',obj.strctBasis.numPatterns,false);
                        if reupload
                            ALPuploadAndPlay(obj.strctCalibrationParams.deviceID,obj.strctBasis.interferenceBasisPatterns(:,:,:,currentColorChannel),...
                                obj.strctCalibrationParams.cameraRate, obj.strctCalibrationParams.numCalibrationAverages);
                        else
                            ALPwrapper('PlayUploadedSequence',obj.strctCalibrationParams.deviceID,hadamardSequenceID(currentColorChannel),obj.strctCalibrationParams.cameraRate, obj.strctCalibrationParams.numCalibrationAverages);
                        end
                        ALPwrapper('WaitForSequenceCompletion',obj.strctCalibrationParams.deviceID); % Block. Wait for sequence to end.
                        WaitSecs(0.5); % allow all images to reach buffer
                        XimeaWrapper('StopAveraging');
                        numI=XimeaWrapper('getNumTrigs');
                        if numI ~= obj.strctBasis.numPatterns*obj.strctCalibrationParams.numCalibrationAverages
                            obj.updateStatus(sprintf('Images mismatch. Trying again with reduced rate (%.2f min)',expTime*obj.strctCalibrationParams.numCalibrationAverages/60/0.6));
                            Z=XimeaWrapper('GetImageBuffer');
                            XimeaWrapper('StartAveraging',obj.strctBasis.numPatterns,false);
                            
                            % trying again....
                            if reupload
                                ALPuploadAndPlay(obj.strctBasis.interferenceBasisPatterns,ceil(0.6*obj.strctCalibrationParams.cameraRate), obj.strctCalibrationParams.numCalibrationAverages);
                            else
                                res=ALPwrapper('PlayUploadedSequence',obj.strctCalibrationParams.deviceID,hadamardSequenceID(currentColorChannel),ceil(0.6*obj.strctCalibrationParams.cameraRate), obj.strctCalibrationParams.numCalibrationAverages);
                            end
                            ALPwrapper('WaitForSequenceCompletion',obj.strctCalibrationParams.deviceID); % Block. Wait for sequence to end.
                            WaitSecs(2); % allow all images to reach buffer
                            XimeaWrapper('StopAveraging');
                            numI=XimeaWrapper('getNumTrigs');
                            if numI ~= obj.strctBasis.numPatterns*obj.strctCalibrationParams.numCalibrationAverages
                                MotorControllerWrapper('SetAbsolutePositionMicrons', StageZeroDepth);
                                obj.updateStatus(sprintf('Number of collected images does not match number of calibration patterns (%d/%d)',numI,obj.strctBasis.numPatterns*obj.strctCalibrationParams.numCalibrationAverages));
                                throwError('Incorrect number of images obtained.');
                                return;
                            end
                        end
                        obj.updateStatus( 'Transferring images from camera memory...');
                        calibrationImages=XimeaWrapper('GetImageBuffer');
                        calibrationImages(1,1:2,:) = 0; % get rid of timestamp ?
                        maxIntensity = squeeze(max(max(calibrationImages,[],1),[],2));
                        obj.updateStatus(sprintf('Mean of max intensity: %.2f. Number of images overexposed: %d\n',mean(maxIntensity),sum(maxIntensity>=1020)));
                        
                        J = single(calibrationImages(obj.strctCalibrationParams.fiberBox(2):obj.strctCalibrationParams.quantization:obj.strctCalibrationParams.fiberBox(2)+obj.strctCalibrationParams.fiberBox(4)-1, ...
                            obj.strctCalibrationParams.fiberBox(1):obj.strctCalibrationParams.quantization:obj.strctCalibrationParams.fiberBox(1)+obj.strctCalibrationParams.fiberBox(3)-1,:));
                        
                        clear calibrationImages
                        % fast method for all pixels!
                        result.newSize = size(J);
                        dumpVariableToCalibration(result.newSize,'newSize');
                        
                        
                        I0 = J(:,:,1:3:end);
                        Ipi_2 = J(:,:,2:3:end);
                        Ipi = J(:,:,3:3:end);
                        Kobs_conj =  (reshape( ((I0-Ipi_2) + 1i*(Ipi_2-Ipi)) / (2*(1+1i)), result.newSize(1)*result.newSize(2), obj.strctBasis.numModes))';
                        clear I0  Ipi_2  Ipi
                            
                       
                        dumpVariableToCalibration(obj.strctCalibrationParams.hadamardSize, 'hadamardSize');
                        if ~obj.strctCalibrationParams.fullReconstruction
                            Kinv_angle = angle(Kobs_conj);
                            dumpVariableToCalibration(Kinv_angle,'Kinv_angle');
                            clear Kinv_angle
                        end
                     
                        dumpVariableToCalibration(obj.strctCalibrationParams.fiberBox,'fiberBox');
                        dumpVariableToCalibration(obj.strctCalibrationParams.radius,'radius');
                        
                        clear J
                        
                        dumpVariableToCalibration(binaryDisc);
                        dumpVariableToCalibration(result.hologramSpotPos,'hologramSpotPos');
                        
                        dumpVariableToCalibration(obj.strctCalibrationParams.numReferencePixels, 'numReferencePixels');
                        dumpVariableToCalibration(obj.strctCalibrationParams.leeBlockSize, 'leeBlockSize');
                        dumpVariableToCalibration(obj.strctCalibrationParams.selectedCarrier(currentColorChannel), 'selectedCarrier');
                        dumpVariableToCalibration(obj.strctCalibrationParams.carrierRotation(currentColorChannel), 'carrierRotation');
                        
                        if obj.strctCalibrationParams.fullReconstruction
                            obj.updateStatus('Computing inverse transform...');
                            % reconstruct Kinv from Kobs_conj
                            
                            %X=(A+B*i), Y=(C+D*i) => X*Y = A*C-B*D + 1i*(A*D+B*C)
                            % => B=0 => X*Y= A*C + 1i*(A*D)
                            Sk = CudaFastMult(obj.strctBasis.phaseBasisReal, real(Kobs_conj));
                            Ck = CudaFastMult(obj.strctBasis.phaseBasisReal, imag(Kobs_conj));
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
                            
                            
                            
                            if obj.strctCalibrationParams.spotRadiusPixels == 1
                                % single pixel spots
                                Ein_all=atan2(Sk,Ck);
                                inputPhases=reshape(Ein_all(:,result.hologramSpotPos), obj.strctCalibrationParams.hadamardSize,obj.strctCalibrationParams.hadamardSize,result.numSpots);
                                
                            else
                                % multi pixel spots
                                inputPhases = zeros( obj.strctCalibrationParams.hadamardSize,obj.strctCalibrationParams.hadamardSize,result.numSpots,'single');
                                [spotY,spotX]=ind2sub(size(binaryDisc),result.hologramSpotPos);
                                
                                
                                
                                
                                %                     [spotX,spotY]=find(binaryDisc(:));
                                
                                
                                for k=1:length(result.hologramSpotPos)
                                    % find neighbors
                                    neighInd =  find(sqrt((spotX(k)-spotX).^2+ (spotY(k)-spotY).^2) <= obj.strctCalibrationParams.spotRadiusPixels);
                                    inputPhases(:,:, k) = reshape(atan2(sum(Sk(:,result.hologramSpotPos(neighInd)),2), sum(Ck(:,result.hologramSpotPos(neighInd)),2)),  obj.strctCalibrationParams.hadamardSize,obj.strctCalibrationParams.hadamardSize);
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
                            
                            obj.updateStatus(sprintf('Generating holograms for %d patterns',result.numSpots));
                            % Generate a dummy disc to get pixel coordinates inside the disc
                            %[dmd.spotY,dmd.spotX]=ind2sub(dmd.newSize(1:2),insideInd);
                            % Generate all lee holograms for all spots
                            clear Ein_all
                            dumpVariableToCalibration(inputPhases,'inputPhases');
                            result.holograms = CudaFastLee(inputPhases,obj.strctCalibrationParams.numReferencePixels, obj.strctCalibrationParams.leeBlockSize, obj.strctCalibrationParams.selectedCarrier(currentColorChannel), obj.strctCalibrationParams.carrierRotation(currentColorChannel));
                            clear inputPhases
                        else
                            result.Kinv_angle = Kinv_angle;
                        end
                        
                        clear Kinv_angle
                        
                        
                        %% now run a sweep test
                        if obj.strctCalibrationParams.sweepTests(currentColorChannel)
                            strTitle=sprintf('Session %d, Depth :  %.0f um + %.0f um', SessionWrapper('GetSessionID'), relativeDepth,FineCalibrationDepths(FineCalibrationIteration));
                             obj.sweepTestAux(strTitle,currentColorChannel, result);
                        end
                        
                        if obj.strctCalibrationParams.psfZtest
                            % Set center spot
                            samplingStepUm = str2num(get(handles.hPSF_Z_Step,'String'));
                            samplingRangeUm = str2num(get(handles.hPSF_Z_Range,'String'));
                            FilterWheelModule('SetNaturalDensity',[1, dmd.naturalDensityForSweepTest]);figure(handles.figure1);
                            XimeaWrapper('SetExposure',1/dmd.exposureForSweepTest);
                            
                            Z=XimeaWrapper('GetImageBuffer');
                            ALPuploadAndPlay(dmd.deviceID,zeros(768,1024)>0,dmd.cameraRate,100);
                            ALPwrapper('WaitForSequenceCompletion',dmd.deviceID);
                            WaitSecs(1); % allow all images to reach buffer
                            baseline=XimeaWrapper('GetImageBuffer');
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
                                obj.updateStatus('%d) Going to %.2f, Reached %.2f. Error: %.2f um\n',k,Fiber_tip_position_um+(samplingPlanesUm(k)),reachedLocation, Fiber_tip_position_um+(samplingPlanesUm(k))-reachedLocation);
                                I=XimeaWrapper('GetImageBuffer');
                                ALPuploadAndPlay(dmd.holograms(:, :,centralPixelIndex), dmd.cameraRate,10);
                                WaitSecs(0.2);
                                I=XimeaWrapper('GetImageBuffer');
                                images(:,:,k) = mean(single(I),3);
                            end
                            dumpVariableToCalibration(images,'PSF_Z');
                            dumpVariableToCalibration(samplingPlanesUm,'samplingPlanesUm');
                            dumpVariableToCalibration(sampledPlanesUm,'sampledPlanesUm');
                            dumpVariableToCalibration(darkImageForPSF,'darkImageForPSF');
                            obj.updateStatus('PSF Z test finished\n');
                            MotorControllerWrapper('SetSpeed',initialSpeed);
                            
                            MotorControllerWrapper('SetAbsolutePositionMicrons',Fiber_tip_position_um);
                        end
                    end
                end
            end
            ALPwrapper('ReleaseSequence',obj.strctCalibrationParams.deviceID,hadamardSequenceID);
            
            
            
            obj.updateStatus('Finished all calibration procedures\n');
            
            if obj.strctCalibrationParams.returnToZero
                MotorControllerWrapper('SetSpeed',450);
                MotorControllerWrapper('SetAbsolutePositionMicrons', StageZeroDepth);
                AgilisWrapper('MoveToPositionUm',0);
                
            end
            obj.updateStatus('Finished Calibration!');
            
        end

        function recomputeHolograms(obj,colorChannel)
            updateStatus('Full reconstruction was not run during calibration...Generating holograms...\n');
            Sk = obj.strctBasis.phaseBasisReal.phaseBasisReal* sin(obj.strctResult.Kinv_angle(:,obj.strctResult.hologramSpotPos)); %Sk=dmd.phaseBasisReal*sin(K);
            Ck = obj.strctBasis.phaseBasisReal.phaseBasisReal* cos(obj.strctResult.Kinv_angle(:,obj.strctResult.hologramSpotPos)); % Ck=dmd.phaseBasisReal*cos(K);
            Ein=atan2(Sk,Ck);
            inputPhases=reshape(Ein, obj.strctCalibrationParams.hadamardSize,obj.strctCalibrationParams.hadamardSize,obj.strctCalibrationParams.numSpots);
            obj.strctResult.holograms = CudaFastLee(inputPhases,obj.strctCalibrationParams.numReferencePixels, obj.strctCalibrationParams.leeBlockSize, obj.strctCalibrationParams.selectedCarrier(colorChannel), obj.strctCalibrationParams.carrierRotation(colorChannel));
        end

        
        function roi=createSubsampledROI(obj,subsampling)
            roi.radius  =obj.strctCalibrationParams.radius ;
            roi.boundingbox = [1 1 2*obj.strctCalibrationParams.radius+1 2*obj.strctCalibrationParams.radius+1]; % full FOV
            roi.subsampling = subsampling;
            roi.maxDMDrate = 22000;
            roi.Mask = zeros(2*roi.radius+1,2*roi.radius+1);
            roi.selectedRate = roi.maxDMDrate ;
            roi=recomputeROI(roi,1);
        end
        
        function stats = sweepTestAux(obj,strFigureTitle,colorChannel, strctResult)
            roi=obj.createSubsampledROI(2);
            cameraRate = obj.strctCalibrationParams.cameraRate;
            abSelectedSpots = ismember(strctResult.hologramSpotPos,roi.selectedSpots);
            indicesToHolograms = find(abSelectedSpots);
            % analyze enhancement factor
            [y,x]=ind2sub(size(roi.Mask),strctResult.hologramSpotPos(abSelectedSpots));
            patternsToPlay = strctResult.holograms(:, :,indicesToHolograms);
            x = x + obj.strctCalibrationParams.fiberBox(1);
            y = y + obj.strctCalibrationParams.fiberBox(2);
            
            ND = [0,1,2,3,4,5];
            exposures = [6000];
            
            stats = SmartSweepTest(obj.strctCalibrationParams.deviceID,patternsToPlay,  x,y,roi,strFigureTitle,ND,exposures,cameraRate,obj.strctCalibrationParams.fiberBox,colorChannel);
            % Dump data to disk.
            
            dumpVariableToCalibration(stats.meanEnhancement,'meanEnhancement');
            dumpVariableToCalibration(stats.meanEnhancementHalfRadius,'meanEnhancementHalfRadius');
            
            dumpVariableToCalibration(stats.RawImages,'rawCalibrationImages');
            stats.RawImages = [];
            dumpVariableToCalibration(stats.ND ,'naturalDensitySweeps');
            dumpVariableToCalibration(stats.exposures ,'exposureSweeps');
            dumpVariableToCalibration(roi.selectedSpots, 'selectedSpeedTestSpots');
            
            dumpVariableToCalibration([x(:),y(:)],'sweepTestPositions');
            
            dumpVariableToCalibration(indicesToHolograms,'sweepTestPositionsIndices');
            
            dumpVariableToCalibration(stats.enhancemnentFactor,'enhancemnentFactor');
            dumpVariableToCalibration(stats.enhancemnentFactor2D,'enhancemnentFactor2D');
            dumpVariableToCalibration(stats.displacementMap,'displacementMap');
            dumpVariableToCalibration(stats.maxIntensityMapping,'maxIntensityMapping');
            dumpVariableToCalibration(stats.mapIntensity2D,'mapIntensity2D');
            
            dumpVariableToCalibration(stats.gaussianFitAmplitude,'gaussianFitAmplitude');
            dumpVariableToCalibration(stats.gaussianFitAmplitude2D,'gaussianFitAmplitude2D');
            dumpVariableToCalibration(stats.gaussianFitSigma,'gaussianFitSigma');
            dumpVariableToCalibration(stats.gaussianFitSigma2D,'gaussianFitSigma2D');
            dumpVariableToCalibration(roi.boundingbox,'boundingbox');
            dumpVariableToCalibration(roi.Mask,'RoiMask');
        end
        
        function stats = sweepTest(obj,strFigureTitle,colorChannel)
            obj.updateStatus( 'Now Running a spot test');
            if ~isfield(obj.strctResult,'holograms')
                obj.recomputeHolograms(colorChannel);
            end
            stats = sweepTestAux(obj,strFigureTitle,colorChannel, obj.strctResult);
        end

        function updateStatus(obj,message)
        fprintf([message,'\n']);
        end

        function throwError(obj,message)
        fprintf([message,'\n']);
        assert(false);
        end

        
    end
end