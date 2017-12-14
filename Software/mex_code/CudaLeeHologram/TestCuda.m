
addpath('C:\Users\shayo\Dropbox (MIT)\Code\Waveform Reshaping code\MEX\x64');

Phases = single(rand(4096,4096));
K = single(rand(4096,50));
R2=CudaFastMult(Phases,K);

fprintf('[%d x %d] x [%d x %d]\n',size(Phases,1),size(Phases,2),size(K,1),size(K,2));

A2=GetSecs();
R2=CudaFastMult(Phases,K);
B2=GetSecs();

A1=GetSecs();
R1=Phases*K;
B1=GetSecs();

fprintf('CUDA: %.5f\n',B2-A2);
fprintf('Matlab: %.5f\n',B1-A1);
fprintf('diff : %.5f\n',max(abs(R2(:)-R1(:))));
clear mex
