function inputPhases=GenerateInputPhasesFromNonFullCalibration(h5file, selectedCalibration)
Kinv_angle= h5read(h5file,sprintf('/calibrations/calibration%d/Kinv_angle',selectedCalibration));
hadamardSize = h5read(h5file,sprintf('/calibrations/calibration%d/hadamardSize',selectedCalibration));
hologramSpotPos = h5read(h5file,sprintf('/calibrations/calibration%d/hologramSpotPos',selectedCalibration));
walshBasis = fnBuildWalshBasis(hadamardSize);
numModes = size(walshBasis ,3);
phaseBasis = single((walshBasis == 1)*pi);
phaseBasisReal = single(reshape(real(exp(1i*phaseBasis)),hadamardSize*hadamardSize,numModes));
Sk = CudaFastMult(phaseBasisReal, sin(Kinv_angle)); %Sk=dmd.phaseBasisReal*sin(K);
Ck = CudaFastMult(phaseBasisReal, cos(Kinv_angle)); % Ck=dmd.phaseBasisReal*cos(K);
Ein_all=atan2(Sk,Ck);
inputPhases=reshape(Ein_all(:,hologramSpotPos), hadamardSize,hadamardSize,length(hologramSpotPos));
