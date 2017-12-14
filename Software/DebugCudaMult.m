%load('C:\cache\Debug.mat');
%size(dmd.phaseBasisReal)
%size(Kinv_angle)
A=single(rand(4096,4096));
B=single(rand(4096,4096));
Sk = CudaFastMult(A,B);

%Sk = CudaFastMult(dmd.phaseBasisReal, sin(Kinv_angle));
dmd.hadamardSize = 192;
dmd.numReferencePixels = 0;
dmd.leeBlockSize = 4;
dmd.carrierRotation = [125/180*pi, 0/180*pi];
    dmd.selectedCarrier = [0.2 0.200];
    
walshBasis = fnBuildWalshBasis(dmd.hadamardSize); % returns hadamardSize x hadamardSize x hadamardSize^2
dmd.phaseBasis = single((walshBasis == 1)*pi);

X = CudaFastLee(dmd.phaseBasis+0,dmd.numReferencePixels, dmd.leeBlockSize,dmd.selectedCarrier(1), dmd.carrierRotation(1));

%Skk = dmd.phaseBasisReal* sin(Kinv_angle);