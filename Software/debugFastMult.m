cd('E:\Dropbox (MIT)\Code\Waveform Reshaping code\MEX\x64');
A=rand(16384,16384,'single');
B=rand(16384,16129,'single');

C=CudaFastMult(A,B);
