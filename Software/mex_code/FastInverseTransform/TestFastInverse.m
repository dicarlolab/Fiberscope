addpath('C:\Users\shayo\Dropbox (MIT)\Code\Waveform Reshaping code\MEX\x64');

phaseBasis = rand(800,800);
K = rand(800,12400);

A1=GetSecs();
R1 = FastInverseTransform(phaseBasis', K);
B1=GetSecs();

A2=GetSecs();
Sk=phaseBasis*sin(K);
Ck=phaseBasis*cos(K);
R2= atan2(Sk,Ck);
B2=GetSecs();


fprintf('mex: %.4f\n',B1-A1);
fprintf('matlab: %.4f\n',B2-A2);
fprintf('Error: %.10f\n',sum(R1(:)-R2(:)));

A=fft2(phaseBasis);
B=fft2(sin(K));
C=A.*B;
D=ifft2(C);
