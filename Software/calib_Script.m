%% Setup parameters
opt.hadamardSize = 64;
opt.cameraRate = 850;
opt.sweepTest = true;
opt.width = 1024;
opt.height = 768;

opt.carrierRotation = 0/180*pi;
opt.selectedCarrier = 0.200;
opt.backgroundLevel =  320;

opt.SweepZ = false;
opt.DepthMinUm = 0;
opt.DepthMaxUm = 100;
opt.DepthIntervalUm = 50;

opt.psfZtest = false;
opt.samplingStepUm = 2;
opt.samplingRangeUm = 30;

opt.fullReconstruction = true;
opt.numCalibrationAverages = 1;
opt.naturalDensityForSegmentation = 4;
opt.naturalDensityForCalibration = 4;
opt.naturalDensityForSweepTest = 5;
opt.exposureForCalibration = 2000;
opt.exposureForSweepTest = 2000;
opt.exposureForSegmtation = 2000;
opt.keepAngles = true;
opt.quantization = 1;
%%
PTwrapper('Release');

[OffsetX, OffsetY, Res] = GetCameraParams();
PTwrapper('InitWithResolutionOffset',OffsetX,OffsetY,Res,Res);

ALPwrapper('Release');
ALPwrapper('Init');

MotorControllerWrapper('Init');

FilterWheelWrapper('Init');
%%
MotorControllerWrapper('SetAbsolutePositionMicrons',5000);

%%
% Calibrate at three depths (0, 
[~,pos0] = MotorControllerWrapper('GetPositionMicrons');


%%
[fiberBox, radius] = coreCalib_segmentFiber(opt);

positions = [pos0, pos0 + 1000, pos0 + 2000];
clear dmd
for k=1:3
    fprintf('************************** Running Calibration %d ******************\n',k);
    MotorControllerWrapper('SetAbsolutePositionMicrons',positions(k));
    dmd{k} = coreCalib_loadPatterns(opt);
    dmd{k} = coreCalib_runCalibration(dmd{k}, opt,fiberBox, radius);
end

% Now go to intermediate plane
MotorControllerWrapper('SetAbsolutePositionMicrons',positions(2));

% generate an interpolated calibration.
Kinv_angle = (dmd{1}.Kinv_angle+dmd{3}.Kinv_angle)/2;

%%
A=GetSecs();
Sk = CudaFastMult(dmd{1}.phaseBasisReal, sin(Kinv_angle)); %Sk=dmd.phaseBasisReal*sin(K);
Ck = CudaFastMult(dmd{1}.phaseBasisReal, cos(Kinv_angle)); % Ck=dmd.phaseBasisReal*cos(K);
Ein_all=atan2(Sk,Ck);
B=GetSecs();
        
inputPhases=reshape(Ein_all(:,dmd{1}.hologramSpotPos), dmd{1}.hadamardSize,dmd{1}.hadamardSize,dmd{1}.numSpots);
clear Ein_all
        
holograms = CudaFastLee(inputPhases,dmd{1}.numReferencePixels, dmd{1}.leeBlockSize, opt.selectedCarrier, opt.carrierRotation);
clear inputPhases


%% Form spot
[Ay,Ax]=ind2sub(dmd{1}.newSize(1:2), dmd{1}.hologramSpotPos);
x = mean(Ax);
y = mean(Ay);
% find closest point...
[~, indx]=min( sqrt ((Ax-x).^2+ (Ay-y).^2));
P=holograms(:,:,indx);
ALPuploadAndPlay(P,200,1)
figure(11);
clf;hold on;
subplot(2,2,1);imagesc(reshape(dmd{1}.Kinv_angle(:, dmd{1}.hologramSpotPos(indx)),64,64),[-pi,pi]);
subplot(2,2,2);imagesc(reshape(dmd{2}.Kinv_angle(:, dmd{1}.hologramSpotPos(indx)),64,64),[-pi,pi]);
subplot(2,2,3);imagesc(reshape(dmd{3}.Kinv_angle(:, dmd{1}.hologramSpotPos(indx)),64,64),[-pi,pi]);

%% Form spot
[Ay,Ax]=ind2sub(dmd{1}.newSize(1:2), dmd{1}.hologramSpotPos);
x = mean(Ax);
y = mean(Ay);
% find closest point...
[~, indx]=min( sqrt ((Ax-x).^2+ (Ay-y).^2));

P=dmd{1}.holograms(:,:,indx);
ALPuploadAndPlay(P,200,1)

%%
CalibrationModule(dmd);

% Go down 


