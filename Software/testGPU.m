strDropBoxFolder = 'C:\Users\shayo\Dropbox';
cd([strDropBoxFolder,'\Code\Waveform Reshaping code\MEX\x64']);

for ii = 1:gpuDeviceCount
    g = gpuDevice(ii);
    fprintf(1,'Device %i has ComputeCapability %s \n', ...
            g.Index,g.ComputeCapability)
end
%%
N=4096;
K=58000;
chunk = 1000;
startInd = 1:chunk:K;
endInd =startInd+1000-1; 
endInd(end)=min(endInd(end),K);
numChunks=length(startInd);
A = rand(N,N);
B = rand(N,K);
parpool

C = zeros(1,N*K);
t0=GetSecs();
chunkSize = chunk*N;
parfor i=1:numChunks-1
    Ctmp=A*B(:,startInd(i):endInd(i));
    offset=(i-1)*chunkSize+1;
    C(offset:offset+chunkSize-1)= Ctmp(:);
end
t1=GetSecs();
fprintf('%.2f Seconds \n',t1-t0);


Agpu = gpuArray(A);


C = zeros(N,K);
t0=GetSecs();
for i=1:numChunks
    fprintf('%d\n',i);
    B_gpu = gpuArray(B(:,startInd(i):endInd(i)));
    C(:,startInd(i):endInd(i))=gather(Agpu*B_gpu);
end
t1=GetSecs();
fprintf('%.2f Seconds \n',t1-t0);

